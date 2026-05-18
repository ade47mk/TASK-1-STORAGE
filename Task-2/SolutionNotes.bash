#!/bin/bash

# Solution Notes for Task 2: Advanced Storage Configuration
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Advanced Storage Configuration
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests advanced storage concepts:
1. Custom StorageClass with specific policies
2. Manual PV creation (not dynamic provisioning)
3. PV/PVC binding behavior
4. Reclaim policy understanding
5. Node affinity configuration

KEY CONCEPTS
------------
• StorageClass: Defines storage "classes" with policies
• Reclaim Policy: What happens to PV when PVC is deleted
  - Delete: PV is automatically deleted
  - Retain: PV remains for manual cleanup
• Node Affinity: Tells Kubernetes which nodes can use the volume
• Manual Provisioning: Admin creates PV, then PVC binds to it

APPROACH
--------

STEP 1: Create the StorageClass
---------------------------------
You need a StorageClass with Retain policy:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

Key points:
- provisioner: Must match installed provisioner
- reclaimPolicy: Retain (default is Delete)
- volumeBindingMode: Immediate (bind PVC immediately)

Save as storageclass.yaml and apply:
```bash
kubectl apply -f storageclass.yaml
```

Verify:
```bash
kubectl get storageclass fast-storage
kubectl describe storageclass fast-storage
```

STEP 2: Create the PersistentVolume
------------------------------------
You need to manually create a PV with node affinity:

First, get a node name:
```bash
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo $NODE_NAME
```

Then create PV:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fast-pv
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  hostPath:
    path: /opt/local-path-provisioner
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <NODE_NAME>  # Replace with actual node name
```

Key points:
- capacity.storage: Must be >= PVC request
- storageClassName: Must match StorageClass
- hostPath: Local directory on node
- nodeAffinity: Ensures volume is on specific node

Save as pv.yaml and apply:
```bash
kubectl apply -f pv.yaml
```

Verify:
```bash
kubectl get pv fast-pv
kubectl describe pv fast-pv
```

STEP 3: Create the PersistentVolumeClaim
-----------------------------------------
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  resources:
    requests:
      storage: 500Mi
```

Key points:
- storageClassName: Must match PV
- accessModes: Must be compatible with PV
- storage request: Must be <= PV capacity

Save as pvc.yaml and apply:
```bash
kubectl apply -f pvc.yaml
```

Verify binding:
```bash
kubectl get pvc fast-pvc
# STATUS should be "Bound"

kubectl get pv fast-pv
# STATUS should be "Bound", CLAIM should show "default/fast-pvc"
```

