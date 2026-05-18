#!/bin/bash

# Solution Notes for Task 7: Taints and Tolerations
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Taints and Tolerations
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. Node taints for pod repelling
2. Pod tolerations for taint bypass
3. Taint effects (NoSchedule, PreferNoSchedule, NoExecute)
4. Scheduling constraints
5. Node isolation strategies

KEY CONCEPTS
------------
• Taints: Applied to nodes to repel pods
• Tolerations: Added to pods to "tolerate" taints
• Effect: How strictly the taint is enforced
• Key-Value Match: Taint and toleration must match
• Node Isolation: Dedicating nodes for specific workloads

APPROACH
--------

STEP 1: Understand Taints and Tolerations
------------------------------------------

Think of taints as "Do Not Enter" signs on nodes.
Tolerations are "special passes" that allow pods through.

Taint format: key=value:effect
- key: Label name (e.g., "special")
- value: Label value (e.g., "dedicated")
- effect: How to enforce (NoSchedule, PreferNoSchedule, NoExecute)

Example: special=dedicated:NoSchedule
- key: special
- value: dedicated
- effect: NoSchedule (block new pods)

STEP 2: Add Taint to Node
--------------------------

Check available nodes:
```bash
kubectl get nodes
```

Add taint to node-1:
```bash
kubectl taint nodes node-1 special=dedicated:NoSchedule
```

Verify the taint:
```bash
kubectl describe node node-1 | grep -A 5 Taint
```

Expected output:
```
Taints: special=dedicated:NoSchedule
```

Or:
```bash
kubectl get node node-1 -o jsonpath='{.spec.taints}'
```

