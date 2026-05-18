#!/bin/bash

# Task 1: Persistent Storage
# Difficulty: Medium
# Points: 15
# Time: 10-15 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 1: Persistent Storage
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 15
Time Estimate: 10-15 minutes

SCENARIO:
---------
A developer needs persistent storage for an application that generates
log files. The application needs to retain these logs even if the pod
is deleted and recreated.

OBJECTIVE:
----------
Create a PersistentVolumeClaim and a Pod that uses it for persistent
storage.

REQUIREMENTS:
-------------
1. PersistentVolumeClaim specifications:
   - Name: app-storage-pvc
   - Storage size: 100Mi
   - Access mode: ReadWriteOnce
   - Storage class: local-path
   - Namespace: default

2. Pod specifications:
   - Name: app-pod
   - Image: nginx:alpine
   - Container name: app-container
   - Mount the PVC at: /data
   - Namespace: default

TASKS:
------
1. Create the PersistentVolumeClaim manifest
2. Apply the PVC and verify it gets bound
3. Create the Pod manifest with volume mount
4. Apply the Pod and verify it's running
5. Test that data can be written to /data
6. Verify persistence (optional but recommended)

VERIFICATION:
-------------
Your solution should meet these criteria:
- PVC named "app-storage-pvc" exists in default namespace
- PVC is in "Bound" state
- PVC has correct size (100Mi) and access mode (ReadWriteOnce)
- PVC uses "local-path" storage class
- Pod named "app-pod" exists in default namespace
- Pod is in "Running" state
- Volume is mounted at /data inside the container
- Data can be written to and read from /data

HINTS:
------
- Use kubectl create to generate base manifests:
  kubectl create pvc <name> --dry-run=client -o yaml

- Check PVC status with:
  kubectl get pvc
  kubectl describe pvc app-storage-pvc

- Test volume mount with:
  kubectl exec app-pod -- sh -c "echo test > /data/test.txt"
  kubectl exec app-pod -- cat /data/test.txt

- To verify persistence (advanced):
  1. Write a test file to /data
  2. Delete the pod
  3. Recreate the pod
  4. Check if the file still exists

DELIVERABLES:
-------------
- PersistentVolumeClaim manifest (applied to cluster)
- Pod manifest with volume mount (applied to cluster)
- Both resources running and functional

SCORING:
--------
- Correct PVC specification: 5 points
- PVC successfully bound: 2 points
- Correct Pod specification: 3 points
- Pod successfully running: 2 points
- Volume properly mounted and writable: 2 points
- Data persistence works: 1 point

Total: 15 points
Passing: 12 points

════════════════════════════════════════════════════════════════

VALIDATION:
Run ./Task-1/validate.sh when complete to check your work.

Need help? Check Task-1/SolutionNotes.bash for hints.

Good luck! 🚀

EOF
