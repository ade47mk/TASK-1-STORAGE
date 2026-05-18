#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 1: Persistent Storage"
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

# Check if local-path storage class exists
echo ""
echo "Checking for local-path storage class..."
if kubectl get storageclass local-path &> /dev/null; then
    echo "✓ local-path storage class exists"
else
    echo "⚠ local-path storage class not found"
    echo "  Installing local-path-provisioner..."
    
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    
    echo "  Waiting for provisioner to be ready..."
    sleep 10
    
    # Verify installation
    if kubectl get storageclass local-path &> /dev/null; then
        echo "✓ local-path storage class installed successfully"
    else
        echo "✗ Failed to install local-path storage class"
        exit 1
    fi
fi

# Show storage class details
echo ""
echo "Storage class details:"
kubectl get storageclass local-path -o yaml | grep -A 5 "^metadata:\|^provisioner:\|^reclaimPolicy:"

# Clean up any existing resources from previous attempts
echo ""
echo "Cleaning up any previous attempts..."

# Delete pod if exists
if kubectl get pod app-pod 2>/dev/null; then
    echo "  Removing old pod..."
    kubectl delete pod app-pod --force --grace-period=0 2>/dev/null
    sleep 5
fi

# Delete PVC if exists
if kubectl get pvc app-storage-pvc 2>/dev/null; then
    echo "  Removing old PVC..."
    kubectl delete pvc app-storage-pvc 2>/dev/null
    sleep 5
fi

# Wait for resources to be fully deleted
echo "  Waiting for cleanup to complete..."
sleep 5

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ local-path storage class is available"
echo "✓ Previous resources cleaned up"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Task-1/Question.bash"
echo "  2. Work on the task"
echo "  3. Validate your solution: ./Task-1/validate.sh"
echo ""
echo "Good luck! 🚀"
echo ""
