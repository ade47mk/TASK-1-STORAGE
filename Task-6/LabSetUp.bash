#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 6: Pod Security Standards"
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

# Check Kubernetes version (PSS requires 1.23+)
echo ""
echo "Checking Kubernetes version..."
K8S_VERSION=$(kubectl version --short 2>/dev/null | grep "Server Version" | awk '{print $3}')
echo "Kubernetes version: $K8S_VERSION"

# Check if namespace exists
echo ""
echo "Checking for existing namespace..."
if kubectl get namespace restricted-ns &> /dev/null; then
    echo "⚠ Namespace 'restricted-ns' already exists"
    echo "  Deleting and recreating..."
    kubectl delete namespace restricted-ns --wait=true 2>/dev/null
    sleep 3
fi

# Create the namespace WITHOUT labels (student will add them)
echo ""
echo "Creating namespace 'restricted-ns'..."
kubectl create namespace restricted-ns

if kubectl get namespace restricted-ns &> /dev/null; then
    echo "✓ Namespace 'restricted-ns' created"
else
    echo "✗ Failed to create namespace"
    exit 1
fi

# Show current namespace labels
echo ""
echo "Current namespace labels:"
kubectl get namespace restricted-ns --show-labels

# Clean up any existing test pods
echo ""
echo "Cleaning up any existing test pods..."
kubectl delete pods --all -n restricted-ns --force --grace-period=0 2>/dev/null
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Namespace 'restricted-ns' created (no security labels yet)"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Add Pod Security Standard labels to the namespace"
echo "  3. Test with privileged and restricted pods"
echo "  4. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Pod Security Standards are enforced via namespace labels"
echo ""
echo "Good luck! 🚀"
echo ""
