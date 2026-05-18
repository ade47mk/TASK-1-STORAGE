#!/bin/bash

# Validation script for Task 4: Horizontal Pod Autoscaling
# This script checks if the HPA has been configured correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 4: Horizontal Pod Autoscaling"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=20

# Check 1: Deployment exists (prerequisite, no points)
echo "Check 1: Does the target deployment exist?"
if kubectl get deployment cpu-demo &> /dev/null; then
    echo "✓ Deployment 'cpu-demo' exists"
    REPLICAS=$(kubectl get deployment cpu-demo -o jsonpath='{.spec.replicas}')
    echo "  Current replicas: $REPLICAS"
else
    echo "✗ Deployment 'cpu-demo' not found"
    echo ""
    echo "Run ./LabSetUp.bash to create the deployment first"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: HPA exists (3 points)
echo "Check 2: Does the HPA exist?"
if kubectl get hpa cpu-demo-hpa &> /dev/null; then
    echo "✓ HPA 'cpu-demo-hpa' exists (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ HPA 'cpu-demo-hpa' not found"
    echo ""
    echo "Current HPAs:"
    kubectl get hpa 2>/dev/null || echo "  No HPAs found"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 3: HPA targets correct deployment (3 points)
echo "Check 3: Does the HPA target the correct deployment?"
HPA_TARGET=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.spec.scaleTargetRef.name}')
HPA_KIND=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.spec.scaleTargetRef.kind}')

if [ "$HPA_TARGET" == "cpu-demo" ] && [ "$HPA_KIND" == "Deployment" ]; then
    echo "✓ HPA targets Deployment/cpu-demo (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ HPA targets: $HPA_KIND/$HPA_TARGET (expected: Deployment/cpu-demo)"
fi

# Check 4: Min replicas (2 points)
echo "Check 4: Is min replicas set correctly?"
MIN_REPLICAS=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.spec.minReplicas}')
if [ "$MIN_REPLICAS" == "1" ]; then
    echo "✓ Min replicas is 1 (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Min replicas is: $MIN_REPLICAS (expected: 1)"
fi

# Check 5: Max replicas (2 points)
echo "Check 5: Is max replicas set correctly?"
MAX_REPLICAS=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.spec.maxReplicas}')
if [ "$MAX_REPLICAS" == "5" ]; then
    echo "✓ Max replicas is 5 (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Max replicas is: $MAX_REPLICAS (expected: 5)"
fi

# Check 6: CPU target percentage (3 points)
echo "Check 6: Is CPU target set correctly?"
CPU_TARGET=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}')
if [ "$CPU_TARGET" == "50" ]; then
    echo "✓ CPU target is 50% (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ CPU target is: $CPU_TARGET% (expected: 50%)"
fi

# Check 7: HPA can read metrics (4 points)
echo "Check 7: Can HPA read metrics?"
HPA_STATUS=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.status.conditions[?(@.type=="ScalingActive")].status}')
CURRENT_METRIC=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null)

if [ "$HPA_STATUS" == "True" ]; then
    echo "✓ HPA ScalingActive condition is True (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    
    if [ -n "$CURRENT_METRIC" ]; then
        echo "  Current CPU: ${CURRENT_METRIC}%"
    fi
else
    echo "⚠ HPA ScalingActive: $HPA_STATUS"
    
    # Check if it's just initializing
    CURRENT_REPLICAS=$(kubectl get hpa cpu-demo-hpa -o jsonpath='{.status.currentReplicas}' 2>/dev/null)
    if [ -z "$CURRENT_REPLICAS" ]; then
        echo "  HPA is still initializing, wait a moment..."
    else
        echo "  Check if Metrics Server is installed and working"
        echo "  Run: kubectl top pods"
    fi
fi

# Check 8: HPA shows current/target metrics (3 points)
echo "Check 8: Does HPA show current and target metrics?"
HPA_OUTPUT=$(kubectl get hpa cpu-demo-hpa -o custom-columns=TARGETS:.status.currentMetrics[0].resource.current.averageUtilization,TARGET:.spec.metrics[0].resource.target.averageUtilization --no-headers 2>/dev/null)

if [ -n "$HPA_OUTPUT" ] && ! echo "$HPA_OUTPUT" | grep -q "<unknown>"; then
    echo "✓ HPA shows current and target metrics (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
    echo "  Metrics: $HPA_OUTPUT"
