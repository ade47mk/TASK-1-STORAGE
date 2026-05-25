#!/bin/bash

# Validation script for Task 9: CoreDNS Troubleshooting
# This script checks if CoreDNS has been properly repaired

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 9: CoreDNS Troubleshooting"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=20

# Check 1: CoreDNS pods exist (2 points)
echo "Check 1: Do CoreDNS pods exist?"
COREDNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l)
if [ "$COREDNS_PODS" -gt 0 ]; then
    echo "✓ CoreDNS pods exist ($COREDNS_PODS found) (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ No CoreDNS pods found in kube-system namespace"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: CoreDNS pods are running (3 points)
echo "Check 2: Are CoreDNS pods running?"
RUNNING_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep -c "Running")
if [ "$RUNNING_PODS" -gt 0 ]; then
    echo "✓ CoreDNS pods are running ($RUNNING_PODS/$COREDNS_PODS) (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ CoreDNS pods are not running"
    kubectl get pods -n kube-system -l k8s-app=kube-dns
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 3: CoreDNS pods are ready (2 points)
echo "Check 3: Are CoreDNS pods ready?"
READY_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' 2>/dev/null | grep -c "True")
if [ "$READY_PODS" -eq "$RUNNING_PODS" ]; then
    echo "✓ All CoreDNS pods are ready ($READY_PODS/$RUNNING_PODS) (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Not all CoreDNS pods are ready ($READY_PODS/$RUNNING_PODS)"
    kubectl describe pods -n kube-system -l k8s-app=kube-dns | grep -A 5 "Conditions:"
fi

# Check 4: CoreDNS ConfigMap exists and has forward directive (2 points)
echo "Check 4: Is CoreDNS ConfigMap properly configured?"
CONFIGMAP_EXISTS=$(kubectl get configmap coredns -n kube-system &> /dev/null && echo "yes" || echo "no")
if [ "$CONFIGMAP_EXISTS" == "yes" ]; then
    echo "✓ CoreDNS ConfigMap exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    
    # Extract the forward directive
    FORWARD_LINE=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' 2>/dev/null | grep -E "^\s*forward")
    echo "  Current forward directive: $FORWARD_LINE"
else
    echo "✗ CoreDNS ConfigMap not found"
fi

# Check 5: Forward directive uses valid DNS servers (3 points)
echo "Check 5: Are valid upstream DNS servers configured?"
FORWARD_CONFIG=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' 2>/dev/null | grep -E "^\s*forward")

# Check if forward directive contains valid DNS servers
VALID_DNS=false
if echo "$FORWARD_CONFIG" | grep -qE "(8\.8\.8\.8|8\.8\.4\.4)"; then
    echo "✓ Using Google DNS (8.8.8.8/8.8.4.4) (3 points)"
    VALID_DNS=true
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
elif echo "$FORWARD_CONFIG" | grep -qE "(1\.1\.1\.1|1\.0\.0\.1)"; then
    echo "✓ Using Cloudflare DNS (1.1.1.1/1.0.0.1) (3 points)"
    VALID_DNS=true
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
elif echo "$FORWARD_CONFIG" | grep -qE "/etc/resolv\.conf"; then
    echo "✓ Using /etc/resolv.conf (node's DNS) (3 points)"
    VALID_DNS=true
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
elif echo "$FORWARD_CONFIG" | grep -qE "(1\.2\.3\.4|5\.6\.7\.8)"; then
    echo "✗ Still using invalid DNS servers (1.2.3.4 or 5.6.7.8)"
    echo "  These are non-existent servers - replace them with valid ones!"
else
    echo "⚠ Using custom DNS servers: $FORWARD_CONFIG"
    echo "  Verify these servers are reachable"
fi

# Check 6: Test pod exists (1 point)
echo "Check 6: Does test pod exist?"
if kubectl get pod dns-test -n default &> /dev/null; then
    echo "✓ Test pod 'dns-test' exists (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
    TEST_POD_EXISTS=true
else
    echo "⚠ Test pod 'dns-test' not found (creating one for testing...)"
    kubectl run dns-test --image=busybox:1.28 --restart=Never -- sleep 3600 &> /dev/null
    sleep 5
    TEST_POD_EXISTS=true
