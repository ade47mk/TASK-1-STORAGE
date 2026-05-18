#!/bin/bash

# Validation script for Task 3: Manual PV and PVC Creation
# This script checks if the PV and PVC have been created correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 3: Manual PV and PVC Creation"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=20

# Check 1: PV exists (2 points)
echo "Check 1: Does the PersistentVolume exist?"
if kubectl get pv static-pv-example &> /dev/null; then
    echo "✓ PersistentVolume 'static-pv-example' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ PersistentVolume 'static-pv-example' not found"
    echo ""
    echo "Current PVs:"
    kubectl get pv
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: PV capacity (2 points)
echo "Check 2: Is the PV capacity correct?"
PV_CAPACITY=$(kubectl get pv static-pv-example -o jsonpath='{.spec.capacity.storage}')
if [ "$PV_CAPACITY" == "200Mi" ]; then
    echo "✓ PV capacity is 200Mi (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ PV capacity is: $PV_CAPACITY (expected: 200Mi)"
fi

# Check 3: PV access mode (2 points)
echo "Check 3: Is the PV access mode correct?"
PV_ACCESS_MODE=$(kubectl get pv static-pv-example -o jsonpath='{.spec.accessModes[0]}')
if [ "$PV_ACCESS_MODE" == "ReadWriteOnce" ]; then
    echo "✓ PV access mode is ReadWriteOnce (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ PV access mode is: $PV_ACCESS_MODE (expected: ReadWriteOnce)"
fi

