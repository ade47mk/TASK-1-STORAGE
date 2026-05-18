# Step 2: Create PersistentVolumeClaim

Now it's time to create the PersistentVolumeClaim (PVC) according to the exam requirements.

## 📋 Requirements

Create a PVC with these specifications:
- **Name**: `app-storage-pvc`
- **Storage Size**: `100Mi`
- **Access Mode**: `ReadWriteOnce`
- **Storage Class**: `local-path`

## 📝 Create the PVC

You can either:

**Option 1**: Create the manifest file manually

```bash
nano manifests/pvc.yaml
```

**Option 2**: Use kubectl to generate the manifest

```bash
kubectl create pvc app-storage-pvc \
  --dry-run=client -o yaml \
  > manifests/pvc.yaml
```

Then edit it to match the requirements.

## 🚀 Apply the PVC

Once your manifest is ready:

```bash
kubectl apply -f manifests/pvc.yaml
```

## ✅ Verify the PVC

Check if the PVC was created:

```bash
kubectl get pvc
```

Check the PVC details:

```bash
kubectl describe pvc app-storage-pvc
```

The PVC should be in `Bound` state, which means a PersistentVolume was automatically provisioned for it.

## 💡 Tip

If you need help with the YAML structure, check the Kubernetes documentation:
- [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

Once your PVC is created and bound, proceed to the next step!
