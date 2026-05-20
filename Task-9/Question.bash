#!/bin/bash

# Task 9: CoreDNS Troubleshooting
# Difficulty: Medium
# Points: 20
# Time: 10-15 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 9: CoreDNS Troubleshooting
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 20
Time Estimate: 10-15 minutes

SCENARIO:
---------
DNS lookups are failing in the cluster. Applications cannot
resolve service names or external domains. You need to identify
and fix the CoreDNS issues.

OBJECTIVE:
----------
Troubleshoot and repair CoreDNS to restore DNS functionality
in the cluster.

REQUIREMENTS:
-------------

Investigation Steps:
  1. Test DNS resolution from a pod
  2. Check CoreDNS pod status
  3. Check CoreDNS deployment
  4. Review CoreDNS logs
  5. Identify and fix the issue(s)

Expected Outcome:
  - CoreDNS pods running and healthy
  - DNS resolution working for services
  - DNS resolution working for external domains
  - At least 2 CoreDNS replicas running

TASKS:
------
1. Test DNS to confirm it's broken:
   kubectl run test-dns --image=busybox:1.28 --restart=Never \
     -- nslookup kubernetes.default

2. Check CoreDNS status:
   kubectl get pods -n kube-system -l k8s-app=coredns

3. Investigate the deployment:
   kubectl get deployment coredns -n kube-system

4. Check for issues:
   - Are pods running?
   - Are there enough replicas?
   - Any errors in logs?

5. Fix the identified issues

6. Verify DNS is working:
   kubectl run test-dns --image=busybox:1.28 --restart=Never \
     -- nslookup kubernetes.default

VERIFICATION:
-------------
Your solution should meet these criteria:
- CoreDNS deployment exists in kube-system
- At least 2 CoreDNS pods running
- CoreDNS pods are in Running state
- DNS resolution works for cluster services
- DNS resolution works for external domains

HINTS:
------
- CoreDNS runs in kube-system namespace
- Common issues:
  * Pods scaled to 0 replicas
  * Pods in CrashLoopBackOff
  * Missing or corrupted ConfigMap
  * Resource constraints
  * Network policy blocking traffic

- Check CoreDNS pods:
  kubectl get pods -n kube-system -l k8s-app=coredns

- Check CoreDNS deployment:
  kubectl get deployment coredns -n kube-system
  kubectl describe deployment coredns -n kube-system

- View CoreDNS logs:
  kubectl logs -n kube-system -l k8s-app=coredns

- Scale CoreDNS:
  kubectl scale deployment coredns -n kube-system --replicas=2

- Test DNS from a pod:
  kubectl run -it --rm debug --image=busybox:1.28 --restart=Never \
    -- nslookup kubernetes.default

- Test external DNS:
  kubectl run -it --rm debug --image=busybox:1.28 --restart=Never \
    -- nslookup google.com

DELIVERABLES:
-------------
- CoreDNS deployment healthy
- At least 2 CoreDNS replicas running
- DNS resolution functional

SCORING:
--------
- CoreDNS deployment exists: 3 points
- CoreDNS has 2+ replicas: 4 points
- CoreDNS pods are Running: 5 points
- Internal DNS works: 4 points
- External DNS works: 4 points

Total: 20 points
Passing: 14 points

════════════════════════════════════════════════════════════════

COMMON DNS ISSUES:
------------------
1. Scaled to 0 replicas
   - Fix: kubectl scale deployment coredns -n kube-system --replicas=2

2. Pods CrashLoopBackOff
   - Check logs: kubectl logs -n kube-system <coredns-pod>
   - Check ConfigMap: kubectl get cm coredns -n kube-system

3. Insufficient resources
   - Check node resources
   - Adjust resource requests/limits

4. Network issues
   - Check kube-proxy
   - Check network plugin (CNI)

5. ConfigMap corruption
   - Verify Corefile syntax
   - Restore from backup if needed

IMPORTANT NOTES:
----------------
• CoreDNS is the default DNS in Kubernetes 1.13+
• Runs as deployment in kube-system namespace
• Uses ConfigMap "coredns" for configuration
• Exposed via Service "kube-dns" (historical name)
• Critical for service discovery
• Required for many cluster operations

DNS RESOLUTION FLOW:
--------------------
1. Pod makes DNS query
2. Query sent to CoreDNS service (10.96.0.10 typically)
3. CoreDNS checks query type
4. For cluster services: returns ClusterIP
5. For external: forwards to upstream DNS
6. Response returned to pod

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
