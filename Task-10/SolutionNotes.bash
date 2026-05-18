#!/bin/bash

# Solution Notes for Task 10: CoreDNS Configuration
# Read this if you need help or want to understand the solution

cat << 'EOF'

════════════════════════════════════════════════════════════════
  SOLUTION NOTES: CoreDNS Configuration - Custom DNS
════════════════════════════════════════════════════════════════

UNDERSTANDING THE TASK
-----------------------
This task tests your knowledge of:
1. CoreDNS ConfigMap management
2. Corefile syntax and plugin configuration
3. hosts plugin for custom DNS entries
4. CoreDNS reload procedures
5. DNS testing and validation

KEY CONCEPTS
------------
• CoreDNS ConfigMap: Stores Corefile configuration
• Corefile: CoreDNS configuration file
• hosts plugin: Define static DNS entries
• fallthrough: Pass to next plugin if no match
• Reload: Apply configuration changes

APPROACH
--------

STEP 1: View Current CoreDNS Configuration
-------------------------------------------

Get the current ConfigMap:

```bash
kubectl get configmap coredns -n kube-system -o yaml
```

Look for the `Corefile:` section in data:

```yaml
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
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
```

This is what we need to modify.

STEP 2: Edit CoreDNS ConfigMap
-------------------------------

Open ConfigMap for editing:

```bash
kubectl edit configmap coredns -n kube-system
```

This opens your default editor (usually vi or nano).

STEP 3: Add hosts Plugin
-------------------------

Add the hosts plugin AFTER the `ready` plugin and BEFORE the `kubernetes` plugin.

**Modified Corefile:**

```yaml
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        hosts {
            10.10.10.10 myapp.internal
            fallthrough
        }
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

Key points:

1. **hosts { }** - Plugin block
2. **10.10.10.10 myapp.internal** - IP then hostname
3. **fallthrough** - Continue to next plugin if no match
4. **Indentation** - Must be consistent (spaces, usually 4 or 2)

Save and exit:
- vi: Press `Esc`, then `:wq`, then `Enter`
- nano: `Ctrl+X`, then `Y`, then `Enter`

STEP 4: Reload CoreDNS
-----------------------

Changes don't apply automatically. Reload CoreDNS:

```bash
kubectl rollout restart deployment coredns -n kube-system
```

Wait for pods to be ready:

```bash
kubectl get pods -n kube-system -l k8s-app=coredns --watch
```

Expected output:
```
NAME                       READY   STATUS        RESTARTS   AGE
coredns-abc123-old         1/1     Terminating   0          10m
coredns-def456-new         0/1     Running       0          5s
coredns-def456-new         1/1     Running       0          10s
```

Or check rollout status:
```bash
kubectl rollout status deployment coredns -n kube-system
```

STEP 5: Test Custom DNS Entry
------------------------------

Test myapp.internal resolution:

```bash
kubectl run test-custom --image=busybox --restart=Never \
  -- nslookup myapp.internal
```

Wait a moment, then check logs:

```bash
kubectl logs test-custom
```

Expected output:
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      myapp.internal
Address 1: 10.10.10.10
```

Perfect! The domain resolves to 10.10.10.10.

Clean up:
```bash
kubectl delete pod test-custom
```

STEP 6: Verify Normal DNS Still Works
--------------------------------------

Test internal cluster DNS:

```bash
kubectl run test-internal --image=busybox --restart=Never \
  -- nslookup kubernetes.default
```

Check logs:
```bash
kubectl logs test-internal
```

Should show kubernetes service IP.

Test external DNS:

```bash
kubectl run test-external --image=busybox --restart=Never \
  -- nslookup google.com
```

Check logs:
```bash
kubectl logs test-external
```

Should resolve google.com.

Clean up:
```bash
kubectl delete pod test-internal test-external
```

UNDERSTANDING HOSTS PLUGIN
---------------------------

The hosts plugin provides static DNS entries.

**Basic syntax:**
```
hosts {
    <IP> <hostname>
    fallthrough
}
```

**Multiple entries:**
```
hosts {
    10.10.10.10 myapp.internal
    10.10.10.11 api.internal app.internal
    10.10.10.12 db.internal
    fallthrough
}
```

**With hosts file:**
```
hosts /etc/coredns/custom.hosts {
    fallthrough
}
```

**Key directives:**

1. **fallthrough**
   - Required!
   - If hostname not found, continue to next plugin
   - Without this, queries for other domains fail

2. **Multiple hostnames per IP**
   - `10.10.10.11 api.internal app.internal`
   - Both names resolve to same IP

3. **Order matters**
   - Place hosts plugin early in chain
   - After ready, before kubernetes

ALTERNATIVE: Using hosts File
------------------------------

