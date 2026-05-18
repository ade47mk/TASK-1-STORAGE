# Step 1: Setup Environment

Before we start working on the exam task, let's verify that our Kubernetes cluster is ready and has the necessary storage class.

## Check Cluster Status

First, verify that the cluster is running:

```bash
kubectl cluster-info
```

## Check Storage Classes

List available storage classes:

```bash
kubectl get storageclass
```

You should see the `local-path` storage class. If it's not available, run the setup script:

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## Verify Setup

Confirm the storage class exists:

```bash
kubectl get storageclass local-path -o yaml
```

## 📝 Understanding Storage Classes

Storage classes provide a way for administrators to describe different types of storage. The `local-path` storage class creates volumes on the local node's filesystem, making it perfect for development and testing.

Once you see the `local-path` storage class, you're ready to move to the next step!
