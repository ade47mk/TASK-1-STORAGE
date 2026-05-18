#!/bin/bash

# Solution Notes for Task 4: Horizontal Pod Autoscaling
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Horizontal Pod Autoscaling (HPA)
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. Horizontal Pod Autoscaler (HPA) configuration
2. Metrics Server requirements
3. CPU-based scaling
4. Resource requests/limits importance
5. Autoscaling behavior and timing

KEY CONCEPTS
------------
• HPA: Automatically scales pods based on metrics
• Metrics Server: Collects resource metrics (CPU, memory)
• Target Utilization: Percentage of requested resources
• Scaling Algorithm: target = current * (current_metric / target_metric)
• Cooldown Periods: Prevent rapid scaling fluctuations

APPROACH
--------

STEP 1: Verify Prerequisites
-----------------------------

Check deployment exists:
```bash
kubectl get deployment cpu-demo
```

Expected output:
```
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
cpu-demo   1/1     1            1           2m
```

Check deployment has resource requests:
```bash
kubectl get deployment cpu-demo -o yaml | grep -A 5 resources
```

Should show:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 50Mi
  limits:
    cpu: 200m
    memory: 100Mi
```

⚠️ CRITICAL: Without resource requests, HPA cannot calculate utilization!

Check Metrics Server:
```bash
kubectl get deployment metrics-server -n kube-system
```

Wait for metrics to be available:
```bash
kubectl top nodes
kubectl top pods
```

If you see "error: Metrics API not available", wait 1-2 minutes.

STEP 2: Create the HPA
-----------------------

METHOD 1: Imperative (kubectl command)
```bash
kubectl autoscale deployment cpu-demo \
  --name=cpu-demo-hpa \
  --cpu-percent=50 \
  --min=1 \
  --max=5
```

This is the fastest method for exams!

METHOD 2: Declarative (YAML manifest)

Create hpa.yaml:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-demo-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cpu-demo
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

Apply it:
```bash
kubectl apply -f hpa.yaml
```

Key points explained:

1. **apiVersion: autoscaling/v2**
   - Use v2 (not v1)
   - v2 supports multiple metrics and advanced features
   - v1 only supports CPU

2. **scaleTargetRef**
   - apiVersion: apps/v1 (for Deployment)
   - kind: Deployment
   - name: cpu-demo (must match exactly)

3. **minReplicas: 1**
   - Minimum number of pods
   - HPA will never scale below this

4. **maxReplicas: 5**
   - Maximum number of pods
   - HPA will never scale above this

5. **metrics[].resource.name: cpu**
   - Target CPU utilization
   - Based on container resource requests

6. **averageUtilization: 50**
   - Target 50% of requested CPU
   - If deployment requests 100m, target is 50m per pod

STEP 3: Verify HPA
------------------

Check HPA exists:
```bash
kubectl get hpa
```

Expected output:
```
NAME            REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
cpu-demo-hpa    Deployment/cpu-demo   15%/50%   1         5         1          30s
```

Key columns:
- TARGETS: current%/target%
- If shows "<unknown>/50%": metrics not ready yet, wait

Detailed information:
```bash
kubectl describe hpa cpu-demo-hpa
```

Look for:
- Reference: Deployment/cpu-demo
- Min replicas: 1
- Max replicas: 5
- Metrics: cpu resource utilization (50%)
- Events: Scaling decisions

STEP 4: Understanding HPA Behavior
-----------------------------------

How HPA calculates desired replicas:

```
desired_replicas = ceil(current_replicas * (current_metric / target_metric))
```

Example:
- Current: 2 replicas
- Current CPU: 75% average
- Target CPU: 50%
- Calculation: ceil(2 * (75 / 50)) = ceil(3) = 3 replicas

Scaling decisions:
- If current > target: scale up
- If current < target (with tolerance): scale down
- Tolerance: typically 10% (40%-60% is stable for 50% target)

Cooldown periods:
- Scale up: 3 minutes (prevents rapid scale-up)
- Scale down: 5 minutes (prevents flapping)

STEP 5: Testing HPA (Optional)
-------------------------------

Generate load to test scaling:

```bash
# Get pod name
POD=$(kubectl get pods -l app=cpu-demo -o jsonpath='{.items[0].metadata.name}')

# Generate CPU load (in pod)
kubectl exec -it $POD -- stress --cpu 1 --timeout 300s
```

Or create a load generator pod:
```bash
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://cpu-demo; done"
```

Watch HPA:
```bash
kubectl get hpa cpu-demo-hpa --watch
```

You should see:
1. TARGETS increase (e.g., 15%/50% → 80%/50%)
2. After ~15-30 seconds: scaling decision
3. REPLICAS increase (1 → 2 → 3...)
4. After scaling: TARGETS decrease

Stop load and watch scale down:
```bash
# Stop the load
kubectl delete pod load-generator

# Watch HPA
kubectl get hpa --watch
```

After 5 minutes of low CPU:
- HPA will scale down
- Replicas return to minReplicas (1)

COMMON MISTAKES
---------------

❌ Wrong: Using autoscaling/v1
```yaml
apiVersion: autoscaling/v1  # Old version
kind: HorizontalPodAutoscaler
```

✓ Correct: Use autoscaling/v2
```yaml
apiVersion: autoscaling/v2  # Current version
kind: HorizontalPodAutoscaler
```

❌ Wrong: Typo in deployment name
```yaml
scaleTargetRef:
  name: cpu-demo-app  # Wrong name
