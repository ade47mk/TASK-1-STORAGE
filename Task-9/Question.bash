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
The cluster's DNS service (CoreDNS) has completely failed. The CoreDNS
pods are in CrashLoopBackOff state (0/1 Ready), and all DNS resolution
in the cluster is broken. Pods cannot resolve any DNS names - neither
internal cluster services nor external domains.

This is a critical issue that must be fixed immediately!

SYMPTOMS:
---------
- CoreDNS pods show STATUS: CrashLoopBackOff
- CoreDNS pods show READY: 0/1 (containers not running)
- CoreDNS pods have high RESTART counts (5+)
- Pods cannot resolve ANY DNS names
- Applications fail to connect to services and external APIs
- kubectl logs shows CoreDNS errors

OBJECTIVE:
----------
Investigate why CoreDNS pods are crashing and restore DNS functionality
in the cluster. The CoreDNS pods must be running (1/1 Ready) and DNS
resolution must work.

REQUIREMENTS:
-------------
1. CoreDNS pods must be Running (not CrashLoopBackOff)
2. CoreDNS pods must be 1/1 Ready
3. External DNS resolution must work
4. Internal cluster DNS must work correctly

INVESTIGATION STEPS:
--------------------
1. Check CoreDNS pod status:
   kubectl get pods -n kube-system -l k8s-app=kube-dns

   Look for:
   - STATUS: CrashLoopBackOff or Error
   - READY: 0/1 (means container failed)
   - RESTARTS: High number (indicates crash loop)

2. Check CoreDNS logs (MOST IMPORTANT!):
   kubectl logs -n kube-system -l k8s-app=kube-dns

   Look for error messages like:
   - "Error during parsing: Unknown directive ..."
   - "Unknown directive 'kubernetezz'"
   - Corefile syntax errors
   - Invalid plugin names (typos)
   - Configuration parsing errors

3. Describe the pod for more details:
   kubectl describe pod -n kube-system -l k8s-app=kube-dns

   Look for events:
   - "Back-off restarting failed container"
   - Exit codes
   - Error messages

4. Examine CoreDNS configuration:
   kubectl get configmap coredns -n kube-system -o yaml

   Check the Corefile for:
   - Syntax errors
   - Missing required plugins
   - Commented-out critical plugins
   - Invalid configuration

COMMON CAUSES OF CrashLoopBackOff:
-----------------------------------
- Corefile syntax errors (most common!)
- TYPOS in directive names (e.g., 'kubernetezz' instead of 'kubernetes')
- Missing required plugins (loop, reload, etc.)
- Invalid plugin configuration
- Incorrect indentation or missing braces
- Resource constraints (memory/CPU)
- Missing permissions (RBAC)

TASKS:
------
1. Identify why CoreDNS containers are crashing
2. Check the logs for specific error messages
3. Fix the CoreDNS ConfigMap (likely Corefile syntax error)
4. Delete CoreDNS pods to apply the fix:
   kubectl delete pods -n kube-system -l k8s-app=kube-dns
5. Verify pods reach Running state (1/1 Ready)
6. Verify DNS resolution works for:
   - Internal cluster services (kubernetes.default)
   - External domains (google.com)

HINTS:
------
- CrashLoopBackOff means the container keeps crashing
- ALWAYS check logs first: kubectl logs -n kube-system -l k8s-app=kube-dns
- Look for "Error during parsing" and "Unknown directive" in logs
- The error message shows the EXACT LINE NUMBER with the problem
- Check for TYPOS in directive names (common exam scenario!)
- The CoreDNS ConfigMap is in kube-system namespace
- Valid directives: kubernetes, forward, cache, loop, reload, etc.
- After fixing ConfigMap, you MUST restart pods:
  kubectl delete pods -n kube-system -l k8s-app=kube-dns

- Test DNS after fix:
  kubectl exec dns-test -- nslookup kubernetes.default
  kubectl exec dns-test -- nslookup google.com

VERIFICATION:
-------------
Your solution should meet these criteria:
- CoreDNS pods are Running (not CrashLoopBackOff)
- CoreDNS pods show 1/1 Ready
- External DNS resolution works (e.g., google.com)
- Internal cluster DNS works (e.g., kubernetes.default)
- No errors in CoreDNS logs
- Pods have RESTARTS: 0 (no more crashes)

DELIVERABLES:
-------------
- Fixed CoreDNS ConfigMap (corrected Corefile)
- CoreDNS pods Running and healthy (1/1 Ready)
- DNS resolution working for both internal and external domains
- Clean logs (no errors)

SCORING:
--------
- Identified the crash issue: 2 points
- Checked logs for error details: 2 points
- Found the Corefile syntax error: 2 points
- Fixed CoreDNS ConfigMap: 6 points
- Restarted CoreDNS pods: 1 point
- Pods now Running (1/1 Ready): 3 points
- External DNS resolution works: 2 points
- Internal DNS resolution works: 2 points

Total: 20 points
Passing: 16 points

════════════════════════════════════════════════════════════════

CRITICAL TIPS:
- CrashLoopBackOff is different from Running-but-misconfigured!
- The container CANNOT START due to a fatal error
- You MUST fix the config before pods can run
- Logs are your best friend - read them carefully!

VALIDATION:
Run ./Task-9/validate.sh when complete to check your work.

Need help? Check Task-9/SolutionNotes.bash for step-by-step solution.

Good luck! 🚀

EOF
