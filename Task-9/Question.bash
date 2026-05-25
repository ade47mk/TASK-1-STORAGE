#!/bin/bash

# Task 9: CoreDNS Troubleshooting
# Difficulty: Hard
# Points: 20
# Time: 15-20 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 9: CoreDNS Troubleshooting
════════════════════════════════════════════════════════════════

Difficulty: Hard
Points: 20
Time Estimate: 15-20 minutes

SCENARIO:
---------
The cluster's DNS service (CoreDNS) is experiencing failures. Pods
cannot resolve external DNS names, and developers are reporting that
their applications cannot connect to external services.

You need to investigate the issue and restore DNS functionality.

SYMPTOMS:
---------
- Pods cannot resolve external DNS names (e.g., google.com, github.com)
- Internal cluster DNS might work partially
- CoreDNS pods are running but not functioning correctly
- Applications fail to connect to external APIs

OBJECTIVE:
----------
Investigate and repair CoreDNS to restore DNS resolution functionality
in the cluster.

REQUIREMENTS:
-------------
1. CoreDNS pods must be running and healthy
2. External DNS resolution must work from pods
3. Internal cluster DNS must work correctly
4. No downtime for running applications

INVESTIGATION STEPS:
--------------------
1. Check CoreDNS pod status:
   kubectl get pods -n kube-system -l k8s-app=kube-dns

2. Check CoreDNS logs:
   kubectl logs -n kube-system -l k8s-app=kube-dns

3. Examine CoreDNS configuration:
   kubectl get configmap coredns -n kube-system -o yaml

4. Test DNS resolution from a pod:
   kubectl exec dns-test -- nslookup kubernetes.default
   kubectl exec dns-test -- nslookup google.com

COMMON ISSUES TO CHECK:
-----------------------
- Invalid upstream DNS servers in CoreDNS ConfigMap
- Incorrect CoreDNS Corefile syntax
- Network policies blocking DNS traffic
- CoreDNS service not configured correctly
- Missing or incorrect DNS endpoints

TASKS:
------
1. Identify why DNS lookups are failing
2. Fix the CoreDNS configuration
3. Restart CoreDNS pods if necessary
4. Verify DNS resolution works for:
   - Internal cluster services (kubernetes.default)
   - External domains (google.com, github.com)

HINTS:
------
- Check the 'forward' directive in CoreDNS Corefile
- Valid upstream DNS servers: /etc/resolv.conf or 8.8.8.8
- After fixing ConfigMap, you may need to restart CoreDNS pods:
  kubectl delete pods -n kube-system -l k8s-app=kube-dns

- Test DNS from the test pod:
  kubectl exec dns-test -- nslookup kubernetes.default
  kubectl exec dns-test -- nslookup google.com

- CoreDNS ConfigMap location:
  configmap/coredns in namespace kube-system

VERIFICATION:
-------------
Your solution should meet these criteria:
- CoreDNS pods are running and ready
- External DNS resolution works (e.g., google.com)
- Internal cluster DNS works (e.g., kubernetes.default)
- No errors in CoreDNS logs related to upstream servers

DELIVERABLES:
-------------
- Fixed CoreDNS ConfigMap
- CoreDNS pods running and healthy
- DNS resolution working for both internal and external domains

SCORING:
--------
- Identified the DNS issue: 4 points
- Fixed CoreDNS ConfigMap: 6 points
- Restarted CoreDNS pods (if needed): 2 points
- External DNS resolution works: 4 points
- Internal DNS resolution works: 3 points
- Clean CoreDNS logs (no errors): 1 point

Total: 20 points
Passing: 16 points

════════════════════════════════════════════════════════════════

VALIDATION:
Run ./Task-9/validate.sh when complete to check your work.

Need help? Check Task-9/SolutionNotes.bash for step-by-step solution.

Good luck! 🚀

EOF
