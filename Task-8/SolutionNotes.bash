#!/bin/bash

# Solution Notes for Task 8: StatefulSets & Headless Services
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: StatefulSets & Headless Services
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. StatefulSets for stateful applications
2. Headless Services for stable network identities
3. VolumeClaimTemplates for per-pod storage
4. Ordered pod creation and scaling
5. Persistent storage with stable identities

KEY CONCEPTS
------------
• StatefulSet: Manages stateful workloads
• Headless Service: Service without cluster IP (clusterIP: None)
• Stable Identity: Predictable pod names and DNS
• VolumeClaimTemplates: Automatic PVC creation per pod
• Ordinal Index: Pods numbered 0, 1, 2...

APPROACH
--------

STEP 1: Create the Headless Service
------------------------------------

StatefulSets require a Headless Service FIRST.

Complete Service manifest (web-service.yaml):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: default
spec:
  clusterIP: None  # This makes it headless!
  selector:
    app: nginx
  ports:
  - port: 80
    name: web
```

Key points:

1. **clusterIP: None** - Critical!
   - Makes the service "headless"
   - No single cluster IP
   - DNS returns pod IPs directly

2. **selector: app=nginx**
   - Must match StatefulSet pod labels
   - Service discovers pods via this selector

3. **ports**
   - Standard service port definition
   - Required even for headless service

Apply the service:
```bash
kubectl apply -f web-service.yaml
```

Verify:
```bash
kubectl get service web
```

Expected output:
```
NAME   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web    ClusterIP   None         <none>        80/TCP    10s
```

Note: CLUSTER-IP shows "None" - this confirms it's headless.

STEP 2: Create the StatefulSet
-------------------------------

Complete StatefulSet manifest (web-statefulset.yaml):

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: default
spec:
  serviceName: web  # Must match headless service name
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx  # Must match service selector
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: web
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

Key sections explained:

1. **serviceName: web**
   - References the headless service
   - Required for StatefulSet
   - Must match service name exactly

2. **replicas: 2**
   - Creates 2 pods: web-0, web-1
   - Created sequentially (0 first, then 1)

3. **selector.matchLabels**
   - Must match template.metadata.labels
   - Used by StatefulSet controller

4. **template.metadata.labels**
   - Must match service selector
   - Pods get these labels

5. **volumeMounts**
   - name: www (matches volumeClaimTemplates name)
   - mountPath: /usr/share/nginx/html

6. **volumeClaimTemplates**
   - Creates PVCs automatically for each pod
   - PVC naming: www-web-0, www-web-1
   - Each pod gets its own persistent storage

Apply the StatefulSet:
```bash
kubectl apply -f web-statefulset.yaml
```

STEP 3: Watch Pod Creation
---------------------------

StatefulSets create pods sequentially:

```bash
kubectl get pods -l app=nginx --watch
```

You'll see:
```
NAME    READY   STATUS              RESTARTS   AGE
web-0   0/1     ContainerCreating   0          5s
web-0   1/1     Running             0          10s
web-1   0/1     Pending             0          1s
web-1   0/1     ContainerCreating   0          2s
web-1   1/1     Running             0          8s
```

Notice: web-0 must be Running before web-1 starts.

STEP 4: Verify PVCs
-------------------

Check automatically created PVCs:

```bash
kubectl get pvc
```

Expected output:
```
NAME        STATUS   VOLUME                     CAPACITY   ACCESS MODES
www-web-0   Bound    pvc-abc123...              1Gi        RWO
www-web-1   Bound    pvc-def456...              1Gi        RWO
```

PVC naming pattern:
```
<volumeClaimTemplate-name>-<statefulset-name>-<ordinal>
www-web-0
www-web-1
```

Check PVC details:
```bash
kubectl describe pvc www-web-0
```

STEP 5: Verify Stable Network Identities
-----------------------------------------

StatefulSet pods have stable DNS names:

Format:
```
<pod-name>.<service-name>.<namespace>.svc.cluster.local
```

For our setup:
```
web-0.web.default.svc.cluster.local
web-1.web.default.svc.cluster.local
```

Test DNS resolution (from within cluster):
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup web-0.web.default.svc.cluster.local
```

STEP 6: Test Persistent Storage
--------------------------------

Write data to web-0:
```bash
kubectl exec web-0 -- sh -c 'echo "Hello from web-0" > /usr/share/nginx/html/index.html'
```

Read back:
```bash
kubectl exec web-0 -- cat /usr/share/nginx/html/index.html
```

Delete the pod:
```bash
kubectl delete pod web-0
```

StatefulSet recreates it (same name):
```bash
kubectl get pods -l app=nginx --watch
```

Data persists:
```bash
kubectl exec web-0 -- cat /usr/share/nginx/html/index.html
# Still shows: Hello from web-0
```

UNDERSTANDING HEADLESS SERVICES
--------------------------------

Normal Service:
- Has a cluster IP
- Load balances to pods
- Single DNS name returns cluster IP

```yaml
spec:
  type: ClusterIP
  # clusterIP is auto-assigned
```

Headless Service:
- No cluster IP (clusterIP: None)
- DNS returns pod IPs directly
- Each pod gets individual DNS name

```yaml
spec:
  clusterIP: None  # Headless!
```

DNS behavior:

Normal service:
```
nslookup web.default.svc.cluster.local
# Returns: 10.96.0.10 (cluster IP)
```

Headless service:
```
nslookup web.default.svc.cluster.local
# Returns multiple IPs:
# 10.244.0.5  (web-0)
# 10.244.0.6  (web-1)
```

