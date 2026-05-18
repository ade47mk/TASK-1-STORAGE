#!/bin/bash

# Task 6: Pod Security Standards
# Difficulty: Medium
# Points: 18
# Time: 10-15 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 6: Pod Security Standards (PSS)
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 18
Time Estimate: 10-15 minutes

SCENARIO:
---------
Your organization requires strict security controls. You need to
ensure that pods in the restricted-ns namespace cannot run with
privileged access, use host networking, or have elevated rights.

OBJECTIVE:
----------
Configure the namespace 'restricted-ns' to enforce the Restricted
Pod Security Standard, preventing pods from running with insecure
configurations.

REQUIREMENTS:
-------------

Namespace Configuration:
  - Name: restricted-ns (already created)
  - Apply Restricted Pod Security Standard
  - Mode: enforce (pods will be rejected)

Security Restrictions:
  - No privileged containers
  - No host networking (hostNetwork: true)
  - No host PID/IPC namespaces
  - No privilege escalation
  - Must run as non-root
  - Must drop ALL capabilities
  - Restrictive seccomp/AppArmor profiles

TASKS:
------
1. Label the namespace to enforce Restricted standard:
   Add the appropriate Pod Security Standard labels

2. Verify the configuration by testing:
   - Create a privileged pod (should be REJECTED)
   - Create a restricted pod (should be ALLOWED)

3. Ensure pods violating the standard cannot be created

VERIFICATION:
-------------
Your solution should meet these criteria:
- Namespace 'restricted-ns' has PSS labels
- Pod Security Standard: Restricted
- Mode: enforce
- Privileged pods are rejected
- Host networking pods are rejected
- Properly configured restricted pods are allowed

HINTS:
------
- Pod Security Standards (PSS) are enforced via namespace labels
  
- Label format:
  pod-security.kubernetes.io/<MODE>: <LEVEL>
  
- Modes:
  * enforce - Violations rejected
  * audit - Violations logged
  * warn - Violations show warnings

- Levels:
  * privileged - Unrestricted (most permissive)
  * baseline - Minimally restrictive
  * restricted - Heavily restricted (most secure)

- For this task, use:
  Mode: enforce
  Level: restricted

- Label the namespace:
  kubectl label namespace restricted-ns \
    pod-security.kubernetes.io/enforce=restricted

- Test with a privileged pod:
  kubectl run privileged-test \
    --image=nginx \
    --privileged \
    -n restricted-ns
  # Should be REJECTED

- Test with a restricted pod:
  kubectl run restricted-test \
    --image=nginx \
    -n restricted-ns \
    --dry-run=client -o yaml | \
  kubectl apply -f -
  # Should be ALLOWED (if properly configured)

- Check namespace labels:
  kubectl get namespace restricted-ns --show-labels

DELIVERABLES:
-------------
- Namespace labeled with PSS enforce=restricted
- Privileged pods cannot be created
- Compliant pods can be created

SCORING:
--------
- Namespace has PSS label: 4 points
- Enforce mode configured: 3 points
- Restricted level set: 4 points
- Privileged pod rejected: 4 points
- Restricted pod allowed: 3 points

Total: 18 points
Passing: 13 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Using wrong label key format
2. Using "audit" or "warn" instead of "enforce"
3. Using "baseline" instead of "restricted"
4. Forgetting to label the namespace
5. Testing in wrong namespace

IMPORTANT NOTES:
----------------
• PSS requires Kubernetes 1.23+
• Labels are applied to namespaces, not pods
• Enforce mode rejects non-compliant pods at admission
• Restricted is the most secure level
• Default namespace has no PSS by default

POD SECURITY STANDARDS LEVELS:
-------------------------------
1. Privileged (Most Permissive)
   - No restrictions
   - Allows everything

2. Baseline (Minimal Restrictions)
   - Prevents most privilege escalation
   - Still allows some flexibility

3. Restricted (Most Secure) ← Use this!
   - Heavily restricted
   - Follows current pod hardening best practices
   - Required for this task

WHAT RESTRICTED BLOCKS:
-----------------------
✗ Privileged containers
✗ Host namespaces (network, PID, IPC)
✗ Privilege escalation
✗ Running as root (UID 0)
✗ Dangerous capabilities
✗ hostPath volumes
✗ Host ports
✗ AppArmor/SELinux/seccomp relaxation

WHAT RESTRICTED REQUIRES:
--------------------------
✓ Run as non-root user
✓ Drop ALL capabilities
✓ Non-privileged containers
✓ Restricted volume types
✓ Secure seccomp profile

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
