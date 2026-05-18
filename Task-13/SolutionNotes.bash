#!/bin/bash

# Solution Notes for Task 13: Gateway API - HTTP Routing
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Gateway API - HTTP Routing
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. Kubernetes Gateway API fundamentals
2. Gateway resource configuration
3. HTTPRoute resource configuration
4. Hostname-based routing
5. Service backend references

KEY CONCEPTS
------------
• Gateway API: Next-generation ingress/routing API
• GatewayClass: Implementation (like StorageClass)
• Gateway: Infrastructure layer (like LoadBalancer)
• HTTPRoute: Routing rules (like Ingress rules)
• Role separation: Infra team (Gateway) vs App team (Routes)

APPROACH
--------

STEP 1: Verify Existing Resources
----------------------------------

Check web-service:

```bash
kubectl get service web-service
```

Expected output:
```
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-service   ClusterIP   10.96.123.456   <none>        80/TCP    5m
```

Check GatewayClass:

```bash
kubectl get gatewayclass example-gw-class
```

Expected output:
```
NAME               CONTROLLER                       ACCEPTED   AGE
example-gw-class   example.com/gateway-controller   True       5m
```

Describe GatewayClass:

```bash
kubectl describe gatewayclass example-gw-class
```

STEP 2: Create Gateway Resource
--------------------------------

Create gateway.yaml:

```bash
cat > gateway.yaml << 'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: example-gw-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: "web.example.com"
YAML
```

Key components:
1. **apiVersion**: gateway.networking.k8s.io/v1 (v1 stable)
2. **gatewayClassName**: Links to GatewayClass
3. **listeners**: Array of listen configurations
   - **name**: Identifier (http, https, etc.)
   - **protocol**: HTTP, HTTPS, TCP, TLS, etc.
   - **port**: Listen port (80 for HTTP)
   - **hostname**: Optional hostname filter

Apply:

```bash
kubectl apply -f gateway.yaml
```

Expected output:
```
gateway.gateway.networking.k8s.io/web-gateway created
```

Verify:

```bash
kubectl get gateway
```

Expected:
```
NAME          CLASS              ADDRESS   PROGRAMMED   AGE
web-gateway   example-gw-class             Unknown      10s
```

Describe:

```bash
kubectl describe gateway web-gateway
```

Check listeners:
```
Listeners:
  Name:      http
  Port:      80
  Protocol:  HTTP
  Hostname:  web.example.com
```

STEP 3: Create HTTPRoute Resource
----------------------------------

Create httproute.yaml:

```bash
cat > httproute.yaml << 'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "web.example.com"
  rules:
  - backendRefs:
    - name: web-service
      port: 80
YAML
```

Key components:
1. **parentRefs**: Links to Gateway
   - **name**: Gateway name (web-gateway)
   - **namespace**: Optional (defaults to same namespace)
2. **hostnames**: Hostname matching (web.example.com)
3. **rules**: Routing rules
   - **backendRefs**: Backend services
     - **name**: Service name (web-service)
     - **port**: Service port (80)

Apply:

```bash
kubectl apply -f httproute.yaml
```

Expected output:
```
httproute.gateway.networking.k8s.io/web-route created
```

Verify:

```bash
kubectl get httproute
```

Expected:
```
NAME        HOSTNAMES             AGE
web-route   ["web.example.com"]   10s
```

Describe:

```bash
kubectl describe httproute web-route
```

Check configuration:
```
Parent Refs:
  Name:      web-gateway
Hostnames:
  web.example.com
Rules:
  Backend Refs:
    Name:  web-service
    Port:  80
```

STEP 4: Verify Complete Configuration
--------------------------------------

Check all Gateway API resources:

```bash
kubectl get gateway,httproute
```

Check Gateway status:

```bash
kubectl get gateway web-gateway -o yaml
```

Check HTTPRoute status:

```bash
kubectl get httproute web-route -o yaml
```

Check connectivity (if Gateway controller is functional):

```bash
# Get Gateway address (if assigned)
kubectl get gateway web-gateway -o jsonpath='{.status.addresses[0].value}'

# Test (if DNS/address available)
curl -H "Host: web.example.com" http://<gateway-ip>/
```

UNDERSTANDING GATEWAY API
--------------------------

**Gateway API vs Ingress:**

Ingress (traditional):
- Single resource type
- Limited expressiveness
- No role separation
- Implementation-specific annotations

Gateway API (modern):
- Multiple resource types (GatewayClass, Gateway, Routes)
- Highly expressive
- Clear role separation
- Portable across implementations

**Role Separation:**

1. **Platform Team** (Infrastructure):
   - Manages GatewayClass
   - Deploys Gateway controller
   - Provisions Gateway resources

2. **Application Team** (Developers):
   - Creates HTTPRoute resources
   - Defines routing rules
   - Links to existing Gateways

**Resource Hierarchy:**

```
GatewayClass (Platform team)
    ↓
Gateway (Platform/Infra team)
    ↓
HTTPRoute (App team)
    ↓
Service (App team)
    ↓
Pod (App team)
```

GATEWAY DEEP DIVE
-----------------

**Gateway Specification:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: default
spec:
  gatewayClassName: example-gw-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: "*.example.com"  # Wildcard
    allowedRoutes:
      namespaces:
        from: Same  # All, Same, Selector
  - name: https
    protocol: HTTPS
    port: 443
    hostname: "secure.example.com"
    tls:
      mode: Terminate
      certificateRefs:
      - name: my-cert
