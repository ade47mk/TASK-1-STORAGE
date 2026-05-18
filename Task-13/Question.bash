#!/bin/bash

# Task 13: Gateway API - HTTP Routing
# Difficulty: Medium
# Points: 22
# Time: 15-18 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 13: Gateway API - HTTP Routing
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 22
Time Estimate: 15-18 minutes

SCENARIO:
---------
Your cluster has adopted the Kubernetes Gateway API for managing
ingress traffic. A web application is running and needs to be
exposed externally with hostname-based routing.

OBJECTIVE:
----------
Use Gateway API resources to expose web-service externally on
HTTP port 80, routed via the hostname web.example.com.

REQUIREMENTS:
-------------

Existing Resources:
  - Service: web-service (default namespace, port 80)
  - GatewayClass: example-gw-class (already available)

Create Resources:
  - Gateway: Use example-gw-class
  - HTTPRoute: Route web.example.com to web-service

Routing:
  - Hostname: web.example.com
  - Protocol: HTTP
  - Port: 80
  - Backend: web-service (port 80)

TASKS:
------
1. Verify existing resources:
   kubectl get service web-service
   kubectl get gatewayclass example-gw-class

2. Create Gateway resource:
   - Name: web-gateway (or similar)
   - GatewayClassName: example-gw-class
   - Listener: HTTP on port 80
   - Hostname: web.example.com

3. Create HTTPRoute resource:
   - Name: web-route (or similar)
   - Parent Gateway: web-gateway
   - Hostname: web.example.com
   - Backend: web-service (port 80)

4. Apply manifests:
   kubectl apply -f gateway.yaml
   kubectl apply -f httproute.yaml

5. Verify:
   kubectl get gateway
   kubectl get httproute
   kubectl describe httproute web-route

VERIFICATION:
-------------
Your solution should meet these criteria:
- Gateway resource exists
- Gateway references example-gw-class
- Gateway has HTTP listener on port 80
- HTTPRoute exists
- HTTPRoute routes web.example.com to web-service
- Resources are properly configured

HINTS:
------
- Gateway manifest example:
  ```yaml
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
  ```

- HTTPRoute manifest example:
  ```yaml
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

- Check Gateway API resources:
  kubectl api-resources | grep gateway
  kubectl get gateway
  kubectl get httproute

- Describe for details:
  kubectl describe gateway web-gateway
  kubectl describe httproute web-route

DELIVERABLES:
-------------
- Gateway resource created
- HTTPRoute resource created
- Routes web.example.com to web-service
- Resources properly linked

SCORING:
--------
- Gateway resource exists: 4 points
- Gateway uses example-gw-class: 3 points
- Gateway has HTTP listener on port 80: 4 points
- HTTPRoute resource exists: 4 points
- HTTPRoute references Gateway: 3 points
- HTTPRoute routes to web-service: 4 points

Total: 22 points
Passing: 16 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Wrong API version (must be gateway.networking.k8s.io/v1)
2. Wrong GatewayClassName
3. Missing hostname in Gateway listener
4. Missing parentRefs in HTTPRoute
5. Wrong service name in backendRefs

IMPORTANT NOTES:
----------------
• Gateway API is next-gen ingress/routing
• GatewayClass defines implementation
• Gateway defines infrastructure (listeners)
• HTTPRoute defines routing rules
• parentRefs links HTTPRoute to Gateway
• backendRefs links to Services

GATEWAY API CONCEPTS:
---------------------
Gateway API Resources:
1. GatewayClass - Implementation (like IngressClass)
2. Gateway - Infrastructure/listeners
3. HTTPRoute - HTTP routing rules
4. TCPRoute - TCP routing
5. TLSRoute - TLS routing
6. GRPCRoute - gRPC routing

Hierarchy:
  GatewayClass
      ↓
    Gateway (listeners)
      ↓
  HTTPRoute (routing rules)
      ↓
  Service (backends)

GATEWAY RESOURCE:
-----------------
Key fields:
- gatewayClassName: Links to GatewayClass
- listeners[]: Array of listeners
  - name: Listener identifier
  - protocol: HTTP, HTTPS, TCP, TLS
  - port: Listen port
  - hostname: Optional hostname filter

HTTPROUTE RESOURCE:
-------------------
Key fields:
- parentRefs[]: Gateway references
  - name: Gateway name
  - namespace: Optional (defaults to same namespace)
- hostnames[]: Hostname matching
- rules[]: Routing rules
  - backendRefs[]: Backend services
    - name: Service name
    - port: Service port

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
