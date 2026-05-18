#!/bin/bash

echo "🔍 Verifying Kubernetes storage solution..."
echo ""

PASS=0
FAIL=0

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo "✅ $2"
        ((PASS++))
    else
        echo "❌ $2"
        ((FAIL++))
    fi
}

# Test 1: Check if PVC exists
echo "Test 1: Checking PersistentVolumeClaim..."
kubectl get pvc app-storage-pvc &> /dev/null
print_result $? "PVC 'app-storage-pvc' exists"

# Test 2: Check PVC specifications
if kubectl get pvc app-storage-pvc &> /dev/null; then
    STORAGE=$(kubectl get pvc app-storage-pvc -o jsonpath='{.spec.resources.requests.storage}')
    if [ "$STORAGE" == "100Mi" ]; then
        print_result 0 "PVC has correct storage size (100Mi)"
    else
        print_result 1 "PVC storage size is incorrect (expected: 100Mi, got: $STORAGE)"
    fi
    
    ACCESS_MODE=$(kubectl get pvc app-storage-pvc -o jsonpath='{.spec.accessModes[0]}')
    if [ "$ACCESS_MODE" == "ReadWriteOnce" ]; then
        print_result 0 "PVC has correct access mode (ReadWriteOnce)"
    else
        print_result 1 "PVC access mode is incorrect (expected: ReadWriteOnce, got: $ACCESS_MODE)"
    fi
    
    STORAGE_CLASS=$(kubectl get pvc app-storage-pvc -o jsonpath='{.spec.storageClassName}')
    if [ "$STORAGE_CLASS" == "local-path" ]; then
        print_result 0 "PVC uses correct storage class (local-path)"
    else
        print_result 1 "PVC storage class is incorrect (expected: local-path, got: $STORAGE_CLASS)"
    fi
fi

# Test 3: Check if PVC is bound
echo ""
echo "Test 2: Checking PVC status..."
PVC_STATUS=$(kubectl get pvc app-storage-pvc -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" == "Bound" ]; then
    print_result 0 "PVC is in Bound state"
    PV_NAME=$(kubectl get pvc app-storage-pvc -o jsonpath='{.spec.volumeName}')
    echo "   📦 Bound to PersistentVolume: $PV_NAME"
else
    print_result 1 "PVC is not bound (current status: $PVC_STATUS)"
fi

# Test 4: Check if Pod exists
echo ""
echo "Test 3: Checking Pod..."
kubectl get pod app-pod &> /dev/null
print_result $? "Pod 'app-pod' exists"

# Test 5: Check if Pod is running
if kubectl get pod app-pod &> /dev/null; then
    POD_STATUS=$(kubectl get pod app-pod -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" == "Running" ]; then
        print_result 0 "Pod is in Running state"
    else
        print_result 1 "Pod is not running (current status: $POD_STATUS)"
    fi
fi

# Test 6: Check volume mount
echo ""
echo "Test 4: Checking volume mount..."
if kubectl get pod app-pod &> /dev/null && [ "$POD_STATUS" == "Running" ]; then
    MOUNT_PATH=$(kubectl get pod app-pod -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}')
    if [ "$MOUNT_PATH" == "/data" ]; then
        print_result 0 "Volume is mounted at /data"
    else
        print_result 1 "Volume mount path is incorrect (expected: /data, got: $MOUNT_PATH)"
    fi
    
    # Test if we can write to the volume
    kubectl exec app-pod -- sh -c "echo 'test' > /data/verify.txt" &> /dev/null
    if [ $? -eq 0 ]; then
        print_result 0 "Volume is writable"
    else
        print_result 1 "Volume is not writable"
    fi
    
    # Test if we can read from the volume
    kubectl exec app-pod -- cat /data/verify.txt &> /dev/null
    if [ $? -eq 0 ]; then
        print_result 0 "Volume is readable"
    else
        print_result 1 "Volume is not readable"
    fi
fi

# Summary
echo ""
echo "================================"
echo "Verification Summary"
echo "================================"
echo "✅ Passed: $PASS"
echo "❌ Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 Congratulations! All tests passed!"
    echo ""
    echo "Optional: Test data persistence"
    echo "  1. Delete the pod: kubectl delete pod app-pod"
    echo "  2. Recreate the pod: kubectl apply -f manifests/pod.yaml"
    echo "  3. Check if /data/verify.txt still exists"
    exit 0
else
    echo "⚠️  Some tests failed. Please review your configuration."
    echo ""
    echo "Troubleshooting tips:"
    echo "  - Check PVC status: kubectl describe pvc app-storage-pvc"
    echo "  - Check Pod status: kubectl describe pod app-pod"
    echo "  - Check Pod logs: kubectl logs app-pod"
    exit 1
fi
