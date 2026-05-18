#!/bin/bash

# Solution Notes for Task 5: Node Affinity
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Node Affinity
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. Node labels and label management
2. Node affinity configuration
3. Pod scheduling constraints
4. Difference between nodeSelector and nodeAffinity
5. Hard vs soft scheduling requirements

KEY CONCEPTS
------------
• Node Labels: Key-value metadata attached to nodes
• Node Affinity: Advanced scheduling rules based on node labels
• Required: Pod MUST be scheduled on matching nodes
• Preferred: Pod SHOULD be on matching nodes (soft constraint)
• Operators: In, NotIn, Exists, DoesNotExist, Gt, Lt

APPROACH
--------

STEP 1: Check Available Nodes
------------------------------

List all nodes:
```bash
kubectl get nodes
```

Example output:
```
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   10d   v1.28.0
node01         Ready    <none>          10d   v1.28.0
```

Check current labels:
```bash
kubectl get nodes --show-labels
```

View detailed labels for a specific node:
```bash
kubectl describe node controlplane
```

STEP 2: Label a Node
--------------------

Choose a node and label it:
```bash
kubectl label nodes controlplane disktype=ssd
```

Or use a different node:
```bash
kubectl label nodes node01 disktype=ssd
```

Verify the label:
```bash
kubectl get nodes -l disktype=ssd
```

Expected output:
```
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   10d   v1.28.0
```

Check the label on the node:
```bash
kubectl describe node controlplane | grep disktype
```

Should show: `disktype=ssd`

💡 You can label multiple nodes if you want, but one is enough.

STEP 3: Create Pod with Node Affinity
--------------------------------------

Complete pod manifest (ssd-pod.yaml):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
  namespace: default
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
  containers:
  - name: nginx
    image: nginx
```

Key sections explained:

1. **affinity.nodeAffinity**
   - Defines node selection rules
   - More powerful than simple nodeSelector

2. **requiredDuringSchedulingIgnoredDuringExecution**
   - HARD requirement - pod will NOT schedule without it
   - "DuringScheduling" = checked when pod is created
   - "IgnoredDuringExecution" = not checked while running

3. **nodeSelectorTerms**
   - List of node selector requirements
   - OR logic between terms
   - AND logic within a term

4. **matchExpressions**
   - Array of label requirements
   - key: disktype
   - operator: In (value must be in the list)
   - values: [ssd]

Alternative operators:

- **In**: Label value must be in the list
  ```yaml
  - key: disktype
    operator: In
    values:
    - ssd
    - nvme
  ```

- **NotIn**: Label value must NOT be in the list
  ```yaml
  - key: disktype
    operator: NotIn
    values:
    - hdd
  ```

- **Exists**: Label key must exist (any value)
  ```yaml
  - key: disktype
    operator: Exists
  ```

- **DoesNotExist**: Label key must NOT exist
  ```yaml
  - key: disktype
    operator: DoesNotExist
  ```

For this task, use **In** with value **ssd**.

STEP 4: Apply the Pod
---------------------

Save the manifest and apply:
```bash
kubectl apply -f ssd-pod.yaml
```

Check pod status:
```bash
kubectl get pod ssd-pod
```

Expected output:
```
NAME      READY   STATUS    RESTARTS   AGE
ssd-pod   1/1     Running   0          10s
```

STEP 5: Verify Scheduling
--------------------------

Check which node the pod is running on:
```bash
kubectl get pod ssd-pod -o wide
```

Look at the NODE column:
```
NAME      READY   STATUS    RESTARTS   AGE   NODE
ssd-pod   1/1     Running   0          20s   controlplane
```

Verify that node has the disktype=ssd label:
```bash
kubectl get node controlplane -o jsonpath='{.metadata.labels.disktype}'
```

Should output: `ssd`

Check pod details:
```bash
kubectl describe pod ssd-pod
```

Look for:
- Node: Should be a node with disktype=ssd
- Events: Should show successful scheduling

UNDERSTANDING NODE AFFINITY
----------------------------

Node Affinity has two types:

1. **requiredDuringSchedulingIgnoredDuringExecution** (HARD)
   - Pod will NOT be scheduled without matching nodes
   - Use this when requirement is absolute

2. **preferredDuringSchedulingIgnoredDuringExecution** (SOFT)
   - Pod PREFERS matching nodes but can schedule elsewhere
   - Includes a weight (1-100) for preference strength
   - Use when it's nice-to-have but not required

Example of PREFERRED:
```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
        - key: disktype
          operator: In
          values:
          - ssd
```

For this task, use **REQUIRED** (hard requirement).

COMMON MISTAKES
---------------

❌ Wrong: Forgetting to label nodes
```bash
# Pod created before labeling any nodes
kubectl apply -f ssd-pod.yaml
kubectl get pod ssd-pod
# STATUS: Pending (no nodes match)
```

✓ Correct: Label first, then create pod
```bash
kubectl label nodes controlplane disktype=ssd
kubectl apply -f ssd-pod.yaml
```

❌ Wrong: Using nodeSelector instead of nodeAffinity
```yaml
spec:
  nodeSelector:
    disktype: ssd  # This works but isn't nodeAffinity
```

✓ Correct: Use nodeAffinity
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution: ...
```

