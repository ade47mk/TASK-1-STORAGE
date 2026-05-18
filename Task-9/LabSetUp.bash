#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 9: CoreDNS Troubleshooting"
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

# Introduce DNS issues for troubleshooting practice
echo ""
echo "Introducing DNS issues for troubleshooting..."

# Check if CoreDNS exists
if kubectl get deployment coredns -n kube-system &> /dev/null; then
    echo "✓ CoreDNS deployment found"
    
    # Break CoreDNS intentionally for practice
    echo ""
    echo "Creating DNS issues:"
    
    # Issue 1: Scale down CoreDNS to 0 replicas
    echo "  1. Scaling CoreDNS to 0 replicas (simulating pod failure)"
    kubectl scale deployment coredns -n kube-system --replicas=0 2>/dev/null
    
    # Wait a moment
    sleep 3
    
    # Issue 2: Add a broken ConfigMap entry (optional, commented out)
    # This is more advanced and might require backup/restore
    # echo "  2. Adding incorrect configuration"
    
    echo ""
    echo "✓ DNS issues introduced"
else
    echo "⚠ CoreDNS not found in kube-system namespace"
    echo "  This setup assumes standard Kubernetes with CoreDNS"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ DNS issues introduced for troubleshooting practice"
echo ""
echo "Current DNS state:"
kubectl get pods -n kube-system -l k8s-app=coredns 2>/dev/null || echo "  No CoreDNS pods running (intentional)"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Test DNS to verify it's broken"
echo "  3. Investigate CoreDNS pods and deployment"
echo "  4. Fix the issues"
echo "  5. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Check CoreDNS pods, deployment, and logs"
echo ""
echo "Good luck! 🚀"
echo ""
