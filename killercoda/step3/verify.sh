#!/bin/bash

# Check if Pod exists
kubectl get pod app-pod &> /dev/null
if [ $? -ne 0 ]; then
    exit 1
fi

# Check if Pod is running
POD_STATUS=$(kubectl get pod app-pod -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    exit 1
fi

# Check if volume is mounted at /data
MOUNT_PATH=$(kubectl get pod app-pod -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name=="app-storage")].mountPath}')
if [ "$MOUNT_PATH" != "/data" ]; then
    exit 1
fi

# Check if volume uses the correct PVC
PVC_NAME=$(kubectl get pod app-pod -o jsonpath='{.spec.volumes[?(@.name=="app-storage")].persistentVolumeClaim.claimName}')
if [ "$PVC_NAME" != "app-storage-pvc" ]; then
    exit 1
fi

# Test if volume is writable
kubectl exec app-pod -- sh -c "echo 'test' > /data/verify.txt" &> /dev/null
if [ $? -ne 0 ]; then
    exit 1
fi

echo "done"
