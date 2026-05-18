# Kubernetes Persistent Storage - Study Guide

## 📚 Core Concepts

### What is Persistent Storage?

Persistent storage in Kubernetes allows data to survive beyond the lifecycle of a pod. Unlike ephemeral volumes, persistent volumes retain data even when pods are deleted and recreated.

## 🔑 Key Components

### 1. PersistentVolume (PV)
- **What it is:** A piece of storage in the cluster
- **Who creates it:** Usually auto-provisioned by a StorageClass
- **Lifecycle:** Independent of any pod

### 2. PersistentVolumeClaim (PVC)
- **What it is:** A request for storage by a user
- **Who creates it:** You (the developer/admin)
- **Purpose:** Abstracts storage details from the pod

### 3. StorageClass
- **What it is:** Defines the "class" of storage
- **Purpose:** Enables dynamic provisioning
- **Examples:** local-path, gp2 (AWS), pd-standard (GCP)

### 4. Volume Mount
- **What it is:** Connects a PVC to a directory in a container
- **Purpose:** Makes the storage accessible inside the pod

## 🔄 How It Works

```
1. You create a PVC (requesting 100Mi storage)
        ↓
2. StorageClass provisioner sees the request
        ↓
3. Provisioner automatically creates a PV (100Mi)
        ↓
4. PV and PVC are "bound" together
        ↓
5. Pod references the PVC in its spec
        ↓
6. Kubernetes mounts the volume in the pod
        ↓
7. Application can read/write to /data
```

## 📖 PVC Specification

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-pvc
spec:
  accessModes:
    - ReadWriteOnce          # How the volume can be accessed
  storageClassName: local-path  # Which provisioner to use
  resources:
    requests:
      storage: 100Mi         # How much storage needed
```

### Access Modes Explained

| Mode | Abbreviation | Description | Use Case |
|------|--------------|-------------|----------|
| ReadWriteOnce | RWO | Mount read-write by single node | Single pod, databases |
| ReadOnlyMany | ROX | Mount read-only by many nodes | Shared config, static content |
| ReadWriteMany | RWX | Mount read-write by many nodes | Shared data across pods |
| ReadWriteOncePod | RWOP | Mount read-write by single pod | Kubernetes 1.22+ |

## 📖 Pod with Volume Mount

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app-container
    image: nginx:alpine
    volumeMounts:              # Where to mount
    - name: storage-volume     # Must match volumes[].name
      mountPath: /data         # Path inside container
  volumes:                     # Volume definitions
  - name: storage-volume       # Name (your choice)
    persistentVolumeClaim:     # Type: PVC
      claimName: app-storage-pvc  # Which PVC to use
```

## 🔍 Key Relationships

### Volume Name Matching
```yaml
# The name here...
volumeMounts:
- name: storage-volume    ← Must match
  mountPath: /data

# ...must match the name here
volumes:
- name: storage-volume    ← Must match
  persistentVolumeClaim:
    claimName: app-storage-pvc
```

### PVC Reference
```yaml
# This claimName...
volumes:
- name: storage-volume
  persistentVolumeClaim:
    claimName: app-storage-pvc    ← Must match PVC metadata.name

# ...must match this
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-pvc    ← Must match
```

## 🛠️ Essential Commands

### Working with PVCs
```bash
# Create PVC from manifest
kubectl apply -f pvc.yaml

# List all PVCs
kubectl get pvc

# Get PVC details
kubectl describe pvc app-storage-pvc

# Check PVC status (should be "Bound")
kubectl get pvc app-storage-pvc -o jsonpath='{.status.phase}'

# Delete PVC
kubectl delete pvc app-storage-pvc
```

### Working with PVs
```bash
# List all PVs (auto-created)
kubectl get pv

# Get PV details
kubectl describe pv <pv-name>

# See which PV is bound to a PVC
kubectl get pvc app-storage-pvc -o jsonpath='{.spec.volumeName}'
```

### Working with Pods
```bash
# Create pod from manifest
kubectl apply -f pod.yaml

# Check pod status
kubectl get pod app-pod

# Get detailed pod info
kubectl describe pod app-pod

# Check volume mounts
kubectl describe pod app-pod | grep -A 10 "Mounts:"

# Delete pod
kubectl delete pod app-pod
```

### Testing Volume Access
```bash
# Write to volume
kubectl exec app-pod -- sh -c "echo 'test data' > /data/test.txt"

# Read from volume
kubectl exec app-pod -- cat /data/test.txt

# List directory contents
kubectl exec app-pod -- ls -la /data

# Check if path is mounted
kubectl exec app-pod -- df -h | grep /data

# Interactive shell
kubectl exec -it app-pod -- sh
```

