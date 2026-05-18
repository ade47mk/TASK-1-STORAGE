# Kubernetes Persistent Storage - Cheat Sheet

## 🚀 Quick Commands

### PVC Operations
```bash
# Create PVC from manifest
kubectl apply -f pvc.yaml

# List PVCs
kubectl get pvc

# Describe PVC (see events, status)
kubectl describe pvc <pvc-name>

# Get PVC status
kubectl get pvc <pvc-name> -o jsonpath='{.status.phase}'

# Delete PVC
kubectl delete pvc <pvc-name>
```

### PV Operations
```bash
# List all PVs
kubectl get pv

# Describe PV
kubectl describe pv <pv-name>

# Get PV bound to a PVC
kubectl get pvc <pvc-name> -o jsonpath='{.spec.volumeName}'
```

### Pod with Volume Operations
```bash
# Create pod from manifest
kubectl apply -f pod.yaml

# Check pod status
kubectl get pod <pod-name>

# Describe pod (see mounts, events)
kubectl describe pod <pod-name>

# Execute command in pod
kubectl exec <pod-name> -- <command>

# Interactive shell
kubectl exec -it <pod-name> -- sh

# View pod logs
kubectl logs <pod-name>
```

### Testing Volume Access
```bash
# Write to volume
kubectl exec <pod-name> -- sh -c "echo 'data' > /data/file.txt"

# Read from volume
kubectl exec <pod-name> -- cat /data/file.txt

# List directory
kubectl exec <pod-name> -- ls -la /data

# Check mount
kubectl exec <pod-name> -- df -h | grep /data
```

### Troubleshooting
```bash
# View events
kubectl get events --sort-by='.lastTimestamp'

# Check storageclass
kubectl get storageclass

# View provisioner pods
kubectl get pods -n <provisioner-namespace>

# Describe for detailed info
kubectl describe pvc <pvc-name>
kubectl describe pod <pod-name>
kubectl describe pv <pv-name>
```

## 📝 Quick YAML Templates

### PVC Template
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <pvc-name>
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: <storage-class>
  resources:
    requests:
      storage: <size>Mi
```

### Pod with PVC Template
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <pod-name>
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

## 🔑 Access Modes

| Mode | Short | Description |
|------|-------|-------------|
| ReadWriteOnce | RWO | Single node, read-write |
| ReadOnlyMany | ROX | Multiple nodes, read-only |
| ReadWriteMany | RWX | Multiple nodes, read-write |
| ReadWriteOncePod | RWOP | Single pod, read-write (K8s 1.22+) |

## 🎯 Common Exam Tasks

### Task: Create PVC
```bash
cat <<EOF | kubectl apply -f -
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
EOF
```

### Task: Create Pod with PVC
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app-container
    image: nginx:alpine
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: app-storage-pvc
EOF
```

### Task: Verify Volume Works
```bash
# Wait for pod
kubectl wait --for=condition=ready pod/app-pod --timeout=60s

# Write test file
kubectl exec app-pod -- sh -c "echo test > /data/test.txt"

# Read test file
kubectl exec app-pod -- cat /data/test.txt
```

### Task: Test Persistence
```bash
# Write data
kubectl exec app-pod -- sh -c "echo persist > /data/persist.txt"

# Delete pod
kubectl delete pod app-pod

# Recreate pod
kubectl apply -f pod.yaml

# Wait for ready
kubectl wait --for=condition=ready pod/app-pod --timeout=60s

# Check data persists
kubectl exec app-pod -- cat /data/persist.txt
# Should output: persist
```

## 🐛 Troubleshooting Quick Guide

### PVC Stuck in Pending
```bash
# Check storageclass exists
kubectl get storageclass <class-name>

# Check provisioner running
kubectl get pods -n <provisioner-ns>

# Check PVC events
kubectl describe pvc <pvc-name>
```

### Pod Won't Start
```bash
# Check PVC bound
kubectl get pvc

# Check pod events
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name>
```

### Can't Write to Volume
```bash
# Check mount exists
kubectl exec <pod-name> -- df -h

# Check permissions
kubectl exec <pod-name> -- ls -la /data

# Verify volume mounted
kubectl describe pod <pod-name> | grep -A 10 Mounts
```

## ⚡ Speed Tips

### Generate Base Manifests
```bash
# Generate pod YAML
kubectl run pod --image=nginx --dry-run=client -o yaml > pod.yaml

# Edit and add volume sections
vim pod.yaml
```

### Use kubectl explain
```bash
# PVC fields
kubectl explain pvc.spec

# Pod volume fields
kubectl explain pod.spec.volumes

# Pod volumeMounts fields
kubectl explain pod.spec.containers.volumeMounts
```

### Quick Status Checks
```bash
# One-liner PVC status
kubectl get pvc <name> -o jsonpath='{.status.phase}'

# One-liner Pod status
kubectl get pod <name> -o jsonpath='{.status.phase}'

# Check if volume mounted
kubectl get pod <name> -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}'
```

## 📋 Verification Checklist

- [ ] PVC created
- [ ] PVC status is "Bound"
- [ ] PVC has correct size
- [ ] PVC has correct access mode
- [ ] PVC uses correct storage class
- [ ] Pod created
- [ ] Pod status is "Running"
- [ ] Volume referenced in pod spec
- [ ] Volume mounted at correct path
- [ ] Can write to volume
- [ ] Can read from volume
- [ ] Data persists after pod restart

## 🎯 Exam Strategy

1. **Read requirements carefully** - Note exact names, sizes, modes
2. **Create PVC first** - Wait for it to bind
3. **Then create Pod** - Reference the bound PVC
4. **Verify incrementally** - Test each step
5. **Use kubectl describe** - When something fails
6. **Save manifests** - You might need to recreate

## ⏱️ Time Allocation

- Create PVC: 2 min
- Verify PVC bound: 1 min
- Create Pod: 2 min
- Verify Pod running: 1 min
- Test volume access: 2 min
- Debug (if needed): 5 min
- **Total: 10-15 min**

---

**Print this for quick reference during practice! 📄**
