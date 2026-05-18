#!/bin/bash

# Solution Notes for Task 3: Manual PV and PVC Creation
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Manual PV and PVC Creation
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task focuses on manual PV provisioning without a StorageClass:
1. Creating a PV with specific node targeting
2. Using empty storageClassName for manual binding
3. Configuring Retain reclaim policy
4. Ensuring proper PV/PVC matching

KEY CONCEPTS
------------
• Manual Provisioning: Admin creates PV before PVC
• Empty StorageClassName: Use "" to bypass dynamic provisioning
• Node Affinity: Restricts which nodes can use the volume
• Retain Policy: PV remains after PVC deletion
• HostPath: Uses directory on the node's filesystem

APPROACH
--------

STEP 1: Get the Node Name
--------------------------
First, identify the actual node name in your cluster:

```bash
kubectl get nodes
```

If you see node-1, use it. Otherwise, use the actual node name.

For example:
```bash
NAME                 STATUS   ROLES           AGE   VERSION
controlplane         Ready    control-plane   10d   v1.28.0
```

In this case, use "controlplane" instead of "node-1".

STEP 2: Create the PersistentVolume
------------------------------------

Complete PV manifest (static-pv-example.yaml):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv-example
spec:
  capacity:
    storage: 200Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/data
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node-1  # Replace with actual node name
```

Key points explained:

1. **capacity.storage: 200Mi**
   - Must be >= PVC request
   - PVC asks for 200Mi, PV provides 200Mi

2. **accessModes: [ReadWriteOnce]**
   - Volume can be mounted read-write by single node
   - Must match PVC access mode

3. **persistentVolumeReclaimPolicy: Retain**
   - When PVC is deleted, PV becomes "Released"
   - Data is preserved for manual recovery
   - Admin must manually clean up

4. **storageClassName: ""**
   - CRITICAL: Empty string (not null, not omitted)
   - Tells Kubernetes this is a manual PV
   - Only PVCs with storageClassName: "" can bind

5. **hostPath**
   - Uses local directory on the node
   - path: /mnt/data (directory path)
   - type: DirectoryOrCreate (creates if missing)

6. **nodeAffinity**
   - Restricts volume to specific node
   - Uses kubernetes.io/hostname label
   - Replace "node-1" with actual node name

Save and apply:
```bash
kubectl apply -f static-pv-example.yaml
```

Verify:
```bash
kubectl get pv static-pv-example
# Should show STATUS: Available
```

STEP 3: Create the PersistentVolumeClaim
-----------------------------------------

Complete PVC manifest (static-pvc-example.yaml):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-pvc-example
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 200Mi
```

Key points explained:

1. **namespace: default**
   - PVCs are namespace-scoped
   - Explicitly set to default

2. **accessModes: [ReadWriteOnce]**
   - Must match PV access mode

3. **storageClassName: ""**
   - CRITICAL: Empty string (same as PV)
   - Enables binding to manual PV
   - Without this, Kubernetes tries dynamic provisioning

4. **resources.requests.storage: 200Mi**
   - Must be <= PV capacity
   - Matches PV capacity exactly

Save and apply:
```bash
kubectl apply -f static-pvc-example.yaml
```

Verify binding:
```bash
kubectl get pvc static-pvc-example
# Should show STATUS: Bound

kubectl get pv static-pv-example
# Should show STATUS: Bound, CLAIM: default/static-pvc-example
```

STEP 4: Verify the Binding
---------------------------

Check PVC details:
```bash
kubectl describe pvc static-pvc-example
```

Look for:
- Status: Bound
- Volume: static-pv-example

Check PV details:
```bash
kubectl describe pv static-pv-example
```

Look for:
- Status: Bound
- Claim: default/static-pvc-example

STEP 5: Test with a Pod (Optional)
-----------------------------------

Create test pod (test-pod.yaml):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: default
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
      claimName: static-pvc-example
```

Apply and test:
```bash
kubectl apply -f test-pod.yaml

# Wait for pod to be ready
kubectl wait --for=condition=ready pod/test-pod --timeout=60s

# Write test data
kubectl exec test-pod -- sh -c "echo 'test' > /data/test.txt"

# Read test data
kubectl exec test-pod -- cat /data/test.txt
# Should output: test
```

COMMON MISTAKES
---------------

❌ Wrong: Omitting storageClassName
```yaml
spec:
  accessModes:
    - ReadWriteOnce
  # Missing storageClassName - Kubernetes uses default class
```

✓ Correct: Explicit empty string
```yaml
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""  # Explicit empty for manual binding
```

❌ Wrong: Using null for storageClassName
```yaml
storageClassName: null  # Not the same as ""
```

✓ Correct: Empty string
```yaml
storageClassName: ""  # Correct for manual binding
```

❌ Wrong: Wrong node name
```yaml
nodeAffinity:
  required:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/hostname
        operator: In
        values:
        - node-1  # But cluster has "controlplane"
