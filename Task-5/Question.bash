#!/bin/bash

# Task 5: Node Affinity
# Difficulty: Medium
# Points: 15
# Time: 8-12 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 5: Node Affinity
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 15
Time Estimate: 8-12 minutes

SCENARIO:
---------
Your application requires specific hardware - specifically nodes
with SSD storage. You need to ensure the pod only runs on nodes
that meet this requirement using node affinity rules.

OBJECTIVE:
----------
Schedule a pod only on nodes that have been labeled with
disktype=ssd using Kubernetes node affinity.

REQUIREMENTS:
-------------

Part 1: Node Labeling
  - Label at least one node with: disktype=ssd
  - You can label any node in your cluster

Part 2: Pod Creation
  - Name: ssd-pod
  - Image: nginx (or any image)
  - Namespace: default
  - Node Affinity: REQUIRED - must have disktype=ssd label
  - The pod should NOT schedule on nodes without this label

TASKS:
------
1. Check available nodes:
   kubectl get nodes

2. Label a node with disktype=ssd:
   kubectl label nodes <node-name> disktype=ssd

3. Create a pod manifest with node affinity that:
   - Requires disktype=ssd label (hard requirement)
   - Uses requiredDuringSchedulingIgnoredDuringExecution

4. Apply the pod manifest

5. Verify the pod is scheduled on the correct node

VERIFICATION:
-------------
Your solution should meet these criteria:
- At least one node has label disktype=ssd
- Pod "ssd-pod" exists in default namespace
- Pod has node affinity configured
- Pod requires disktype=ssd label
- Pod is scheduled (Running or ContainerCreating)
- Pod is on a node with disktype=ssd label

HINTS:
------
- Node affinity syntax:
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: ssd-pod
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

- Label a node:
  kubectl label nodes <node-name> disktype=ssd

- Check node labels:
  kubectl get nodes --show-labels
  kubectl describe node <node-name>

- Check which nodes have the label:
  kubectl get nodes -l disktype=ssd

- Node affinity types:
  * requiredDuringSchedulingIgnoredDuringExecution
    - HARD requirement (pod won't schedule without it)
  * preferredDuringSchedulingIgnoredDuringExecution
    - SOFT preference (pod tries but can schedule elsewhere)

- Use "required" for this task (hard requirement)

- "IgnoredDuringExecution" means:
  If label is removed after pod is running, pod stays running

DELIVERABLES:
-------------
- At least one node labeled with disktype=ssd
- Pod manifest with node affinity
- Pod created and running
- Pod scheduled on correct node

SCORING:
--------
- Node has disktype=ssd label: 3 points
- Pod exists with correct name: 2 points
- Pod has node affinity configured: 4 points
- Node affinity requires disktype=ssd: 3 points
- Pod is scheduled (not Pending): 2 points
- Pod is on node with disktype=ssd: 1 point

Total: 15 points
Passing: 11 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Forgetting to label any nodes first
2. Using nodeSelector instead of nodeAffinity
3. Wrong operator (use "In", not "Exists" or "Equal")
4. Typo in label key or value
5. Using preferred instead of required
6. Wrong pod name

IMPORTANT NOTES:
----------------
• Label nodes BEFORE creating the pod
• Use requiredDuringScheduling... (hard requirement)
• Pod will stay Pending if no node has the label
• You can label any node in your cluster
• Multiple nodes can have the same label

NODE AFFINITY vs NODE SELECTOR:
--------------------------------
NodeSelector (simple):
  nodeSelector:
    disktype: ssd

NodeAffinity (advanced):
  affinity:
    nodeAffinity:
      requiredDuringScheduling...:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd

Use NodeAffinity for this task (more flexible).

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
