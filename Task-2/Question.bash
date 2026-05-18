#!/bin/bash

# Task 2: Advanced Storage Configuration
# Difficulty: Hard
# Points: 25
# Time: 15-20 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 2: Advanced Storage Configuration
════════════════════════════════════════════════════════════════

Difficulty: Hard
Points: 25
Time Estimate: 15-20 minutes

SCENARIO:
---------
Your organization needs a custom storage solution with specific
retention requirements. When storage is released, it should not
be automatically deleted but retained for manual inspection and
potential data recovery.

OBJECTIVE:
----------
Create a custom StorageClass with a Retain reclaim policy, then
manually create a PersistentVolume with node affinity and a
PersistentVolumeClaim that binds to it. Finally, verify the
retain behavior.

REQUIREMENTS:
-------------

Part 1: StorageClass
  - Name: fast-storage
  - Provisioner: rancher.io/local-path
  - Reclaim Policy: Retain
  - Volume Binding Mode: Immediate (default)
  - Namespace: default

Part 2: PersistentVolume
  - Name: fast-pv
  - Capacity: 500Mi
  - Access Mode: ReadWriteOnce
  - Storage Class: fast-storage
  - Host Path: /opt/local-path-provisioner (or any valid path)
  - Node Affinity: Configure to match a node in your cluster
  - Namespace: N/A (PVs are cluster-scoped)

Part 3: PersistentVolumeClaim
  - Name: fast-pvc
  - Storage Request: 500Mi
  - Access Mode: ReadWriteOnce
  - Storage Class: fast-storage
  - Namespace: default

Part 4: Verification
  - Create a test pod using the PVC
  - Write test data to the volume
  - Delete the PVC
  - Verify PV is in "Released" state (not "Deleted")

TASKS:
------
1. Create the StorageClass manifest with Retain policy
2. Create the PersistentVolume manifest with node affinity
3. Create the PersistentVolumeClaim manifest
4. Apply all manifests and verify binding
5. Create a test pod to use the PVC
6. Write data to the volume
7. Delete the PVC
8. Verify the PV status changes to "Released" (not deleted)

VERIFICATION:
-------------
Your solution should meet these criteria:
- StorageClass "fast-storage" exists with Retain policy
- PersistentVolume "fast-pv" exists with correct specs
- PV has node affinity configured
- PersistentVolumeClaim "fast-pvc" exists and is Bound
- PVC successfully binds to the PV (not dynamic provisioning)
- After PVC deletion, PV remains in "Released" state
- PV is NOT automatically deleted

HINTS:
------
- StorageClass reclaimPolicy field controls what happens to PV
  when PVC is deleted (Delete vs Retain)

- For manual PV, you need:
  * spec.capacity.storage
  * spec.accessModes
  * spec.storageClassName
  * spec.hostPath or similar volume source
  * spec.nodeAffinity (optional but recommended)

- PVC will bind to PV if:
  * Storage class matches
  * Capacity is sufficient
  * Access modes are compatible

- To test Retain policy:
  1. Create PVC and verify it binds
  2. kubectl delete pvc fast-pvc
  3. kubectl get pv fast-pv
  4. Status should show "Released" not "Bound"

- Node affinity example:
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <node-name>

- Get node name:
  kubectl get nodes -o jsonpath='{.items[0].metadata.name}'

DELIVERABLES:
-------------
- StorageClass manifest (applied to cluster)
- PersistentVolume manifest (applied to cluster)
- PersistentVolumeClaim manifest (applied to cluster)
- All resources created and functional
- PV remains after PVC deletion

SCORING:
--------
- Correct StorageClass specification: 5 points
- StorageClass has Retain policy: 3 points
- Correct PV specification: 5 points
- PV has node affinity: 2 points
- Correct PVC specification: 3 points
- PVC successfully binds to PV: 3 points
- PV remains after PVC deletion: 4 points

Total: 25 points
Passing: 18 points

════════════════════════════════════════════════════════════════

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for hints.

Good luck! 🚀

EOF
