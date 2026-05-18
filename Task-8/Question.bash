#!/bin/bash

# Task 8: StatefulSets & Headless Services
# Difficulty: Hard
# Points: 25
# Time: 15-20 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 8: StatefulSets & Headless Services
════════════════════════════════════════════════════════════════

Difficulty: Hard
Points: 25
Time Estimate: 15-20 minutes

SCENARIO:
---------
You need to deploy a stateful application that requires stable
network identities and persistent storage. Each pod must have
its own persistent volume that survives pod rescheduling.

OBJECTIVE:
----------
Deploy a StatefulSet with a Headless Service to provide stable
network identities and persistent storage for each replica.

REQUIREMENTS:
-------------

Part 1: Headless Service
  - Name: web
  - Type: ClusterIP with clusterIP: None (headless)
  - Selector: app=nginx
  - Port: 80
  - Namespace: default

Part 2: StatefulSet
  - Name: web
  - Replicas: 2
  - Image: nginx
  - Service: web (headless)
  - VolumeClaimTemplate:
    - Name: www
    - Size: 1Gi
    - AccessMode: ReadWriteOnce
    - MountPath: /usr/share/nginx/html
  - Labels: app=nginx
  - Namespace: default

TASKS:
------
1. Create the Headless Service first
   - Must have clusterIP: None
   - Must match StatefulSet pod selector

2. Create the StatefulSet
   - Use volumeClaimTemplates for persistent storage
   - Each pod gets its own PVC automatically
   - Pods named: web-0, web-1

3. Verify stable network identities:
   - Pods have stable DNS names
   - Format: <pod-name>.<service-name>.<namespace>.svc.cluster.local

4. Verify persistent storage:
   - Each pod has its own PVC
   - PVCs named: www-web-0, www-web-1
   - Storage persists across pod restarts

VERIFICATION:
-------------
Your solution should meet these criteria:
- Headless Service "web" exists (clusterIP: None)
- StatefulSet "web" exists with 2 replicas
- Pods named web-0 and web-1
- PVCs www-web-0 and www-web-1 exist and are bound
- Each PVC is 1Gi
- Pods are Running
- Storage mounted at /usr/share/nginx/html

HINTS:
------
- Create Headless Service first:
  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: web
  spec:
    clusterIP: None  # Makes it headless
    selector:
      app: nginx
    ports:
    - port: 80
      name: web
  ```

- Create StatefulSet:
  ```yaml
  apiVersion: apps/v1
  kind: StatefulSet
  metadata:
    name: web
  spec:
    serviceName: web
    replicas: 2
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - name: nginx
          image: nginx
          volumeMounts:
          - name: www
            mountPath: /usr/share/nginx/html
    volumeClaimTemplates:
    - metadata:
        name: www
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi
  ```

- Order matters: Service BEFORE StatefulSet

- StatefulSet creates pods sequentially:
  web-0 first, then web-1

- PVCs are created automatically:
  Format: <volumeClaimTemplate-name>-<statefulset-name>-<ordinal>
  Example: www-web-0, www-web-1

- Stable DNS names:
  web-0.web.default.svc.cluster.local
  web-1.web.default.svc.cluster.local

DELIVERABLES:
-------------
- Headless Service "web" created
- StatefulSet "web" with 2 replicas
- 2 PVCs automatically created and bound
- All pods running

SCORING:
--------
- Headless Service exists: 4 points
- Service has clusterIP: None: 3 points
- StatefulSet exists with correct name: 3 points
- StatefulSet has 2 replicas: 2 points
- StatefulSet uses nginx image: 2 points
- VolumeClaimTemplate configured: 4 points
- PVCs created (www-web-0, www-web-1): 3 points
- PVCs are 1Gi: 2 points
- Pods are running: 2 points

Total: 25 points
Passing: 18 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Creating StatefulSet before Service
2. Forgetting clusterIP: None (not headless)
3. Wrong serviceName in StatefulSet spec
4. Missing volumeClaimTemplates
5. Wrong PVC size or access mode
6. Mismatch between Service selector and Pod labels

IMPORTANT NOTES:
----------------
• Headless Service: clusterIP: None
• Order: Create Service BEFORE StatefulSet
• StatefulSet creates pods sequentially (0, 1, 2...)
• Each pod gets its own PVC automatically
• PVC naming: <template-name>-<statefulset>-<ordinal>
• Stable DNS: <pod>.<service>.<namespace>.svc.cluster.local
• PVCs persist even if StatefulSet is deleted (manual cleanup)

STATEFULSET vs DEPLOYMENT:
--------------------------
Deployment:
- Pods are interchangeable
- Random names
- No stable network identity
- Shared storage (if any)

StatefulSet:
- Pods have unique identities
- Predictable names (web-0, web-1)
- Stable DNS names
- Individual persistent storage

USE CASES:
----------
StatefulSets are for:
- Databases (MySQL, PostgreSQL, MongoDB)
- Distributed systems (Kafka, ZooKeeper, etcd)
- Apps needing stable network IDs
- Apps needing persistent storage per instance

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
