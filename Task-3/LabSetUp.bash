#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 3: Manual PV and PVC Creation"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verify kubectl is working
echo "Verifying cluster connectivity..."
if kubectl get nodes &> /dev/null; then
    echo "✓ kubectl is working"
    kubectl get nodes
else
    echo "✗ kubectl is not working properly"
    exit 1
fi

# Check nodes
echo ""
echo "Checking available nodes..."
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
echo "Found $NODE_COUNT node(s) in the cluster"

# Show node details
kubectl get nodes -o wide

# Check if node-1 exists (or use first available node)
echo ""
if kubectl get node node-1 &> /dev/null; then
    echo "✓ Node 'node-1' exists"
    TARGET_NODE="node-1"
else
    echo "⚠ Node 'node-1' not found"
    TARGET_NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    echo "  Using first available node: $TARGET_NODE"
    echo ""
    echo "  NOTE: Adjust your PV nodeAffinity to use: $TARGET_NODE"
fi

# Clean up any existing resources from previous attempts
echo ""
echo "Cleaning up any previous attempts..."

# Delete PVC if exists
if kubectl get pvc static-pvc-example 2>/dev/null; then
    echo "  Removing old PVC..."
    kubectl delete pvc static-pvc-example --force --grace-period=0 2>/dev/null
    sleep 3
fi

# Delete PV if exists
if kubectl get pv static-pv-example 2>/dev/null; then
    echo "  Removing old PV..."
    kubectl delete pv static-pv-example --force --grace-period=0 2>/dev/null
    sleep 3
fi

# Wait for resources to be fully deleted
echo "  Waiting for cleanup to complete..."
sleep 3

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Available node(s) identified"
echo "✓ Previous resources cleaned up"
echo ""
echo "Target node for hostPath: $TARGET_NODE"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Create PV manifest (static-pv-example)"
echo "  3. Create PVC manifest (static-pvc-example)"
echo "  4. Validate your solution: ./validate.sh"
echo ""
echo "Good luck! 🚀"
echo ""