You can also use an external hosts file:

1. Create ConfigMap with hosts file:
```bash
kubectl create configmap custom-hosts -n kube-system \
  --from-literal=custom.hosts=$'10.10.10.10 myapp.internal\n10.10.10.11 api.internal'
```

2. Mount ConfigMap in CoreDNS:
```yaml
# Add volume
volumes:
- name: custom-hosts
  configMap:
    name: custom-hosts

# Add volumeMount
volumeMounts:
- name: custom-hosts
  mountPath: /etc/coredns/custom.hosts
  subPath: custom.hosts
```

3. Update Corefile:
```
hosts /etc/coredns/custom.hosts {
    fallthrough
}
```

For this task, inline entries are simpler.

COMMON MISTAKES
---------------

❌ Wrong: Forgetting fallthrough
```
hosts {
    10.10.10.10 myapp.internal
    # Missing fallthrough!
}
```
Result: Other DNS queries fail!

✓ Correct: Include fallthrough
```
hosts {
    10.10.10.10 myapp.internal
    fallthrough
}
```

❌ Wrong: Wrong order (hostname then IP)
```
hosts {
    myapp.internal 10.10.10.10  # Wrong order!
    fallthrough
}
```

✓ Correct: IP then hostname
```
hosts {
    10.10.10.10 myapp.internal
    fallthrough
}
```

❌ Wrong: Wrong indentation
```
hosts {
10.10.10.10 myapp.internal  # No indentation
fallthrough                  # No indentation
}
```

✓ Correct: Consistent indentation
```
hosts {
    10.10.10.10 myapp.internal
    fallthrough
}
```

❌ Wrong: Not reloading CoreDNS
```bash
# Edit ConfigMap
kubectl edit configmap coredns -n kube-system
# Forgot to reload - changes not applied!
```

✓ Correct: Reload after editing
```bash
kubectl edit configmap coredns -n kube-system
kubectl rollout restart deployment coredns -n kube-system
```

TROUBLESHOOTING
---------------

Problem: Changes not taking effect
→ Did you reload CoreDNS?
→ kubectl rollout restart deployment coredns -n kube-system
→ Wait for pods to be ready

Problem: CoreDNS pods CrashLoopBackOff
→ Syntax error in Corefile
→ Check logs: kubectl logs -n kube-system -l k8s-app=coredns
→ Fix ConfigMap and reload

Problem: All DNS queries failing
→ Missing fallthrough in hosts plugin
→ Add fallthrough directive
→ Reload CoreDNS

Problem: Custom domain not resolving
→ Check syntax: IP then hostname
→ Check for typos
→ Verify CoreDNS reloaded
→ Test with nslookup

KUBECTL CHEAT SHEET
-------------------
# View ConfigMap
kubectl get configmap coredns -n kube-system -o yaml

# Edit ConfigMap
kubectl edit configmap coredns -n kube-system

# Backup ConfigMap
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# Restore ConfigMap
kubectl apply -f coredns-backup.yaml

# Reload CoreDNS
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=coredns
kubectl logs -n kube-system -l k8s-app=coredns

# Test DNS
kubectl run test --image=busybox --restart=Never -- nslookup myapp.internal
kubectl logs test
kubectl delete pod test

# Interactive test
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Then: nslookup myapp.internal

COMPLETE SOLUTION EXAMPLE
--------------------------

Here's the complete modified Corefile:

```yaml
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
        hosts {
            10.10.10.10 myapp.internal
            fallthrough
        }
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

Apply and reload:
```bash
kubectl apply -f coredns-configmap.yaml
kubectl rollout restart deployment coredns -n kube-system
```

EXAM TIPS
---------
1. Backup ConfigMap before editing
2. Add hosts plugin after ready, before kubernetes
3. Syntax: IP then hostname
4. Always include fallthrough
5. Reload CoreDNS after changes
6. Test both custom and normal DNS
7. Check CoreDNS logs if issues arise
8. Use kubectl edit for quick changes

TIME MANAGEMENT
---------------
For this task (12-15 minutes):
• 2 min: View current ConfigMap
• 3 min: Edit ConfigMap to add hosts plugin
• 2 min: Save and reload CoreDNS
• 3 min: Test custom domain resolution
• 2 min: Verify normal DNS works
• 3 min: Debug if needed

QUICK REFERENCE
---------------
Commands:
```bash
# Edit CoreDNS config
kubectl edit configmap coredns -n kube-system

# Add this to Corefile (after ready plugin):
# hosts {
#     10.10.10.10 myapp.internal
#     fallthrough
# }

# Reload CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# Test
kubectl run test --image=busybox --restart=Never -- nslookup myapp.internal
kubectl logs test
```

Good luck! 🚀

EOF
