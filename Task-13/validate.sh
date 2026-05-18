#!/bin/bash

# Validation script for Task 13: Gateway API - HTTP Routing
# This script checks if Gateway and HTTPRoute have been configured correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 13: Gateway API - HTTP Routing"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=22

# Check 1: Gateway resource exists (4 points)
echo "Check 1: Does Gateway resource exist?"
if kubectl get gateway web-gateway &>/dev/null; then
    echo "✓ Gateway 'web-gateway' exists (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    GATEWAY_EXISTS=true
elif kubectl get gateway &>/dev/null 2>&1 | grep -q gateway; then
    GATEWAY_NAME=$(kubectl get gateway -o name | head -1 | cut -d'/' -f2)
    echo "✓ Gateway '$GATEWAY_NAME' exists (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    GATEWAY_EXISTS=true
else
    echo "✗ No Gateway resource found"
    echo "  Create a Gateway using example-gw-class"
    GATEWAY_EXISTS=false
fi

# Check 2: Gateway uses example-gw-class (3 points)
if [ "$GATEWAY_EXISTS" = true ]; then
    echo "Check 2: Does Gateway use example-gw-class?"
    GW_CLASS=$(kubectl get gateway -o jsonpath='{.items[0].spec.gatewayClassName}' 2>/dev/null)
    
    if [ "$GW_CLASS" == "example-gw-class" ]; then
        echo "✓ Gateway uses example-gw-class (3 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 3))
    else
        echo "✗ Gateway uses '$GW_CLASS' (expected: example-gw-class)"
    fi
fi

# Check 3: Gateway has HTTP listener on port 80 (4 points)
if [ "$GATEWAY_EXISTS" = true ]; then
    echo "Check 3: Does Gateway have HTTP listener on port 80?"
    
    LISTENER_COUNT=$(kubectl get gateway -o jsonpath='{.items[0].spec.listeners[*].protocol}' 2>/dev/null | grep -o HTTP | wc -l | tr -d ' ')
    LISTENER_PORT=$(kubectl get gateway -o jsonpath='{.items[0].spec.listeners[?(@.protocol=="HTTP")].port}' 2>/dev/null)
    
    if [ "$LISTENER_PORT" == "80" ]; then
        echo "✓ Gateway has HTTP listener on port 80 (4 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 4))
    else
        echo "✗ Gateway HTTP listener port is '$LISTENER_PORT' (expected: 80)"
    fi
fi

# Check 4: HTTPRoute resource exists (4 points)
echo ""
echo "Check 4: Does HTTPRoute resource exist?"
if kubectl get httproute web-route &>/dev/null; then
    echo "✓ HTTPRoute 'web-route' exists (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    HTTPROUTE_EXISTS=true
elif kubectl get httproute &>/dev/null 2>&1 | grep -q httproute; then
    ROUTE_NAME=$(kubectl get httproute -o name | head -1 | cut -d'/' -f2)
    echo "✓ HTTPRoute '$ROUTE_NAME' exists (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    HTTPROUTE_EXISTS=true
else
    echo "✗ No HTTPRoute resource found"
    echo "  Create an HTTPRoute to route traffic"
    HTTPROUTE_EXISTS=false
fi

# Check 5: HTTPRoute references Gateway (3 points)
if [ "$HTTPROUTE_EXISTS" = true ]; then
    echo "Check 5: Does HTTPRoute reference a Gateway?"
    
    PARENT_REF=$(kubectl get httproute -o jsonpath='{.items[0].spec.parentRefs[0].name}' 2>/dev/null)
    
    if [ -n "$PARENT_REF" ]; then
        echo "✓ HTTPRoute references Gateway '$PARENT_REF' (3 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 3))
    else
        echo "✗ HTTPRoute has no parentRefs"
        echo "  Add parentRefs to link HTTPRoute to Gateway"
    fi
fi

# Check 6: HTTPRoute routes to web-service (4 points)
if [ "$HTTPROUTE_EXISTS" = true ]; then
    echo "Check 6: Does HTTPRoute route to web-service?"
    
    BACKEND_SERVICE=$(kubectl get httproute -o jsonpath='{.items[0].spec.rules[0].backendRefs[0].name}' 2>/dev/null)
    BACKEND_PORT=$(kubectl get httproute -o jsonpath='{.items[0].spec.rules[0].backendRefs[0].port}' 2>/dev/null)
    
    if [ "$BACKEND_SERVICE" == "web-service" ] && [ "$BACKEND_PORT" == "80" ]; then
        echo "✓ HTTPRoute routes to web-service:80 (4 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 4))
    elif [ "$BACKEND_SERVICE" == "web-service" ]; then
        echo "⚠ HTTPRoute routes to web-service but port is '$BACKEND_PORT' (expected: 80)"
        TOTAL_POINTS=$((TOTAL_POINTS + 2))
    else
        echo "✗ HTTPRoute routes to '$BACKEND_SERVICE' (expected: web-service)"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent Gateway API configuration!"
    echo ""
    echo "✓ Gateway resource configured"
    echo "✓ Correct GatewayClass"
    echo "✓ HTTP listener on port 80"
    echo "✓ HTTPRoute created"
    echo "✓ Route references Gateway"
    echo "✓ Routes to web-service"
    echo ""
