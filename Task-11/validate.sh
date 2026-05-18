#!/bin/bash

# Validation script for Task 11: Helm - Traefik Ingress Controller
# This script checks if Traefik has been deployed correctly with Helm

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 11: Helm - Traefik Deployment"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=22

# Check 1: Helm installed (3 points)
echo "Check 1: Is Helm installed?"
if command -v helm &> /dev/null; then
    HELM_VERSION=$(helm version --short 2>/dev/null || echo "unknown")
    echo "✓ Helm is installed: $HELM_VERSION (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Helm not found"
    echo ""
    echo "Install Helm with:"
    echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: Traefik Helm repo added (3 points)
echo "Check 2: Is Traefik Helm repository added?"
if helm repo list 2>/dev/null | grep -q "traefik"; then
    echo "✓ Traefik Helm repository is added (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Traefik repository not found"
    echo "  Add with: helm repo add traefik https://traefik.github.io/charts"
fi

# Check 3: Traefik release exists (4 points)
echo "Check 3: Does Traefik Helm release exist?"
if helm list -n traefik 2>/dev/null | grep -q "traefik"; then
    echo "✓ Traefik Helm release exists (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ Traefik release not found"
    echo ""
    echo "Install with:"
    echo "  helm install traefik traefik/traefik -n traefik --create-namespace \\"
    echo "    --set providers.kubernetesGateway.enabled=true"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 4: Release name is "traefik" (2 points)
echo "Check 4: Is release name correct?"
RELEASE_NAME=$(helm list -n traefik -o json 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | head -1)

if [ "$RELEASE_NAME" == "traefik" ]; then
    echo "✓ Release name is 'traefik' (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Release name is '$RELEASE_NAME' (expected: traefik)"
fi

# Check 5: Deployed in "traefik" namespace (3 points)
echo "Check 5: Is release deployed in traefik namespace?"
NAMESPACE=$(helm list -n traefik -o json 2>/dev/null | grep -o '"namespace":"[^"]*"' | cut -d'"' -f4 | head -1)

if [ "$NAMESPACE" == "traefik" ]; then
    echo "✓ Deployed in 'traefik' namespace (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Deployed in '$NAMESPACE' namespace (expected: traefik)"
fi

# Check 6: Traefik pods running (4 points)
echo "Check 6: Are Traefik pods running?"
RUNNING_PODS=$(kubectl get pods -n traefik -l app.kubernetes.io/name=traefik --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$RUNNING_PODS" -ge 1 ]; then
    echo "✓ $RUNNING_PODS Traefik pod(s) running (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    kubectl get pods -n traefik -l app.kubernetes.io/name=traefik
else
    echo "✗ No Traefik pods running"
    echo "  Check pod status:"
    kubectl get pods -n traefik 2>/dev/null || echo "  No pods found"
fi

# Check 7: Gateway API enabled (3 points)
echo ""
echo "Check 7: Is Gateway API enabled in Traefik configuration?"
GATEWAY_ENABLED=$(helm get values traefik -n traefik 2>/dev/null | grep -A 2 "kubernetesGateway" | grep "enabled" | grep -o "true\|false")

if [ "$GATEWAY_ENABLED" == "true" ]; then
    echo "✓ Gateway API is enabled (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Gateway API not enabled"
    echo "  Enable with:"
    echo "  helm upgrade traefik traefik/traefik -n traefik \\"
    echo "    --set providers.kubernetesGateway.enabled=true"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent Helm deployment!"
    echo ""
    echo "✓ Helm installed"
    echo "✓ Traefik repository added"
    echo "✓ Release deployed correctly"
    echo "✓ Pods running"
    echo "✓ Gateway API enabled"
    echo ""
elif [ $TOTAL_POINTS -ge 16 ]; then
    echo "✅ PASSED! Traefik deployed successfully!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 12 ]; then
    echo "⚠️ PARTIAL - Deployment incomplete"
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

# Show Helm status
if command -v helm &> /dev/null; then
    echo "Helm Repositories:"
    helm repo list 2>/dev/null || echo "  No repositories added"
    echo ""
    
    echo "Helm Releases:"
    helm list -n traefik 2>/dev/null || echo "  No releases in traefik namespace"
    echo ""
fi

# Show Traefik resources
echo "Traefik Resources:"
echo ""
echo "Namespace:"
kubectl get namespace traefik 2>/dev/null || echo "  traefik namespace not found"
echo ""

echo "Pods:"
kubectl get pods -n traefik 2>/dev/null || echo "  No pods in traefik namespace"
echo ""

echo "Services:"
kubectl get services -n traefik 2>/dev/null || echo "  No services in traefik namespace"
echo ""

# Show Traefik values if release exists
if helm list -n traefik 2>/dev/null | grep -q "traefik"; then
    echo "Traefik Configuration (user-supplied values):"
    echo ""
    helm get values traefik -n traefik 2>/dev/null || echo "  Could not retrieve values"
    echo ""
fi

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if ! command -v helm &> /dev/null; then
        echo "Helm not installed:"
        echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
        echo ""
    fi
    
    if ! helm repo list 2>/dev/null | grep -q "traefik"; then
        echo "Traefik repository not added:"
        echo "  helm repo add traefik https://traefik.github.io/charts"
        echo "  helm repo update"
        echo ""
    fi
    
    if ! helm list -n traefik 2>/dev/null | grep -q "traefik"; then
        echo "Traefik not installed:"
        echo "  kubectl create namespace traefik"
        echo "  helm install traefik traefik/traefik -n traefik \\"
        echo "    --set providers.kubernetesGateway.enabled=true"
        echo ""
    fi
    
    if [ "$GATEWAY_ENABLED" != "true" ]; then
        echo "Gateway API not enabled:"
        echo "  helm upgrade traefik traefik/traefik -n traefik \\"
        echo "    --set providers.kubernetesGateway.enabled=true"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  helm list -n traefik"
    echo "  helm get values traefik -n traefik"
    echo "  kubectl get pods -n traefik"
    echo "  kubectl logs -n traefik -l app.kubernetes.io/name=traefik"
    echo ""
fi

echo "💡 Complete Solution:"
echo ""
echo "# Install Helm"
echo "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
echo ""
echo "# Add Traefik repository"
echo "helm repo add traefik https://traefik.github.io/charts"
echo "helm repo update"
echo ""
echo "# Install Traefik"
echo "helm install traefik traefik/traefik \\"
echo "  --namespace traefik \\"
echo "  --create-namespace \\"
echo "  --set providers.kubernetesGateway.enabled=true"
echo ""
echo "# Verify"
echo "helm list -n traefik"
echo "kubectl get pods -n traefik"
echo "helm get values traefik -n traefik"
echo ""

exit 0
