#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 2: Advanced Storage Configuration"
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

# Check if local-path provisioner is installed
echo ""
echo "Checking for rancher.io/local-path provisioner..."

if kubectl get deployment -n local-path-storage local-path-provisioner &> /dev/null; then
    echo "✓ local-path provisioner is installed"
else
    echo "⚠ local-path provisioner not found"
    echo "  Installing local-path-provisioner..."
    
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    
    echo "  Waiting for provisioner to be ready..."
    sleep 10
    
    if kubectl get deployment -n local-path-storage local-path-provisioner &> /dev/null; then
        echo "✓ local-path provisioner installed successfully"
    else
        echo "✗ Failed to install local-path provisioner"
        exit 1
    fi
fi

# Show provisioner details
echo ""
echo "Provisioner details:"
kubectl get deployment -n local-path-storage local-path-provisioner

# Clean up any existing resources from previous attempts
echo ""
echo "Cleaning up any previous attempts..."

# Delete PVC if exists
if kubectl get pvc fast-pvc 2>/dev/null; then
    echo "  Removing old PVC..."
    kubectl delete pvc fast-pvc --force --grace-period=0 2>/dev/null
    sleep 3
fi

# Delete PV if exists
if kubectl get pv fast-pv 2>/dev/null; then
    echo "  Removing old PV..."
    kubectl delete pv fast-pv --force --grace-period=0 2>/dev/null
    sleep 3
fi

# Delete StorageClass if exists
if kubectl get storageclass fast-storage 2>/dev/null; then
    echo "  Removing old StorageClass..."
    kubectl delete storageclass fast-storage 2>/dev/null
    sleep 2
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
echo "✓ Provisioner is available"
echo "✓ Previous resources cleaned up"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Work on the task"
echo "  3. Validate your solution: ./validate.sh"
echo ""
echo "Good luck! 🚀"
echo ""
