# Solution: Kubernetes Persistent Storage

This document provides the complete solution and detailed explanation for the storage exam task.

## Task Requirements

Create a PersistentVolumeClaim and Pod with the following specifications:
- **PVC Size**: 100Mi
- **Access Mode**: ReadWriteOnce
- **Storage Class**: local-path
- **Mount Path**: /data in the Pod

---

## Solution

### 1. PersistentVolumeClaim (pvc.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 100Mi
```

**Explanation:**
- `accessModes: [ReadWriteOnce]` - The volume can be mounted as read-write by a single node
- `storageClassName: local-path` - Uses the local-path provisioner to dynamically create a PV
- `resources.requests.storage: 100Mi` - Requests 100 mebibytes of storage

### 2. Pod (pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: storage-demo
spec:
  containers:
  - name: app-container
    image: nginx:alpine
    volumeMounts:
    - name: app-storage
      mountPath: /data
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date) >> /data/log.txt; sleep 5; done"]
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-storage-pvc
```

**Explanation:**
- `volumes` section declares a volume named `app-storage` that references the PVC
- `volumeMounts` section mounts the volume at `/data` in the container
- The container runs a simple script that writes timestamps to `/data/log.txt`
- This demonstrates that the volume is both writable and persistent

---

## Deployment Steps

1. **Apply the PVC**:
   ```bash
   kubectl apply -f manifests/pvc.yaml
   ```

2. **Verify PVC is bound**:
   ```bash
   kubectl get pvc app-storage-pvc
   ```
   Expected output: STATUS should be "Bound"

3. **Apply the Pod**:
   ```bash
   kubectl apply -f manifests/pod.yaml
   ```

4. **Verify Pod is running**:
   ```bash
   kubectl get pod app-pod
   ```
   Expected output: STATUS should be "Running"

5. **Test the volume**:
   ```bash
   kubectl exec app-pod -- cat /data/log.txt
   ```
   You should see timestamps being written every 5 seconds

---

## Verification Checklist

✅ PVC exists with name `app-storage-pvc`  
✅ PVC has storage size of 100Mi  
✅ PVC uses access mode ReadWriteOnce  
✅ PVC uses storage class "local-path"  
✅ PVC is in Bound state  
✅ Pod exists with name `app-pod`  
✅ Pod is in Running state  
✅ Volume is mounted at `/data`  
✅ Volume is readable and writable  
✅ Data persists after Pod restart  

---

## Testing Persistence

To verify that data actually persists:

1. **Write test data**:
   ```bash
   kubectl exec app-pod -- sh -c "echo 'persistence test' > /data/test.txt"
   ```

2. **Verify the file exists**:
   ```bash
   kubectl exec app-pod -- cat /data/test.txt
   ```

3. **Delete the Pod**:
   ```bash
   kubectl delete pod app-pod
   ```

4. **Recreate the Pod**:
   ```bash
   kubectl apply -f manifests/pod.yaml
   ```

5. **Wait for Pod to be ready**:
   ```bash
   kubectl wait --for=condition=ready pod/app-pod --timeout=60s
   ```

6. **Verify data still exists**:
   ```bash
   kubectl exec app-pod -- cat /data/test.txt
   ```

If you can still read "persistence test", the volume is working correctly!

---

## How It Works

1. **PVC Creation**: When you create the PVC, Kubernetes looks for a matching PersistentVolume (PV). If none exists and a StorageClass is specified, it triggers dynamic provisioning.

2. **Dynamic Provisioning**: The local-path provisioner (installed in the cluster) automatically creates a PV that matches the PVC requirements and binds them together.

3. **Pod Mounting**: When the Pod starts, Kubernetes mounts the PV at the specified path (`/data`) inside the container.

4. **Data Persistence**: The actual storage is on the node's filesystem. Even if the Pod is deleted, the PV and PVC remain. When a new Pod references the same PVC, it gets access to the same storage with all existing data intact.

---

## Common Issues and Solutions

### PVC Stuck in Pending State

**Cause**: Storage class doesn't exist or provisioner is not installed

**Solution**:
```bash
kubectl describe pvc app-storage-pvc
# Check events for error messages

# Install local-path provisioner if missing
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### Pod Fails to Start

**Cause**: PVC is not bound yet

**Solution**: Wait for the PVC to be bound before creating the Pod:
```bash
kubectl get pvc app-storage-pvc --watch
```

### Cannot Write to Volume

**Cause**: Incorrect mount permissions or path

**Solution**:
```bash
# Check mount details
kubectl describe pod app-pod

# Verify the mount path
kubectl exec app-pod -- df -h | grep /data

# Test write permissions
kubectl exec app-pod -- sh -c "touch /data/test && rm /data/test"
```

---

## Additional Notes

### Access Modes Explained

- **ReadWriteOnce (RWO)**: Volume can be mounted read-write by a single node
- **ReadOnlyMany (ROX)**: Volume can be mounted read-only by many nodes
- **ReadWriteMany (RWX)**: Volume can be mounted read-write by many nodes
- **ReadWriteOncePod (RWOP)**: Volume can be mounted read-write by a single Pod (Kubernetes 1.22+)

For this task, ReadWriteOnce is appropriate because:
- We're running a single Pod
- The storage is node-local (local-path)
- It's the most commonly used access mode

### Storage Classes

Different storage classes provide different types of storage:
- **local-path**: Local node storage (fast, but not portable across nodes)
- **gp2/gp3**: AWS EBS volumes
- **pd-standard/pd-ssd**: Google Cloud persistent disks
- **azure-disk**: Azure managed disks

For development/testing, local-path is sufficient. For production, use cloud-provider storage classes that support features like replication, snapshots, and cross-zone availability.

---

## Clean Up

When you're done:

```bash
kubectl delete pod app-pod
kubectl delete pvc app-storage-pvc
```

The PersistentVolume will also be automatically deleted due to the `Retain` reclaim policy of local-path storage class.
