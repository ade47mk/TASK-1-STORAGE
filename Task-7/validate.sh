#!/bin/bash

# Validation script for Task 7: Taints and Tolerations
# This script checks if the node is tainted and pod has matching toleration

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 7: Taints and Tolerations"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=16

# Determine target node
if kubectl get node node-1 &> /dev/null; then
    TARGET_NODE="node-1"
else
    TARGET_NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    echo "⚠ Using node: $TARGET_NODE (node-1 not found)"
    echo ""
fi

# Check 1: Node has taint (prerequisite)
echo "Check 1: Does the node have any taints?"
TAINT_COUNT=$(kubectl get node $TARGET_NODE -o jsonpath='{.spec.taints}' | grep -c "key" || echo "0")

if [ "$TAINT_COUNT" -gt 0 ]; then
    echo "✓ Node '$TARGET_NODE' has taint(s)"
    echo "  Taints:"
    kubectl get node $TARGET_NODE -o jsonpath='{.spec.taints[*]}' | jq '.' 2>/dev/null || \
    kubectl describe node $TARGET_NODE | grep "Taints:" | head -1
else
    echo "✗ Node '$TARGET_NODE' has no taints"
    echo ""
    echo "Add taint with:"
    echo "  kubectl taint nodes $TARGET_NODE special=dedicated:NoSchedule"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: Taint has correct key (3 points)
echo ""
echo "Check 2: Does the taint have the correct key 'special'?"
TAINT_KEY=$(kubectl get node $TARGET_NODE -o jsonpath='{.spec.taints[?(@.key=="special")].key}')

if [ "$TAINT_KEY" == "special" ]; then
    echo "✓ Taint key is 'special' (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Taint key is not 'special'"
    echo "  Found taints:"
    kubectl get node $TARGET_NODE -o jsonpath='{.spec.taints[*].key}' | tr ' ' '\n' | sed 's/^/  - /'
fi

# Check 3: Taint has correct value (2 points)
echo "Check 3: Does the taint have the correct value 'dedicated'?"
TAINT_VALUE=$(kubectl get node $TARGET_NODE -o jsonpath='{.spec.taints[?(@.key=="special")].value}')

if [ "$TAINT_VALUE" == "dedicated" ]; then
    echo "✓ Taint value is 'dedicated' (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Taint value is: '$TAINT_VALUE' (expected: dedicated)"
fi

# Check 4: Taint has NoSchedule effect (2 points)
echo "Check 4: Does the taint have NoSchedule effect?"
TAINT_EFFECT=$(kubectl get node $TARGET_NODE -o jsonpath='{.spec.taints[?(@.key=="special")].effect}')

if [ "$TAINT_EFFECT" == "NoSchedule" ]; then
    echo "✓ Taint effect is NoSchedule (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
elif [ "$TAINT_EFFECT" == "PreferNoSchedule" ]; then
    echo "✗ Taint effect is PreferNoSchedule (expected: NoSchedule)"
    echo "  PreferNoSchedule is a soft preference, not strict"
elif [ "$TAINT_EFFECT" == "NoExecute" ]; then
    echo "⚠ Taint effect is NoExecute"
    echo "  This works but is more aggressive (evicts existing pods)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ Taint effect is: '$TAINT_EFFECT' (expected: NoSchedule)"
fi

# Check 5: Pod exists (2 points)
echo ""
echo "Check 5: Does the pod exist?"
if kubectl get pod tolerated-pod &> /dev/null; then
    echo "✓ Pod 'tolerated-pod' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Pod 'tolerated-pod' not found"
    echo ""
    echo "Current pods:"
    kubectl get pods
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 6: Pod has tolerations configured (3 points)
echo "Check 6: Does the pod have tolerations configured?"
if kubectl get pod tolerated-pod -o yaml | grep -q "tolerations"; then
    echo "✓ Pod has tolerations configured (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Pod does not have tolerations configured"
fi

# Check 7: Toleration matches taint (3 points)
echo "Check 7: Does the toleration match the taint?"
POD_TOL_KEY=$(kubectl get pod tolerated-pod -o jsonpath='{.spec.tolerations[?(@.key=="special")].key}')
POD_TOL_VALUE=$(kubectl get pod tolerated-pod -o jsonpath='{.spec.tolerations[?(@.key=="special")].value}')
POD_TOL_EFFECT=$(kubectl get pod tolerated-pod -o jsonpath='{.spec.tolerations[?(@.key=="special")].effect}')

TOLERATION_MATCH=true

if [ "$POD_TOL_KEY" == "special" ]; then
    echo "  ✓ Toleration key matches: special"
else
    echo "  ✗ Toleration key doesn't match (found: $POD_TOL_KEY, expected: special)"
    TOLERATION_MATCH=false
fi

if [ "$POD_TOL_VALUE" == "dedicated" ]; then
    echo "  ✓ Toleration value matches: dedicated"
