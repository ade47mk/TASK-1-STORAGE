#!/bin/bash

# Ensure Pod is running
POD_STATUS=$(kubectl get pod app-pod -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    exit 1
fi

# Check if test data exists
kubectl exec app-pod -- test -f /data/persistence-test.txt &> /dev/null
if [ $? -ne 0 ]; then
    exit 1
fi

# Verify all components are working correctly
./scripts/verify.sh &> /dev/null
if [ $? -eq 0 ]; then
    echo "done"
    exit 0
else
    exit 1
fi