elif [ $TOTAL_POINTS -ge 16 ]; then
    echo "✅ PASSED! Gateway API configured successfully!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 12 ]; then
    echo "⚠️ PARTIAL - Configuration incomplete"
    echo ""
    echo "Review the failed checks above."
    echo "Check SolutionNotes.bash for hints."
    echo ""
else
    echo "❌ NEEDS WORK"
    echo ""
    echo "Review the failed checks above."
    echo "Read the Question.bash again carefully."
    echo "Check SolutionNotes.bash for guidance."
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""

# Show current resources
echo "Current Gateway API Resources:"
echo ""
echo "GatewayClass:"
kubectl get gatewayclass example-gw-class 2>/dev/null || echo "  example-gw-class not found"
echo ""

echo "Gateway:"
kubectl get gateway 2>/dev/null || echo "  No Gateway resources found"
echo ""

echo "HTTPRoute:"
kubectl get httproute 2>/dev/null || echo "  No HTTPRoute resources found"
echo ""

echo "Service:"
kubectl get service web-service 2>/dev/null || echo "  web-service not found"
echo ""

# Show Gateway details if exists
if kubectl get gateway &>/dev/null 2>&1; then
    echo "Gateway Details:"
    kubectl get gateway -o yaml 2>/dev/null | grep -A 20 "spec:" | head -20
    echo ""
fi

# Show HTTPRoute details if exists
if kubectl get httproute &>/dev/null 2>&1; then
    echo "HTTPRoute Details:"
    kubectl get httproute -o yaml 2>/dev/null | grep -A 20 "spec:" | head -20
    echo ""
fi

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if [ "$GATEWAY_EXISTS" = false ]; then
        echo "Gateway not found:"
        echo "  Create gateway.yaml with Gateway resource"
        echo "  Use gatewayClassName: example-gw-class"
        echo "  Add HTTP listener on port 80"
        echo ""
    fi
    
    if [ "$GW_CLASS" != "example-gw-class" ]; then
        echo "Wrong GatewayClass:"
        echo "  Update Gateway to use gatewayClassName: example-gw-class"
        echo ""
    fi
    
    if [ "$HTTPROUTE_EXISTS" = false ]; then
        echo "HTTPRoute not found:"
        echo "  Create httproute.yaml with HTTPRoute resource"
        echo "  Add parentRefs to reference Gateway"
        echo "  Add backendRefs to reference web-service"
        echo ""
    fi
    
    if [ -z "$PARENT_REF" ]; then
        echo "HTTPRoute missing parentRefs:"
        echo "  Add spec.parentRefs:"
        echo "  - name: web-gateway"
        echo ""
    fi
    
    if [ "$BACKEND_SERVICE" != "web-service" ]; then
        echo "HTTPRoute not routing to web-service:"
        echo "  Update spec.rules[0].backendRefs:"
        echo "  - name: web-service"
        echo "    port: 80"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl get gateway,httproute"
    echo "  kubectl describe gateway <name>"
    echo "  kubectl describe httproute <name>"
    echo ""
fi

echo "💡 Complete Solution:"
echo ""
echo "# Gateway"
echo "cat > gateway.yaml << 'EOF'"
echo "apiVersion: gateway.networking.k8s.io/v1"
echo "kind: Gateway"
echo "metadata:"
echo "  name: web-gateway"
echo "spec:"
echo "  gatewayClassName: example-gw-class"
echo "  listeners:"
echo "  - name: http"
echo "    protocol: HTTP"
echo "    port: 80"
echo "    hostname: \"web.example.com\""
echo "EOF"
echo ""
echo "# HTTPRoute"
echo "cat > httproute.yaml << 'EOF'"
echo "apiVersion: gateway.networking.k8s.io/v1"
echo "kind: HTTPRoute"
echo "metadata:"
echo "  name: web-route"
echo "spec:"
echo "  parentRefs:"
echo "  - name: web-gateway"
echo "  hostnames:"
echo "  - \"web.example.com\""
echo "  rules:"
echo "  - backendRefs:"
echo "    - name: web-service"
echo "      port: 80"
echo "EOF"
echo ""
echo "# Apply"
echo "kubectl apply -f gateway.yaml"
echo "kubectl apply -f httproute.yaml"
echo ""
echo "# Verify"
echo "kubectl get gateway,httproute"
echo ""

exit 0
