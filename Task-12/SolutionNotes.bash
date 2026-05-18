#!/bin/bash

# Solution Notes for Task 12: Kustomize - Production Variants
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Kustomize - Production Deployment
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. Kustomize basics and directory structure
2. Overlay pattern for environment variants
3. namePrefix for resource naming
4. commonLabels for tagging
5. Image tag transformation

KEY CONCEPTS
------------
• Kustomize: Template-free configuration customization
• Base: Common manifests shared across environments
• Overlay: Environment-specific customizations
• Patching: Modifying base resources without editing them

APPROACH
--------

STEP 1: Understand Base Manifests
----------------------------------

Check the base directory:

```bash
cd /home/student/kustomize
ls -la base/
```

Expected files:
```
deployment.yaml      - Nginx deployment (nginx:1.19)
service.yaml         - Nginx service
kustomization.yaml   - Base kustomization
```

View base kustomization:

```bash
cat base/kustomization.yaml
```

Typical content:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml

commonLabels:
  app: nginx
```

View deployment:

```bash
cat base/deployment.yaml
```

Check image version:
```yaml
containers:
- name: nginx
  image: nginx:1.19  # Base version
```

STEP 2: Create Production Overlay Directory
--------------------------------------------

Create directory structure:

```bash
cd /home/student/kustomize
mkdir -p overlays/production
```

Verify:

```bash
tree /home/student/kustomize
# Or
find /home/student/kustomize -type f
```

Expected structure:
```
kustomize/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    └── production/
        └── (kustomization.yaml - to be created)
```

STEP 3: Create Production Kustomization
----------------------------------------

Create the production kustomization file:

```bash
cat > /home/student/kustomize/overlays/production/kustomization.yaml << 'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Reference base manifests
resources:
- ../../base

# Add prefix to all resource names
namePrefix: prod-

# Add label to all resources
commonLabels:
  environment: production

# Transform nginx image tag
images:
- name: nginx
  newTag: "1.21"
YAML
```

Or create with editor:

```bash
cd /home/student/kustomize/overlays/production
vi kustomization.yaml
# Or
nano kustomization.yaml
```

Content:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

namePrefix: prod-

commonLabels:
  environment: production

images:
- name: nginx
  newTag: "1.21"
```

STEP 4: Preview Generated Manifests
------------------------------------

Preview what will be created:

```bash
cd /home/student/kustomize
kubectl kustomize overlays/production/
```

Expected output (Deployment excerpt):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
    environment: production    # Added label
  name: prod-nginx-app         # Added prefix
spec:
  selector:
    matchLabels:
      app: nginx
      environment: production  # Added label
  template:
    metadata:
      labels:
        app: nginx
        environment: production  # Added label
    spec:
      containers:
      - image: nginx:1.21      # Changed tag!
        name: nginx
```

Expected output (Service excerpt):
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
    environment: production
  name: prod-nginx-service     # Added prefix
spec:
  selector:
    app: nginx
    environment: production
```

STEP 5: Apply Production Variant
---------------------------------

Apply the production configuration:

```bash
kubectl apply -k overlays/production/
```

Or with full path:
```bash
kubectl apply -k /home/student/kustomize/overlays/production/
```

Expected output:
```
deployment.apps/prod-nginx-app created
service/prod-nginx-service created
```

STEP 6: Verify Deployment
--------------------------

Check resources:

```bash
kubectl get deployment,service
```

Expected:
```
NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/prod-nginx-app   2/2     2            2           30s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/prod-nginx-service   ClusterIP   10.96.123.456   <none>        80/TCP    30s
```

Check labels:

```bash
kubectl get all -l environment=production
```

Check deployment details:

```bash
kubectl describe deployment prod-nginx-app
```

Look for:
- Name: prod-nginx-app (prefix added)
- Labels: environment=production (label added)
- Image: nginx:1.21 (tag changed)

Check image tag:

```bash
kubectl get deployment prod-nginx-app -o yaml | grep image:
```

Should show:
```
image: nginx:1.21
```

Check service:

```bash
kubectl get service prod-nginx-service -o yaml | grep environment
```

Should show:
```
environment: production
```

UNDERSTANDING KUSTOMIZE
-----------------------

**Why Kustomize?**

Traditional approach problems:
- Copy/paste YAML files for each environment
- Hard to track differences
- Error-prone
- Duplication

