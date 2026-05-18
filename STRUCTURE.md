# Repository Structure

This document explains the repository structure and what each file does.

## 📁 Directory Structure

```
k8s-storage-exam/
├── README.md                    # Main documentation and overview
├── QUICK-START.md              # Fast-track guide for Killercoda
├── STUDY-GUIDE.md              # Comprehensive learning material
├── CHEAT-SHEET.md              # Quick reference commands
├── LICENSE                     # MIT License
├── .gitignore                  # Git ignore patterns
│
└── Task-1/                     # Task folder
    ├── LabSetUp.bash          # Environment setup script
    ├── Question.bash          # Task requirements (executable)
    ├── SolutionNotes.bash     # Hints and solution guidance
    └── validate.sh            # Solution validation script
```

## 📄 File Descriptions

### Root Level Files

#### README.md
- **Purpose:** Main entry point for the repository
- **Contains:** 
  - Introduction and overview
  - Learning objectives
  - How to use in Killercoda
  - Task summary
  - Scoring information
  - Prerequisites and tips

#### QUICK-START.md
- **Purpose:** Get started quickly
- **Contains:**
  - Minimal steps to begin
  - Essential commands only
  - Quick tips
  - Link to full documentation

#### STUDY-GUIDE.md
- **Purpose:** Comprehensive learning resource
- **Contains:**
  - Core concepts explained
  - How Persistent Storage works
  - YAML examples with annotations
  - Troubleshooting guide
  - Best practices
  - CKA exam tips

#### CHEAT-SHEET.md
- **Purpose:** Quick command reference
- **Contains:**
  - Common kubectl commands
  - YAML templates
  - One-liners
  - Quick troubleshooting steps
  - Time management tips

#### LICENSE
- **Purpose:** Legal license information
- **Contains:** MIT License text

#### .gitignore
- **Purpose:** Git ignore patterns
- **Contains:** Files/folders to exclude from version control

### Task-1 Directory

#### LabSetUp.bash
- **Purpose:** Prepare the Killercoda environment
- **Actions:**
  - Verifies cluster connectivity
  - Checks for local-path storage class
  - Installs provisioner if needed
  - Cleans up previous attempts
- **Usage:** `./Task-1/LabSetUp.bash`

#### Question.bash
- **Purpose:** Display the task requirements
- **Contains:**
  - Task description
  - Objectives and requirements
  - Deliverables
  - Scoring breakdown
  - Hints
- **Usage:** `cat Task-1/Question.bash`

#### SolutionNotes.bash
- **Purpose:** Provide hints and solution guidance
- **Contains:**
  - Step-by-step approach
  - YAML examples
  - Common mistakes
  - Troubleshooting tips
  - kubectl cheat sheet
- **Usage:** `cat Task-1/SolutionNotes.bash`

#### validate.sh
- **Purpose:** Validate your solution
- **Actions:**
  - Checks PVC exists and specifications
  - Verifies PVC is bound
  - Checks Pod exists and specifications
  - Verifies Pod is running
  - Tests volume mount functionality
  - Calculates and displays score
- **Usage:** `./Task-1/validate.sh`

## 🎯 File Relationships

```
User Journey:
1. Read README.md → Understand the exam
2. Follow QUICK-START.md → Get started fast
3. Run LabSetUp.bash → Prepare environment
4. Read Question.bash → Understand requirements
5. Refer to STUDY-GUIDE.md → Learn concepts (if needed)
6. Use CHEAT-SHEET.md → Quick command reference
7. Work on solution → Create your YAML files
8. Run validate.sh → Check your work
9. Read SolutionNotes.bash → Get hints (if stuck)
```

## 📚 Documentation Hierarchy

```
README.md
├── Overview for all users
├── Points to QUICK-START.md for fast track
└── Points to STUDY-GUIDE.md for learning

QUICK-START.md
├── Minimal steps to start
└── Points back to README.md for details

STUDY-GUIDE.md
├── Deep-dive learning material
├── Concepts and theory
└── References to official docs

CHEAT-SHEET.md
├── Quick reference only
└── Assumes you know the concepts
```

## 🔄 Workflow

### For Learners
```bash
# 1. Clone repo
git clone https://github.com/YOUR_USERNAME/k8s-storage-exam.git
cd k8s-storage-exam

# 2. Setup environment
chmod +x Task-1/LabSetUp.bash
./Task-1/LabSetUp.bash

# 3. Read question
cat Task-1/Question.bash

# 4. Study (if needed)
cat STUDY-GUIDE.md

# 5. Work on solution
vim pvc.yaml
kubectl apply -f pvc.yaml
vim pod.yaml
kubectl apply -f pod.yaml

# 6. Validate
chmod +x Task-1/validate.sh
./Task-1/validate.sh

# 7. Get hints (if stuck)
cat Task-1/SolutionNotes.bash
```

### For Instructors
```bash
# 1. Fork/clone repo
git clone <this-repo>

# 2. Test all scripts
cd k8s-storage-exam
./Task-1/LabSetUp.bash
# Test the task
./Task-1/validate.sh

# 3. Customize if needed
vim Task-1/Question.bash
vim Task-1/validate.sh

# 4. Push to your repo
git add .
git commit -m "Customized for my class"
git push
```

## 🎨 Design Principles

### Modularity
- Each task in its own folder
- Easy to add Task-2, Task-3, etc.
- Scripts are self-contained

### User-Friendly
- Clear, descriptive filenames
- Consistent structure across tasks
- Progress through difficulty levels

### Killercoda-Optimized
- Scripts work in CKA playground
- No external dependencies
- Auto-installs provisioner if needed

### Educational
- Multiple learning resources
- Progressive disclosure (quick-start → study guide)
- Hands-on practice focused

### Exam-Focused
- Mirrors CKA exam format
- Time estimates provided
- Scoring system
- Validation scripts

## 🚀 Adding More Tasks

To add Task-2:

```bash
mkdir Task-2
cd Task-2

# Copy templates from Task-1
cp ../Task-1/LabSetUp.bash .
cp ../Task-1/Question.bash .
cp ../Task-1/SolutionNotes.bash .
cp ../Task-1/validate.sh .

# Customize for new task
vim LabSetUp.bash      # Adjust setup
vim Question.bash      # New requirements
vim SolutionNotes.bash # New solution
vim validate.sh        # New validation

# Update README.md to include Task-2
```

## 📝 Best Practices

### For Script Authors
- Use clear, descriptive echo messages
- Provide helpful error messages
- Test scripts in fresh environment
- Add comments for complex logic

### For Documentation
- Keep QUICK-START.md minimal
- Make STUDY-GUIDE.md comprehensive
- Keep CHEAT-SHEET.md concise
- Update all docs when changing tasks

### For Validation
- Test all possible error cases
- Provide specific error messages
- Show what was expected vs actual
- Give partial credit when appropriate

## 🔗 Related Patterns

This structure is based on:
- [static-pods-exam](https://github.com/ade47mk/static-pods-exam) - Original pattern
- CKA exam format - Official Kubernetes certification
- Killercoda best practices - Interactive learning platform

---

**This structure makes it easy to learn, practice, and validate Kubernetes skills!** 🎓