## 🐛 Troubleshooting Guide

### Problem: PVC Stuck in "Pending"

**Symptoms:**
```bash
$ kubectl get pvc
NAME              STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS
app-storage-pvc   Pending                                      local-path
```

**Causes & Solutions:**

1. **StorageClass doesn't exist**
   ```bash
   kubectl get storageclass local-path
   # If not found, install provisioner
   ```

2. **Provisioner not running**
   ```bash
   kubectl get pods -n local-path-storage
   # Should see local-path-provisioner running
   ```

3. **Check events**
   ```bash
   kubectl describe pvc app-storage-pvc
   # Look at Events section for errors
   ```

### Problem: Pod Fails to Start

**Symptoms:**
```bash
$ kubectl get pod
NAME      READY   STATUS              RESTARTS   AGE
app-pod   0/1     ContainerCreating   0          2m
```

**Causes & Solutions:**

1. **PVC not bound yet**
   ```bash
   kubectl get pvc
   # PVC must be "Bound" before pod can use it
   ```

2. **Wrong PVC name**
   ```bash
   kubectl describe pod app-pod | grep -A 5 "Volumes:"
   # Verify claimName matches actual PVC
   ```

3. **Check pod events**
   ```bash
   kubectl describe pod app-pod
   # Look at Events section
   ```

### Problem: Cannot Write to /data

**Symptoms:**
```bash
$ kubectl exec app-pod -- touch /data/test
touch: /data/test: Read-only file system
```

**Causes & Solutions:**

1. **Wrong mount path**
   ```bash
   kubectl describe pod app-pod | grep -A 10 "Mounts:"
   # Verify mountPath is /data
   ```

2. **Volume not mounted**
   ```bash
   kubectl exec app-pod -- df -h
   # Should see a mount at /data
   ```

3. **Permissions issue**
   ```bash
   kubectl exec app-pod -- ls -la /data
   # Check directory permissions
   ```

## 📝 Common Exam Patterns

### Pattern 1: Basic PVC Creation
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <name>
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: <class-name>
  resources:
    requests:
      storage: <size>
```

### Pattern 2: Pod with Single Volume
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <name>
spec:
  containers:
  - name: <container-name>
    image: <image>
    volumeMounts:
    - name: <volume-name>
      mountPath: <path>
  volumes:
  - name: <volume-name>
    persistentVolumeClaim:
      claimName: <pvc-name>
```

### Pattern 3: Pod with Multiple Volumes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <name>
spec:
  containers:
  - name: <container-name>
    image: <image>
    volumeMounts:
    - name: vol1
      mountPath: /data1
    - name: vol2
      mountPath: /data2
  volumes:
  - name: vol1
    persistentVolumeClaim:
      claimName: pvc-1
  - name: vol2
    persistentVolumeClaim:
      claimName: pvc-2
```

## 🎯 CKA Exam Tips

### Time Management
- **Creating PVC:** 2-3 minutes
- **Creating Pod:** 2-3 minutes
- **Verification:** 2-3 minutes
- **Debugging:** 3-5 minutes (if needed)

### Best Practices

1. **Use kubectl dry-run for base manifests**
   ```bash
   kubectl run pod --image=nginx --dry-run=client -o yaml > pod.yaml
   ```

2. **Verify each step**
   - Create PVC → Check it's Bound
   - Create Pod → Check it's Running
   - Test access → Write/read file

3. **Save your work**
   - Keep manifest files
   - You might need to recreate resources

4. **Use kubectl explain**
   ```bash
   kubectl explain pvc.spec
   kubectl explain pod.spec.volumes
   ```

5. **Check events on failures**
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

## 📚 Additional Resources

### Official Documentation
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Configure Pod to Use PVC](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

### Practice Labs
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Killercoda CKA Playground](https://killercoda.com/playgrounds/scenario/cka)

### Kubectl Cheat Sheet
- [Official Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## ✅ Pre-Exam Checklist

Before taking the exam, make sure you can:

- [ ] Create a PVC with specific size and access mode
- [ ] Verify a PVC is bound to a PV
- [ ] Create a Pod that mounts a PVC
- [ ] Verify volume is mounted inside container
- [ ] Write and read data from mounted volume
- [ ] Explain the difference between PV and PVC
- [ ] List all access modes and when to use each
- [ ] Troubleshoot common PVC/Pod issues
- [ ] Delete and recreate resources quickly
- [ ] Use kubectl exec to test volume access

## 🚀 Ready to Practice?

Head over to [QUICK-START.md](QUICK-START.md) to begin the exam!

---

**Good luck with your CKA preparation! 📚**