STATEFULSET POD MANAGEMENT
--------------------------

**Creation Order:**
- Sequential: 0 → 1 → 2
- Next pod created only when previous is Running

**Deletion Order:**
- Reverse: 2 → 1 → 0
- Graceful shutdown

**Scaling Up:**
```bash
kubectl scale statefulset web --replicas=3
```
Creates: web-2

**Scaling Down:**
```bash
kubectl scale statefulset web --replicas=1
```
Deletes: web-1 first

**Update Strategy:**
```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 0
```

COMMON MISTAKES
---------------

❌ Wrong: Creating StatefulSet before Service
```bash
kubectl apply -f statefulset.yaml  # Service doesn't exist yet!
```

✓ Correct: Service first
```bash
kubectl apply -f service.yaml
kubectl apply -f statefulset.yaml
```

❌ Wrong: Missing clusterIP: None
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  # Missing clusterIP: None
  selector:
    app: nginx
```

✓ Correct: Explicit clusterIP: None
```yaml
spec:
  clusterIP: None  # Headless
```

❌ Wrong: Wrong serviceName
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: nginx  # Wrong! Should be 'web'
```

✓ Correct: Match service name
```yaml
spec:
  serviceName: web  # Matches service name
```

❌ Wrong: Missing volumeClaimTemplates
```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        volumeMounts:
        - name: www
          mountPath: /data
  # No volumeClaimTemplates - mount will fail!
```

✓ Correct: With volumeClaimTemplates
```yaml
spec:
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

❌ Wrong: Label mismatch
```yaml
# Service
selector:
  app: nginx

# StatefulSet
template:
  metadata:
    labels:
      app: web  # Mismatch!
```

✓ Correct: Matching labels
```yaml
# Both use: app: nginx
```

TROUBLESHOOTING
---------------

Problem: Pods stuck in Pending
→ Check PVC status: kubectl get pvc
→ Ensure StorageClass exists and is available
→ Check: kubectl describe pod web-0

Problem: PVCs not created
→ Check volumeClaimTemplates syntax
→ Ensure StatefulSet is created successfully
→ Check: kubectl describe statefulset web

Problem: Pod can't mount volume
→ Check if PVC is Bound
→ Verify accessModes match
→ Check: kubectl describe pvc www-web-0

Problem: Service not headless
→ Verify clusterIP: None in service spec
→ Check: kubectl get service web -o yaml

Problem: Pods created out of order
→ This shouldn't happen with StatefulSet
→ Check StatefulSet status
→ Verify previous pod is Running before next starts

KUBECTL CHEAT SHEET
-------------------
# Create Service
kubectl apply -f web-service.yaml

# Check Service
kubectl get service web
kubectl describe service web

# Create StatefulSet
kubectl apply -f web-statefulset.yaml

# Check StatefulSet
kubectl get statefulset web
kubectl describe statefulset web

# Check Pods
kubectl get pods -l app=nginx
kubectl get pods -l app=nginx --watch

# Check PVCs
kubectl get pvc
kubectl describe pvc www-web-0

# Scale StatefulSet
kubectl scale statefulset web --replicas=3

# Delete pod (will be recreated)
kubectl delete pod web-0

# Check DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup web-0.web

# Clean up
kubectl delete statefulset web
kubectl delete service web
kubectl delete pvc www-web-0 www-web-1

VOLUMECLAIMTEMPLATES DEEP DIVE
-------------------------------

volumeClaimTemplates creates PVCs automatically:

```yaml
volumeClaimTemplates:
- metadata:
    name: www  # Template name
  spec:
    accessModes: [ "ReadWriteOnce" ]
    storageClassName: local-path  # Optional
    resources:
      requests:
        storage: 1Gi
```

For each pod, a PVC is created:
- web-0 → www-web-0
- web-1 → www-web-1
- web-2 → www-web-2

PVC lifecycle:
- Created when pod is created
- Bound to a PV automatically
- NOT deleted when pod is deleted
- NOT deleted when StatefulSet is deleted
- Must be manually deleted

This ensures data persists!

STATEFULSET USE CASES
---------------------

1. **Databases**
   - MySQL cluster
   - PostgreSQL replication
   - MongoDB replica set

2. **Distributed Systems**
   - Kafka brokers
   - ZooKeeper ensemble
   - etcd cluster

3. **Caching**
   - Redis cluster
   - Memcached instances

4. **Messaging**
   - RabbitMQ cluster
   - NATS streaming

EXAM TIPS
---------
1. Create Service BEFORE StatefulSet
2. Headless Service: clusterIP: None
3. serviceName in StatefulSet must match Service name
4. Labels must match between Service and StatefulSet
5. volumeClaimTemplates creates PVCs automatically
6. PVC naming: <template>-<statefulset>-<ordinal>
7. Pods created sequentially: 0, 1, 2...
8. Use kubectl get pods --watch to see ordering

TIME MANAGEMENT
---------------
For this task (15-20 minutes):
• 3 min: Create Headless Service
• 5 min: Create StatefulSet with volumeClaimTemplates
• 3 min: Wait for pods to be created
• 3 min: Verify PVCs are bound
• 3 min: Test and verify
• 3 min: Debug if needed

QUICK REFERENCE
---------------
Service (headless):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  clusterIP: None
  selector:
    app: nginx
  ports:
  - port: 80
```

StatefulSet:
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

Verification:
```bash
kubectl get service web
kubectl get statefulset web
kubectl get pods -l app=nginx
kubectl get pvc
```

Good luck! 🚀

EOF
