# Kubernetes Persistent Storage Exam - Quick Start Guide

## 🚀 Quick Start in Killercoda

This is the fastest way to get started with this exam.

### 1. Open Killercoda CKA Playground
```
https://killercoda.com/playgrounds/scenario/cka
```

### 2. Clone and Setup
```bash
git clone https://github.com/YOUR_USERNAME/k8s-storage-exam.git
cd k8s-storage-exam
chmod +x Task-1/LabSetUp.bash
./Task-1/LabSetUp.bash
```

### 3. Read the Question
```bash
cat Task-1/Question.bash
```

### 4. Work on Your Solution
Create your YAML manifests and apply them to the cluster.

### 5. Validate Your Solution
```bash
chmod +x Task-1/validate.sh
./Task-1/validate.sh
```

### 6. Need Help?
```bash
cat Task-1/SolutionNotes.bash
```

## 📝 What This Exam Tests

- Creating PersistentVolumeClaims
- Configuring storage classes and access modes
- Mounting volumes in Pods
- Verifying data persistence

## ⏱️ Time Estimate
**10-15 minutes**

## 🎯 Passing Score
**12/15 points**

## 💡 Tips

1. **Read carefully** - All requirements are specific
2. **Verify incrementally** - Test as you go
3. **Use kubectl describe** - When things don't work
4. **Check PVC first** - Must be "Bound" before pod can use it

## 📚 Full Documentation

For detailed information, see [README.md](README.md)

---

**Good luck! 🚀**