else
    # Check if using Exists operator (which doesn't need value)
    POD_TOL_OPERATOR=$(kubectl get pod tolerated-pod -o jsonpath='{.spec.tolerations[?(@.key=="special")].operator}')
    if [ "$POD_TOL_OPERATOR" == "Exists" ]; then
        echo "  ✓ Toleration uses Exists operator (accepts any value)"
    else
        echo "  ✗ Toleration value doesn't match (found: $POD_TOL_VALUE, expected: dedicated)"
        TOLERATION_MATCH=false
    fi
fi

if [ "$POD_TOL_EFFECT" == "NoSchedule" ]; then
    echo "  ✓ Toleration effect matches: NoSchedule"
elif [ "$POD_TOL_EFFECT" == "NoExecute" ]; then
    echo "  ✓ Toleration effect is NoExecute (also valid)"
elif [ -z "$POD_TOL_EFFECT" ]; then
    echo "  ✓ Toleration effect is empty (matches all effects)"
else
    echo "  ✗ Toleration effect doesn't match (found: $POD_TOL_EFFECT, expected: NoSchedule)"
    TOLERATION_MATCH=false
fi

if [ "$TOLERATION_MATCH" = true ]; then
    echo "✓ Toleration matches taint (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Toleration does not match taint"
fi

# Check 8: Pod is scheduled (1 point)
echo ""
echo "Check 8: Is the pod scheduled?"
POD_STATUS=$(kubectl get pod tolerated-pod -o jsonpath='{.status.phase}')
POD_NODE=$(kubectl get pod tolerated-pod -o jsonpath='{.spec.nodeName}')

if [ "$POD_STATUS" != "Pending" ] && [ -n "$POD_NODE" ]; then
    echo "✓ Pod is scheduled (status: $POD_STATUS) (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
    echo "  Scheduled on node: $POD_NODE"
else
    echo "⚠ Pod is Pending or not scheduled"
    echo "  Pod status: $POD_STATUS"
    echo ""
    echo "  Check pod events:"
    kubectl describe pod tolerated-pod | tail -10
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent work!"
    echo ""
    echo "✓ Node tainted correctly"
    echo "✓ Pod created with matching toleration"
    echo "✓ Pod scheduled successfully"
    echo ""
elif [ $TOTAL_POINTS -ge 12 ]; then
    echo "✅ PASSED! Good work!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 9 ]; then
    echo "⚠️ PARTIAL PASS - Several issues to fix"
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

# Show resource summary
echo "Node Taints:"
echo ""
kubectl describe node $TARGET_NODE | grep "Taints:" || echo "  No taints found"
echo ""

echo "Pod Details:"
if kubectl get pod tolerated-pod &> /dev/null; then
    kubectl get pod tolerated-pod -o wide
    echo ""
    echo "Pod Tolerations:"
    kubectl get pod tolerated-pod -o jsonpath='{.spec.tolerations}' | jq '.' 2>/dev/null || \
    kubectl get pod tolerated-pod -o yaml | grep -A 10 "tolerations:"
else
    echo "  Pod not found"
fi
echo ""

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if [ -z "$TAINT_KEY" ] || [ "$TAINT_KEY" != "special" ]; then
        echo "Taint not configured correctly:"
        echo "  kubectl taint nodes $TARGET_NODE special=dedicated:NoSchedule"
        echo ""
    fi
    
    if ! kubectl get pod tolerated-pod &> /dev/null; then
        echo "Pod not created yet:"
        echo "  Create pod with toleration matching the taint"
        echo "  See SolutionNotes.bash for full example"
        echo ""
    elif [ "$TOLERATION_MATCH" = false ]; then
        echo "Toleration doesn't match taint:"
        echo "  Taint: special=dedicated:NoSchedule"
        echo "  Toleration must have same key, value, and effect"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl describe node $TARGET_NODE | grep Taint"
    echo "  kubectl get pod tolerated-pod -o yaml | grep -A 5 tolerations"
    echo "  kubectl describe pod tolerated-pod"
    echo ""
fi

echo "💡 Quick Reference:"
echo ""
echo "Correct taint:"
echo "  kubectl taint nodes $TARGET_NODE special=dedicated:NoSchedule"
echo ""
echo "Verify taint:"
echo "  kubectl describe node $TARGET_NODE | grep Taint"
echo ""
echo "Pod with matching toleration:"
echo "  apiVersion: v1"
echo "  kind: Pod"
echo "  metadata:"
echo "    name: tolerated-pod"
echo "  spec:"
echo "    tolerations:"
echo "    - key: special"
echo "      operator: Equal"
echo "      value: dedicated"
echo "      effect: NoSchedule"
echo "    containers:"
echo "    - name: nginx"
echo "      image: nginx"
echo ""
echo "Apply and verify:"
echo "  kubectl apply -f tolerated-pod.yaml"
echo "  kubectl get pod tolerated-pod -o wide"
echo ""

exit 0