Kustomize benefits:
- DRY (Don't Repeat Yourself)
- Template-free
- Built into kubectl
- Git-friendly
- Clear separation: base vs overlays

**Overlay Pattern:**

```
Base (shared):
  deployment.yaml
  service.yaml
  kustomization.yaml

Overlay (environment-specific):
  production/
    kustomization.yaml (references base + customizations)
  staging/
    kustomization.yaml (different customizations)
```

KUSTOMIZATION.YAML DEEP DIVE
-----------------------------

**1. resources:**
```yaml
resources:
- ../../base           # Reference base directory
- deployment.yaml      # Additional resource
- https://example.com/manifest.yaml  # Remote resource
```

**2. namePrefix / nameSuffix:**
```yaml
namePrefix: prod-      # Adds prefix
nameSuffix: -v2        # Adds suffix
```

Result:
- Deployment: nginx-app → prod-nginx-app-v2

**3. commonLabels:**
```yaml
commonLabels:
  environment: production
  team: platform
```

Added to:
- All resource metadata.labels
- All selectors (Deployment, Service, etc.)
- All template labels (Pod templates)

**4. images:**
```yaml
images:
- name: nginx         # Original image name
  newTag: "1.21"      # New tag
  
# Or change name and tag:
- name: nginx
  newName: myregistry.com/nginx
  newTag: "1.21"
```

**5. replicas:**
```yaml
replicas:
- name: nginx-app
  count: 5
```

**6. patches:**
```yaml
patches:
- target:
    kind: Deployment
    name: nginx-app
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 5
```

COMMON KUSTOMIZE PATTERNS
--------------------------

**Pattern 1: Environment Overlays**

```
base/
overlays/
  dev/
    kustomization.yaml      # 1 replica, dev labels
  staging/
    kustomization.yaml      # 2 replicas, staging labels
  production/
    kustomization.yaml      # 5 replicas, prod labels, resources
```

**Pattern 2: Multi-Component Base**

```
base/
  frontend/
    deployment.yaml
    service.yaml
    kustomization.yaml
  backend/
    deployment.yaml
    service.yaml
    kustomization.yaml
  kustomization.yaml        # Aggregates frontend + backend
```

**Pattern 3: Shared Components**

```
base/
components/
  monitoring/
    kustomization.yaml      # Prometheus resources
  logging/
    kustomization.yaml      # ELK stack
overlays/
  production/
    kustomization.yaml      # Includes base + components
```

COMMON MISTAKES
---------------

❌ Wrong: Incorrect path to base
```yaml
resources:
- ../base    # Wrong!
```

✓ Correct: Relative path from overlay location
```yaml
resources:
- ../../base
```

❌ Wrong: Using newName instead of newTag
```yaml
images:
- name: nginx
  newName: "1.21"    # Wrong field!
```

✓ Correct: Use newTag for tag changes
```yaml
images:
- name: nginx
  newTag: "1.21"
```

❌ Wrong: Forgetting quotes on numeric tags
```yaml
images:
- name: nginx
  newTag: 1.21       # YAML interprets as float!
```

✓ Correct: Quote tag values
```yaml
images:
- name: nginx
  newTag: "1.21"
```

❌ Wrong: Wrong indentation (YAML!)
```yaml
images:
  - name: nginx     # 2-space indent
  newTag: "1.21"    # Wrong! Should be indented
```

✓ Correct: Proper indentation
```yaml
images:
- name: nginx
  newTag: "1.21"
```

TROUBLESHOOTING
---------------

Problem: kustomize command not found
→ Use kubectl kustomize instead
→ Or install standalone: https://kubectl.docs.kubernetes.io/installation/kustomize/

Problem: Error: unable to find base
→ Check resources path in overlay kustomization.yaml
→ Verify base directory exists
→ Use relative path from overlay location

Problem: Image not changed
→ Check images.name matches original image
→ Use newTag not newName
→ Quote tag value

Problem: Labels not applied
→ Check YAML syntax
→ Verify commonLabels indentation
→ Check if resources are recreated (not patched)

KUBECTL + KUSTOMIZE CHEAT SHEET
--------------------------------
# Preview generated manifests
kubectl kustomize <dir>
kubectl kustomize overlays/production/

# Apply
kubectl apply -k <dir>
kubectl apply -k overlays/production/

# Delete
kubectl delete -k overlays/production/

# Diff (dry-run)
kubectl diff -k overlays/production/

# Build with standalone kustomize
kustomize build overlays/production/

# Verify files
tree overlays/production/
cat overlays/production/kustomization.yaml

ALTERNATIVE: Using Patches
---------------------------

Instead of images transformer, you can use patches:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

namePrefix: prod-

commonLabels:
  environment: production

patches:
- target:
    kind: Deployment
    name: nginx-app
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: nginx:1.21
```

But images transformer is simpler!

EXAM TIPS
---------
1. Kustomize is built into kubectl (kubectl kustomize)
2. Use overlays for environment variants
3. namePrefix/Suffix for naming conventions
4. commonLabels for environment tagging
5. images for tag transformations
6. Always preview with kubectl kustomize first
7. Quote numeric image tags
8. Use relative paths for resources

TIME MANAGEMENT
---------------
For this task (12-15 minutes):
• 2 min: Review base manifests
• 3 min: Create overlay directory
• 4 min: Create production kustomization.yaml
• 2 min: Preview with kubectl kustomize
• 2 min: Apply and verify
• 2 min: Debug if needed

COMPLETE SOLUTION
-----------------

```bash
# 1. Navigate to kustomize directory
cd /home/student/kustomize

# 2. Create overlay directory
mkdir -p overlays/production

# 3. Create production kustomization
cat > overlays/production/kustomization.yaml << 'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

namePrefix: prod-

commonLabels:
  environment: production

images:
- name: nginx
  newTag: "1.21"
YAML

# 4. Preview
kubectl kustomize overlays/production/

# 5. Apply
kubectl apply -k overlays/production/

# 6. Verify
kubectl get deployment prod-nginx-app
kubectl get service prod-nginx-service
kubectl get all -l environment=production
kubectl get deployment prod-nginx-app -o yaml | grep image:
```

Good luck! 🚀

EOF
