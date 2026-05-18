#!/bin/bash

# Task 12: Kustomize - Production Variants
# Difficulty: Medium
# Points: 20
# Time: 12-15 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 12: Kustomize - Production Deployment Variant
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 20
Time Estimate: 12-15 minutes

SCENARIO:
---------
Your organization uses Kustomize to manage environment-specific
configurations. Base manifests exist for an nginx application,
and you need to create a production variant with specific
customizations.

OBJECTIVE:
----------
Use Kustomize to deploy a production variant of the app from
base manifests with custom labels, name prefix, and image version.

REQUIREMENTS:
-------------

Base Manifests:
  - Location: /home/student/kustomize/base
  - Contains: deployment.yaml, service.yaml, kustomization.yaml
  - Image: nginx:1.19

Production Overlay:
  - Add label: environment: production (to all resources)
  - Prefix resource names with: prod-
  - Change image tag: nginx:1.19 → nginx:1.21

Location:
  - Create overlay at: /home/student/kustomize/overlays/production
  - Deploy using: kubectl apply -k overlays/production

TASKS:
------
1. Verify base manifests exist:
   ls -la /home/student/kustomize/base/

2. Create production overlay directory:
   mkdir -p /home/student/kustomize/overlays/production

3. Create production kustomization.yaml:
   /home/student/kustomize/overlays/production/kustomization.yaml

4. Configure kustomization with:
   - Reference base manifests
   - namePrefix: prod-
   - commonLabels: environment: production
   - images: nginx:1.21

5. Preview generated manifests:
   kubectl kustomize overlays/production/

6. Apply production variant:
   kubectl apply -k overlays/production/

7. Verify deployment:
   kubectl get deployment,service
   kubectl get deployment prod-nginx-app -o yaml

VERIFICATION:
-------------
Your solution should meet these criteria:
- Production kustomization.yaml exists
- Deployment named: prod-nginx-app
- Service named: prod-nginx-service
- All resources have label: environment: production
- Image tag: nginx:1.21
- Resources running

HINTS:
------
- Production kustomization.yaml structure:
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

- Create file:
  cd /home/student/kustomize
  cat > overlays/production/kustomization.yaml << 'EOF'
  # (content above)
  EOF

- Preview:
  kubectl kustomize overlays/production/

- Apply:
  kubectl apply -k overlays/production/

- Verify:
  kubectl get all -l environment=production
  kubectl describe deployment prod-nginx-app

- Check image:
  kubectl get deployment prod-nginx-app -o yaml | grep image:

DELIVERABLES:
-------------
- Production kustomization.yaml created
- Resources prefixed with prod-
- Label environment: production on all resources
- Image nginx:1.21 used
- Resources deployed and running

SCORING:
--------
- Production kustomization.yaml exists: 3 points
- namePrefix configured: 3 points
- commonLabels configured: 4 points
- Image tag updated to 1.21: 4 points
- Deployment exists with correct name: 3 points
- Resources running: 3 points

Total: 20 points
Passing: 14 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Wrong path to base manifests
2. Incorrect YAML syntax
3. Wrong image field (name vs newName)
4. Forgetting to apply after creating kustomization
5. Wrong overlay directory structure

IMPORTANT NOTES:
----------------
• Kustomize is built into kubectl (kubectl kustomize)
• Overlays reference base manifests
• namePrefix adds prefix to resource names
• commonLabels adds labels to all resources
• images section transforms image tags
• kubectl apply -k applies kustomize directory

KUSTOMIZE BASICS:
-----------------
Structure:
```
kustomize/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── development/
    │   └── kustomization.yaml
    └── production/
        └── kustomization.yaml
```

Commands:
- kubectl kustomize <dir>     - Preview manifests
- kubectl apply -k <dir>      - Apply manifests
- kustomize build <dir>       - Build manifests (standalone)

KUSTOMIZATION FIELDS:
---------------------
Common fields:
- resources: []       - Base manifests or directories
- namePrefix: ""      - Add prefix to resource names
- nameSuffix: ""      - Add suffix to resource names
- commonLabels: {}    - Add labels to all resources
- commonAnnotations: {} - Add annotations
- images: []          - Transform image names/tags
- replicas: []        - Override replica counts
- patches: []         - Strategic merge patches

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
