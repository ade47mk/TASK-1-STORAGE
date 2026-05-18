#!/bin/bash

# Task 3: Manual PV and PVC Creation
# Difficulty: Medium
# Points: 20
# Time: 10-15 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 3: Manual PV and PVC Creation
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 20
Time Estimate: 10-15 minutes

SCENARIO:
---------
You need to create storage for an application that requires a
specific PersistentVolume on a particular node. This storage
must be manually provisioned (no StorageClass) and must persist
even if the PVC is deleted.

OBJECTIVE:
----------
Manually create a PersistentVolume with specific requirements,
then create a matching PersistentVolumeClaim that binds to it.

REQUIREMENTS:
-------------

Part 1: PersistentVolume
  - Name: static-pv-example
  - Capacity: 200Mi
  - Access Mode: ReadWriteOnce
  - Reclaim Policy: Retain
  - Host Path: /mnt/data (or any valid path)
  - Node Affinity: Target node-1 (or adjust based on your cluster)
  - Storage Class: "" (empty string, for manual binding)
  - Namespace: N/A (PVs are cluster-scoped)

Part 2: PersistentVolumeClaim
  - Name: static-pvc-example
  - Storage Request: 200Mi
  - Access Mode: ReadWriteOnce
  - Storage Class: "" (empty string, to bind to manual PV)
  - Namespace: default

TASKS:
------
1. Create the PersistentVolume manifest
   - Configure hostPath volume
   - Set Retain reclaim policy
   - Add node affinity for node-1
   - Use empty storageClassName for manual binding

2. Create the PersistentVolumeClaim manifest
   - Match the PV capacity (200Mi)
   - Match the access mode (ReadWriteOnce)
   - Use empty storageClassName

3. Apply both manifests

4. Verify the PVC successfully binds to the PV

5. (Optional) Create a test pod to verify the volume works

VERIFICATION:
-------------
Your solution should meet these criteria:
- PV "static-pv-example" exists
- PV has capacity of 200Mi
- PV has access mode ReadWriteOnce
- PV has Retain reclaim policy
- PV uses hostPath volume type
- PV has node affinity configured
- PV has empty storageClassName ("")
- PVC "static-pvc-example" exists in default namespace
- PVC requests 200Mi storage
- PVC has access mode ReadWriteOnce
- PVC has empty storageClassName ("")
- PVC is in "Bound" state
- PVC is bound to "static-pv-example"

HINTS:
------
- Empty storageClassName: Use `storageClassName: ""`
  This tells Kubernetes to look for manual PVs only

- Node affinity format:
  ```yaml
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node-1
  ```

- Get actual node name:
  ```bash
  kubectl get nodes
  ```
  Use the actual node name in your manifest

- HostPath volume:
  ```yaml
  hostPath:
    path: /mnt/data
    type: DirectoryOrCreate
  ```

- PV and PVC must match on:
  * storageClassName (both empty)
  * accessModes (both ReadWriteOnce)
  * capacity (PV >= PVC request)

- Reclaim policy in PV spec:
  ```yaml
  persistentVolumeReclaimPolicy: Retain
  ```

- For manual binding (no StorageClass):
  * PV: storageClassName: ""
  * PVC: storageClassName: ""
  * Both must have empty string explicitly

DELIVERABLES:
-------------
- PV manifest (static-pv-example.yaml)
- PVC manifest (static-pvc-example.yaml)
- Both resources applied and functional
- PVC bound to PV

SCORING:
--------
- PV exists with correct name: 2 points
- PV has correct capacity (200Mi): 2 points
- PV has correct access mode: 2 points
- PV has Retain reclaim policy: 3 points
- PV uses hostPath: 2 points
- PV has node affinity: 2 points
- PV has empty storageClassName: 2 points
- PVC exists with correct name: 1 point
- PVC has correct specifications: 2 points
- PVC is bound to the PV: 2 points

Total: 20 points
Passing: 14 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Forgetting to set storageClassName: "" (empty string)
2. Using "null" instead of "" for storageClassName
3. Omitting storageClassName entirely (different from "")
4. Wrong node name in nodeAffinity
5. Mismatched access modes between PV and PVC
6. Capacity mismatch (PVC requests more than PV provides)

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
