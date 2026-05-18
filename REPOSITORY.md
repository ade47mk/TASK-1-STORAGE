# Kubernetes Persistent Storage Exam

A hands-on Kubernetes exam focused on persistent storage concepts.

## 📁 Repository Structure

```
k8s-storage-exam/
├── README.md                          # Main documentation
├── manifests/                         # Kubernetes manifests
│   ├── pvc.yaml                      # PersistentVolumeClaim template
│   └── pod.yaml                      # Pod template with volume mount
├── scripts/                          # Helper scripts
│   ├── setup.sh                     # Environment setup
│   ├── verify.sh                    # Solution verification
│   └── cleanup.sh                   # Resource cleanup
├── killercoda/                      # Killercoda scenario files
│   ├── index.json                   # Scenario configuration
│   ├── intro.md                     # Introduction screen
│   ├── finish.md                    # Completion screen
│   └── step[1-4]/                  # Step-by-step instructions
│       ├── text.md                 # Step instructions
│       └── verify.sh               # Step verification
└── solution/                        # Reference solution
    ├── pvc-solution.yaml           # Complete PVC solution
    ├── pod-solution.yaml           # Complete Pod solution
    └── SOLUTION.md                 # Detailed explanation
```

## 🚀 Quick Start

### For Instructors/Repository Maintainers

1. **Clone this repository**:
   ```bash
   git clone <your-repo-url>
   cd k8s-storage-exam
   ```

2. **Test locally** (requires Kubernetes cluster):
   ```bash
   ./scripts/setup.sh
   kubectl apply -f manifests/
   ./scripts/verify.sh
   ```

3. **Deploy to Killercoda**:
   - Copy the `killercoda/` directory contents to your Killercoda scenario
   - Ensure the `assets` are properly configured to copy files to the environment
   - Test the scenario in Killercoda's preview mode

### For Students/Learners

1. Access the scenario on Killercoda (or set up locally)
2. Follow the step-by-step instructions
3. Create the required Kubernetes resources
4. Verify your solution

## 🎯 Learning Objectives

- Create PersistentVolumeClaims with specific requirements
- Configure storage classes and access modes
- Mount persistent volumes in Pods
- Verify data persistence across Pod restarts

## 📝 Exam Requirements

Create resources with these specifications:
- **PVC Size**: 100Mi
- **Access Mode**: ReadWriteOnce
- **Storage Class**: local-path
- **Mount Path**: /data

## 🔧 Scripts

### setup.sh
Prepares the environment by verifying cluster access and ensuring the local-path storage class is available.

### verify.sh
Comprehensive verification script that checks:
- PVC creation and specifications
- PVC binding status
- Pod creation and running state
- Volume mount configuration
- Read/write functionality

### cleanup.sh
Removes all created resources to reset the environment.

## 📚 Files Included

### Manifests
- `manifests/pvc.yaml`: Template for PersistentVolumeClaim
- `manifests/pod.yaml`: Template for Pod with volume mount

### Killercoda Scenario
Complete interactive scenario with 4 steps:
1. Setup environment and verify storage class
2. Create PersistentVolumeClaim
3. Create Pod with volume mount
4. Verify and test persistence

### Solution
- Complete working manifests
- Detailed explanation document
- Troubleshooting guide

## 🧪 Testing

Before deploying to students:

1. **Test all scripts**:
   ```bash
   chmod +x scripts/*.sh
   ./scripts/setup.sh
   ./scripts/verify.sh
   ./scripts/cleanup.sh
   ```

2. **Verify Killercoda scenario**:
   - Test each step's verification script
   - Ensure proper error messages
   - Confirm completion detection

3. **Review documentation**:
   - All links work
   - Instructions are clear
   - Examples are correct

## 🔗 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/concepts/storage/)
- [Killercoda Platform](https://killercoda.com/)
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner)

## 🤝 Contributing

To improve this exam:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This educational content is provided for learning purposes.

---

**Note**: This repository is ready for GitHub. Make sure to:
1. Replace `<your-repo-url>` with your actual GitHub repository URL
2. Add a `.gitignore` file if needed
3. Consider adding GitHub Actions for automated testing
4. Update the Killercoda scenario link once published
