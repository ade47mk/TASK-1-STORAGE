#!/bin/bash

# Check if PVC exists
kubectl get pvc app-storage-pvc &> /dev/null
if [ $? -ne 0 ]; then
    exit 1
fi

# Check if PVC is bound
PVC_STATUS=$(kubectl get pvc app-storage-pvc -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" != "Bound" ]; then
    exit 1
fi

# Check storage size
STORAGE=$(kubectl get pvc app-storage-pvc -o jsonpath='{.spec.resources.requests.storage}')
if [ "$STORAGE" != "100Mi" ]; then
    exit 1
fi

# Check access mode
ACCESS_MODE=$(kubectl get pvc app-storage-pvc -o jsonpath='{.spec.accessModes[0]}')
if [ "$ACCESS_MODE" != "ReadWriteOnce" ]; then
    exit 1
fi

# Check storage class
STORAGE_CLASS=$(kubectl get pvc app-storage-pvc -o jsonpath='{.spec.storageClassName}')
if [ "$STORAGE_CLASS" != "local-path" ]; then
    exit 1
fi

echo "done"
