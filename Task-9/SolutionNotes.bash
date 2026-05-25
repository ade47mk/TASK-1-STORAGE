#!/bin/bash

# Solution Notes for Task 9: CoreDNS Troubleshooting
# This file contains the step-by-step solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION: CoreDNS Troubleshooting (CrashLoopBackOff)
════════════════════════════════════════════════════════════════

PROBLEM ANALYSIS:
-----------------
The CoreDNS pods are in CrashLoopBackOff state (0/1 Ready), meaning
the containers are failing to start and Kubernetes keeps trying to
restart them.

ROOT CAUSE:
-----------
The CoreDNS ConfigMap has a Corefile syntax error - there's a TYPO
in the directive name. Line 7 contains 'kubernetezz' instead of
'kubernetes'. This causes CoreDNS to fail parsing and crash immediately.

ERROR MESSAGE:
/etc/coredns/Corefile:7 - Error during parsing: Unknown directive 'kubernetezz'

STEP-BY-STEP SOLUTION:
-----------------------

Step 1: Verify CoreDNS Pods Are Crashing
-----------------------------------------
Check CoreDNS pod status:

kubectl get pods -n kube-system -l k8s-app=kube-dns

Expected output:
NAME                       READY   STATUS             RESTARTS   AGE
coredns-6b59c98dd4-zfvm9  0/1     CrashLoopBackOff   5          5m
coredns-6b59c98dd4-xxxxx  0/1     CrashLoopBackOff   5          5m

Key indicators:
- READY: 0/1 (container not ready)
- STATUS: CrashLoopBackOff (or Error)
- RESTARTS: High number (5+)


Step 2: Check CoreDNS Logs for Error Messages
----------------------------------------------
View the logs to identify the EXACT error:

kubectl logs -n kube-system coredns-6b59c98dd4-zfvm9

Expected error output:
/etc/coredns/Corefile:7 - Error during parsing: Unknown directive 'kubernetezz'

This tells you:
- Line 7 has the error
- The directive 'kubernetezz' is not recognized
- It's likely a TYPO (should be 'kubernetes')


Step 3: Examine the CoreDNS ConfigMap
--------------------------------------
Check the current configuration:

kubectl get configmap coredns -n kube-system -o yaml

