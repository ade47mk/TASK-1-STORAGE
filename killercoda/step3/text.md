# Step 3: Create Pod with Volume Mount

Now that we have a PersistentVolumeClaim, let's create a Pod that uses it.

## 📋 Requirements

Create a Pod with these specifications:
- **Name**: `app-pod`
- **Container Image**: Your choice (e.g., `nginx:alpine`, `busybox`, `ubuntu`)
- **Volume Mount**: Mount the PVC at `/data`
- **PVC Reference**: Use `app-storage-pvc`

## 📝 Create the Pod Manifest

Create a Pod manifest that:
1. References the PVC in the `volumes` section
2. Mounts the volume at `/data` in the container

```bash
nano manifests/pod.yaml
```

## 🔑 Key Concepts

Your Pod manifest should include:

- A `volumes` section that references the PVC:
  ```yaml
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-storage-pvc
  ```

- A `volumeMounts` section in the container:
  ```yaml
  volumeMounts:
  - name: app-storage
    mountPath: /data
  ```

## 🚀 Apply the Pod

```bash
kubectl apply -f manifests/pod.yaml
```

## ✅ Verify the Pod

Check if the Pod is running:

```bash
kubectl get pod app-pod
```

Check the Pod details:

```bash
kubectl describe pod app-pod
```

Test the mount by writing a file:

```bash
kubectl exec app-pod -- sh -c "echo 'Hello from persistent storage!' > /data/test.txt"
kubectl exec app-pod -- cat /data/test.txt
```

Once your Pod is running with the volume mounted, proceed to the final step!
