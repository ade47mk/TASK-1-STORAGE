#!/bin/bash

# Task 4: Horizontal Pod Autoscaling
# Difficulty: Medium
# Points: 20
# Time: 10-15 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 4: Horizontal Pod Autoscaling (HPA)
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 20
Time Estimate: 10-15 minutes

SCENARIO:
---------
Your application needs to automatically scale based on CPU load.
During peak times, the application should scale up to handle
increased traffic. During low usage, it should scale down to
save resources.

OBJECTIVE:
----------
Configure Horizontal Pod Autoscaling for an existing deployment
to automatically adjust the number of replicas based on CPU
utilization.

REQUIREMENTS:
-------------

Target Deployment:
  - Name: cpu-demo (already created by setup)
  - Current replicas: 1
  - Namespace: default

HPA Configuration:
  - Name: cpu-demo-hpa
  - Target: deployment/cpu-demo
  - Min replicas: 1
  - Max replicas: 5
  - CPU threshold: 50% (average CPU utilization)
  - Namespace: default

TASKS:
------
1. Verify the cpu-demo deployment exists and is running

2. Check that Metrics Server is available:
   kubectl top nodes
   kubectl top pods

3. Create an HPA resource that:
   - Targets the cpu-demo deployment
   - Maintains between 1 and 5 replicas
   - Scales up when average CPU > 50%
   - Scales down when average CPU < 50%

4. Verify the HPA is working:
   - Check HPA status
   - Observe current metrics
   - Ensure HPA can read metrics

5. (Optional) Test scaling behavior:
   - Generate load on the pods
   - Watch HPA scale up
   - Remove load and watch scale down

VERIFICATION:
-------------
Your solution should meet these criteria:
- HPA resource exists with name "cpu-demo-hpa"
- HPA targets deployment "cpu-demo"
- Min replicas set to 1
- Max replicas set to 5
- CPU target set to 50%
- HPA can successfully read metrics
- HPA is in "Ready" state

HINTS:
------
- Create HPA using kubectl or YAML manifest

- Using kubectl (imperative):
  kubectl autoscale deployment cpu-demo \
    --name=cpu-demo-hpa \
    --cpu-percent=50 \
    --min=1 \
    --max=5

- Using YAML (declarative):
  apiVersion: autoscaling/v2
  kind: HorizontalPodAutoscaler
  metadata:
    name: cpu-demo-hpa
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

- Check HPA status:
  kubectl get hpa
  kubectl describe hpa cpu-demo-hpa

- View current metrics:
  kubectl top pods
  kubectl get hpa cpu-demo-hpa --watch

- The deployment MUST have resource requests defined
  (already configured in setup)

- Wait 1-2 minutes after deployment creation for metrics
  to be available

DELIVERABLES:
-------------
- HPA resource created and functional
- HPA successfully reading metrics
- HPA shows target deployment
- All configurations match requirements

SCORING:
--------
- HPA exists with correct name: 3 points
- HPA targets correct deployment: 3 points
- Min replicas set to 1: 2 points
- Max replicas set to 5: 2 points
- CPU target set to 50%: 3 points
- HPA can read metrics (not unknown): 4 points
- HPA shows current/target metrics: 3 points

Total: 20 points
Passing: 14 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Creating HPA before Metrics Server is ready
2. Target deployment missing resource requests
3. Wrong API version (use autoscaling/v2, not v1)
4. Typo in deployment name
5. Wrong namespace
6. Not waiting for metrics to be available

IMPORTANT NOTES:
----------------
• Metrics Server must be installed and running
• Deployment must have CPU requests defined
• Initial metrics take 1-2 minutes to appear
• HPA checks metrics every 15 seconds (default)
• Scaling decisions have cooldown periods:
  - Scale up: 3 minutes
  - Scale down: 5 minutes

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
