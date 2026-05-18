#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 11: Helm - Traefik Ingress Controller"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verify kubectl is working
echo "Verifying cluster connectivity..."
if kubectl get nodes &> /dev/null; then
    echo "✓ kubectl is working"
else
    echo "✗ kubectl is not working properly"
    exit 1
fi

# Check if helm is installed
echo ""
echo "Checking Helm installation..."
if command -v helm &> /dev/null; then
    HELM_VERSION=$(helm version --short 2>/dev/null)
    echo "✓ Helm is installed: $HELM_VERSION"
else
    echo "⚠ Helm not found"
    echo ""
    echo "  Helm is required for this task."
    echo "  In Killercoda CKA playground, install with:"
    echo ""
    echo "    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo ""
fi

# Clean up any previous installations
echo ""
echo "Cleaning up any previous Traefik installations..."

# Delete helm release if exists
if helm list -n traefik 2>/dev/null | grep -q traefik; then
    echo "  Removing previous Traefik release..."
    helm uninstall traefik -n traefik 2>/dev/null || true
fi

# Delete namespace if exists
if kubectl get namespace traefik &> /dev/null; then
    echo "  Removing traefik namespace..."
    kubectl delete namespace traefik --force --grace-period=0 2>/dev/null || true
    sleep 3
fi

# Wait for cleanup
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Previous installations cleaned up"
echo ""

# Check if helm is available
if command -v helm &> /dev/null; then
    echo "✓ Helm is ready to use"
else
    echo "⚠ Install Helm before proceeding"
fi

echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Install Helm (if not already installed)"
echo "  3. Add Traefik Helm repository"
echo "  4. Create traefik namespace"
echo "  5. Install Traefik with Helm"
echo "  6. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Use helm install with custom values to enable Gateway API"
echo ""
echo "Good luck! 🚀"
echo ""
