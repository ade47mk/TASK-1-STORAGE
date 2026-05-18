#!/bin/bash

# Verify that the local-path storage class exists
kubectl get storageclass local-path &> /dev/null
if [ $? -eq 0 ]; then
    echo "done"
    exit 0
else
    exit 1
fi