STEP 4: Test with a Pod (Optional but Recommended)
---------------------------------------------------
Create a test pod to verify the volume works:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-container
    image: busybox
    command: ["/bin/sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: fast-pvc
```

Save as pod.yaml and apply:
```bash
kubectl apply -f pod.yaml
```

Write test data:
```bash
kubectl exec test-pod -- sh -c "echo 'test data' > /data/test.txt"
kubectl exec test-pod -- cat /data/test.txt
```

STEP 5: Verify Retain Policy
-----------------------------
This is the critical test!

1. Delete the PVC:
```bash
kubectl delete pvc fast-pvc
```

2. Check PV status:
```bash
kubectl get pv fast-pv
```

Expected output:
- STATUS: "Released" (NOT "Available" or deleted)
- CLAIM: Still shows "default/fast-pvc"
- RECLAIM POLICY: "Retain"

The PV should remain in the cluster!

3. Check PV details:
```bash
kubectl describe pv fast-pv
```

You should see:
- Status: Released
- Claim Reference still present
- Volume is not deleted

COMMON MISTAKES
---------------

❌ Wrong: Using Delete reclaim policy
```yaml
reclaimPolicy: Delete  # PV will be deleted!
```

✓ Correct: Using Retain policy
```yaml
reclaimPolicy: Retain  # PV remains
```

❌ Wrong: Missing storageClassName in PV
```yaml
# Without storageClassName, PVC won't bind
spec:
  capacity:
    storage: 500Mi
```

✓ Correct: Including storageClassName
```yaml
spec:
  capacity:
    storage: 500Mi
  storageClassName: fast-storage
```

❌ Wrong: Mismatched storage class names
```yaml
# StorageClass
metadata:
  name: fast-storage

# PVC
spec:
  storageClassName: fast-store  # Typo!
```

✓ Correct: Matching names
```yaml
# Both use "fast-storage"
```

❌ Wrong: No node affinity
```yaml
# PV without nodeAffinity may not work properly
spec:
  hostPath:
    path: /opt/local-path-provisioner
```

✓ Correct: With node affinity
```yaml
spec:
  hostPath:
    path: /opt/local-path-provisioner
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <node-name>
```

TROUBLESHOOTING
---------------

Problem: PVC stuck in Pending
→ Check if PV exists:
  kubectl get pv

→ Check if storage class matches:
  kubectl get pvc fast-pvc -o yaml | grep storageClassName
  kubectl get pv fast-pv -o yaml | grep storageClassName

→ Check if capacity matches:
  kubectl describe pvc fast-pvc
  kubectl describe pv fast-pv

→ Check PVC events:
  kubectl describe pvc fast-pvc

Problem: PVC binds to wrong PV (dynamic provisioning)
→ Ensure PV has correct storageClassName
→ Ensure PV exists before creating PVC
→ Check if there are multiple PVs available

Problem: PV gets deleted when PVC is deleted
→ Check StorageClass reclaim policy:
  kubectl get storageclass fast-storage -o yaml | grep reclaimPolicy
  
→ Should show "Retain", not "Delete"

Problem: Node affinity errors
→ Verify node name is correct:
  kubectl get nodes
  
→ Check PV node affinity matches real node

→ Use correct hostname label:
  kubernetes.io/hostname

KUBECTL CHEAT SHEET
-------------------
# Get node name
kubectl get nodes
kubectl get nodes -o jsonpath='{.items[0].metadata.name}'

# Create StorageClass
kubectl apply -f storageclass.yaml

# Check StorageClass
kubectl get storageclass
kubectl describe storageclass fast-storage

# Create PV
kubectl apply -f pv.yaml

# Check PV
kubectl get pv
kubectl describe pv fast-pv
kubectl get pv fast-pv -o yaml

# Create PVC
kubectl apply -f pvc.yaml

# Check PVC
kubectl get pvc
kubectl describe pvc fast-pvc
kubectl get pvc fast-pvc -o yaml

# Check binding
kubectl get pv,pvc

# Test retain policy
kubectl delete pvc fast-pvc
kubectl get pv fast-pv
# Should show STATUS: Released

# Clean up
kubectl delete pv fast-pv
kubectl delete storageclass fast-storage

UNDERSTANDING RECLAIM POLICIES
-------------------------------

Delete (default):
- When PVC is deleted, PV is automatically deleted
- Underlying storage is cleaned up
- Use for: Temporary storage, dev environments

Retain (this task):
- When PVC is deleted, PV moves to "Released" state
- PV is NOT deleted
- Data is preserved
- Admin must manually clean up
- Use for: Important data, production, compliance

Recycle (deprecated):
- Basic data scrub (rm -rf /volume/*)
- PV becomes "Available" again
- Not recommended

EXAM TIPS
---------
1. Always check reclaim policy in StorageClass
2. Understand difference between Dynamic and Manual provisioning
3. Know how to configure node affinity
4. Practice testing retain behavior
5. Remember PVs are cluster-scoped (no namespace)
6. PVCs are namespace-scoped

TIME MANAGEMENT
---------------
For this task (15-20 minutes):
• 3-4 min: Create StorageClass
• 3-4 min: Create PV with node affinity
• 2-3 min: Create PVC
• 2-3 min: Verify binding
• 2-3 min: Test retain policy
• 3-5 min: Debug if needed

Good luck! 🚀

EOF
