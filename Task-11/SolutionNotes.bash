#!/bin/bash

# Solution Notes for Task 11: Helm - Traefik Ingress Controller
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Helm - Traefik Deployment
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. Helm package manager for Kubernetes
2. Adding and managing Helm repositories
3. Installing charts with custom values
4. Traefik ingress controller
5. Kubernetes Gateway API

KEY CONCEPTS
------------
• Helm: Package manager for Kubernetes
• Charts: Helm packages (like apt/yum packages)
• Repositories: Chart storage locations
• Release: Installed instance of a chart
• Values: Configuration parameters

APPROACH
--------

STEP 1: Install Helm
--------------------

Check if Helm is already installed:

```bash
helm version
```

If not installed:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Or manual installation:

```bash
# Download
wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz

# Extract
tar -zxvf helm-v3.12.0-linux-amd64.tar.gz

# Move to PATH
sudo mv linux-amd64/helm /usr/local/bin/helm

# Verify
helm version
```

Expected output:
```
version.BuildInfo{Version:"v3.12.0", ...}
```

STEP 2: Add Traefik Helm Repository
------------------------------------

Add the official Traefik repository:

```bash
helm repo add traefik https://traefik.github.io/charts
```

Expected output:
```
"traefik" has been added to your repositories
```

Update repository index:

```bash
helm repo update
```

Expected output:
```
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "traefik" chart repository
Update Complete. ⎈Happy Helming!⎈
```

Verify repository:

```bash
helm repo list
```

Expected output:
```
NAME      URL
traefik   https://traefik.github.io/charts
```

Search for Traefik chart:

```bash
helm search repo traefik
```

Expected output:
```
NAME            CHART VERSION   APP VERSION     DESCRIPTION
traefik/traefik 26.0.0          v3.0.0          A Traefik...
```

STEP 3: Create Namespace
-------------------------

Create traefik namespace:

```bash
kubectl create namespace traefik
```

Expected output:
```
namespace/traefik created
```

Verify:

```bash
kubectl get namespace traefik
```

STEP 4: Install Traefik with Helm
----------------------------------

Install Traefik with Gateway API enabled:

```bash
helm install traefik traefik/traefik \
  --namespace traefik \
  --set providers.kubernetesGateway.enabled=true
```

Expected output:
```
NAME: traefik
LAST DEPLOYED: Mon May 18 16:40:00 2026
NAMESPACE: traefik
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Traefik Proxy v3.0.0 has been deployed successfully
...
```

Alternative with values file:

Create values.yaml:
```yaml
providers:
  kubernetesGateway:
    enabled: true
```

Install:
```bash
helm install traefik traefik/traefik \
  --namespace traefik \
  -f values.yaml
```

With --create-namespace flag:
```bash
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set providers.kubernetesGateway.enabled=true
```

STEP 5: Verify Installation
----------------------------

Check Helm release:

```bash
helm list -n traefik
```

Expected output:
```
NAME    NAMESPACE  REVISION  UPDATED                   STATUS    CHART           APP VERSION
traefik traefik    1         2026-05-18 16:40:00       deployed  traefik-26.0.0  v3.0.0
```

Check release status:

```bash
helm status traefik -n traefik
```

Check installed values:

```bash
helm get values traefik -n traefik
```

Should show:
```yaml
USER-SUPPLIED VALUES:
providers:
  kubernetesGateway:
    enabled: true
```

Check all values:

```bash
helm get values traefik -n traefik --all
```

STEP 6: Verify Traefik Pods
----------------------------

Check pods:

```bash
kubectl get pods -n traefik
```

Expected output:
```
NAME                       READY   STATUS    RESTARTS   AGE
traefik-abc123-xyz         1/1     Running   0          2m
```

Check all resources:

```bash
kubectl get all -n traefik
```

Check pod logs:

```bash
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

Should show Gateway API provider loaded:
```
time="2026-05-18T16:40:00Z" level=info msg="Configuration loaded from flags."
time="2026-05-18T16:40:00Z" level=info msg="Starting provider *kubernetesgateway.Provider"
```

UNDERSTANDING HELM
------------------

**Helm Components:**

1. **Chart**
   - Package containing K8s resource definitions
   - templates/ - Resource templates
   - values.yaml - Default configuration
   - Chart.yaml - Metadata

2. **Repository**
   - Storage for charts
   - Like apt/yum repositories
   - Can be public or private

3. **Release**
   - Installed instance of a chart
   - Has name and namespace
   - Can be upgraded/rolled back

4. **Values**
   - Configuration parameters
   - Override defaults
   - Can use --set or -f values.yaml

**Helm Architecture (v3):**
- Client-only (no Tiller!)
- Uses kubectl config
- Stores releases as secrets in K8s

HELM VALUES
-----------

Three ways to provide values:

1. **Command line (--set):**
```bash
helm install traefik traefik/traefik \
  --set providers.kubernetesGateway.enabled=true
