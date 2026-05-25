#!/bin/bash

# Solution Notes for Task 9: CoreDNS Troubleshooting
# This file contains the step-by-step solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION: CoreDNS Troubleshooting
════════════════════════════════════════════════════════════════

PROBLEM ANALYSIS:
-----------------
The CoreDNS service is misconfigured with invalid upstream DNS servers
(1.2.3.4 and 5.6.7.8), causing external DNS lookups to fail.

ROOT CAUSE:
-----------
The CoreDNS ConfigMap contains a 'forward' directive pointing to
non-existent or unreachable upstream DNS servers.

STEP-BY-STEP SOLUTION:
-----------------------

Step 1: Verify the Issue
-------------------------
Check if DNS lookups are failing:

kubectl exec dns-test -- nslookup kubernetes.default
kubectl exec dns-test -- nslookup google.com

Expected result: Internal DNS works, external DNS fails.


Step 2: Check CoreDNS Pods
---------------------------
Verify CoreDNS pods are running:

kubectl get pods -n kube-system -l k8s-app=kube-dns

Expected: Pods are running but DNS still fails.


Step 3: Examine CoreDNS Configuration
--------------------------------------
Check the CoreDNS ConfigMap:

kubectl get configmap coredns -n kube-system -o yaml

Look at the 'forward' directive. You'll see:

forward . 1.2.3.4 5.6.7.8

These are invalid/unreachable DNS servers!


Step 4: Check CoreDNS Logs (Optional)
--------------------------------------
kubectl logs -n kube-system -l k8s-app=kube-dns | grep -i error

You may see timeout errors or connection failures.


Step 5: Fix the CoreDNS ConfigMap
----------------------------------
Edit the ConfigMap:

kubectl edit configmap coredns -n kube-system

Find the line:
  forward . 1.2.3.4 5.6.7.8

Replace it with valid DNS servers. Options:
  A) Use /etc/resolv.conf (let the node resolve):
     forward . /etc/resolv.conf

  B) Use Google DNS:
     forward . 8.8.8.8 8.8.4.4

  C) Use Cloudflare DNS:
     forward . 1.1.1.1 1.0.0.1

Save and exit the editor.


Step 6: Restart CoreDNS Pods
-----------------------------
After changing the ConfigMap, restart CoreDNS pods to apply changes:

kubectl delete pods -n kube-system -l k8s-app=kube-dns

Wait for new pods to start:

kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s


Step 7: Verify DNS Resolution
------------------------------
Test internal DNS:

kubectl exec dns-test -- nslookup kubernetes.default

Expected output: Successful resolution to 10.96.0.1

Test external DNS:

kubectl exec dns-test -- nslookup google.com

Expected output: Successful resolution to Google's IP addresses


Step 8: Check CoreDNS Logs Again
---------------------------------
kubectl logs -n kube-system -l k8s-app=kube-dns | tail -20

Should see no errors related to upstream servers.


COMPLETE FIXED COREFILE EXAMPLE:
---------------------------------
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


ALTERNATIVE: Using kubectl patch
---------------------------------
You can also fix it with a single command:

kubectl patch configmap coredns -n kube-system --type merge -p '
{
  "data": {
    "Corefile": ".:53 {\n    errors\n    health {\n      lameduck 5s\n    }\n    ready\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n      pods insecure\n      fallthrough in-addr.arpa ip6.arpa\n      ttl 30\n    }\n    prometheus :9153\n    forward . /etc/resolv.conf\n    cache 30\n    loop\n    reload\n    loadbalance\n}\n"
  }
}'

Then restart pods:
kubectl delete pods -n kube-system -l k8s-app=kube-dns


KEY TAKEAWAYS:
--------------
1. CoreDNS configuration is stored in a ConfigMap
2. The 'forward' directive controls upstream DNS resolution
3. Always verify both internal and external DNS after changes
4. CoreDNS pods must be restarted after ConfigMap changes
5. Common upstream DNS options:
   - /etc/resolv.conf (uses node's DNS)
   - 8.8.8.8 8.8.4.4 (Google DNS)
   - 1.1.1.1 1.0.0.1 (Cloudflare DNS)


COMMON MISTAKES TO AVOID:
--------------------------
- Forgetting to restart CoreDNS pods after ConfigMap changes
- Using invalid DNS server addresses
- Incorrect Corefile syntax
- Not testing both internal AND external DNS resolution


VALIDATION:
-----------
Run ./Task-9/validate.sh to verify your solution.

════════════════════════════════════════════════════════════════

EOF
