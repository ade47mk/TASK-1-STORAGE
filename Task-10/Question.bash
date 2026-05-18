#!/bin/bash

# Task 10: CoreDNS Configuration
# Difficulty: Medium
# Points: 20
# Time: 12-15 minutes

cat << 'EOF'

════════════════════════════════════════════════════════════════
  TASK 10: CoreDNS Configuration - Custom DNS Entries
════════════════════════════════════════════════════════════════

Difficulty: Medium
Points: 20
Time Estimate: 12-15 minutes

SCENARIO:
---------
Your cluster workloads need to resolve a custom internal domain.
Applications are configured to access `myapp.internal` but this
domain needs to resolve to a specific IP address within your
infrastructure.

OBJECTIVE:
----------
Configure CoreDNS to provide a custom DNS entry so that queries
for `myapp.internal` return the IP address `10.10.10.10`.

REQUIREMENTS:
-------------

Custom DNS Entry:
  - Domain: myapp.internal
  - IP Address: 10.10.10.10
  - Must work for all pods in the cluster

Configuration:
  - Edit CoreDNS ConfigMap in kube-system namespace
  - Add custom DNS entry using hosts plugin
  - Reload CoreDNS to apply changes

Verification:
  - Pods can resolve myapp.internal to 10.10.10.10
  - Normal DNS functionality remains intact
  - External DNS still works

TASKS:
------
1. View current CoreDNS configuration:
   kubectl get configmap coredns -n kube-system -o yaml

2. Edit CoreDNS ConfigMap to add custom entry:
   kubectl edit configmap coredns -n kube-system

3. Add hosts plugin with custom entry

4. Reload CoreDNS to apply changes:
   kubectl rollout restart deployment coredns -n kube-system

5. Test resolution:
   kubectl run test --image=busybox --restart=Never \
     -- nslookup myapp.internal

6. Verify result shows 10.10.10.10

VERIFICATION:
-------------
Your solution should meet these criteria:
- CoreDNS ConfigMap contains hosts plugin
- hosts plugin includes myapp.internal → 10.10.10.10
- nslookup myapp.internal returns 10.10.10.10
- Normal DNS functionality works
- External DNS still resolves

HINTS:
------
- CoreDNS config is in ConfigMap "coredns" in kube-system

- Add hosts plugin to Corefile:
  ```
  .:53 {
      errors
      health
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
      # ... rest of config
  }
  ```

- Edit ConfigMap:
  kubectl edit configmap coredns -n kube-system

- Reload CoreDNS:
  kubectl rollout restart deployment coredns -n kube-system

- Test:
  kubectl run test --image=busybox --restart=Never -- nslookup myapp.internal
  kubectl logs test

- Clean up test pod:
  kubectl delete pod test

DELIVERABLES:
-------------
- CoreDNS ConfigMap updated with hosts plugin
- myapp.internal resolves to 10.10.10.10
- CoreDNS reloaded and working

SCORING:
--------
- CoreDNS ConfigMap contains hosts plugin: 5 points
- hosts plugin has correct entry (10.10.10.10 myapp.internal): 5 points
- myapp.internal resolves to 10.10.10.10: 6 points
- Normal DNS still works: 4 points

Total: 20 points
Passing: 14 points

════════════════════════════════════════════════════════════════

COMMON PITFALLS:
----------------
1. Wrong syntax in hosts plugin
2. Forgetting fallthrough directive
3. Not reloading CoreDNS after changes
4. Wrong order in Corefile
5. Breaking existing DNS functionality

IMPORTANT NOTES:
----------------
• CoreDNS ConfigMap: coredns in kube-system namespace
• Corefile format: YAML data field
• hosts plugin: Define custom DNS entries
• fallthrough: Continue to next plugin if no match
• Reload required: Changes don't apply automatically
• Syntax matters: Incorrect syntax breaks CoreDNS

COREDNS PLUGINS:
----------------
Common plugins in order:
1. errors - Error logging
2. health - Health check endpoint
3. ready - Readiness endpoint
4. hosts - Custom DNS entries (add this!)
5. kubernetes - K8s service DNS
6. forward - External DNS forwarding
7. cache - Response caching

HOSTS PLUGIN SYNTAX:
--------------------
```
hosts {
    <IP> <hostname>
    fallthrough
}
```

Example:
```
hosts {
    10.10.10.10 myapp.internal
    10.10.10.11 api.internal
    fallthrough
}
```

VALIDATION:
Run ./validate.sh when complete to check your work.

Need help? Check SolutionNotes.bash for detailed guidance.

Good luck! 🚀

EOF
