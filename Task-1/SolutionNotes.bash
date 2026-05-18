#!/bin/bash

# Solution Notes for Task 1: Persistent Storage
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Persistent Storage
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your ability to:
1. Create a PersistentVolumeClaim (PVC)
2. Mount the PVC in a Pod
3. Verify that storage persists beyond pod lifecycle

KEY CONCEPTS
------------
• PersistentVolumeClaim (PVC): A request for storage by a user
• PersistentVolume (PV): The actual storage (auto-created by provisioner)
• StorageClass: Defines the "type" of storage and provisioner
• Volume Mount: Connects the storage to a directory in the container

APPROACH
--------

STEP 1: Create the PersistentVolumeClaim
-----------------------------------------
You need to create a PVC with these specs:
- Name: app-storage-pvc
- Size: 100Mi
- Access Mode: ReadWriteOnce
- Storage Class: local-path

Basic PVC structure:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 100Mi
```

Save this as pvc.yaml and apply:
```bash
kubectl apply -f pvc.yaml
```

Verify it's bound:
```bash
kubectl get pvc app-storage-pvc
# Should show STATUS: Bound
```

STEP 2: Create the Pod with Volume Mount
-----------------------------------------
You need to create a Pod that references the PVC.

Key components:
1. Define the volume in spec.volumes (references the PVC)
2. Mount the volume in the container (spec.containers[].volumeMounts)

Basic Pod structure:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app-container
    image: nginx:alpine
    volumeMounts:
    - name: storage-volume      # Must match volumes[].name below
      mountPath: /data           # Where to mount in the container
  volumes:
  - name: storage-volume         # Name you choose
    persistentVolumeClaim:
      claimName: app-storage-pvc # Must match PVC name
```

Save this as pod.yaml and apply:
```bash
kubectl apply -f pod.yaml
```

Verify the pod is running:
```bash
kubectl get pod app-pod
# Should show STATUS: Running
```

STEP 3: Verify the Volume Mount
--------------------------------
Test that you can write to /data:
```bash
kubectl exec app-pod -- sh -c "echo 'Hello from storage!' > /data/test.txt"
kubectl exec app-pod -- cat /data/test.txt
# Should output: Hello from storage!
```

STEP 4: Test Persistence (Optional but Recommended)
----------------------------------------------------
This proves the storage is truly persistent:

1. Write a file:
```bash
kubectl exec app-pod -- sh -c "echo 'persistence test' > /data/persist.txt"
```

2. Delete the pod:
```bash
kubectl delete pod app-pod
```

3. Recreate the pod:
```bash
kubectl apply -f pod.yaml
```

4. Wait for pod to be ready:
```bash
kubectl wait --for=condition=ready pod/app-pod --timeout=60s
```

5. Check if file still exists:
```bash
kubectl exec app-pod -- cat /data/persist.txt
# Should still output: persistence test
```

If you see the file, the PVC is working correctly!

COMMON MISTAKES
---------------

❌ Wrong: Using hostPath volume instead of PVC
```yaml
volumes:
- name: storage-volume
  hostPath:
    path: /data
```
This uses the node's filesystem, not a PVC.

✓ Correct: Using persistentVolumeClaim
```yaml
volumes:
- name: storage-volume
  persistentVolumeClaim:
    claimName: app-storage-pvc
```

❌ Wrong: Mismatched volume names
```yaml
volumeMounts:
- name: my-volume
  mountPath: /data
volumes:
- name: different-name  # Names must match!
  persistentVolumeClaim:
    claimName: app-storage-pvc
```

✓ Correct: Matching volume names
```yaml
volumeMounts:
- name: storage-volume
  mountPath: /data
volumes:
- name: storage-volume  # Same name
  persistentVolumeClaim:
    claimName: app-storage-pvc
```

❌ Wrong: Wrong PVC reference
```yaml
persistentVolumeClaim:
  claimName: wrong-pvc-name  # Must match actual PVC
```

✓ Correct: Correct PVC reference
```yaml
persistentVolumeClaim:
  claimName: app-storage-pvc  # Matches the PVC you created
```

TROUBLESHOOTING
---------------

Problem: PVC stuck in "Pending" state
→ Check if storage class exists:
  kubectl get storageclass local-path

→ Check provisioner is running:
  kubectl get pods -n local-path-storage

→ Check PVC events:
  kubectl describe pvc app-storage-pvc

Problem: Pod fails to start
→ Check if PVC is bound first:
  kubectl get pvc app-storage-pvc
  # Wait until STATUS is "Bound"

→ Check pod events:
  kubectl describe pod app-pod

→ Check pod logs:
  kubectl logs app-pod

Problem: Cannot write to /data
→ Verify mount path:
  kubectl describe pod app-pod | grep -A 5 "Mounts:"

→ Test write permissions:
  kubectl exec app-pod -- ls -la /data
  kubectl exec app-pod -- touch /data/test

→ Check if volume is actually mounted:
  kubectl exec app-pod -- df -h | grep /data

KUBECTL CHEAT SHEET
-------------------
# Generate PVC manifest
kubectl create pvc app-storage-pvc --dry-run=client -o yaml > pvc.yaml

# Check PVC status
kubectl get pvc
kubectl describe pvc app-storage-pvc

# Check PV (auto-created)
kubectl get pv

# Create pod from manifest
kubectl apply -f pod.yaml

# Check pod status
kubectl get pod app-pod
kubectl describe pod app-pod

# Test volume access
kubectl exec app-pod -- ls /data
kubectl exec app-pod -- sh -c "echo test > /data/file.txt"
kubectl exec app-pod -- cat /data/file.txt

# Delete and recreate for persistence test
kubectl delete pod app-pod
kubectl apply -f pod.yaml

# Clean up
kubectl delete pod app-pod
kubectl delete pvc app-storage-pvc

UNDERSTANDING ACCESS MODES
---------------------------
• ReadWriteOnce (RWO) - Volume can be mounted read-write by a single node
  → Use for: Single pod applications, databases
  
• ReadOnlyMany (ROX) - Volume can be mounted read-only by many nodes
  → Use for: Shared configuration, static content
  
• ReadWriteMany (RWX) - Volume can be mounted read-write by many nodes
  → Use for: Shared data between multiple pods
  → Note: Not all storage classes support this

For this task, ReadWriteOnce is correct because:
- We have a single pod
- The storage is node-local (local-path)
- It's the most common access mode

EXAM TIPS
---------
1. Always verify each resource after creating it
2. Use "kubectl describe" to troubleshoot issues
3. Check events with "kubectl get events"
4. Remember: PVC must be "Bound" before pod can use it
5. Use "kubectl exec" to verify volume is accessible
6. In the exam, save your manifests - you might need to recreate

TIME MANAGEMENT
---------------
For this task (10-15 minutes):
• 2-3 min: Create and verify PVC
• 3-5 min: Create and verify Pod
• 2-3 min: Test volume functionality
• 2-3 min: Debug if needed
• 1 min: Run validation script

Good luck! 🚀

EOF
