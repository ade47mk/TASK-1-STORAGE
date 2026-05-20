#!/bin/bash

# Solution Notes for Task 9: CoreDNS Troubleshooting
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: CoreDNS Troubleshooting
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. DNS in Kubernetes clusters
2. CoreDNS architecture and components
3. Troubleshooting methodology
4. Log analysis and debugging
5. Common DNS failure modes

KEY CONCEPTS
------------
• CoreDNS: Modern DNS server for Kubernetes
• kube-system namespace: Where CoreDNS runs
• kube-dns service: Exposes CoreDNS to pods
• Corefile: CoreDNS configuration
• Service Discovery: DNS-based service lookup

APPROACH
--------

STEP 1: Confirm DNS is Broken
------------------------------

Test DNS resolution:

```bash
kubectl run test-dns --image=busybox:1.28 --restart=Never \
  -- nslookup kubernetes.default
```

Wait a moment, then check:
```bash
kubectl logs test-dns
```

If DNS is broken, you'll see:
```
Server:    10.96.0.10
Address 1: 10.96.0.10

nslookup: can't resolve 'kubernetes.default'
```

Or the pod might timeout.

Clean up:
```bash
kubectl delete pod test-dns
```

STEP 2: Check CoreDNS Pod Status
---------------------------------

List CoreDNS pods:
```bash
kubectl get pods -n kube-system -l k8s-app=coredns
```

Common issues:

**Issue 1: No pods running**
```
No resources found in kube-system namespace.
```
Cause: Deployment scaled to 0 or deleted.

**Issue 2: Pods in CrashLoopBackOff**
```
NAME                       READY   STATUS             RESTARTS   AGE
coredns-5d78c9869d-abc123  0/1     CrashLoopBackOff   5          5m
```
Cause: Configuration error or resource issue.

**Issue 3: Pods Pending**
```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-abc123  0/1     Pending   0          5m
```
Cause: Insufficient resources or node issues.

STEP 3: Check CoreDNS Deployment
---------------------------------

View deployment:
```bash
kubectl get deployment coredns -n kube-system
```

Expected output:
```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   2/2     2            2           10d
```

Common issue - scaled to 0:
```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   0/0     0            0           10d
```

Describe deployment:
```bash
kubectl describe deployment coredns -n kube-system
```

Look for:
- Replicas: Should be 2 (or more)
- Pod Template: Check image, resources
- Events: Any recent errors

STEP 4: Fix Scaled Down Deployment
-----------------------------------

If replicas are 0, scale up:

```bash
kubectl scale deployment coredns -n kube-system --replicas=2
```

Verify pods are starting:
```bash
kubectl get pods -n kube-system -l k8s-app=coredns --watch
```

Wait for pods to be Running:
```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-abc123  1/1     Running   0          30s
coredns-5d78c9869d-def456  1/1     Running   0          30s
```

STEP 5: Check CoreDNS Logs
---------------------------

View logs from CoreDNS pods:

```bash
kubectl logs -n kube-system -l k8s-app=coredns --tail=50
```

Look for:
- Startup messages: `:53` (listening on port 53)
- Plugin loading: `plugin/cache`, `plugin/forward`, etc.
- Errors: `[ERROR]`, `[FATAL]`

Healthy CoreDNS log example:
```
.:53
[INFO] plugin/reload: Running configuration MD5 = abc123def456
CoreDNS-1.9.3
linux/amd64, go1.18, abc123
```

STEP 6: Verify DNS is Fixed
----------------------------

Test internal DNS (cluster service):
```bash
kubectl run test-internal --image=busybox:1.28 --restart=Never \
  -- nslookup kubernetes.default
```

Check logs:
```bash
kubectl logs test-internal
```

Expected output:
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

Test external DNS:
```bash
kubectl run test-external --image=busybox:1.28 --restart=Never \
  -- nslookup google.com
```

Check logs:
```bash
kubectl logs test-external
```

Expected output:
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      google.com
Address 1: 172.217.160.46
Address 2: 2607:f8b0:4004:c07::71
```

Clean up test pods:
```bash
kubectl delete pod test-internal test-external
```

UNDERSTANDING COREDNS ARCHITECTURE
-----------------------------------

Components:

1. **CoreDNS Deployment**
   - Runs DNS server pods
   - Typically 2 replicas for HA
   - Namespace: kube-system

2. **CoreDNS Service (kube-dns)**
   - ClusterIP service
   - Usually 10.96.0.10
   - Exposes CoreDNS to all pods

3. **CoreDNS ConfigMap**
   - Name: coredns
   - Contains Corefile configuration
   - Defines plugins and zones

4. **kubelet configuration**
   - Points pods to DNS service
   - Sets nameserver in /etc/resolv.conf

DNS Query Flow:

```
Pod → /etc/resolv.conf → kube-dns service (10.96.0.10)
  → CoreDNS pod → plugin chain → response
