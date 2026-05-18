#!/bin/bash

echo "🧹 Cleaning up Kubernetes storage exam resources..."

# Delete Pod
if kubectl get pod app-pod &> /dev/null; then
    echo "Deleting Pod..."
    kubectl delete pod app-pod
fi

# Delete PVC (this will also delete the PV)
if kubectl get pvc app-storage-pvc &> /dev/null; then
    echo "Deleting PersistentVolumeClaim..."
    kubectl delete pvc app-storage-pvc
fi

# Wait for resources to be deleted
echo "Waiting for resources to be deleted..."
sleep 5

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "To start over:"
echo "  1. Run ./scripts/setup.sh"
echo "  2. Apply your manifests"
echo "  3. Verify with ./scripts/verify.sh"
