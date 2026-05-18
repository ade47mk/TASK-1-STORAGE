#!/bin/bash

# Task 11: Helm - Traefik Ingress Controller
# Difficulty: Medium
# Points: 22
# Time: 15-18 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 11: Helm - Deploy Traefik Ingress Controller
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 22
Time Estimate: 15-18 minutes

SCENARIO:
---------
Your cluster needs an ingress controller to route external traffic
to services. You've been asked to deploy Traefik using Helm with
specific configurations.

OBJECTIVE:
----------
Use Helm to deploy Traefik Ingress Controller with Gateway API
support enabled.

REQUIREMENTS:
-------------

Helm Installation:
  - Release name: traefik
  - Namespace: traefik (create if doesn't exist)
  - Chart: traefik/traefik (official Traefik chart)

Configuration:
  - Enable Kubernetes Gateway API support
  - Use Helm values to configure

Verification:
  - Traefik deployed successfully
  - Pods running in traefik namespace
  - Gateway API support enabled

TASKS:
------
1. Install Helm (if not already installed):
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

2. Add Traefik Helm repository:
   helm repo add traefik https://traefik.github.io/charts
   helm repo update

3. Create traefik namespace:
   kubectl create namespace traefik

4. Install Traefik with Gateway API enabled:
   helm install traefik traefik/traefik \
     --namespace traefik \
     --set providers.kubernetesGateway.enabled=true

5. Verify deployment:
   helm list -n traefik
   kubectl get pods -n traefik

VERIFICATION:
-------------
Your solution should meet these criteria:
- Helm installed and working
- Traefik Helm release exists with name "traefik"
- Release deployed in namespace "traefik"
- Traefik pods running
- Gateway API provider enabled

HINTS:
------
- Install Helm 3:
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

- Add Traefik repo:
  helm repo add traefik https://traefik.github.io/charts
  helm repo update

- Install with custom values:
  helm install <release-name> <repo/chart> \
    --namespace <namespace> \
    --create-namespace \
    --set <key>=<value>

- Enable Gateway API:
  --set providers.kubernetesGateway.enabled=true

- Check installation:
  helm list -n traefik
  helm get values traefik -n traefik

- Check pods:
  kubectl get pods -n traefik
  kubectl get all -n traefik

- Troubleshoot:
  helm status traefik -n traefik
  kubectl logs -n traefik -l app.kubernetes.io/name=traefik

DELIVERABLES:
-------------
- Helm installed
- Traefik deployed via Helm
- Release name: traefik
- Namespace: traefik
- Gateway API enabled

SCORING:
--------
- Helm installed: 3 points
- Traefik Helm repo added: 3 points
- Traefik release exists: 4 points
- Release name is "traefik": 2 points
- Deployed in "traefik" namespace: 3 points
- Traefik pods running: 4 points
- Gateway API enabled: 3 points

Total: 22 points
Passing: 16 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Forgetting to add Helm repository
2. Wrong release or namespace name
3. Not enabling Gateway API support
4. Not creating namespace first
5. Using wrong Helm chart

IMPORTANT NOTES:
----------------
• Helm 3 recommended (no Tiller required)
• Traefik is a popular ingress controller
• Gateway API is next-gen ingress/routing
• Helm values override default configuration
• --create-namespace flag creates namespace automatically
• Release names must be unique per namespace

HELM BASICS:
------------
Common commands:
- helm repo add <name> <url> - Add repository
- helm repo update - Update repositories
- helm search repo <chart> - Search for charts
- helm install <release> <chart> - Install chart
- helm list - List releases
- helm uninstall <release> - Remove release
- helm get values <release> - Show values

TRAEFIK:
--------
Traefik is a modern HTTP reverse proxy and load balancer.

Features:
- Ingress controller
- Gateway API support
- Automatic service discovery
- Let's Encrypt integration
- WebSocket support
- HTTP/2 and gRPC

GATEWAY API:
------------
Kubernetes Gateway API is the next generation of:
- Ingress
- Service mesh
- Network routing

Enables:
- More expressive routing
- Better role separation
- Vendor neutrality

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
