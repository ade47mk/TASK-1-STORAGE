#!/bin/bash

# Task 7: Taints and Tolerations
# Difficulty: Medium
# Points: 16
# Time: 10-12 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 7: Taints and Tolerations
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 16
Time Estimate: 10-12 minutes

SCENARIO:
---------
You need to dedicate node-1 for special workloads. Normal pods
should not schedule there, but specific pods with the correct
toleration should be allowed.

OBJECTIVE:
----------
Add a taint to node-1 to prevent normal pods from scheduling,
then create a pod with a toleration that allows it to schedule
on the tainted node.

REQUIREMENTS:
-------------

Part 1: Taint the Node
  - Node: controlplane (or adjust based on your cluster)
  - Taint key: special
  - Taint value: dedicated
  - Effect: NoSchedule
  - Normal pods should NOT schedule on this node

Part 2: Create Tolerating Pod
  - Name: tolerated-pod
  - Image: nginx (or any image)
  - Toleration: Must match the taint
  - Namespace: default
  - Pod should schedule on node-1

TASKS:
------
1. Check available nodes:
   kubectl get nodes

2. Add a taint to node-1:
   kubectl taint nodes node-1 special=dedicated:NoSchedule

3. Verify normal pods cannot schedule:
   - Create a test pod without toleration
   - It should stay Pending on single-node clusters
   - Or schedule on other nodes in multi-node clusters

4. Create a pod with toleration:
   - Add toleration matching the taint
   - Pod should schedule successfully on node-1

5. Verify pod placement:
   kubectl get pod tolerated-pod -o wide

VERIFICATION:
-------------
Your solution should meet these criteria:
- Node node-1 has taint: special=dedicated:NoSchedule
- Pod "tolerated-pod" exists
- Pod has toleration matching the taint
- Pod is scheduled (Running or ContainerCreating)
- Pod is on node-1 (if using node affinity or selector)

HINTS:
------
- Add taint to node:
  kubectl taint nodes node-1 special=dedicated:NoSchedule

- Remove taint (if needed):
  kubectl taint nodes node-1 special-

- Pod with toleration:
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
    containers:
    - name: nginx
      image: nginx
  ```

- Toleration operators:
  * Equal: key=value (exact match)
  * Exists: key exists (any value)

- Taint effects:
  * NoSchedule: New pods won't schedule
  * PreferNoSchedule: Avoid if possible (soft)
  * NoExecute: Evict existing pods

- Check node taints:
  kubectl describe node node-1 | grep Taint

- To ensure pod lands on node-1, combine with:
  * nodeSelector: kubernetes.io/hostname=node-1
  * OR nodeAffinity

DELIVERABLES:
-------------
- Node node-1 tainted with special=dedicated:NoSchedule
- Pod created with matching toleration
- Pod scheduled successfully

SCORING:
--------
- Node has correct taint key: 3 points
- Taint has correct value: 2 points
- Taint has NoSchedule effect: 2 points
- Pod exists with correct name: 2 points
- Pod has toleration configured: 3 points
- Toleration matches taint: 3 points
- Pod is scheduled: 1 point

Total: 16 points
Passing: 12 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Wrong taint syntax
2. Typo in taint key or value
3. Using wrong effect (PreferNoSchedule instead of NoSchedule)
4. Toleration doesn't match taint exactly
5. Forgetting to add toleration to pod
6. Wrong operator in toleration

IMPORTANT NOTES:
----------------
• Taints are applied to nodes
• Tolerations are added to pods
• Both key, value, and effect must match
• NoSchedule prevents new pods (doesn't evict existing)
• Pods with matching tolerations can schedule
• Pods without tolerations are repelled

TAINT EFFECTS:
--------------
1. NoSchedule (Use this!)
   - Prevents scheduling new pods
   - Existing pods remain

2. PreferNoSchedule
   - Soft preference
   - Scheduler tries to avoid but may schedule

3. NoExecute
   - Prevents scheduling AND evicts existing pods
   - Most aggressive

TOLERATION OPERATORS:
---------------------
1. Equal (Use this!)
   - key=value must match exactly
   - Most specific

2. Exists
   - Only key must exist
   - Any value accepted

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
