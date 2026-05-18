#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 8: StatefulSets & Headless Services"
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

# Check for existing resources
echo ""
echo "Checking for existing resources..."

# Clean up any existing StatefulSet
if kubectl get statefulset web &> /dev/null; then
    echo "  Removing old StatefulSet..."
    kubectl delete statefulset web --force --grace-period=0 2>/dev/null
fi

# Clean up any existing Service
if kubectl get service web &> /dev/null; then
    echo "  Removing old Service..."
    kubectl delete service web 2>/dev/null
fi

# Clean up any existing PVCs
if kubectl get pvc -l app=nginx &> /dev/null 2>&1; then
    echo "  Removing old PVCs..."
    kubectl delete pvc -l app=nginx --force --grace-period=0 2>/dev/null
fi

# Wait for cleanup
sleep 5

# Check if StorageClass exists
echo ""
echo "Checking StorageClass..."
SC_COUNT=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$SC_COUNT" -gt 0 ]; then
    echo "✓ Found $SC_COUNT StorageClass(es)"
    kubectl get storageclass
    echo ""
    DEFAULT_SC=$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
    if [ -n "$DEFAULT_SC" ]; then
        echo "  Default StorageClass: $DEFAULT_SC"
    else
        echo "  ⚠ No default StorageClass found"
        echo "  You may need to specify storageClassName in volumeClaimTemplates"
    fi
else
    echo "⚠ No StorageClass found"
    echo "  StatefulSet requires a StorageClass for dynamic PV provisioning"
    echo "  In Killercoda CKA, 'local-path' is usually available"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Previous resources cleaned up"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Create Headless Service for StatefulSet"
echo "  3. Create StatefulSet with volumeClaimTemplates"
echo "  4. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: StatefulSets require a Headless Service (clusterIP: None)"
echo ""
echo "Good luck! 🚀"
echo ""