```

✓ Correct: Exact deployment name
```yaml
scaleTargetRef:
  name: cpu-demo  # Must match exactly
```

❌ Wrong: Missing resource requests
```yaml
# Deployment without requests
containers:
- name: app
  image: nginx
  # No resources defined - HPA can't work!
```

✓ Correct: Resource requests defined
```yaml
containers:
- name: app
  image: nginx
  resources:
    requests:
      cpu: 100m  # HPA uses this
```

❌ Wrong: Creating HPA before metrics ready
```bash
# Immediately after deployment
kubectl autoscale deployment cpu-demo ...
kubectl get hpa  # Shows <unknown>/50%
```

✓ Correct: Wait for metrics
```bash
# Wait 1-2 minutes
kubectl top pods
# Then create HPA
kubectl autoscale deployment cpu-demo ...
```

TROUBLESHOOTING
---------------

Problem: HPA shows "<unknown>/50%"
→ Metrics Server not ready or deployment has no requests
→ Wait 1-2 minutes for metrics to be available
→ Check: kubectl top pods
→ Verify deployment has resource requests

Problem: "unable to get metrics"
→ Metrics Server not installed
→ Check: kubectl get deployment metrics-server -n kube-system
→ Install if missing:
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

Problem: HPA created but not scaling
→ Current CPU might be within tolerance
→ Check current utilization: kubectl get hpa
→ If 45%-55%, no scaling (tolerance)
→ Generate load to test

Problem: HPA targets wrong deployment
→ Check scaleTargetRef name matches deployment
→ Check namespace matches
→ Verify: kubectl get deployment cpu-demo

Problem: "missing request for cpu"
→ Deployment pods don't have CPU requests
→ HPA requires requests to calculate utilization
→ Fix deployment to add resources.requests.cpu

KUBECTL CHEAT SHEET
-------------------
# Create HPA (imperative)
kubectl autoscale deployment cpu-demo --cpu-percent=50 --min=1 --max=5

# Create HPA with custom name
kubectl autoscale deployment cpu-demo \
  --name=cpu-demo-hpa \
  --cpu-percent=50 \
  --min=1 \
  --max=5

# Get HPA
kubectl get hpa
kubectl get hpa cpu-demo-hpa
kubectl describe hpa cpu-demo-hpa

# Watch HPA
kubectl get hpa --watch
kubectl get hpa cpu-demo-hpa -w

# Check metrics
kubectl top nodes
kubectl top pods
kubectl top pods -l app=cpu-demo

# View HPA YAML
kubectl get hpa cpu-demo-hpa -o yaml

# Edit HPA
kubectl edit hpa cpu-demo-hpa

# Delete HPA
kubectl delete hpa cpu-demo-hpa

# Check deployment scaling
kubectl get deployment cpu-demo --watch
kubectl get pods -l app=cpu-demo --watch

UNDERSTANDING CPU UTILIZATION
------------------------------

CPU request: 100m (millicores)
CPU target: 50%
Effective target: 50m per pod

Scaling examples:

1 pod using 80m:
- Utilization: 80/100 = 80%
- Above target (50%)
- Desired: ceil(1 * (80/50)) = ceil(1.6) = 2 pods

2 pods using 40m each:
- Utilization: 40/100 = 40%
- Below target (50%)
- Desired: ceil(2 * (40/50)) = ceil(1.6) = 2 pods (stays at 2)

2 pods using 20m each:
- Utilization: 20/100 = 20%
- Well below target (50%)
- Desired: ceil(2 * (20/50)) = ceil(0.8) = 1 pod (scale down)

HPA CONFIGURATION OPTIONS
--------------------------

Basic CPU-based HPA:
```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 50
```

Memory-based HPA:
```yaml
metrics:
- type: Resource
  resource:
    name: memory
    target:
      type: Utilization
      averageUtilization: 70
```

Multiple metrics (both CPU and memory):
```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 50
- type: Resource
  resource:
    name: memory
    target:
      type: Utilization
      averageUtilization: 70
```

With multiple metrics, HPA uses the highest recommended replica count.

EXAM TIPS
---------
1. Use imperative command (kubectl autoscale) for speed
2. Always verify deployment has resource requests
3. Wait 1-2 minutes for metrics before checking HPA
4. Use kubectl get hpa --watch to observe behavior
5. Remember: minReplicas, maxReplicas, and cpu-percent
6. Check HPA targets show numbers, not "<unknown>"
7. Use autoscaling/v2 for YAML manifests

TIME MANAGEMENT
---------------
For this task (10-15 minutes):
• 2 min: Verify deployment and Metrics Server
• 2 min: Create HPA (imperative is fastest)
• 3 min: Verify HPA is working and reading metrics
• 3 min: Debug if needed
• 3 min: Optional load testing
• 2 min: Final verification

QUICK REFERENCE
---------------
HPA checklist:
✓ Name: cpu-demo-hpa
✓ Target: deployment/cpu-demo
✓ Min replicas: 1
✓ Max replicas: 5
✓ CPU target: 50%
✓ Metrics available (not <unknown>)

Commands:
```bash
# Create
kubectl autoscale deployment cpu-demo \
  --name=cpu-demo-hpa \
  --cpu-percent=50 \
  --min=1 \
  --max=5

# Verify
kubectl get hpa
kubectl describe hpa cpu-demo-hpa

# Monitor
kubectl get hpa --watch
kubectl top pods
```

Good luck! 🚀

EOF
