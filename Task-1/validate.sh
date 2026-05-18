#!/bin/bash

# Validation script for Task 1: Persistent Storage
# This script checks if the PVC and Pod have been created correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 1: Persistent Storage"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=15

# Check 1: PVC exists (2 points)
echo "Check 1: Does the PersistentVolumeClaim exist?"
if kubectl get pvc app-storage-pvc -n default &> /dev/null; then
    echo "✓ PVC 'app-storage-pvc' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ PVC 'app-storage-pvc' not found in default namespace"
    echo ""
    echo "Current PVCs in default namespace:"
    kubectl get pvc -n default 2>/dev/null || echo "  No PVCs found"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: PVC storage size (1 point)
echo "Check 2: Is the PVC storage size correct?"
STORAGE=$(kubectl get pvc app-storage-pvc -n default -o jsonpath='{.spec.resources.requests.storage}')
if [ "$STORAGE" == "100Mi" ]; then
    echo "✓ PVC storage size is 100Mi (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ PVC storage size is: $STORAGE (expected: 100Mi)"
fi

# Check 3: PVC access mode (1 point)
echo "Check 3: Is the PVC access mode correct?"
ACCESS_MODE=$(kubectl get pvc app-storage-pvc -n default -o jsonpath='{.spec.accessModes[0]}')
if [ "$ACCESS_MODE" == "ReadWriteOnce" ]; then
    echo "✓ PVC access mode is ReadWriteOnce (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ PVC access mode is: $ACCESS_MODE (expected: ReadWriteOnce)"
fi

# Check 4: PVC storage class (1 point)
echo "Check 4: Is the PVC using the correct storage class?"
STORAGE_CLASS=$(kubectl get pvc app-storage-pvc -n default -o jsonpath='{.spec.storageClassName}')
if [ "$STORAGE_CLASS" == "local-path" ]; then
    echo "✓ PVC uses 'local-path' storage class (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ PVC storage class is: $STORAGE_CLASS (expected: local-path)"
fi

# Check 5: PVC is bound (2 points)
echo "Check 5: Is the PVC bound to a PersistentVolume?"
PVC_STATUS=$(kubectl get pvc app-storage-pvc -n default -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" == "Bound" ]; then
    echo "✓ PVC is in Bound state (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    PV_NAME=$(kubectl get pvc app-storage-pvc -n default -o jsonpath='{.spec.volumeName}')
    echo "  Bound to PersistentVolume: $PV_NAME"
else
    echo "✗ PVC status is: $PVC_STATUS (expected: Bound)"
    echo "  This may indicate a problem with the storage provisioner"
fi

# Check 6: Pod exists (2 points)
echo "Check 6: Does the Pod exist?"
if kubectl get pod app-pod -n default &> /dev/null; then
    echo "✓ Pod 'app-pod' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Pod 'app-pod' not found in default namespace"
    echo ""
    echo "Current pods in default namespace:"
    kubectl get pods -n default 2>/dev/null || echo "  No pods found"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 7: Pod image (1 point)
echo "Check 7: Is the Pod using the correct image?"
POD_IMAGE=$(kubectl get pod app-pod -n default -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" == *"nginx"* ]] && [[ "$POD_IMAGE" == *"alpine"* ]]; then
    echo "✓ Pod uses nginx:alpine image (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ Pod image is: $POD_IMAGE (expected: nginx:alpine)"
fi

# Check 8: Pod is running (2 points)
echo "Check 8: Is the Pod running?"
POD_STATUS=$(kubectl get pod app-pod -n default -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" == "Running" ]; then
    echo "✓ Pod is running (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Pod status is: $POD_STATUS (expected: Running)"
    echo "  Pod details:"
    kubectl describe pod app-pod -n default | tail -20
fi

# Check 9: Volume is mounted correctly (2 points)
echo "Check 9: Is the volume mounted at /data?"
MOUNT_PATH=$(kubectl get pod app-pod -n default -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}')
VOLUME_NAME=$(kubectl get pod app-pod -n default -o jsonpath='{.spec.containers[0].volumeMounts[0].name}')
PVC_NAME=$(kubectl get pod app-pod -n default -o jsonpath='{.spec.volumes[?(@.name=="'$VOLUME_NAME'")].persistentVolumeClaim.claimName}')

if [ "$MOUNT_PATH" == "/data" ] && [ "$PVC_NAME" == "app-storage-pvc" ]; then
    echo "✓ Volume mounted correctly at /data (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Volume mount configuration issue"
    echo "  Mount path: $MOUNT_PATH (expected: /data)"
    echo "  PVC reference: $PVC_NAME (expected: app-storage-pvc)"
fi

# Check 10: Volume is writable (1 point)
echo "Check 10: Can data be written to the volume?"
if [ "$POD_STATUS" == "Running" ]; then
    # Try to write to the volume
    if kubectl exec app-pod -n default -- sh -c "echo 'validation-test' > /data/test-validation.txt" &> /dev/null; then
        # Try to read from the volume
        READ_DATA=$(kubectl exec app-pod -n default -- cat /data/test-validation.txt 2>/dev/null)
        if [ "$READ_DATA" == "validation-test" ]; then
            echo "✓ Volume is writable and readable (1 point)"
            TOTAL_POINTS=$((TOTAL_POINTS + 1))
        else
            echo "✗ Data written doesn't match data read"
        fi
    else
        echo "✗ Cannot write to /data directory"
        echo "  Check mount path and permissions"
    fi
else
    echo "⚠ Skipping write test (pod not running)"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent work!"
    echo ""
    echo "✓ PersistentVolumeClaim created correctly"
    echo "✓ PVC is bound to a PersistentVolume"
    echo "✓ Pod created with correct specifications"
    echo "✓ Volume mounted and functional"
    echo ""
    echo "BONUS CHALLENGE (optional):"
    echo "Test data persistence:"
    echo "  1. kubectl exec app-pod -- sh -c 'echo persist-test > /data/persist.txt'"
    echo "  2. kubectl delete pod app-pod"
    echo "  3. kubectl apply -f <your-pod-manifest.yaml>"
    echo "  4. kubectl exec app-pod -- cat /data/persist.txt"
    echo "  If you see 'persist-test', your storage is truly persistent!"
    echo ""
elif [ $TOTAL_POINTS -ge 12 ]; then
    echo "✅ PASSED! Good work, with minor issues."
    echo ""
    echo "Review the output above to see what could be improved."
    echo ""
elif [ $TOTAL_POINTS -ge 8 ]; then
    echo "⚠️ PARTIAL PASS - Several issues to fix"
    echo ""
    echo "Review the failed checks above."
    echo "Check Task-1/SolutionNotes.bash for hints."
    echo ""
else
    echo "❌ NEEDS WORK"
    echo ""
    echo "Review the failed checks above."
    echo "Read Task-1/Question.bash again carefully."
    echo "Check Task-1/SolutionNotes.bash for guidance."
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""

# Show resource details
echo "Resource Summary:"
echo ""
echo "PersistentVolumeClaim:"
kubectl get pvc app-storage-pvc -n default 2>/dev/null || echo "  Not found"
echo ""
echo "Pod:"
kubectl get pod app-pod -n default 2>/dev/null || echo "  Not found"
echo ""

exit 0