fi

# Wait for test pod to be ready
if [ "$TEST_POD_EXISTS" == "true" ]; then
    kubectl wait --for=condition=ready pod/dns-test -n default --timeout=30s &> /dev/null
fi

# Check 7: Internal DNS resolution works (3 points)
echo "Check 7: Does internal DNS resolution work?"
if [ "$TEST_POD_EXISTS" == "true" ] && kubectl get pod dns-test -n default -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Running"; then
    INTERNAL_DNS=$(kubectl exec dns-test -n default -- nslookup kubernetes.default 2>&1)
    if echo "$INTERNAL_DNS" | grep -q "Address.*10\.96\.0\.1"; then
        echo "✓ Internal DNS resolution works (kubernetes.default resolves) (3 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 3))
    else
        echo "✗ Internal DNS resolution failed"
        echo "  Output: $INTERNAL_DNS"
    fi
else
    echo "⚠ Skipping internal DNS test (test pod not ready)"
fi

# Check 8: External DNS resolution works (4 points)
echo "Check 8: Does external DNS resolution work?"
if [ "$TEST_POD_EXISTS" == "true" ] && kubectl get pod dns-test -n default -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Running"; then
    EXTERNAL_DNS=$(kubectl exec dns-test -n default -- nslookup google.com 2>&1)
    if echo "$EXTERNAL_DNS" | grep -qE "Address.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"; then
        echo "✓ External DNS resolution works (google.com resolves) (4 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 4))
    else
        echo "✗ External DNS resolution failed"
        echo "  Output: $EXTERNAL_DNS"
        echo "  Verify CoreDNS forward directive and restart CoreDNS pods"
    fi
else
    echo "⚠ Skipping external DNS test (test pod not ready)"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent troubleshooting!"
    echo ""
    echo "✓ CoreDNS pods are running and healthy"
    echo "✓ Valid upstream DNS servers configured"
    echo "✓ Internal cluster DNS working"
    echo "✓ External DNS resolution working"
    echo ""
    echo "You've successfully repaired CoreDNS! 🚀"
    echo ""
elif [ $TOTAL_POINTS -ge 16 ]; then
    echo "✅ PASSED! Good troubleshooting work."
    echo ""
    echo "Review the output above for any remaining issues."
    echo ""
elif [ $TOTAL_POINTS -ge 10 ]; then
    echo "⚠️ PARTIAL PASS - CoreDNS still needs work"
    echo ""
    echo "Common fixes:"
    echo "  1. Edit CoreDNS ConfigMap:"
    echo "     kubectl edit configmap coredns -n kube-system"
    echo "  2. Replace invalid DNS servers in 'forward' directive with:"
    echo "     - /etc/resolv.conf  (use node's DNS)"
    echo "     - 8.8.8.8 8.8.4.4   (Google DNS)"
    echo "     - 1.1.1.1 1.0.0.1   (Cloudflare DNS)"
    echo "  3. Restart CoreDNS pods:"
    echo "     kubectl delete pods -n kube-system -l k8s-app=kube-dns"
    echo ""
else
    echo "❌ NEEDS WORK"
    echo ""
    echo "CoreDNS is not functioning properly. Check:"
    echo "  - Are CoreDNS pods running?"
    echo "  - Is the ConfigMap properly configured?"
    echo "  - Are you using valid upstream DNS servers?"
    echo ""
    echo "Review Task-9/SolutionNotes.bash for detailed guidance."
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""

# Show resource details
echo "Resource Summary:"
echo ""
echo "CoreDNS Pods:"
kubectl get pods -n kube-system -l k8s-app=kube-dns 2>/dev/null || echo "  Not found"
echo ""
echo "CoreDNS Forward Configuration:"
kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' 2>/dev/null | grep -E "^\s*forward" || echo "  Not found"
echo ""
echo ""
echo "Test Pod:"
kubectl get pod dns-test -n default 2>/dev/null || echo "  Not found"
echo ""

# Show recent CoreDNS logs if there are errors
echo "Recent CoreDNS Logs (last 5 lines):"
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=5 2>/dev/null || echo "  Unable to retrieve logs"
echo ""

exit 0