```

**Multiple Listeners:**

You can have multiple listeners for:
- Different protocols (HTTP + HTTPS)
- Different ports
- Different hostnames
- Different TLS configs

**Hostname Matching:**

```yaml
hostname: "exact.example.com"      # Exact match
hostname: "*.example.com"          # Wildcard
hostname: "example.com"            # Single label
```

HTTPROUTE DEEP DIVE
--------------------

**HTTPRoute Specification:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
    namespace: infra  # Cross-namespace reference
  hostnames:
  - "app.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
      method: GET
    backendRefs:
    - name: api-service
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80
```

**Path Matching:**

```yaml
matches:
- path:
    type: Exact          # Exact match
    value: /api/v1
- path:
    type: PathPrefix     # Prefix match
    value: /api
- path:
    type: RegularExpression  # Regex (implementation-specific)
    value: "^/api/v[0-9]+"
```

**Header Matching:**

```yaml
matches:
- headers:
  - type: Exact
    name: version
    value: v1
```

**Query Parameter Matching:**

```yaml
matches:
- queryParams:
  - type: Exact
    name: env
    value: production
```

**Traffic Splitting:**

```yaml
backendRefs:
- name: service-v1
  port: 80
  weight: 90
- name: service-v2
  port: 80
  weight: 10
```

COMMON PATTERNS
---------------

**Pattern 1: Simple HTTP Routing**

```yaml
# Gateway
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: example-gw-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80

---
# HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "web.example.com"
  rules:
  - backendRefs:
    - name: web-service
      port: 80
```

**Pattern 2: HTTPS with TLS**

```yaml
# Gateway
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: secure-gateway
spec:
  gatewayClassName: example-gw-class
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: "secure.example.com"
    tls:
      mode: Terminate
      certificateRefs:
      - name: tls-secret

---
# HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: secure-route
spec:
  parentRefs:
  - name: secure-gateway
  hostnames:
  - "secure.example.com"
  rules:
  - backendRefs:
    - name: secure-service
      port: 443
```

**Pattern 3: Path-Based Routing**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: multi-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "app.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: api-service
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /static
    backendRefs:
    - name: static-service
      port: 80
  - backendRefs:  # Default route
    - name: web-service
      port: 80
```

COMMON MISTAKES
---------------

❌ Wrong: Old API version
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1  # Deprecated!
```

✓ Correct: Use v1 (stable)
```yaml
apiVersion: gateway.networking.k8s.io/v1
```

❌ Wrong: Missing parentRefs
```yaml
spec:
  hostnames:
  - "web.example.com"
  # Missing parentRefs!
```

✓ Correct: Include parentRefs
```yaml
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "web.example.com"
```

❌ Wrong: Wrong GatewayClass reference
```yaml
gatewayClassName: nginx  # Doesn't exist!
```

✓ Correct: Use existing GatewayClass
```yaml
gatewayClassName: example-gw-class
```

❌ Wrong: Missing quotes on hostname
```yaml
hostname: web.example.com  # YAML might interpret as object!
```

✓ Correct: Quote hostnames
```yaml
hostname: "web.example.com"
```

TROUBLESHOOTING
---------------

Problem: Gateway not created
→ Check GatewayClass exists: kubectl get gatewayclass
→ Check API version: gateway.networking.k8s.io/v1
→ Check YAML syntax

Problem: HTTPRoute not working
→ Check parentRefs name matches Gateway
→ Check hostnames match Gateway listener
→ Check backendRefs service name and port

Problem: Gateway shows "NotReady"
→ Gateway controller might not be running
→ Check controller logs
→ In exam, focus on correct YAML

KUBECTL CHEAT SHEET
-------------------
# Gateway API resources
kubectl api-resources | grep gateway

# List resources
kubectl get gatewayclass
kubectl get gateway
kubectl get httproute

# Describe
kubectl describe gateway <name>
kubectl describe httproute <name>

# Get YAML
kubectl get gateway <name> -o yaml
kubectl get httproute <name> -o yaml

# Apply
kubectl apply -f gateway.yaml
kubectl apply -f httproute.yaml

# Delete
kubectl delete gateway <name>
kubectl delete httproute <name>

EXAM TIPS
---------
1. Use v1 API version (stable)
2. Quote hostname strings
3. parentRefs links HTTPRoute to Gateway
4. backendRefs links to Services
5. GatewayClass must exist before Gateway
6. Check existing resources first
7. Describe resources for detailed status

TIME MANAGEMENT
---------------
For this task (15-18 minutes):
• 2 min: Verify existing resources
• 5 min: Create Gateway YAML
• 5 min: Create HTTPRoute YAML
• 3 min: Apply and verify
• 3 min: Debug if needed

COMPLETE SOLUTION
-----------------

```bash
# 1. Verify resources
kubectl get service web-service
kubectl get gatewayclass example-gw-class

# 2. Create Gateway
cat > gateway.yaml << 'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: example-gw-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: "web.example.com"
YAML

# 3. Create HTTPRoute
cat > httproute.yaml << 'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "web.example.com"
  rules:
  - backendRefs:
    - name: web-service
      port: 80
YAML

# 4. Apply
kubectl apply -f gateway.yaml
kubectl apply -f httproute.yaml

# 5. Verify
kubectl get gateway,httproute
kubectl describe httproute web-route
```

Good luck! 🚀

EOF
