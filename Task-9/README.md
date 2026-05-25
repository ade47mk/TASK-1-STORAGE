# TASK 9: CoreDNS Troubleshooting

**Difficulty:** Hard  
**Points:** 20  
**Time Estimate:** 15-20 minutes

## 🎯 Scenario

DNS lookups are failing in the Kubernetes cluster. Pods cannot resolve external DNS names, and developers are reporting that their applications cannot connect to external services. You need to investigate and repair CoreDNS.

## 📋 Files

```
TASK-9-COREDNS/
├── LabSetUp.bash          # Sets up the broken CoreDNS scenario
├── Question.bash          # Displays the task requirements
├── SolutionNotes.bash     # Step-by-step solution guide
├── original-question.text # Plain text problem statement
└── validate.sh            # Validation script to check your solution
```

## 🚀 Getting Started

### 1. Set Up the Lab Environment

```bash
./LabSetUp.bash
```

This will:
- Verify cluster connectivity
- Create a misconfigured CoreDNS ConfigMap (invalid upstream DNS servers)
- Restart CoreDNS pods to apply the broken config
- Create a test pod for DNS verification

### 2. Read the Question

```bash
cat Question.bash
```

or simply:

```bash
./Question.bash
```

### 3. Work on the Task

**Key Investigation Steps:**

1. Check CoreDNS pod status:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   ```

2. Check CoreDNS logs:
   ```bash
   kubectl logs -n kube-system -l k8s-app=kube-dns
   ```

3. Examine CoreDNS configuration:
   ```bash
   kubectl get configmap coredns -n kube-system -o yaml
   ```

4. Test DNS resolution:
   ```bash
   kubectl exec dns-test -- nslookup kubernetes.default
   kubectl exec dns-test -- nslookup google.com
   ```

### 4. Validate Your Solution

```bash
./validate.sh
```

The validation script will check:
- ✓ CoreDNS pods are running and ready
- ✓ Valid upstream DNS servers configured
- ✓ Internal DNS resolution works (kubernetes.default)
- ✓ External DNS resolution works (google.com)

## 💡 Hints

<details>
<summary>Click to reveal hints</summary>

1. The problem is in the CoreDNS ConfigMap's **forward directive**
2. Look for invalid upstream DNS servers (1.2.3.4, 5.6.7.8)
3. Replace them with valid options:
   - `/etc/resolv.conf` (use node's DNS)
   - `8.8.8.8 8.8.4.4` (Google DNS)
   - `1.1.1.1 1.0.0.1` (Cloudflare DNS)
4. After fixing the ConfigMap, restart CoreDNS pods:
   ```bash
   kubectl delete pods -n kube-system -l k8s-app=kube-dns
   ```

</details>

## 📚 Need the Full Solution?

```bash
cat SolutionNotes.bash
```

or:

```bash
./SolutionNotes.bash
```

## 🎓 Learning Objectives

After completing this task, you will understand:
- How CoreDNS is configured in Kubernetes
- Where DNS configuration is stored (ConfigMap)
- How to troubleshoot DNS issues in a cluster
- How to identify and fix invalid upstream DNS servers
- How to restart CoreDNS pods to apply changes
- How to verify both internal and external DNS resolution

## 📊 Scoring Breakdown

| Check | Points | Description |
|-------|--------|-------------|
| Identified the DNS issue | 4 | Found the invalid upstream DNS servers |
| Fixed CoreDNS ConfigMap | 6 | Updated forward directive with valid DNS |
| Restarted CoreDNS pods | 2 | Applied the configuration changes |
| External DNS resolution | 4 | google.com resolves correctly |
| Internal DNS resolution | 3 | kubernetes.default resolves correctly |
| Clean CoreDNS logs | 1 | No errors in logs |
| **Total** | **20** | Passing score: 16 points |

## 🔧 Quick Fix Command

If you're stuck, here's the fastest way to fix CoreDNS:

```bash
# Edit the ConfigMap
kubectl edit configmap coredns -n kube-system

# Find this line:
#   forward . 1.2.3.4 5.6.7.8
# Replace with:
#   forward . /etc/resolv.conf

# Save and exit, then restart CoreDNS:
kubectl delete pods -n kube-system -l k8s-app=kube-dns

# Wait for pods to restart:
kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s

# Verify:
kubectl exec dns-test -- nslookup google.com
```

## 🐛 Troubleshooting

**DNS still not working after fix?**
1. Check if CoreDNS pods restarted successfully
2. Verify the forward directive syntax is correct
3. Check CoreDNS logs for errors
4. Ensure test pod is running

**Can't find the test pod?**
```bash
kubectl run dns-test --image=busybox:1.28 --restart=Never -- sleep 3600
```

## 📖 Reference

Based on CKA exam question from: [2025 CKA Exam Questions & Solutions UPDATE](https://www.youtube.com/watch?v=eGv6iPWQKyo) @26:57

---

**Good luck! 🚀**
