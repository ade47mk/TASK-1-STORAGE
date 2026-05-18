#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 7: Taints and Tolerations"
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

# Show available nodes
echo ""
echo "Available nodes in the cluster:"
kubectl get nodes -o wide

# Count nodes
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
echo ""
echo "Total nodes: $NODE_COUNT"

# Check if node-1 exists
echo ""
if kubectl get node node-1 &> /dev/null; then
    echo "✓ Node 'node-1' exists"
    TARGET_NODE="node-1"
else
    echo "⚠ Node 'node-1' not found"
    echo ""
    TARGET_NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    echo "  Using first available node: $TARGET_NODE"
    echo "  NOTE: Adjust commands to use: $TARGET_NODE instead of node-1"
fi

# Remove any existing taints from target node
echo ""
echo "Removing any existing taints from $TARGET_NODE..."
kubectl taint nodes $TARGET_NODE special- 2>/dev/null || echo "  (no taints to remove)"
kubectl taint nodes $TARGET_NODE dedicated- 2>/dev/null || echo "  (no taints to remove)"

# Clean up any existing test pods
echo ""
echo "Cleaning up any existing test pods..."
kubectl delete pod tolerated-pod untolerated-pod --force --grace-period=0 2>/dev/null
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Target node: $TARGET_NODE"
echo "✓ Node has no taints (clean slate)"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Add a taint to $TARGET_NODE"
echo "  3. Create a pod with matching toleration"
echo "  4. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Taints repel pods; tolerations allow scheduling"
echo ""
echo "Good luck! 🚀"
echo ""