What this does:
- Prevents normal pods from scheduling on node-1
- Existing pods remain (NoSchedule doesn't evict)
- Only pods with matching toleration can schedule

STEP 3: Test Without Toleration (Optional)
-------------------------------------------

Create a pod WITHOUT toleration:
```bash
kubectl run untolerated-pod --image=nginx
```

Check its status:
```bash
kubectl get pod untolerated-pod -o wide
```

Result depends on cluster:
- **Single-node cluster**: Pod stays Pending
- **Multi-node cluster**: Pod schedules on other nodes

This proves the taint is working!

Clean up:
```bash
kubectl delete pod untolerated-pod
```

STEP 4: Create Pod with Toleration
-----------------------------------

Complete pod manifest (tolerated-pod.yaml):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tolerated-pod
  namespace: default
spec:
  tolerations:
  - key: special
    operator: Equal
    value: dedicated
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx
```

Key sections explained:

1. **tolerations** - Array of tolerations
2. **key: special** - Must match taint key
3. **operator: Equal** - Exact match required
4. **value: dedicated** - Must match taint value
5. **effect: NoSchedule** - Must match taint effect

Apply the pod:
```bash
kubectl apply -f tolerated-pod.yaml
```

Verify pod is created:
```bash
kubectl get pod tolerated-pod
```

Expected:
```
NAME            READY   STATUS    RESTARTS   AGE
tolerated-pod   1/1     Running   0          10s
```

Check which node it's on:
```bash
kubectl get pod tolerated-pod -o wide
```

STEP 5: Ensure Pod Lands on node-1 (Optional but Recommended)
--------------------------------------------------------------

Toleration alone allows the pod to schedule on node-1,
but doesn't guarantee it will.

To FORCE scheduling on node-1, add nodeSelector:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tolerated-pod
spec:
  tolerations:
  - key: special
    operator: Equal
    value: dedicated
    effect: NoSchedule
  nodeSelector:
    kubernetes.io/hostname: node-1
  containers:
  - name: nginx
    image: nginx
```

Or use nodeAffinity:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tolerated-pod
spec:
  tolerations:
  - key: special
    operator: Equal
    value: dedicated
    effect: NoSchedule
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - node-1
  containers:
  - name: nginx
    image: nginx
```

TOLERATION VARIATIONS
---------------------

**Option 1: Exact match (Equal operator)**
```yaml
tolerations:
- key: special
  operator: Equal
  value: dedicated
  effect: NoSchedule
```
Matches: special=dedicated:NoSchedule

**Option 2: Key exists (Exists operator)**
```yaml
tolerations:
- key: special
  operator: Exists
  effect: NoSchedule
```
Matches: special=<any-value>:NoSchedule

**Option 3: Tolerate all taints (wildcard)**
```yaml
tolerations:
- operator: Exists
```
Matches: Any taint (use carefully!)

For this task, use **Option 1** (Equal with exact values).

UNDERSTANDING TAINT EFFECTS
----------------------------

**NoSchedule** (Use this!)
- New pods without toleration: Blocked
- Existing pods: Stay running
- Use case: Reserve nodes for specific workloads

**PreferNoSchedule**
- Soft preference
- Scheduler tries to avoid but may place pods there
- Use case: Gentle guidance

**NoExecute**
- New pods without toleration: Blocked
- Existing pods without toleration: Evicted!
- Use case: Aggressive node maintenance

Example with NoExecute:
```bash
kubectl taint nodes node-1 maintenance=true:NoExecute
# All pods without matching toleration are evicted
```

COMMON MISTAKES
---------------

❌ Wrong: Typo in taint key
```bash
kubectl taint nodes node-1 specail=dedicated:NoSchedule  # Typo!
```

✓ Correct: Exact key
```bash
kubectl taint nodes node-1 special=dedicated:NoSchedule
```

❌ Wrong: Mismatch between taint and toleration
```yaml
# Taint: special=dedicated:NoSchedule
tolerations:
- key: special
  operator: Equal
  value: reserved  # Wrong value!
  effect: NoSchedule
```

✓ Correct: Matching values
```yaml
tolerations:
- key: special
  operator: Equal
  value: dedicated  # Matches taint
  effect: NoSchedule
```

❌ Wrong: Wrong effect
```yaml
# Taint: special=dedicated:NoSchedule
tolerations:
- key: special
  operator: Equal
  value: dedicated
  effect: PreferNoSchedule  # Wrong effect!
```

✓ Correct: Matching effect
```yaml
tolerations:
- key: special
  operator: Equal
  value: dedicated
  effect: NoSchedule  # Matches taint
```

❌ Wrong: Missing toleration
```yaml
# Pod without tolerations trying to schedule on tainted node
apiVersion: v1
kind: Pod
metadata:
  name: pod
spec:
  containers:
  - name: nginx
    image: nginx
  # No tolerations - will be rejected!
```

✓ Correct: With toleration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod
spec:
  tolerations:
  - key: special
    operator: Equal
    value: dedicated
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx
```

TROUBLESHOOTING
---------------

Problem: Pod stuck in Pending
→ Check if taint is too restrictive
→ Verify toleration matches taint exactly
→ Check: kubectl describe pod <pod> | grep -A 10 Events
→ Look for "MatchNodeSelector" or "PodToleratesNodeTaints" errors

Problem: Pod scheduled on wrong node
→ Toleration allows scheduling but doesn't force it
→ Add nodeSelector or nodeAffinity
→ Check: kubectl get pod <pod> -o wide

Problem: Taint not working (pods still schedule)
→ Check taint syntax: kubectl describe node <node> | grep Taint
→ Ensure effect is NoSchedule (not PreferNoSchedule)
→ Verify taint was applied correctly

Problem: Cannot remove taint
→ Syntax: kubectl taint nodes <node> <key>-
→ Example: kubectl taint nodes node-1 special-
→ The minus sign (-) removes the taint

KUBECTL CHEAT SHEET
-------------------
# Add taint
kubectl taint nodes node-1 special=dedicated:NoSchedule

# Check node taints
kubectl describe node node-1 | grep Taint
kubectl get node node-1 -o jsonpath='{.spec.taints}'

# Remove taint
kubectl taint nodes node-1 special-

# Remove all taints (if you know the keys)
kubectl taint nodes node-1 special- dedicated- maintenance-

# Create pod with toleration
kubectl apply -f tolerated-pod.yaml

# Check pod placement
kubectl get pod tolerated-pod -o wide

# Test without toleration
kubectl run test-pod --image=nginx
kubectl get pod test-pod -o wide

# Delete pods
kubectl delete pod tolerated-pod test-pod

REAL-WORLD USE CASES
--------------------

1. **GPU Nodes**
   ```bash
   kubectl taint nodes gpu-node-1 gpu=true:NoSchedule
   ```
   Only ML workloads with toleration can use GPU nodes

2. **Maintenance Mode**
   ```bash
   kubectl taint nodes node-1 maintenance=true:NoExecute
   ```
   Evict all pods for node maintenance

3. **Production vs Dev**
   ```bash
   kubectl taint nodes prod-node-1 environment=production:NoSchedule
   ```
   Separate prod and dev workloads

4. **Spot Instances**
   ```bash
   kubectl taint nodes spot-node-1 spot=true:PreferNoSchedule
   ```
   Prefer regular nodes but allow spot if needed

EXAM TIPS
---------
1. Remember taint syntax: key=value:effect
2. Toleration must match ALL three: key, value, effect
3. Use NoSchedule (most common)
4. Check with: kubectl describe node | grep Taint
5. Test with a pod without toleration first
6. Remove taints with: kubectl taint nodes <node> <key>-
7. Combine with nodeSelector to force node placement

TIME MANAGEMENT
---------------
For this task (10-12 minutes):
• 2 min: Review requirements and check nodes
• 2 min: Add taint to node-1
• 3 min: Create pod with toleration
• 2 min: Verify pod schedules correctly
• 2 min: Debug if needed
• 1 min: Final verification

QUICK REFERENCE
---------------
Task checklist:
✓ Add taint: kubectl taint nodes node-1 special=dedicated:NoSchedule
✓ Verify taint: kubectl describe node node-1 | grep Taint
✓ Create pod with matching toleration
✓ Pod should have: key=special, value=dedicated, effect=NoSchedule
✓ Verify pod scheduled: kubectl get pod tolerated-pod -o wide

Taint format:
```
<key>=<value>:<effect>
special=dedicated:NoSchedule
```

Toleration format:
```yaml
tolerations:
- key: <key>
  operator: Equal
  value: <value>
  effect: <effect>
```

Good luck! 🚀

EOF