```

COMMON TROUBLESHOOTING SCENARIOS
---------------------------------

**Scenario 1: Scaled to 0 replicas**

Symptoms:
- No CoreDNS pods running
- All DNS queries fail

Diagnosis:
```bash
kubectl get deployment coredns -n kube-system
# Shows: 0/0 replicas
```

Fix:
```bash
kubectl scale deployment coredns -n kube-system --replicas=2
```

**Scenario 2: CrashLoopBackOff**

Symptoms:
- Pods restarting repeatedly
- DNS intermittently works

Diagnosis:
```bash
kubectl logs -n kube-system <coredns-pod>
# Look for error messages
```

Common causes:
- Corrupted ConfigMap
- Plugin errors
- Resource limits too low

Fix:
- Check ConfigMap syntax
- Increase resource limits
- Restore ConfigMap from backup

**Scenario 3: Insufficient Resources**

Symptoms:
- Pods Pending
- Evictions

Diagnosis:
```bash
kubectl describe pod -n kube-system <coredns-pod>
# Look for: "Insufficient cpu" or "Insufficient memory"
```

Fix:
- Free up node resources
- Adjust resource requests
- Add more nodes

**Scenario 4: Network Plugin Issues**

Symptoms:
- CoreDNS pods Running
- DNS still fails

Diagnosis:
```bash
kubectl get pods -n kube-system
# Check CNI plugin pods (calico, flannel, etc.)
```

Fix:
- Restart CNI plugin
- Check network configuration

COREDNS CONFIGURATION
---------------------

View CoreDNS ConfigMap:
```bash
kubectl get configmap coredns -n kube-system -o yaml
```

Example Corefile:
```yaml
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

Key plugins:
- **kubernetes**: Handles cluster DNS
- **forward**: Forwards external queries
- **cache**: Caches responses
- **health**: Health check endpoint
- **ready**: Readiness check endpoint

KUBECTL CHEAT SHEET
-------------------
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=coredns
kubectl describe pod -n kube-system <coredns-pod>

# Check deployment
kubectl get deployment coredns -n kube-system
kubectl describe deployment coredns -n kube-system

# View logs
kubectl logs -n kube-system -l k8s-app=coredns
kubectl logs -n kube-system -l k8s-app=coredns --tail=100

# Scale deployment
kubectl scale deployment coredns -n kube-system --replicas=2

# Check service
kubectl get service kube-dns -n kube-system
kubectl describe service kube-dns -n kube-system

# Check ConfigMap
kubectl get configmap coredns -n kube-system
kubectl describe configmap coredns -n kube-system

# Test DNS
kubectl run test --image=busybox:1.28 --restart=Never -- nslookup kubernetes.default
kubectl logs test

# Interactive DNS test
kubectl run -it --rm debug --image=busybox:1.28 --restart=Never -- sh
# Inside pod:
# nslookup kubernetes.default
# nslookup google.com

# Restart CoreDNS (if needed)
kubectl rollout restart deployment coredns -n kube-system

ADVANCED TROUBLESHOOTING
-------------------------

Check DNS service endpoint:
```bash
kubectl get endpoints kube-dns -n kube-system
```

Expected: Lists CoreDNS pod IPs
```
NAME       ENDPOINTS                       AGE
kube-dns   10.244.0.5:53,10.244.0.6:53     10d
```

If empty: CoreDNS pods not ready or service selector wrong.

Check pod DNS configuration:
```bash
kubectl run test --image=busybox:1.28 --restart=Never --command -- sleep 3600
kubectl exec test -- cat /etc/resolv.conf
```

Expected:
```
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

Check CoreDNS metrics:
```bash
kubectl port-forward -n kube-system deployment/coredns 9153:9153
curl localhost:9153/metrics
```

EXAM TIPS
---------
1. Always check pods first: kubectl get pods -n kube-system
2. Check deployment replicas: should be 2+
3. View logs for specific errors
4. Most common issue: scaled to 0
5. Test both internal and external DNS
6. CoreDNS runs in kube-system namespace
7. Service name is "kube-dns" (historical)
8. ConfigMap name is "coredns"

TIME MANAGEMENT
---------------
For this task (10-15 minutes):
• 2 min: Test DNS to confirm issue
• 2 min: Check CoreDNS pod status
• 3 min: Identify the problem (usually scaled to 0)
• 2 min: Fix (scale up deployment)
• 3 min: Verify DNS is working
• 2 min: Test both internal and external DNS

QUICK REFERENCE
---------------
Troubleshooting checklist:
✓ Test DNS: nslookup kubernetes.default
✓ Check pods: kubectl get pods -n kube-system -l k8s-app=coredns
✓ Check deployment: kubectl get deployment coredns -n kube-system
✓ Check logs: kubectl logs -n kube-system -l k8s-app=coredns
✓ Fix: kubectl scale deployment coredns -n kube-system --replicas=2
✓ Verify: Run DNS tests again

Common fixes:
```bash
# Scale up if 0 replicas
kubectl scale deployment coredns -n kube-system --replicas=2

# Restart if CrashLooping
kubectl rollout restart deployment coredns -n kube-system

# Check if config is valid
kubectl get configmap coredns -n kube-system -o yaml
```

Good luck! 🚀

EOF
