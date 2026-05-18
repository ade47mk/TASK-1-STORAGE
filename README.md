# Kubernetes Persistent Storage Exam

This repository contains a hands-on Kubernetes exam question focused on persistent storage concepts, including PersistentVolumeClaims (PVC) and Pod volume mounts.

## 📋 Exam Question

**TASK 1: STORAGE**

A developer needs a persistent volume for an application. Create a PersistentVolumeClaim with:
- Size: 100Mi
- Access mode: ReadWriteOnce
- Storage class: "local-path"

Create a Pod that mounts this PVC at `/data` and verify that the volume is automatically created and mounted.

## 🚀 Quick Start

### Using Killercoda

1. Open the scenario in Killercoda (link will be generated after publishing)
2. Follow the step-by-step instructions
3. Verify your solution using the provided verification scripts

### Local Testing

```bash
# Ensure you have a Kubernetes cluster with local-path storage class
kubectl get storageclass

# Apply the manifests
kubectl apply -f manifests/

# Verify the setup
./scripts/verify.sh
```

## 📁 Repository Structure

```
.
├── README.md                 # This file
├── manifests/               # Kubernetes manifest files
│   ├── pvc.yaml            # PersistentVolumeClaim definition
│   └── pod.yaml            # Pod with volume mount
├── scripts/                # Helper scripts
│   ├── setup.sh           # Initial setup script
│   ├── verify.sh          # Solution verification script
│   └── cleanup.sh         # Resource cleanup script
├── killercoda/            # Killercoda scenario files
│   ├── index.json         # Scenario configuration
│   ├── intro.md           # Introduction screen
│   ├── finish.md          # Completion screen
│   └── step1/            # Step 1 files
│       ├── text.md       # Step instructions
│       └── verify.sh     # Step verification
└── solution/             # Reference solution
    ├── pvc-solution.yaml
    ├── pod-solution.yaml
    └── SOLUTION.md       # Detailed explanation
```

## 🎯 Learning Objectives

After completing this exam, you will understand:
- How to create PersistentVolumeClaims in Kubernetes
- How to configure storage classes and access modes
- How to mount persistent volumes in Pods
- How to verify volume creation and mounting

## 🧪 Verification Criteria

Your solution should meet the following criteria:
- [ ] PVC is created with correct specifications
- [ ] PVC is bound to a PersistentVolume
- [ ] Pod is running successfully
- [ ] Volume is mounted at `/data` in the Pod
- [ ] Data written to `/data` persists across Pod restarts

## 📚 Prerequisites

- Basic understanding of Kubernetes concepts
- Familiarity with kubectl commands
- Understanding of storage concepts (volumes, persistent storage)

## 🛠️ Technologies Used

- Kubernetes
- kubectl
- Bash scripting
- Killercoda platform

## 📖 Additional Resources

- [Kubernetes Persistent Volumes Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Configure Pod to Use PersistentVolume](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

## 🤝 Contributing

Feel free to submit issues or pull requests if you find any problems or have suggestions for improvement.

## 📄 License

This project is provided for educational purposes.
