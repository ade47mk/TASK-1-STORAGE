#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 14: Pod Admission - Resource Limits"
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

# Create limit-test namespace
echo ""
echo "Creating limit-test namespace..."
kubectl create namespace limit-test 2>/dev/null || echo "  Namespace might already exist"

# Verify namespace
if kubectl get namespace limit-test &> /dev/null; then
    echo "✓ Namespace 'limit-test' exists"
else
    echo "✗ Failed to create namespace"
    exit 1
fi

# Clean up any previous LimitRange or ResourceQuota
echo ""
echo "Cleaning up any previous resource limits..."
kubectl delete limitrange --all -n limit-test 2>/dev/null || true
kubectl delete resourcequota --all -n limit-test 2>/dev/null || true
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Namespace 'limit-test' created"
echo "✓ Previous resource limits cleaned up"
echo ""
echo "Current namespace status:"
kubectl get namespace limit-test 2>/dev/null
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Create LimitRange for default limits:"
echo "     - Default request: 100m CPU, 50Mi memory"
echo "     - Default limit: 200m CPU, 100Mi memory"
echo "  3. Create ResourceQuota for max limits:"
echo "     - Max memory per container: 500Mi"
echo "  4. Apply to limit-test namespace"
echo "  5. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Use LimitRange for defaults and ResourceQuota for max limits"
echo ""
echo "Good luck! 🚀"
echo ""