Look at the Corefile content. You'll see on line 7:

    kubernetezz cluster.local in-addr.arpa ip6.arpa {

This is the problem! It should be 'kubernetes', not 'kubernetezz'.


Step 4: Describe the Pod (Optional - More Details)
---------------------------------------------------
kubectl describe pod -n kube-system -l k8s-app=kube-dns | tail -30

Look for events like:
- Back-off restarting failed container
- Error: exit code 1
- Last State: Terminated (exit code 1)


Step 5: Fix the CoreDNS ConfigMap
----------------------------------
Edit the ConfigMap to fix the typo:

kubectl edit configmap coredns -n kube-system

Find line 7 with the typo:
    kubernetezz cluster.local in-addr.arpa ip6.arpa {

Change 'kubernetezz' to 'kubernetes':
    kubernetes cluster.local in-addr.arpa ip6.arpa {

Save and exit the editor (:wq in vi/vim).

The corrected section should look like:

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
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }


Step 6: Delete CoreDNS Pods to Apply Changes
---------------------------------------------
After fixing the ConfigMap, delete the pods to force recreation:

kubectl delete pods -n kube-system -l k8s-app=kube-dns

Kubernetes will automatically recreate them with the fixed config.

Wait for new pods to start (they should now start successfully):

kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s


Step 7: Verify CoreDNS Pods Are Running
----------------------------------------
Check the status again:

kubectl get pods -n kube-system -l k8s-app=kube-dns

Expected output (FIXED):
NAME                       READY   STATUS    RESTARTS   AGE
coredns-xxxxxx-xxxxx      1/1     Running   0          30s
coredns-xxxxxx-xxxxx      1/1     Running   0          30s

Key indicators:
- READY: 1/1 ✓ (container is ready)
- STATUS: Running ✓ (no crashes)
- RESTARTS: 0 ✓ (no restart loops)


Step 8: Verify DNS Resolution Works
------------------------------------
Test internal DNS:

kubectl exec dns-test -- nslookup kubernetes.default

Expected output: Successful resolution to 10.96.0.1

Test external DNS:

kubectl exec dns-test -- nslookup google.com

Expected output: Successful resolution to Google's IP addresses


Step 9: Check CoreDNS Logs Are Clean
-------------------------------------
kubectl logs -n kube-system -l k8s-app=kube-dns | tail -20

Should see normal startup messages, no errors:
[INFO] plugin/reload: Running configuration ...
[INFO] CoreDNS-1.x.x
[INFO] linux/amd64, go1.x.x
.:53
[INFO] plugin/ready: Still waiting on: "kubernetes"
[INFO] plugin/kubernetes: Starting server on :8181


COMPLETE FIXED COREFILE:
-------------------------
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
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
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }


ALTERNATIVE: Fix with kubectl patch
------------------------------------
You can also use sed to fix the typo and apply:

kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-fix.yaml
sed -i 's/kubernetezz/kubernetes/g' /tmp/coredns-fix.yaml
kubectl apply -f /tmp/coredns-fix.yaml
kubectl delete pods -n kube-system -l k8s-app=kube-dns


ALTERNATIVE: One-liner fix (advanced)
--------------------------------------
kubectl get configmap coredns -n kube-system -o yaml | \
  sed 's/kubernetezz/kubernetes/g' | \
  kubectl apply -f - && \
  kubectl delete pods -n kube-system -l k8s-app=kube-dns


WHY DID THIS HAPPEN?
--------------------
The 'kubernetes' plugin in CoreDNS is essential because:
1. It enables CoreDNS to resolve Kubernetes services
2. It queries the Kubernetes API for service/endpoint discovery
3. It's required for in-cluster DNS (service.namespace.svc.cluster.local)
4. Without it (or with a typo), CoreDNS cannot function

When CoreDNS validates its Corefile on startup, it checks that
all directives are valid. When it encounters 'kubernetezz', it
doesn't recognize it as a valid directive, fails validation, and
exits immediately with exit code 1.

Kubernetes sees the container exit repeatedly, enters
CrashLoopBackOff state, and backs off retries with exponential
backoff (10s, 20s, 40s, 80s, etc.).


EXAM TIP:
---------
In CKA exams, typos in configuration files are VERY common test
scenarios. Always:
1. Check logs FIRST - they tell you the exact error
2. Look for typos in directive names, field names, etc.
3. Use tab completion or copy-paste from documentation
4. Validate syntax before applying changes


KEY TAKEAWAYS:
--------------
1. CrashLoopBackOff = Container is crashing repeatedly
2. ALWAYS check logs first: kubectl logs <pod>
3. Logs tell you the EXACT line number and error
4. Typos in configuration = instant crash
5. Fix ConfigMap → Delete pods → Verify
6. Test both internal AND external DNS after fixing

Common CoreDNS Typos/Errors:
- kubernetezz instead of kubernetes
- forword instead of forward
- prometheous instead of prometheus
- Missing closing braces {}
- Wrong indentation
- Invalid plugin names


COMMON MISTAKES TO AVOID:
--------------------------
- Not checking logs (most important step!)
- Only editing ConfigMap without restarting pods
- Assuming the error is network/DNS servers (it's a typo!)
- Not verifying the exact line number from error message
- Forgetting to test DNS resolution after the fix


VALIDATION:
-----------
Run ./Task-9/validate.sh to verify your solution.

Your solution is correct when:
✓ CoreDNS pods are 1/1 Ready and Running
✓ No CrashLoopBackOff status
✓ Logs show successful startup (no errors)
✓ Internal DNS works (kubernetes.default)
✓ External DNS works (google.com)

════════════════════════════════════════════════════════════════

EOF