else
    echo "⚠ HPA metrics not available yet"
    echo "  This is normal if you just created the HPA"
    echo "  Wait 1-2 minutes for metrics to be collected"
    echo ""
    echo "  Check metrics availability:"
    echo "    kubectl top pods"
    echo "    kubectl get hpa --watch"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent work!"
    echo ""
    echo "✓ HPA created with correct name"
    echo "✓ HPA targets correct deployment"
    echo "✓ Min/Max replicas configured correctly"
    echo "✓ CPU target set to 50%"
    echo "✓ HPA successfully reading metrics"
    echo ""
elif [ $TOTAL_POINTS -ge 14 ]; then
    echo "✅ PASSED! Good work!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
    if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
        echo "💡 TIP: If metrics show as unavailable, wait a bit longer."
        echo "Metrics Server needs time to collect initial data."
    fi
    echo ""
elif [ $TOTAL_POINTS -ge 10 ]; then
    echo "⚠️ PARTIAL PASS - Several issues to fix"
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

# Show resource summary
echo "Resource Summary:"
echo ""
echo "Deployment:"
kubectl get deployment cpu-demo 2>/dev/null || echo "  Not found"
echo ""
echo "HPA:"
kubectl get hpa cpu-demo-hpa 2>/dev/null || echo "  Not found"
echo ""
echo "Pods:"
kubectl get pods -l app=cpu-demo 2>/dev/null || echo "  Not found"
echo ""

# Show detailed HPA info
if kubectl get hpa cpu-demo-hpa &> /dev/null; then
    echo "HPA Details:"
    echo ""
    kubectl describe hpa cpu-demo-hpa | head -30
    echo ""
fi

# Check Metrics Server
echo "Metrics Server Status:"
if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    METRICS_READY=$(kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.readyReplicas}')
    if [ "$METRICS_READY" -gt 0 ]; then
        echo "  ✓ Metrics Server is running"
    else
        echo "  ⚠ Metrics Server is not ready"
    fi
else
    echo "  ✗ Metrics Server not installed"
    echo ""
    echo "  Install Metrics Server:"
    echo "    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
fi
echo ""

# Show current metrics if available
echo "Current Metrics:"
if kubectl top pods -l app=cpu-demo &> /dev/null; then
    kubectl top pods -l app=cpu-demo
else
    echo "  Metrics not available yet"
    echo "  Wait 1-2 minutes and check again"
fi
echo ""

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if [ $TOTAL_POINTS -lt 11 ]; then
        echo "To create HPA (imperative):"
        echo "  kubectl autoscale deployment cpu-demo \\"
        echo "    --name=cpu-demo-hpa \\"
        echo "    --cpu-percent=50 \\"
        echo "    --min=1 \\"
        echo "    --max=5"
        echo ""
    fi
    
    if ! kubectl get hpa cpu-demo-hpa &> /dev/null; then
        echo "HPA not found. Create it with:"
        echo "  kubectl autoscale deployment cpu-demo --cpu-percent=50 --min=1 --max=5"
        echo ""
    elif echo "$HPA_OUTPUT" | grep -q "<unknown>" || [ -z "$HPA_OUTPUT" ]; then
        echo "Metrics not available:"
        echo "  1. Wait 1-2 minutes for initial metrics collection"
        echo "  2. Check Metrics Server: kubectl get pods -n kube-system | grep metrics"
        echo "  3. Try: kubectl top pods"
        echo "  4. Then check HPA again: kubectl get hpa --watch"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl get hpa cpu-demo-hpa"
    echo "  kubectl describe hpa cpu-demo-hpa"
    echo "  kubectl get hpa --watch"
    echo "  kubectl top pods"
    echo ""
fi

# Optional testing suggestion
echo "💡 OPTIONAL: Test HPA Scaling"
echo ""
echo "To test scale-up:"
echo "  # Generate load"
echo "  POD=\$(kubectl get pods -l app=cpu-demo -o jsonpath='{.items[0].metadata.name}')"
echo "  kubectl exec -it \$POD -- stress --cpu 1 --timeout 300s"
echo ""
echo "  # Watch HPA scale up"
echo "  kubectl get hpa --watch"
echo ""
echo "To test scale-down:"
echo "  # Stop the load and wait 5 minutes"
echo "  # HPA will scale back down to minReplicas"
echo ""

exit 0
