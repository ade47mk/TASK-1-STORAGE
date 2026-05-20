#!/bin/bash

# Validation script for Task 9: CoreDNS Troubleshooting
# This script checks if CoreDNS has been fixed and DNS is working

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 9: CoreDNS Troubleshooting"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=20

# Check 1: CoreDNS deployment exists (3 points)
echo "Check 1: Does CoreDNS deployment exist?"
if kubectl get deployment coredns -n kube-system &> /dev/null; then
    echo "✓ CoreDNS deployment exists (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ CoreDNS deployment not found in kube-system"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: CoreDNS has 2+ replicas (4 points)
echo "Check 2: Does CoreDNS have at least 2 replicas?"
REPLICAS=$(kubectl get deployment coredns -n kube-system -o jsonpath='{.spec.replicas}')

if [ "$REPLICAS" -ge 2 ]; then
    echo "✓ CoreDNS has $REPLICAS replicas (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
elif [ "$REPLICAS" -eq 1 ]; then
    echo "⚠ CoreDNS has only 1 replica (recommended: 2 for HA)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ CoreDNS has $REPLICAS replicas (should be 2+)"
fi

# Check 3: CoreDNS pods are Running (5 points)
echo "Check 3: Are CoreDNS pods running?"
RUNNING_PODS=$(kubectl get pods -n kube-system -l k8s-app=coredns --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
READY_REPLICAS=$(kubectl get deployment coredns -n kube-system -o jsonpath='{.status.readyReplicas}')

if [ "$READY_REPLICAS" -ge 2 ]; then
    echo "✓ $READY_REPLICAS CoreDNS pods are Running and Ready (5 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 5))
    kubectl get pods -n kube-system -l k8s-app=coredns
elif [ "$READY_REPLICAS" -eq 1 ]; then
    echo "⚠ Only 1 CoreDNS pod is Ready"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
    kubectl get pods -n kube-system -l k8s-app=coredns
else
    echo "✗ No CoreDNS pods are Ready"
    echo "  Current pod status:"
    kubectl get pods -n kube-system -l k8s-app=coredns
fi

# Check 4: Internal DNS works (4 points)
echo ""
echo "Check 4: Does internal DNS resolution work?"
echo "  Testing DNS for kubernetes.default service..."

# Clean up any existing test pod
kubectl delete pod dns-test-internal --force --grace-period=0 &>/dev/null 2>&1

# Create test pod
kubectl run dns-test-internal --image=busybox:1.28 --restart=Never \
  --command -- nslookup kubernetes.default &>/dev/null

# Wait for pod to complete
sleep 8

# Check logs
DNS_INTERNAL_OUTPUT=$(kubectl logs dns-test-internal 2>/dev/null)

if echo "$DNS_INTERNAL_OUTPUT" | grep -qi "Address.*10\."; then
    echo "✓ Internal DNS resolution works (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ Internal DNS resolution failed"
    echo "  Test output:"
    echo "$DNS_INTERNAL_OUTPUT" | head -10
fi

# Clean up
kubectl delete pod dns-test-internal --force --grace-period=0 &>/dev/null 2>&1

# Check 5: External DNS works (4 points)
echo "Check 5: Does external DNS resolution work?"
echo "  Testing DNS for google.com..."

# Clean up any existing test pod
kubectl delete pod dns-test-external --force --grace-period=0 &>/dev/null 2>&1

# Create test pod
kubectl run dns-test-external --image=busybox:1.28 --restart=Never \
  --command -- nslookup google.com &>/dev/null

# Wait for pod to complete
sleep 8

# Check logs
DNS_EXTERNAL_OUTPUT=$(kubectl logs dns-test-external 2>/dev/null)

if echo "$DNS_EXTERNAL_OUTPUT" | grep -qi "Address.*[0-9]"; then
    echo "✓ External DNS resolution works (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ External DNS resolution failed"
    echo "  Test output:"
    echo "$DNS_EXTERNAL_OUTPUT" | head -10
fi

# Clean up
kubectl delete pod dns-test-external --force --grace-period=0 &>/dev/null 2>&1

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
    echo "✓ CoreDNS deployment healthy"
    echo "✓ Multiple replicas running"
    echo "✓ All pods ready"
    echo "✓ Internal DNS working"
    echo "✓ External DNS working"
    echo ""
elif [ $TOTAL_POINTS -ge 14 ]; then
    echo "✅ PASSED! DNS is functional!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 10 ]; then
    echo "⚠️ PARTIAL - DNS partially working"
    echo ""
    echo "Review the failed checks above."
    echo "Check SolutionNotes.bash for hints."
    echo ""
else
    echo "❌ NEEDS WORK - DNS still broken"
    echo ""
    echo "Review the failed checks above."
    echo "Read the Question.bash again carefully."
    echo "Check SolutionNotes.bash for guidance."
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""

# Show resource summary
echo "CoreDNS Status:"
echo ""
echo "Deployment:"
kubectl get deployment coredns -n kube-system 2>/dev/null || echo "  Not found"
echo ""
echo "Pods:"
kubectl get pods -n kube-system -l k8s-app=coredns 2>/dev/null || echo "  No pods found"
echo ""
echo "Service:"
kubectl get service kube-dns -n kube-system 2>/dev/null || echo "  Not found"
echo ""

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if [ "$REPLICAS" -lt 2 ]; then
        echo "Not enough replicas:"
        echo "  kubectl scale deployment coredns -n kube-system --replicas=2"
        echo ""
    fi
    
    if [ "$READY_REPLICAS" -lt 2 ]; then
        echo "Pods not ready:"
        echo "  Check pod status:"
        echo "  kubectl get pods -n kube-system -l k8s-app=coredns"
        echo ""
        echo "  Check logs:"
        echo "  kubectl logs -n kube-system -l k8s-app=coredns"
        echo ""
    fi
    
    if ! echo "$DNS_INTERNAL_OUTPUT" | grep -qi "Address"; then
        echo "DNS not working:"
        echo "  1. Ensure CoreDNS pods are Running"
        echo "  2. Check CoreDNS logs for errors"
        echo "  3. Verify kube-dns service exists"
        echo "  4. May need to restart: kubectl rollout restart deployment coredns -n kube-system"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl get pods -n kube-system -l k8s-app=coredns"
    echo "  kubectl logs -n kube-system -l k8s-app=coredns"
    echo "  kubectl describe deployment coredns -n kube-system"
    echo ""
fi

echo "💡 Quick Fix Commands:"
echo ""
echo "Scale CoreDNS:"
echo "  kubectl scale deployment coredns -n kube-system --replicas=2"
echo ""
echo "Check status:"
echo "  kubectl get pods -n kube-system -l k8s-app=coredns --watch"
echo ""
echo "View logs:"
echo "  kubectl logs -n kube-system -l k8s-app=coredns --tail=50"
echo ""
echo "Test DNS manually:"
echo "  kubectl run test --image=busybox --restart=Never -- nslookup kubernetes.default"
echo "  kubectl logs test"
echo "  kubectl delete pod test"
echo ""

# Show recent CoreDNS logs if available
if [ "$READY_REPLICAS" -gt 0 ]; then
    echo "Recent CoreDNS Logs:"
    echo ""
    kubectl logs -n kube-system -l k8s-app=coredns --tail=10 2>/dev/null | head -10
    echo ""
fi

exit 0