```

✓ Correct: Actual node name
```yaml
nodeAffinity:
  required:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/hostname
        operator: In
        values:
        - controlplane  # Use actual node name
```

❌ Wrong: Mismatched access modes
```yaml
# PV
accessModes:
  - ReadWriteOnce

# PVC
accessModes:
  - ReadWriteMany  # Mismatch!
```

✓ Correct: Matching access modes
```yaml
# Both PV and PVC
accessModes:
  - ReadWriteOnce
```

❌ Wrong: PVC requests more than PV provides
```yaml
# PV
capacity:
  storage: 200Mi

# PVC
resources:
  requests:
    storage: 500Mi  # Too much!
```

✓ Correct: PVC requests <= PV capacity
```yaml
# PV
capacity:
  storage: 200Mi

# PVC
resources:
  requests:
    storage: 200Mi  # Matches or less
```

TROUBLESHOOTING
---------------

Problem: PVC stuck in Pending
→ Check if PV exists:
  kubectl get pv static-pv-example

→ Check if storageClassName matches:
  kubectl get pv static-pv-example -o yaml | grep storageClassName
  kubectl get pvc static-pvc-example -o yaml | grep storageClassName
  # Both should show: storageClassName: ""

→ Check PVC events:
  kubectl describe pvc static-pvc-example

→ Verify access modes match:
  kubectl get pv static-pv-example -o jsonpath='{.spec.accessModes}'
  kubectl get pvc static-pvc-example -o jsonpath='{.spec.accessModes}'

Problem: PVC binds to wrong PV
→ Ensure PV has storageClassName: ""
→ Ensure PVC has storageClassName: ""
→ Check if there are other available PVs

Problem: PV not available
→ Check node affinity matches real node:
  kubectl get nodes
  kubectl get pv static-pv-example -o yaml | grep -A 10 nodeAffinity

→ Verify hostPath is accessible on node

Problem: "no persistent volumes available"
→ PV doesn't exist yet - create it first
→ PV exists but storageClassName mismatch
→ PV capacity is less than PVC request

KUBECTL CHEAT SHEET
-------------------
# Get node names
kubectl get nodes
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Create PV
kubectl apply -f static-pv-example.yaml

# Check PV
kubectl get pv
kubectl get pv static-pv-example
kubectl describe pv static-pv-example

# Create PVC
kubectl apply -f static-pvc-example.yaml

# Check PVC
kubectl get pvc
kubectl get pvc static-pvc-example -n default
kubectl describe pvc static-pvc-example -n default

# Check binding
kubectl get pv,pvc
kubectl get pv static-pv-example -o yaml | grep claimRef -A 5

# Check if bound correctly
kubectl get pvc static-pvc-example -o jsonpath='{.spec.volumeName}'
# Should output: static-pv-example

# Clean up
kubectl delete pvc static-pvc-example
kubectl delete pv static-pv-example

UNDERSTANDING STORAGECLASSNAME: ""
-----------------------------------

Three scenarios:

1. **Dynamic Provisioning** (with StorageClass):
   ```yaml
   storageClassName: local-path
   ```
   - Kubernetes creates PV automatically
   - Uses specified StorageClass provisioner

2. **Manual Provisioning** (empty string):
   ```yaml
   storageClassName: ""
   ```
   - Kubernetes looks for existing PVs
   - PV must also have storageClassName: ""
   - Admin creates PV manually

3. **Default StorageClass** (omitted):
   ```yaml
   # No storageClassName field
   ```
   - Kubernetes uses default StorageClass
   - Creates PV automatically
   - NOT what we want for this task

EXAM TIPS
---------
1. Always check actual node names with kubectl get nodes
2. Remember storageClassName: "" (empty string) for manual binding
3. PV must exist before PVC for manual provisioning
4. Verify both PV and PVC have matching storageClassName: ""
5. Check events if PVC stays Pending
6. Use kubectl describe to debug binding issues
7. Remember: PV is cluster-scoped, PVC is namespace-scoped

TIME MANAGEMENT
---------------
For this task (10-15 minutes):
• 2 min: Check node names and understand requirements
• 3 min: Create PV manifest with node affinity
• 2 min: Create PVC manifest
• 2 min: Apply and verify binding
• 2 min: Debug if needed
• 2 min: Final verification

QUICK REFERENCE
---------------
PV checklist:
✓ name: static-pv-example
✓ capacity: 200Mi
✓ accessModes: [ReadWriteOnce]
✓ persistentVolumeReclaimPolicy: Retain
✓ storageClassName: ""
✓ hostPath configured
✓ nodeAffinity set

PVC checklist:
✓ name: static-pvc-example
✓ namespace: default
✓ accessModes: [ReadWriteOnce]
✓ storageClassName: ""
✓ requests.storage: 200Mi

Good luck! 🚀

EOF