```

2. **Values file (-f):**
```bash
helm install traefik traefik/traefik \
  -f my-values.yaml
```

3. **Multiple values files:**
```bash
helm install traefik traefik/traefik \
  -f values1.yaml \
  -f values2.yaml
```

Priority (highest to lowest):
1. --set
2. -f (last file wins)
3. Chart defaults

TRAEFIK CONFIGURATION
---------------------

Key Traefik Helm values:

```yaml
# Enable Gateway API
providers:
  kubernetesGateway:
    enabled: true

# Enable Ingress (default)
providers:
  kubernetesIngress:
    enabled: true

# Service type
service:
  type: LoadBalancer  # or NodePort, ClusterIP

# Resource limits
resources:
  requests:
    memory: "100Mi"
    cpu: "100m"
  limits:
    memory: "300Mi"
    cpu: "300m"

# Replica count
deployment:
  replicas: 2
```

COMMON MISTAKES
---------------

❌ Wrong: Forgetting to add repository
```bash
helm install traefik traefik/traefik  # Fails: repo not added
```

✓ Correct: Add repo first
```bash
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik
```

❌ Wrong: Wrong namespace
```bash
helm install traefik traefik/traefik -n default
```

✓ Correct: Use traefik namespace
```bash
helm install traefik traefik/traefik -n traefik
```

❌ Wrong: Forgetting Gateway API
```bash
helm install traefik traefik/traefik -n traefik
# Gateway API not enabled!
```

✓ Correct: Enable Gateway API
```bash
helm install traefik traefik/traefik -n traefik \
  --set providers.kubernetesGateway.enabled=true
```

❌ Wrong: Namespace doesn't exist
```bash
helm install traefik traefik/traefik -n traefik
# Error: namespace doesn't exist
```

✓ Correct: Create namespace or use --create-namespace
```bash
kubectl create namespace traefik
helm install traefik traefik/traefik -n traefik
# Or
helm install traefik traefik/traefik -n traefik --create-namespace
```

TROUBLESHOOTING
---------------

Problem: Helm not found
→ Install Helm: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

Problem: Repository not found
→ Add repository: helm repo add traefik https://traefik.github.io/charts
→ Update: helm repo update

Problem: Release already exists
→ Use different name or uninstall: helm uninstall traefik -n traefik

Problem: Pods not starting
→ Check logs: kubectl logs -n traefik -l app.kubernetes.io/name=traefik
→ Check events: kubectl get events -n traefik

Problem: Gateway API not enabled
→ Check values: helm get values traefik -n traefik
→ Upgrade: helm upgrade traefik traefik/traefik -n traefik --set providers.kubernetesGateway.enabled=true

KUBECTL vs HELM
---------------

**kubectl apply:**
- Manual resource management
- Direct YAML files
- No versioning
- No rollback
- No templating

**helm install:**
- Package management
- Templated resources
- Versioned releases
- Easy rollback
- Configuration via values

HELM CHEAT SHEET
----------------
# Repository management
helm repo add <name> <url>
helm repo update
helm repo list
helm repo remove <name>

# Chart search
helm search repo <keyword>
helm search hub <keyword>

# Install/upgrade
helm install <release> <chart> -n <namespace>
helm upgrade <release> <chart> -n <namespace>
helm upgrade --install <release> <chart>  # Install or upgrade

# List/status
helm list -n <namespace>
helm list --all-namespaces
helm status <release> -n <namespace>

# Values
helm show values <chart>
helm get values <release> -n <namespace>
helm get values <release> -n <namespace> --all

# Uninstall
helm uninstall <release> -n <namespace>

# History/rollback
helm history <release> -n <namespace>
helm rollback <release> <revision> -n <namespace>

EXAM TIPS
---------
1. Install Helm before starting if not available
2. Always add repository before installing
3. Use --create-namespace to create namespace automatically
4. Check release with: helm list -n <namespace>
5. Verify pods: kubectl get pods -n <namespace>
6. Use helm get values to confirm configuration
7. Helm v3 doesn't need Tiller
8. Release names must be unique per namespace

TIME MANAGEMENT
---------------
For this task (15-18 minutes):
• 2 min: Install Helm (if needed)
• 2 min: Add Traefik repository
• 2 min: Create namespace
• 5 min: Install Traefik with correct values
• 3 min: Verify installation
• 3 min: Check pods and Gateway API
• 3 min: Debug if needed

QUICK REFERENCE
---------------
Complete solution:

```bash
# 1. Install Helm (if needed)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 2. Add repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# 3. Create namespace
kubectl create namespace traefik

# 4. Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --set providers.kubernetesGateway.enabled=true

# 5. Verify
helm list -n traefik
kubectl get pods -n traefik
helm get values traefik -n traefik
```

Good luck! 🚀

EOF