❌ Wrong: Wrong operator
```yaml
matchExpressions:
- key: disktype
  operator: Exists  # Wrong - doesn't check value
```

✓ Correct: Use "In" operator
```yaml
matchExpressions:
- key: disktype
  operator: In
  values:
  - ssd
```

❌ Wrong: Typo in label key or value
```yaml
# Node labeled: disktype=ssd
# Pod requires: diskType=ssd  # Wrong capitalization
```

✓ Correct: Exact match
```yaml
# Both use: disktype=ssd
```

❌ Wrong: Using preferred instead of required
```yaml
affinity:
  nodeAffinity:
    preferredDuringScheduling...  # Too weak
```

✓ Correct: Use required
```yaml
affinity:
  nodeAffinity:
    requiredDuringScheduling...  # Enforced
```

TROUBLESHOOTING
---------------

Problem: Pod stuck in Pending
→ No nodes have the required label
→ Check: kubectl get nodes -l disktype=ssd
→ Fix: kubectl label nodes <node-name> disktype=ssd

Problem: Pod scheduled on wrong node
→ Check if multiple nodes have the label
→ Verify node labels: kubectl get nodes --show-labels
→ Check pod's node: kubectl get pod ssd-pod -o wide

Problem: "node(s) didn't match Pod's node affinity/selector"
→ Node affinity requirements not met
→ Check label exists: kubectl get nodes -l disktype=ssd
→ Verify label value matches exactly

Problem: Can't find pod
→ Check namespace: kubectl get pod ssd-pod -n default
→ List all pods: kubectl get pods --all-namespaces

Problem: Wrong pod name in validation
→ Pod must be named exactly "ssd-pod"
→ Check: kubectl get pod ssd-pod

KUBECTL CHEAT SHEET
-------------------
# Label management
kubectl label nodes <node-name> disktype=ssd
kubectl label nodes <node-name> disktype-  # Remove label
kubectl get nodes --show-labels
kubectl get nodes -l disktype=ssd
kubectl describe node <node-name> | grep disktype

# Pod management
kubectl apply -f ssd-pod.yaml
kubectl get pod ssd-pod
kubectl get pod ssd-pod -o wide
kubectl describe pod ssd-pod

# Check scheduling
kubectl get pod ssd-pod -o jsonpath='{.spec.nodeName}'
kubectl get pod ssd-pod -o yaml | grep -A 10 nodeAffinity

# Debug
kubectl get events | grep ssd-pod
kubectl logs ssd-pod

# Cleanup
kubectl delete pod ssd-pod
kubectl label nodes <node-name> disktype-

NODEAFFINITY vs NODESELECTOR
-----------------------------

Both achieve similar goals but nodeAffinity is more powerful:

**nodeSelector** (Simple):
```yaml
spec:
  nodeSelector:
    disktype: ssd
```

Pros:
- Simple syntax
- Easy to read

Cons:
- Only supports exact match
- No OR logic
- No NOT logic
- No soft preferences

**nodeAffinity** (Advanced):
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
```

Pros:
- Multiple operators (In, NotIn, Exists, etc.)
- OR logic (multiple nodeSelectorTerms)
- Soft preferences (preferred...)
- More expressive

Cons:
- More verbose
- Slightly more complex

For this task, use **nodeAffinity**.

ADVANCED EXAMPLES
-----------------

Multiple label requirements (AND):
```yaml
matchExpressions:
- key: disktype
  operator: In
  values:
  - ssd
- key: zone
  operator: In
  values:
  - us-west
```

Multiple alternatives (OR):
```yaml
nodeSelectorTerms:
- matchExpressions:
  - key: disktype
    operator: In
    values:
    - ssd
- matchExpressions:
  - key: disktype
    operator: In
    values:
    - nvme
```

Both required AND preferred:
```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disktype
          operator: In
          values:
          - ssd
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
        - key: zone
          operator: In
          values:
          - us-west
```

EXAM TIPS
---------
1. Always label nodes BEFORE creating pods
2. Use "In" operator for exact value matching
3. Remember: requiredDuringScheduling... is the hard requirement
4. Verify labels with: kubectl get nodes -l <key>=<value>
5. Check pod placement with: kubectl get pod -o wide
6. Use kubectl describe to debug scheduling issues
7. Node affinity is under spec.affinity.nodeAffinity

TIME MANAGEMENT
---------------
For this task (8-12 minutes):
• 2 min: Check nodes and choose one
• 2 min: Label the node
• 3 min: Create pod manifest with node affinity
• 2 min: Apply and verify pod is scheduled
• 2 min: Debug if needed
• 1 min: Final verification

QUICK REFERENCE
---------------
Task checklist:
✓ Label node: kubectl label nodes <node> disktype=ssd
✓ Create pod manifest with nodeAffinity
✓ Use requiredDuringScheduling...
✓ matchExpressions with key=disktype, operator=In, values=[ssd]
✓ Pod name: ssd-pod
✓ Apply and verify

Commands:
```bash
# Label node
kubectl label nodes controlplane disktype=ssd

# Verify label
kubectl get nodes -l disktype=ssd

# Apply pod
kubectl apply -f ssd-pod.yaml

# Check scheduling
kubectl get pod ssd-pod -o wide
```

Good luck! 🚀

EOF
