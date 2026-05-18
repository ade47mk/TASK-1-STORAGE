#!/bin/bash

# Solution Notes for Task 6: Pod Security Standards
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: Pod Security Standards (PSS)
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. Pod Security Standards (PSS) in Kubernetes
2. Namespace label-based security enforcement
3. Different PSS levels and modes
4. Security best practices for pod workloads
5. Testing and validating security policies

KEY CONCEPTS
------------
• Pod Security Standards: Built-in security policies
• Namespace Labels: How PSS is configured
• Enforce Mode: Rejects non-compliant pods
• Restricted Level: Most secure standard
• Admission Control: When policies are checked

APPROACH
--------

STEP 1: Understand Pod Security Standards
------------------------------------------

PSS replaced PodSecurityPolicy (PSP) in Kubernetes 1.25+

Three security levels:
1. **Privileged**: No restrictions (default)
2. **Baseline**: Basic restrictions
3. **Restricted**: Strict restrictions (use this)

Three enforcement modes:
1. **enforce**: Blocks non-compliant pods
2. **audit**: Logs violations, allows pods
3. **warn**: Shows warnings, allows pods

For this task: Use **enforce** mode with **restricted** level

STEP 2: Label the Namespace
----------------------------

Pod Security Standards are configured via namespace labels.

Label format:
```
pod-security.kubernetes.io/<MODE>: <LEVEL>
```

For this task:
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted
```

This single label enforces the Restricted standard.

Verify the label:
```bash
kubectl get namespace restricted-ns --show-labels
```

Expected output should include:
```
pod-security.kubernetes.io/enforce=restricted
```

Alternative: Add multiple modes at once
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

This enforces, audits, AND warns (belt and suspenders approach).

STEP 3: Test with Privileged Pod (Should Fail)
-----------------------------------------------

Try creating a privileged pod:
```bash
kubectl run privileged-test \
  --image=nginx \
  --privileged \
  -n restricted-ns
```

Expected error:
```
Error from server (Forbidden): pods "privileged-test" is forbidden:
violates PodSecurity "restricted:latest": privileged
(container "privileged-test" must not set securityContext.privileged=true)
```

This confirms the Restricted standard is enforcing!

Other tests that should FAIL:
```bash
# Host networking
kubectl run hostnet-test \
  --image=nginx \
  --overrides='{"spec":{"hostNetwork":true}}' \
  -n restricted-ns

# Running as root
kubectl run root-test \
  --image=nginx \
  --overrides='{"spec":{"containers":[{"name":"nginx","image":"nginx","securityContext":{"runAsUser":0}}]}}' \
  -n restricted-ns
```

All should be rejected by PSS.

STEP 4: Test with Restricted Pod (Should Succeed)
--------------------------------------------------

Create a pod that complies with Restricted standard:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-test
  namespace: restricted-ns
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      runAsNonRoot: true
      runAsUser: 1000
      seccompProfile:
        type: RuntimeDefault
```

Apply it:
```bash
kubectl apply -f restricted-pod.yaml
```

This pod should be ALLOWED because it meets all requirements:
- Runs as non-root (UID 1000)
- Drops all capabilities
- No privilege escalation
- Uses secure seccomp profile

Simpler test (if above is too complex):
```bash
kubectl run simple-test \
  --image=nginx:alpine \
  -n restricted-ns \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":1000},"containers":[{"name":"simple-test","image":"nginx:alpine","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}'
```

STEP 5: Verify Configuration
-----------------------------

Check namespace labels:
```bash
kubectl describe namespace restricted-ns
```

Look for:
```
Labels: pod-security.kubernetes.io/enforce=restricted
```

List all pods in namespace:
```bash
kubectl get pods -n restricted-ns
```

Should show only compliant pods.

UNDERSTANDING PSS LABELS
-------------------------

Complete label structure:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-ns
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

Key fields:
- **enforce**: Blocks violations
- **audit**: Logs violations to audit log
- **warn**: Shows warnings to user
- **enforce-version**: Pin to specific K8s version (optional)

For this task, minimum required:
```
pod-security.kubernetes.io/enforce=restricted
```

RESTRICTED STANDARD REQUIREMENTS
---------------------------------

A pod must meet ALL these requirements:

1. **No privileged containers**
   ```yaml
   securityContext:
     privileged: false  # or omit
   ```

2. **No host namespaces**
   ```yaml
   # None of these:
   hostNetwork: false
   hostPID: false
   hostIPC: false
   ```

3. **No privilege escalation**
   ```yaml
   securityContext:
     allowPrivilegeEscalation: false
   ```

