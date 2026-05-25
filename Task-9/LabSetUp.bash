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
echo "Creating a broken CoreDNS scenario..."
echo ""

# Backup original CoreDNS ConfigMap
echo "Backing up original CoreDNS ConfigMap..."
kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-original.yaml 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ Original CoreDNS config backed up to /tmp/coredns-original.yaml"
else
    echo "⚠ Could not backup CoreDNS ConfigMap (might not exist yet)"
fi

# Create a misconfigured CoreDNS ConfigMap
echo ""
echo "Introducing DNS lookup failures..."
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
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
          ttl 30
        }
        prometheus :9153
        forward . 1.2.3.4 5.6.7.8
        cache 30
        loop
        reload
        loadbalance
    }
EOF

if [ $? -eq 0 ]; then
    echo "✓ Misconfigured CoreDNS ConfigMap applied"
else
    echo "✗ Failed to apply misconfigured ConfigMap"
fi

# Restart CoreDNS pods to apply changes
echo ""
echo "Restarting CoreDNS pods..."
kubectl delete pods -n kube-system -l k8s-app=kube-dns --force --grace-period=0 > /dev/null 2>&1
sleep 5

# Wait for CoreDNS pods to restart
echo "Waiting for CoreDNS pods to restart..."
sleep 10

# Create a test pod for DNS testing
echo ""
echo "Creating test pod for DNS verification..."
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
echo "✓ CoreDNS has been misconfigured (DNS lookups will fail)"
echo "✓ Test pod 'dns-test' created for verification"
echo ""
echo "DNS Issue Simulated:"
echo "  - CoreDNS is configured with invalid upstream DNS servers"
echo "  - External DNS resolution will fail"
echo "  - Internal cluster DNS may work for some services"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Task-9/Question.bash"
echo "  2. Investigate and fix CoreDNS"
echo "  3. Validate your solution: ./Task-9/validate.sh"
echo ""
echo "Good luck! 🚀"
echo ""
