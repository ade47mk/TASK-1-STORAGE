#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 9: CoreDNS Troubleshooting"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verify kubectl is working
echo "Verifying cluster connectivity..."
if kubectl get nodes &> /dev/null; then
    echo "✓ kubectl is working"
    kubectl get nodes
else
    echo "✗ kubectl is not working properly"
    exit 1
fi

echo ""
echo "Creating a broken CoreDNS scenario (CrashLoopBackOff)..."
echo ""

# Backup original CoreDNS ConfigMap
echo "Backing up original CoreDNS ConfigMap..."
kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-original-backup.yaml 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ Original CoreDNS config backed up to /tmp/coredns-original-backup.yaml"
else
    echo "⚠ Could not backup CoreDNS ConfigMap (might not exist yet)"
fi

# Create a CoreDNS ConfigMap with typo: "kubernetezz" instead of "kubernetes"
# This will cause: "Unknown directive 'kubernetezz'" error and CrashLoopBackOff
echo ""
echo "Introducing Corefile syntax error (typo: 'kubernetezz')..."
cat << 'EOF' | kubectl apply -f - > /dev/null 2>&1
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
        kubernetezz cluster.local in-addr.arpa ip6.arpa {
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
EOF

if [ $? -eq 0 ]; then
    echo "✓ Broken CoreDNS ConfigMap applied (typo: 'kubernetezz' instead of 'kubernetes')"
else
    echo "✗ Failed to apply broken ConfigMap"
fi

# Force restart CoreDNS pods to apply the broken config
echo ""
echo "Restarting CoreDNS pods to trigger CrashLoopBackOff..."
kubectl delete pods -n kube-system -l k8s-app=kube-dns --force --grace-period=0 > /dev/null 2>&1

# Wait a bit for pods to start crashing
echo "Waiting for CoreDNS pods to enter CrashLoopBackOff state..."
sleep 10

# Show the current status
echo ""
echo "Current CoreDNS pod status:"
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check if pods are crashing
echo ""
echo "Checking for crash status..."
sleep 5
CRASH_STATUS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[*].status.containerStatuses[*].state}' 2>/dev/null)
if echo "$CRASH_STATUS" | grep -q "CrashLoopBackOff\|waiting\|Error"; then
    echo "✓ CoreDNS pods are now crashing (CrashLoopBackOff or Error state)"
else
    echo "⚠ Pods may still be starting or not crashing yet (check again in a moment)"
fi

# Show a sample log error
echo ""
echo "Sample CoreDNS error log:"
sleep 2
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=5 2>/dev/null | head -10 || echo "  (Logs will show: Unknown directive 'kubernetezz')"

# Create a test pod for DNS testing (once CoreDNS is fixed)
echo ""
echo "Creating test pod for DNS verification..."
kubectl delete pod dns-test -n default --force --grace-period=0 > /dev/null 2>&1
sleep 2

cat << 'EOF' | kubectl apply -f - > /dev/null 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
  namespace: default
spec:
  containers:
  - name: dns-test
    image: busybox:1.28
    command:
    - sleep
    - "3600"
EOF

if [ $? -eq 0 ]; then
    echo "✓ Test pod 'dns-test' created in default namespace"
else
    echo "⚠ Could not create test pod"
fi

# Wait for test pod to be ready
echo "Waiting for test pod to be ready..."
kubectl wait --for=condition=ready pod/dns-test -n default --timeout=60s > /dev/null 2>&1

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ CoreDNS has been broken with a Corefile typo"
echo "✓ CoreDNS pods should be in CrashLoopBackOff state"
echo "✓ Test pod 'dns-test' created for verification"
echo ""
echo "Problem Simulated:"
echo "  - CoreDNS Corefile has a typo: 'kubernetezz' instead of 'kubernetes'"
echo "  - Error: Unknown directive 'kubernetezz' in Corefile:7"
echo "  - CoreDNS pods will crash on startup"
echo "  - Status: CrashLoopBackOff (0/1 Ready)"
echo "  - All DNS resolution in the cluster will fail"
echo ""
echo "Check current status:"
echo "  kubectl get pods -n kube-system -l k8s-app=kube-dns"
echo "  kubectl logs -n kube-system -l k8s-app=kube-dns"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Task-9/Question.bash"
echo "  2. Investigate and fix CoreDNS"
echo "  3. Validate your solution: ./Task-9/validate.sh"
echo ""
echo "Good luck! 🚀"
echo ""
