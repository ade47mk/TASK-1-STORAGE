#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 5: Node Affinity"
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

# Check if any nodes already have disktype=ssd label
echo ""
echo "Checking for existing disktype labels..."
NODES_WITH_LABEL=$(kubectl get nodes -l disktype=ssd --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$NODES_WITH_LABEL" -gt 0 ]; then
    echo "✓ Found $NODES_WITH_LABEL node(s) with disktype=ssd label:"
    kubectl get nodes -l disktype=ssd
else
    echo "⚠ No nodes have disktype=ssd label yet"
    echo ""
    echo "You will need to label a node with disktype=ssd"
    echo ""
    echo "Example:"
    FIRST_NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    echo "  kubectl label nodes $FIRST_NODE disktype=ssd"
    echo ""
fi

# Clean up any existing resources from previous attempts
echo ""
echo "Cleaning up any previous attempts..."

# Delete pod if exists
if kubectl get pod ssd-pod 2>/dev/null; then
    echo "  Removing old pod..."
    kubectl delete pod ssd-pod --force --grace-period=0 2>/dev/null
    sleep 3
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Node information displayed"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Label a node with disktype=ssd"
echo "  3. Create a pod with node affinity"
echo "  4. Validate your solution: ./validate.sh"
echo ""
echo "Good luck! 🚀"
echo ""
