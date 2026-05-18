#!/bin/bash

# Validation script for Task 10: CoreDNS Configuration
# This script checks if CoreDNS has been configured with custom DNS entry

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 10: CoreDNS Configuration"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=20

# Check 1: CoreDNS ConfigMap contains hosts plugin (5 points)
echo "Check 1: Does CoreDNS ConfigMap contain hosts plugin?"
COREFILE=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')

if echo "$COREFILE" | grep -q "hosts"; then
    echo "✓ CoreDNS ConfigMap contains hosts plugin (5 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 5))
else
    echo "✗ hosts plugin not found in CoreDNS ConfigMap"
    echo ""
    echo "Add hosts plugin to Corefile in coredns ConfigMap"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: hosts plugin has correct entry (5 points)
echo "Check 2: Does hosts plugin have the correct entry?"

# Check for the custom entry
if echo "$COREFILE" | grep -q "10.10.10.10.*myapp.internal"; then
    echo "✓ hosts plugin has correct entry: 10.10.10.10 myapp.internal (5 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 5))
else
    echo "✗ hosts plugin missing correct entry"
    echo "  Expected: 10.10.10.10 myapp.internal"
fi

# Check if fallthrough is present
if echo "$COREFILE" | grep -A 5 "hosts" | grep -q "fallthrough"; then
    echo "  ✓ fallthrough directive present"
else
    echo "  ⚠ fallthrough directive missing (may break other DNS)"
fi

# Check 3: myapp.internal resolves to 10.10.10.10 (6 points)
echo ""
echo "Check 3: Does myapp.internal resolve to 10.10.10.10?"
echo "  Testing DNS resolution..."

# Clean up any existing test pod
kubectl delete pod dns-test-custom --force --grace-period=0 &>/dev/null 2>&1

# Create test pod
kubectl run dns-test-custom --image=busybox --restart=Never \
  -- nslookup myapp.internal &>/dev/null

# Wait for pod to complete
sleep 5

# Check logs
DNS_OUTPUT=$(kubectl logs dns-test-custom 2>/dev/null)

if echo "$DNS_OUTPUT" | grep -q "10.10.10.10"; then
    echo "✓ myapp.internal resolves to 10.10.10.10 (6 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 6))
    echo "  DNS resolution successful!"
else
    echo "✗ myapp.internal does not resolve correctly"
    echo "  Expected: 10.10.10.10"
    echo "  Test output:"
    echo "$DNS_OUTPUT" | grep -A 3 "Name:" | head -5
fi

# Clean up
kubectl delete pod dns-test-custom --force --grace-period=0 &>/dev/null 2>&1

# Check 4: Normal DNS still works (4 points)
echo "Check 4: Does normal DNS still work?"
echo "  Testing internal DNS (kubernetes.default)..."

# Clean up any existing test pod
kubectl delete pod dns-test-normal --force --grace-period=0 &>/dev/null 2>&1

# Create test pod for normal DNS
kubectl run dns-test-normal --image=busybox --restart=Never \
  -- nslookup kubernetes.default &>/dev/null

# Wait for pod to complete
sleep 5

# Check logs
NORMAL_DNS_OUTPUT=$(kubectl logs dns-test-normal 2>/dev/null)

if echo "$NORMAL_DNS_OUTPUT" | grep -qi "Address.*kubernetes"; then
    echo "✓ Normal DNS still works (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    echo "  Internal DNS resolution successful!"
else
    echo "✗ Normal DNS broken"
    echo "  Check if fallthrough is present in hosts plugin"
    echo "  Test output:"
    echo "$NORMAL_DNS_OUTPUT" | head -5
fi

# Clean up
kubectl delete pod dns-test-normal --force --grace-period=0 &>/dev/null 2>&1

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent configuration!"
    echo ""
    echo "✓ hosts plugin configured"
    echo "✓ Custom DNS entry correct"
    echo "✓ myapp.internal resolves to 10.10.10.10"
    echo "✓ Normal DNS still functional"
    echo ""
elif [ $TOTAL_POINTS -ge 14 ]; then
    echo "✅ PASSED! CoreDNS configured correctly!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 10 ]; then
    echo "⚠️ PARTIAL - Configuration incomplete"
    echo ""
    echo "Review the failed checks above."
    echo "Check SolutionNotes.bash for hints."
    echo ""
else
    echo "❌ NEEDS WORK"
    echo ""
    echo "Review the failed checks above."
    echo "Read the Question.bash again carefully."
    echo "Check SolutionNotes.bash for guidance."
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""

# Show CoreDNS status
echo "CoreDNS Status:"
echo ""
echo "ConfigMap:"
kubectl get configmap coredns -n kube-system 2>/dev/null || echo "  Not found"
echo ""
echo "Deployment:"
kubectl get deployment coredns -n kube-system 2>/dev/null || echo "  Not found"
echo ""
echo "Pods:"
kubectl get pods -n kube-system -l k8s-app=coredns 2>/dev/null || echo "  No pods"
echo ""

# Show relevant ConfigMap section
echo "Current hosts plugin configuration:"
echo ""
if echo "$COREFILE" | grep -q "hosts"; then
    echo "$COREFILE" | grep -A 5 "hosts" | head -6
else
    echo "  hosts plugin not found in Corefile"
fi
echo ""

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if ! echo "$COREFILE" | grep -q "hosts"; then
        echo "hosts plugin not configured:"
        echo "  kubectl edit configmap coredns -n kube-system"
        echo "  Add after 'ready' plugin:"
        echo "    hosts {"
        echo "        10.10.10.10 myapp.internal"
        echo "        fallthrough"
        echo "    }"
        echo ""
    elif ! echo "$COREFILE" | grep -q "10.10.10.10.*myapp.internal"; then
        echo "Incorrect entry in hosts plugin:"
        echo "  Expected format: 10.10.10.10 myapp.internal"
        echo "  Order matters: IP then hostname"
        echo ""
    fi
    
    if ! echo "$DNS_OUTPUT" | grep -q "10.10.10.10"; then
        echo "DNS not resolving:"
        echo "  1. Verify ConfigMap is correct"
        echo "  2. Reload CoreDNS: kubectl rollout restart deployment coredns -n kube-system"
        echo "  3. Wait for pods to be ready"
        echo "  4. Test again"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl get configmap coredns -n kube-system -o yaml"
    echo "  kubectl logs -n kube-system -l k8s-app=coredns"
    echo "  kubectl rollout restart deployment coredns -n kube-system"
    echo ""
fi

echo "💡 Quick Fix Guide:"
echo ""
echo "1. Edit CoreDNS ConfigMap:"
echo "   kubectl edit configmap coredns -n kube-system"
echo ""
echo "2. Add hosts plugin (after 'ready' plugin):"
echo "   hosts {"
echo "       10.10.10.10 myapp.internal"
echo "       fallthrough"
echo "   }"
echo ""
echo "3. Save and reload CoreDNS:"
echo "   kubectl rollout restart deployment coredns -n kube-system"
echo ""
echo "4. Test:"
echo "   kubectl run test --image=busybox --restart=Never -- nslookup myapp.internal"
echo "   kubectl logs test"
echo "   kubectl delete pod test"
echo ""

# Show example of correct configuration
echo "Example correct hosts plugin configuration:"
echo ""
echo "  .:53 {"
echo "      errors"
echo "      health"
echo "      ready"
echo "      hosts {"
echo "          10.10.10.10 myapp.internal"
echo "          fallthrough"
echo "      }"
echo "      kubernetes cluster.local in-addr.arpa ip6.arpa {"
echo "         ..."
echo "      }"
echo "      ..."
echo "  }"
echo ""

exit 0
