#!/bin/bash

echo "🔧 Setting up Kubernetes storage exam environment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot access Kubernetes cluster. Please check your configuration."
    exit 1
fi

# Check if local-path storage class exists
if ! kubectl get storageclass local-path &> /dev/null; then
    echo "⚠️  local-path storage class not found."
    echo "Installing local-path-provisioner..."
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    sleep 5
fi

# Verify storage class
kubectl get storageclass local-path &> /dev/null
if [ $? -eq 0 ]; then
    echo "✅ local-path storage class is available"
else
    echo "❌ Failed to set up local-path storage class"
    exit 1
fi

echo ""
echo "✅ Setup complete! You can now work on the exam task."
echo ""
echo "Next steps:"
echo "  1. Create the PersistentVolumeClaim (PVC)"
echo "  2. Create the Pod that uses the PVC"
echo "  3. Run ./scripts/verify.sh to check your solution"