# Check 4: PV reclaim policy (3 points)
echo "Check 4: Is the PV reclaim policy Retain?"
PV_RECLAIM=$(kubectl get pv static-pv-example -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
if [ "$PV_RECLAIM" == "Retain" ]; then
    echo "✓ PV reclaim policy is Retain (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ PV reclaim policy is: $PV_RECLAIM (expected: Retain)"
    echo "  This means PV will be deleted when PVC is deleted!"
fi

# Check 5: PV uses hostPath (2 points)
echo "Check 5: Does the PV use hostPath volume type?"
if kubectl get pv static-pv-example -o yaml | grep -q "hostPath"; then
    echo "✓ PV uses hostPath volume type (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    
    # Show hostPath details
    HOST_PATH=$(kubectl get pv static-pv-example -o jsonpath='{.spec.hostPath.path}')
    echo "  Host path: $HOST_PATH"
else
    echo "✗ PV does not use hostPath volume type"
    echo "  Check PV spec for hostPath configuration"
fi

# Check 6: PV has node affinity (2 points)
echo "Check 6: Does the PV have node affinity?"
if kubectl get pv static-pv-example -o yaml | grep -q "nodeAffinity"; then
    echo "✓ PV has node affinity configured (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    
    # Show node affinity details
    NODE_SELECTOR=$(kubectl get pv static-pv-example -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')
    echo "  Target node: $NODE_SELECTOR"
else
    echo "✗ PV does not have node affinity"
    echo "  Node affinity restricts which nodes can use this volume"
fi

# Check 7: PV has empty storageClassName (2 points)
echo "Check 7: Does the PV have empty storageClassName?"
PV_SC=$(kubectl get pv static-pv-example -o jsonpath='{.spec.storageClassName}')
if [ -z "$PV_SC" ] || [ "$PV_SC" == '""' ]; then
    echo "✓ PV has empty storageClassName (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    echo "  This enables manual PV/PVC binding"
else
    echo "✗ PV storageClassName is: '$PV_SC' (expected: empty string)"
    echo "  Use storageClassName: \"\" for manual binding"
fi

# Check 8: PVC exists (1 point)
echo "Check 8: Does the PersistentVolumeClaim exist?"
if kubectl get pvc static-pvc-example -n default &> /dev/null; then
    echo "✓ PVC 'static-pvc-example' exists (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ PVC 'static-pvc-example' not found in default namespace"
    echo ""
    echo "Current PVCs in default namespace:"
    kubectl get pvc -n default
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 9: PVC specifications (2 points)
echo "Check 9: Are the PVC specifications correct?"
PVC_STORAGE=$(kubectl get pvc static-pvc-example -n default -o jsonpath='{.spec.resources.requests.storage}')
PVC_ACCESS=$(kubectl get pvc static-pvc-example -n default -o jsonpath='{.spec.accessModes[0]}')
PVC_SC=$(kubectl get pvc static-pvc-example -n default -o jsonpath='{.spec.storageClassName}')

SPEC_CORRECT=true

if [ "$PVC_STORAGE" == "200Mi" ]; then
    echo "  ✓ PVC requests 200Mi storage"
else
    echo "  ✗ PVC requests: $PVC_STORAGE (expected: 200Mi)"
    SPEC_CORRECT=false
fi

if [ "$PVC_ACCESS" == "ReadWriteOnce" ]; then
    echo "  ✓ PVC access mode is ReadWriteOnce"
else
    echo "  ✗ PVC access mode is: $PVC_ACCESS (expected: ReadWriteOnce)"
    SPEC_CORRECT=false
fi

if [ -z "$PVC_SC" ] || [ "$PVC_SC" == '""' ]; then
    echo "  ✓ PVC has empty storageClassName"
else
    echo "  ✗ PVC storageClassName is: '$PVC_SC' (expected: empty string)"
    SPEC_CORRECT=false
fi

if [ "$SPEC_CORRECT" = true ]; then
    echo "✓ All PVC specifications are correct (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Some PVC specifications are incorrect"
fi

# Check 10: PVC is bound (2 points)
echo "Check 10: Is the PVC bound to the PV?"
PVC_STATUS=$(kubectl get pvc static-pvc-example -n default -o jsonpath='{.status.phase}')
PVC_VOLUME=$(kubectl get pvc static-pvc-example -n default -o jsonpath='{.spec.volumeName}')

if [ "$PVC_STATUS" == "Bound" ]; then
    if [ "$PVC_VOLUME" == "static-pv-example" ]; then
        echo "✓ PVC is bound to 'static-pv-example' (2 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 2))
    else
        echo "✗ PVC is bound to: $PVC_VOLUME (expected: static-pv-example)"
        echo "  PVC bound to wrong PV"
    fi
else
    echo "✗ PVC status is: $PVC_STATUS (expected: Bound)"
    echo "  Check PVC events for binding issues:"
    kubectl describe pvc static-pvc-example -n default | tail -10
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
    echo "✓ PersistentVolume manually created"
    echo "✓ PV has Retain reclaim policy"
    echo "✓ PV uses hostPath with node affinity"
    echo "✓ PVC successfully bound to PV"
    echo "✓ Manual binding (empty storageClassName)"
    echo ""
elif [ $TOTAL_POINTS -ge 14 ]; then
    echo "✅ PASSED! Good work!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 10 ]; then
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
echo "PersistentVolume:"
kubectl get pv static-pv-example 2>/dev/null || echo "  Not found"
echo ""
echo "PersistentVolumeClaim:"
kubectl get pvc static-pvc-example -n default 2>/dev/null || echo "  Not found"
echo ""

# Show detailed binding info
if kubectl get pv static-pv-example &> /dev/null && kubectl get pvc static-pvc-example -n default &> /dev/null; then
    echo "Binding Details:"
    echo ""
    echo "PV Status:"
    kubectl get pv static-pv-example -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CLAIM:.spec.claimRef.name,STORAGECLASS:.spec.storageClassName,REASON:.status.reason
    echo ""
    echo "PVC Status:"
    kubectl get pvc static-pvc-example -n default -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.status.capacity.storage,STORAGECLASS:.spec.storageClassName
    echo ""
fi

# Additional guidance
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    echo "If PVC is stuck in Pending:"
    echo "  1. Check that both PV and PVC have storageClassName: \"\""
    echo "  2. Verify access modes match (both ReadWriteOnce)"
    echo "  3. Ensure PVC request (200Mi) <= PV capacity (200Mi)"
    echo "  4. Check PVC events: kubectl describe pvc static-pvc-example"
    echo ""
    echo "Common issues:"
    echo "  - Missing storageClassName: \"\" in PV or PVC"
    echo "  - Wrong node name in PV nodeAffinity"
    echo "  - Capacity mismatch"
    echo ""
fi

# Optional: Test with a pod
echo "💡 OPTIONAL: Test the volume with a pod"
echo ""
echo "Create a test pod:"
echo "  cat <<YAML | kubectl apply -f -"
echo "  apiVersion: v1"
echo "  kind: Pod"
echo "  metadata:"
echo "    name: test-pod"
echo "  spec:"
echo "    containers:"
echo "    - name: test"
echo "      image: busybox"
echo "      command: [\"/bin/sh\", \"-c\", \"sleep 3600\"]"
echo "      volumeMounts:"
echo "      - name: storage"
echo "        mountPath: /data"
echo "    volumes:"
echo "    - name: storage"
echo "      persistentVolumeClaim:"
echo "        claimName: static-pvc-example"
echo "  YAML"
echo ""
echo "Test the volume:"
echo "  kubectl exec test-pod -- sh -c \"echo test > /data/test.txt\""
echo "  kubectl exec test-pod -- cat /data/test.txt"
echo ""

exit 0
