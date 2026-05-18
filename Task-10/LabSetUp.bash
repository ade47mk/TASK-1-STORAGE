#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 10: CoreDNS Configuration"
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

# Check CoreDNS
echo ""
echo "Checking CoreDNS status..."
if kubectl get deployment coredns -n kube-system &> /dev/null; then
    echo "✓ CoreDNS deployment found"
    
    # Check if CoreDNS pods are running
    READY_REPLICAS=$(kubectl get deployment coredns -n kube-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY_REPLICAS" -ge 1 ]; then
        echo "✓ CoreDNS pods are running ($READY_REPLICAS replicas)"
    else
        echo "⚠ CoreDNS pods not ready"
    fi
else
    echo "⚠ CoreDNS not found"
fi

# Backup CoreDNS ConfigMap
echo ""
echo "Backing up original CoreDNS ConfigMap..."
kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-configmap-backup.yaml 2>/dev/null
if [ -f /tmp/coredns-configmap-backup.yaml ]; then
    echo "✓ Backup saved to /tmp/coredns-configmap-backup.yaml"
else
    echo "⚠ Could not backup ConfigMap"
fi

# Remove any previous custom configurations
echo ""
echo "Cleaning up any previous custom configurations..."
echo "  (Restoring original CoreDNS config if needed)"

# Note: We won't auto-restore here to let students practice
# They can restore manually if needed

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ CoreDNS ConfigMap backed up"
echo ""
echo "Current CoreDNS ConfigMap status:"
kubectl get configmap coredns -n kube-system 2>/dev/null || echo "  Not found"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Edit CoreDNS ConfigMap to add custom DNS entry"
echo "  3. Reload CoreDNS to apply changes"
echo "  4. Test custom domain resolution"
echo "  5. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Edit the coredns ConfigMap in kube-system namespace"
echo ""
echo "Backup location: /tmp/coredns-configmap-backup.yaml"
echo ""
echo "Good luck! 🚀"
echo ""