4. **Run as non-root**
   ```yaml
   securityContext:
     runAsNonRoot: true
     runAsUser: 1000  # any UID > 0
   ```

5. **Drop all capabilities**
   ```yaml
   securityContext:
     capabilities:
       drop:
       - ALL
   ```

6. **Restricted volumes only**
   Allowed: configMap, downwardAPI, emptyDir, projected, secret, etc.
   Blocked: hostPath

7. **No host ports**
   ```yaml
   # Don't use:
   ports:
   - hostPort: 8080
   ```

8. **Secure profiles**
   ```yaml
   securityContext:
     seccompProfile:
       type: RuntimeDefault
   ```

COMMON MISTAKES
---------------

❌ Wrong: Using baseline instead of restricted
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=baseline  # Wrong level
```

✓ Correct: Use restricted
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted
```

❌ Wrong: Using warn or audit instead of enforce
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/warn=restricted  # Too weak
```

✓ Correct: Use enforce
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted
```

❌ Wrong: Wrong label key format
```bash
kubectl label namespace restricted-ns \
  pod-security=restricted  # Wrong key
```

✓ Correct: Full label key
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted
```

❌ Wrong: Testing in wrong namespace
```bash
kubectl run test --image=nginx --privileged
# Runs in default namespace, not restricted-ns
```

✓ Correct: Specify namespace
```bash
kubectl run test --image=nginx --privileged -n restricted-ns
```

TROUBLESHOOTING
---------------

Problem: Label not working, privileged pods still allowed
→ Check label syntax: kubectl get ns restricted-ns --show-labels
→ Verify label key: pod-security.kubernetes.io/enforce
→ Check you're testing in correct namespace
→ K8s version must be 1.23+

Problem: All pods rejected, even simple ones
→ Restricted standard is very strict
→ Pods must explicitly meet requirements
→ Add securityContext with runAsNonRoot, drop capabilities
→ Use examples from SolutionNotes

Problem: "pod-security.kubernetes.io not supported"
→ K8s version too old (need 1.23+)
→ Check: kubectl version --short

Problem: Label command fails
→ Check namespace exists: kubectl get ns restricted-ns
→ Try: kubectl label ns restricted-ns <label>

KUBECTL CHEAT SHEET
-------------------
# Label namespace
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted

# Check labels
kubectl get namespace restricted-ns --show-labels
kubectl describe namespace restricted-ns

# Test privileged pod (should fail)
kubectl run priv-test --image=nginx --privileged -n restricted-ns

# Test host network (should fail)
kubectl run host-test --image=nginx \
  --overrides='{"spec":{"hostNetwork":true}}' \
  -n restricted-ns

# Create compliant pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: restricted-ns
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: [ALL]
EOF

# List pods
kubectl get pods -n restricted-ns

# Remove label (cleanup)
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce-

PSS vs PSP
----------
If you're familiar with PodSecurityPolicy (PSP):

**PodSecurityPolicy (Deprecated)**
- Cluster-wide RBAC resource
- Complex to configure
- Deprecated in 1.21, removed in 1.25

**Pod Security Standards (Current)**
- Namespace-scoped labels
- Simple to configure
- Built-in, no CRDs needed
- Recommended for K8s 1.23+

For this task, use PSS (namespace labels).

EXAM TIPS
---------
1. Remember label key: pod-security.kubernetes.io/enforce
2. Use "restricted" level for maximum security
3. Use "enforce" mode to block violations
4. Test both privileged (fail) and compliant (succeed) pods
5. Check namespace labels with --show-labels
6. PSS requires K8s 1.23+ (usually available in CKA)
7. Label format is case-sensitive

TIME MANAGEMENT
---------------
For this task (10-15 minutes):
• 2 min: Review requirements and PSS levels
• 3 min: Label the namespace
• 3 min: Test with privileged pod (verify rejection)
• 3 min: Test with compliant pod (verify allowed)
• 2 min: Verify configuration
• 2 min: Debug if needed

QUICK REFERENCE
---------------
Task checklist:
✓ Label namespace: pod-security.kubernetes.io/enforce=restricted
✓ Verify label: kubectl get ns restricted-ns --show-labels
✓ Test rejection: kubectl run test --privileged -n restricted-ns
✓ Confirm error message
✓ Test compliant pod (optional but recommended)

One-liner solution:
```bash
kubectl label namespace restricted-ns \
  pod-security.kubernetes.io/enforce=restricted
```

Good luck! 🚀

EOF
