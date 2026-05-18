# Kubernetes Persistent Storage Exam - CKA Practice

## Introduction
This repository contains a hands-on lab focused on **Persistent Storage** - a crucial Kubernetes concept for the CKA exam. You'll learn how to create and manage PersistentVolumeClaims, mount volumes in pods, and verify data persistence.

**Difficulty:** Intermediate  
**Total Points:** 15  
**Estimated Time:** 10-15 minutes

## What You'll Learn

- Creating PersistentVolumeClaims (PVC)
- Configuring storage classes and access modes
- Mounting persistent volumes in Pods
- Verifying volume creation and data persistence
- Testing volume persistence across pod restarts

## Repository Structure

The task folder `Task-1` contains:

- `Question.bash` — The task requirements and objectives
- `LabSetUp.bash` — Executable bash script to prepare the Killercoda environment
- `SolutionNotes.bash` — Hints and solution guidance
- `validate.sh` — Script to validate your solution

## How to Use in Killercoda

1. **Open the CKA playground:**
   ```
   https://killercoda.com/playgrounds/scenario/cka
   ```

2. **Clone this repo:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/k8s-storage-exam.git
   cd k8s-storage-exam
   ```

3. **Make the setup script executable:**
   ```bash
   chmod +x Task-1/LabSetUp.bash
   ```

4. **Run the setup script:**
   ```bash
   ./Task-1/LabSetUp.bash
   ```

5. **Read the question:**
   ```bash
   cat Task-1/Question.bash
   ```

6. **Work on the task**, then validate your solution:
   ```bash
   chmod +x Task-1/validate.sh
   ./Task-1/validate.sh
   ```

7. **If stuck, check solution notes:**
   ```bash
   cat Task-1/SolutionNotes.bash
   ```

## Task Overview

| Task | Topic | Difficulty | Points | Time |
|------|-------|------------|--------|------|
| [Task-1](Task-1/) | Persistent Volume Claim | Medium | 15 | 10-15 min |

## Task Summary

### Task 1: PersistentVolumeClaim with Pod Mount (15 points)
Create a PersistentVolumeClaim and a Pod that uses it for persistent storage.

**Key concepts:** 
- PersistentVolumeClaim creation
- Storage class configuration
- Volume mounting in pods
- Data persistence verification

**Requirements:**
- PVC with 100Mi storage
- ReadWriteOnce access mode
- local-path storage class
- Pod mounting volume at /data

## Scoring

The task is worth 15 points total:
- Correct PVC specification: 5 points
- PVC successfully bound: 2 points
- Pod specification correct: 3 points
- Pod successfully running: 2 points
- Volume properly mounted: 2 points
- Data persistence verified: 1 point

**Passing Score:** 12/15 points

## Prerequisites

- Basic understanding of Kubernetes concepts
- Familiarity with kubectl commands
- Understanding of YAML syntax
- Knowledge of storage concepts (volumes, persistent storage)

## Tips for Success

1. **Read the question carefully** - Note all the specific requirements
2. **Use kubectl dry-run** - Generate base manifests to start from
3. **Check your work incrementally** - Don't wait until the end to test
4. **Use kubectl describe** - Investigate issues if things aren't working
5. **Check the validation script** - It will tell you exactly what's wrong

## Common Issues

### PVC Stuck in Pending
- **Cause:** Storage class not available or provisioner not running
- **Solution:** Check if local-path storage class exists and provisioner is running

### Pod Failing to Start
- **Cause:** PVC not bound yet or incorrect volume reference
- **Solution:** Wait for PVC to bind, verify PVC name matches in pod spec

### Volume Not Writable
- **Cause:** Incorrect mount path or permissions
- **Solution:** Check mount path is correct (/data), verify with kubectl exec

## Additional Resources

- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Configure Pod to Use PVC](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)
- [CKA Exam Tips](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## Contributing

Found an issue or have a suggestion? Feel free to:
- Open an issue
- Submit a pull request
- Share your feedback

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

This repository structure is inspired by effective CKA practice labs designed for the Killercoda platform.

---

**Good luck with your CKA preparation! 🚀**
