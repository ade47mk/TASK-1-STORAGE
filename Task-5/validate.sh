#!/bin/bash

# Validation script for Task 5: Node Affinity
# This script checks if the node is labeled and pod is scheduled correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 5: Node Affinity"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=15

# Check 1: At least one node has disktype=ssd label (3 points)
echo "Check 1: Is there a node with disktype=ssd label?"
LABELED_NODES=$(kubectl get nodes -l disktype=ssd --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$LABELED_NODES" -gt 0 ]; then
    echo "✓ Found $LABELED_NODES node(s) with disktype=ssd label (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
    
    echo ""
    echo "  Labeled nodes:"
    kubectl get nodes -l disktype=ssd -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,LABEL:.metadata.labels.disktype
    echo ""
else
    echo "✗ No nodes have disktype=ssd label"
    echo ""
    echo "Label a node with:"
    NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    echo "  kubectl label nodes $NODE_NAME disktype=ssd"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: Pod exists (2 points)
echo "Check 2: Does the pod exist?"
if kubectl get pod ssd-pod &> /dev/null; then
    echo "✓ Pod 'ssd-pod' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Pod 'ssd-pod' not found"
    echo ""
    echo "Current pods in default namespace:"
    kubectl get pods -n default 2>/dev/null || echo "  No pods found"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 3: Pod has node affinity configured (4 points)
echo "Check 3: Does the pod have node affinity configured?"
if kubectl get pod ssd-pod -o yaml | grep -q "nodeAffinity"; then
    echo "✓ Pod has node affinity configured (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ Pod does not have node affinity configured"
    echo "  Check spec.affinity.nodeAffinity in pod manifest"
fi

# Check 4: Node affinity requires disktype=ssd (3 points)
echo "Check 4: Does node affinity require disktype=ssd?"
if kubectl get pod ssd-pod -o yaml | grep -A 5 "matchExpressions" | grep -q "disktype"; then
    if kubectl get pod ssd-pod -o yaml | grep -A 10 "matchExpressions" | grep -q "ssd"; then
        echo "✓ Node affinity requires disktype=ssd (3 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 3))
    else
        echo "✗ Node affinity uses disktype key but wrong value"
        echo "  Expected value: ssd"
    fi
else
    echo "✗ Node affinity does not check disktype label"
    echo "  Expected: key=disktype, value=ssd"
fi

# Check 5: Pod is scheduled (not Pending) (2 points)
echo "Check 5: Is the pod scheduled?"
POD_PHASE=$(kubectl get pod ssd-pod -o jsonpath='{.status.phase}')
POD_NODE=$(kubectl get pod ssd-pod -o jsonpath='{.spec.nodeName}')

if [ "$POD_PHASE" != "Pending" ] && [ -n "$POD_NODE" ]; then
    echo "✓ Pod is scheduled (status: $POD_PHASE) (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    echo "  Scheduled on node: $POD_NODE"
else
    echo "⚠ Pod is Pending or not scheduled"
    echo "  Pod phase: $POD_PHASE"
    
    if [ -z "$POD_NODE" ]; then
        echo "  Pod has not been assigned to any node"
        echo ""
        echo "  Check if node has disktype=ssd label:"
        kubectl get nodes -l disktype=ssd
        echo ""
        echo "  Check pod events:"
        kubectl describe pod ssd-pod | tail -15
    fi
fi

# Check 6: Pod is on node with disktype=ssd (1 point)
echo "Check 6: Is the pod on a node with disktype=ssd label?"
if [ -n "$POD_NODE" ]; then
    NODE_LABEL=$(kubectl get node "$POD_NODE" -o jsonpath='{.metadata.labels.disktype}' 2>/dev/null)
    
    if [ "$NODE_LABEL" == "ssd" ]; then
        echo "✓ Pod is on node with disktype=ssd (1 point)"
        TOTAL_POINTS=$((TOTAL_POINTS + 1))
    else
        echo "✗ Pod is on node '$POD_NODE' which has disktype='$NODE_LABEL' (expected: ssd)"
    fi
else
    echo "⚠ Pod not scheduled yet, cannot verify node label"
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
    echo "✓ Node labeled with disktype=ssd"
    echo "✓ Pod created with node affinity"
    echo "✓ Node affinity requires disktype=ssd"
    echo "✓ Pod successfully scheduled"
    echo "✓ Pod running on correct node"
    echo ""
elif [ $TOTAL_POINTS -ge 11 ]; then
    echo "✅ PASSED! Good work!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 8 ]; then
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
echo "Resource Summary:"
echo ""
echo "Nodes with disktype=ssd:"
kubectl get nodes -l disktype=ssd 2>/dev/null || echo "  None found"
echo ""
echo "Pod:"
if kubectl get pod ssd-pod &> /dev/null; then
    kubectl get pod ssd-pod -o wide
else
    echo "  Pod 'ssd-pod' not found"
fi
echo ""

# Show node affinity details if pod exists
if kubectl get pod ssd-pod &> /dev/null; then
    echo "Pod Node Affinity:"
    echo ""
    if kubectl get pod ssd-pod -o yaml | grep -q "nodeAffinity"; then
        kubectl get pod ssd-pod -o yaml | grep -A 20 "nodeAffinity:" | head -15
        echo ""
    else
        echo "  No node affinity configured"
        echo ""
    fi
fi

# Show all nodes with their disktype label status
echo "All Nodes and Labels:"
echo ""
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,DISKTYPE:.metadata.labels.disktype
echo ""

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if [ "$LABELED_NODES" -eq 0 ]; then
        echo "No nodes labeled yet:"
        echo "  kubectl label nodes <node-name> disktype=ssd"
        echo ""
        NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
        echo "  Example:"
        echo "  kubectl label nodes $NODE_NAME disktype=ssd"
        echo ""
    fi
    
    if ! kubectl get pod ssd-pod &> /dev/null; then
        echo "Pod not created yet:"
        echo "  Create a pod with node affinity requiring disktype=ssd"
        echo "  See SolutionNotes.bash for full example"
        echo ""
    elif [ "$POD_PHASE" == "Pending" ]; then
        echo "Pod is Pending:"
        echo "  1. Check if any nodes have disktype=ssd label"
        echo "  2. Check pod events: kubectl describe pod ssd-pod"
        echo "  3. Verify node affinity matches label exactly"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl get nodes -l disktype=ssd"
    echo "  kubectl describe pod ssd-pod"
    echo "  kubectl get pod ssd-pod -o yaml | grep -A 15 nodeAffinity"
    echo ""
fi

# Show pod events if pod exists but has issues
if kubectl get pod ssd-pod &> /dev/null; then
    if [ "$POD_PHASE" == "Pending" ] || [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
        echo "Pod Events:"
        echo ""
        kubectl describe pod ssd-pod | grep -A 10 "Events:" | tail -10
        echo ""
    fi
fi

echo "💡 Quick Fix Guide:"
echo ""
echo "1. Label a node:"
echo "   kubectl label nodes <node-name> disktype=ssd"
echo ""
echo "2. Create pod with node affinity:"
echo "   cat <<YAML | kubectl apply -f -"
echo "   apiVersion: v1"
echo "   kind: Pod"
echo "   metadata:"
echo "     name: ssd-pod"
echo "   spec:"
echo "     affinity:"
echo "       nodeAffinity:"
echo "         requiredDuringSchedulingIgnoredDuringExecution:"
echo "           nodeSelectorTerms:"
echo "           - matchExpressions:"
echo "             - key: disktype"
echo "               operator: In"
echo "               values:"
echo "               - ssd"
echo "     containers:"
echo "     - name: nginx"
echo "       image: nginx"
echo "   YAML"
echo ""
echo "3. Verify:"
echo "   kubectl get pod ssd-pod -o wide"
echo ""

exit 0
