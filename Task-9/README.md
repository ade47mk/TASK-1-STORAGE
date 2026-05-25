# TASK 9: CoreDNS Troubleshooting

**Difficulty:** Hard  
**Points:** 20  
**Time Estimate:** 15-20 minutes

## 🎯 Scenario

The cluster's DNS service (CoreDNS) has completely failed with pods in **CrashLoopBackOff** state. CoreDNS containers are failing to start due to a **Corefile syntax error** - specifically a typo where `kubernetezz` is used instead of `kubernetes`. You need to identify the error from logs and fix the configuration.

**Error:** `/etc/coredns/Corefile:7 - Error during parsing: Unknown directive 'kubernetezz'`

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
- Backup the original CoreDNS ConfigMap
- Create a broken CoreDNS ConfigMap with a **typo: 'kubernetezz'** instead of 'kubernetes'
- Restart CoreDNS pods (they will enter **CrashLoopBackOff** state)
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

1. Check CoreDNS pod status (will show CrashLoopBackOff):
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   ```

2. **Check logs for the exact error (MOST IMPORTANT!):**
   ```bash
   kubectl logs -n kube-system -l k8s-app=kube-dns
   ```
   
   You'll see: `/etc/coredns/Corefile:7 - Error during parsing: Unknown directive 'kubernetezz'`

3. Examine CoreDNS configuration (look for the typo):
   ```bash
   kubectl get configmap coredns -n kube-system -o yaml
   ```
   
   Line 7 will have: `kubernetezz cluster.local ...` (should be `kubernetes`)

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

1. **CrashLoopBackOff means the container keeps crashing** - check logs first!
2. The error message shows **line 7** has the problem
3. Look for **"Unknown directive 'kubernetezz'"** in the logs
4. It's a **TYPO**: 'kubernetezz' should be 'kubernetes'
5. Fix the typo in the ConfigMap:
   ```bash
   kubectl edit configmap coredns -n kube-system
   # Change 'kubernetezz' to 'kubernetes'
   ```
6. After fixing, **restart the pods**:
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
# 1. Check logs to confirm the error
kubectl logs -n kube-system -l k8s-app=kube-dns

# 2. Edit the ConfigMap
kubectl edit configmap coredns -n kube-system

# Find line 7:
#   kubernetezz cluster.local in-addr.arpa ip6.arpa {
# Change to:
#   kubernetes cluster.local in-addr.arpa ip6.arpa {

# Save and exit (:wq)

# 3. Restart CoreDNS pods
kubectl delete pods -n kube-system -l k8s-app=kube-dns

# 4. Wait for pods to be ready
kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s

# 5. Verify DNS works
kubectl exec dns-test -- nslookup kubernetes.default
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
