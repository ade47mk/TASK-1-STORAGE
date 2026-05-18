# 🎯 Repository Summary

This repository provides a **hands-on Kubernetes Persistent Storage exam** optimized for Killercoda's CKA playground.

## ✅ What's Included

### 📚 Learning Resources
- **STUDY-GUIDE.md** - Complete learning material (concepts, examples, troubleshooting)
- **CHEAT-SHEET.md** - Quick command reference
- **QUICK-START.md** - Fast-track getting started guide

### 🧪 Practice Task
- **Task-1/** - Complete hands-on lab with:
  - Environment setup script
  - Task requirements
  - Solution hints
  - Automated validation

### 📖 Documentation
- **README.md** - Main overview and instructions
- **STRUCTURE.md** - Repository structure explanation
- **LICENSE** - MIT License

## 🚀 Quick Usage

```bash
# In Killercoda CKA Playground
git clone https://github.com/YOUR_USERNAME/k8s-storage-exam.git
cd k8s-storage-exam
./Task-1/LabSetUp.bash
cat Task-1/Question.bash
# [work on your solution]
./Task-1/validate.sh
```

## 🎓 Learning Path

1. **Complete Beginner?**
   - Start with STUDY-GUIDE.md
   - Study all concepts
   - Try the practice task

2. **Some Experience?**
   - Read QUICK-START.md
   - Jump into Task-1
   - Refer to CHEAT-SHEET.md

3. **Exam Prep?**
   - Time yourself on Task-1
   - Aim for 12/15 points
   - Practice until under 15 minutes

## 📊 Task Overview

| Aspect | Details |
|--------|---------|
| Topic | PersistentVolumeClaim & Pod Volume Mounts |
| Difficulty | Medium |
| Points | 15 (passing: 12) |
| Time | 10-15 minutes |
| Skills Tested | PVC creation, volume mounting, persistence verification |

## 🎯 What You'll Learn

✅ Create PersistentVolumeClaims with specific requirements  
✅ Configure storage classes and access modes  
✅ Mount volumes in Pods correctly  
✅ Verify data persistence  
✅ Troubleshoot storage issues  

## 🌟 Key Features

- **Self-Contained**: All scripts and resources included
- **Auto-Setup**: Provisioner installed automatically
- **Auto-Validation**: Instant feedback on your solution
- **Educational**: Multiple learning resources at different levels
- **Exam-Focused**: Mirrors real CKA format and scoring

## 📂 Repository Pattern

Following the proven pattern from [static-pods-exam](https://github.com/ade47mk/static-pods-exam):

```
Task-1/
├── LabSetUp.bash       # Setup the environment
├── Question.bash       # Read the requirements
├── SolutionNotes.bash  # Get hints
└── validate.sh         # Check your work
```

## 🔗 Quick Links

- **Start Learning:** [STUDY-GUIDE.md](STUDY-GUIDE.md)
- **Quick Start:** [QUICK-START.md](QUICK-START.md)
- **Command Reference:** [CHEAT-SHEET.md](CHEAT-SHEET.md)
- **Task Details:** [Task-1/Question.bash](Task-1/Question.bash)

## 🏆 Success Criteria

Your solution is successful when:
- PVC created with correct specs (100Mi, RWO, local-path)
- PVC is bound to a PersistentVolume
- Pod is running with volume mounted at /data
- Can write to and read from /data
- Score ≥ 12/15 points

## 💡 Pro Tips

1. **Always verify PVC is bound before creating Pod**
2. **Use `kubectl describe` for troubleshooting**
3. **Test volume access with `kubectl exec`**
4. **Save your manifests - you might need to recreate**
5. **Time yourself - exam conditions are strict**

## 🌐 Platform Support

✅ **Killercoda** - Primary target  
✅ **Minikube** - Local testing  
✅ **Kind** - Local testing  
✅ **K3s** - Edge/lightweight clusters  

Requires: `local-path` storage class (auto-installed by setup script)

## 📝 For Instructors

This repository can be:
- Forked and customized for your class
- Extended with additional tasks
- Integrated into your curriculum
- Used for self-paced learning

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional tasks (Task-2, Task-3, etc.)
- More storage scenarios
- Different storage classes
- StatefulSet examples

## 📄 License

MIT License - Free to use, modify, and share

---

**Ready to master Kubernetes Persistent Storage? Start with [QUICK-START.md](QUICK-START.md)!** 🚀
