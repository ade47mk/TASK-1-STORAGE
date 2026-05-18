#!/bin/bash

# Validation script for Task 2: Advanced Storage Configuration
# This script checks if the StorageClass, PV, and PVC have been created correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 2: Advanced Storage Configuration"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=25

# Check 1: StorageClass exists (2 points)
echo "Check 1: Does the StorageClass exist?"
if kubectl get storageclass fast-storage &> /dev/null; then
    echo "✓ StorageClass 'fast-storage' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ StorageClass 'fast-storage' not found"
    echo ""
    echo "Current StorageClasses:"
    kubectl get storageclass
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: StorageClass provisioner (1 point)
echo "Check 2: Is the provisioner correct?"
PROVISIONER=$(kubectl get storageclass fast-storage -o jsonpath='{.provisioner}')
if [ "$PROVISIONER" == "rancher.io/local-path" ]; then
    echo "✓ Provisioner is 'rancher.io/local-path' (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ Provisioner is: $PROVISIONER (expected: rancher.io/local-path)"
fi

# Check 3: StorageClass reclaim policy (3 points)
echo "Check 3: Is the reclaim policy Retain?"
RECLAIM_POLICY=$(kubectl get storageclass fast-storage -o jsonpath='{.reclaimPolicy}')
if [ "$RECLAIM_POLICY" == "Retain" ]; then
    echo "✓ Reclaim policy is 'Retain' (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Reclaim policy is: $RECLAIM_POLICY (expected: Retain)"
    echo "  This is critical - without Retain, PV will be deleted!"
fi

# Check 4: StorageClass binding mode (2 points)
echo "Check 4: Is the volume binding mode correct?"
BINDING_MODE=$(kubectl get storageclass fast-storage -o jsonpath='{.volumeBindingMode}')
if [ "$BINDING_MODE" == "Immediate" ] || [ -z "$BINDING_MODE" ]; then
    echo "✓ Volume binding mode is Immediate (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ Volume binding mode is: $BINDING_MODE (expected: Immediate or empty)"
fi

# Check 5: PV exists (2 points)
echo "Check 5: Does the PersistentVolume exist?"
if kubectl get pv fast-pv &> /dev/null; then
    echo "✓ PersistentVolume 'fast-pv' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ PersistentVolume 'fast-pv' not found"
    echo ""
    echo "Current PVs:"
    kubectl get pv
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 6: PV capacity (1 point)
echo "Check 6: Is the PV capacity correct?"
PV_CAPACITY=$(kubectl get pv fast-pv -o jsonpath='{.spec.capacity.storage}')
if [ "$PV_CAPACITY" == "500Mi" ]; then
    echo "✓ PV capacity is 500Mi (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ PV capacity is: $PV_CAPACITY (expected: 500Mi)"
fi

# Check 7: PV access mode (1 point)
echo "Check 7: Is the PV access mode correct?"
PV_ACCESS_MODE=$(kubectl get pv fast-pv -o jsonpath='{.spec.accessModes[0]}')
if [ "$PV_ACCESS_MODE" == "ReadWriteOnce" ]; then
    echo "✓ PV access mode is ReadWriteOnce (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ PV access mode is: $PV_ACCESS_MODE (expected: ReadWriteOnce)"
fi

# Check 8: PV storage class (1 point)
echo "Check 8: Does the PV use the correct storage class?"
PV_SC=$(kubectl get pv fast-pv -o jsonpath='{.spec.storageClassName}')
if [ "$PV_SC" == "fast-storage" ]; then
    echo "✓ PV uses 'fast-storage' (1 point)"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "✗ PV storage class is: $PV_SC (expected: fast-storage)"
fi

# Check 9: PV has node affinity (2 points)
echo "Check 9: Does the PV have node affinity?"
if kubectl get pv fast-pv -o yaml | grep -q "nodeAffinity"; then
    echo "✓ PV has node affinity configured (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ PV does not have node affinity"
    echo "  While optional, it's recommended for hostPath volumes"
fi

# Check 10: PVC exists (2 points)
echo "Check 10: Does the PersistentVolumeClaim exist?"
if kubectl get pvc fast-pvc -n default &> /dev/null; then
    echo "✓ PVC 'fast-pvc' exists (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    
    # Check 11: PVC is bound (3 points)
    echo "Check 11: Is the PVC bound?"
    PVC_STATUS=$(kubectl get pvc fast-pvc -n default -o jsonpath='{.status.phase}')
    if [ "$PVC_STATUS" == "Bound" ]; then
        echo "✓ PVC is bound (3 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 3))
        
        # Check 12: PVC bound to correct PV (2 points)
        echo "Check 12: Is the PVC bound to the correct PV?"
        PVC_VOLUME=$(kubectl get pvc fast-pvc -n default -o jsonpath='{.spec.volumeName}')
        if [ "$PVC_VOLUME" == "fast-pv" ]; then
            echo "✓ PVC is bound to 'fast-pv' (2 points)"
            TOTAL_POINTS=$((TOTAL_POINTS + 2))
        else
            echo "✗ PVC is bound to: $PVC_VOLUME (expected: fast-pv)"
            echo "  PVC may have dynamically provisioned a new PV"
        fi
    else
        echo "✗ PVC status is: $PVC_STATUS (expected: Bound)"
    fi
else
    echo "⚠ PVC 'fast-pvc' not found"
    echo "  This is okay if you already deleted it to test Retain policy"
    echo ""
    echo "Check 11: Testing Retain Policy..."
    
    # If PVC doesn't exist, check if PV is in Released state
    PV_STATUS=$(kubectl get pv fast-pv -o jsonpath='{.status.phase}' 2>/dev/null)
    if [ "$PV_STATUS" == "Released" ]; then
        echo "✓ PV is in Released state after PVC deletion (5 points bonus!)"
        echo "  This proves the Retain policy works correctly!"
        TOTAL_POINTS=$((TOTAL_POINTS + 5))
    elif [ "$PV_STATUS" == "Bound" ]; then
        echo "⚠ PV is still Bound - PVC may still exist"
    elif [ "$PV_STATUS" == "Available" ]; then
        echo "⚠ PV is Available - it was never bound or claim ref was removed"
    else
        echo "⚠ PV status: $PV_STATUS"
    fi
fi

# Check 13: PVC storage request (1 point)
if kubectl get pvc fast-pvc -n default &> /dev/null; then
    echo "Check 13: Is the PVC storage request correct?"
    PVC_REQUEST=$(kubectl get pvc fast-pvc -n default -o jsonpath='{.spec.resources.requests.storage}')
    if [ "$PVC_REQUEST" == "500Mi" ]; then
        echo "✓ PVC requests 500Mi (1 point)"
        TOTAL_POINTS=$((TOTAL_POINTS + 1))
    else
        echo "✗ PVC requests: $PVC_REQUEST (expected: 500Mi)"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Outstanding work!"
    echo ""
    echo "✓ StorageClass created with Retain policy"
    echo "✓ PersistentVolume manually created"
    echo "✓ PVC successfully bound to PV"
    echo "✓ Retain policy verified"
    echo ""
elif [ $TOTAL_POINTS -ge 18 ]; then
    echo "✅ PASSED! Good work!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 12 ]; then
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
echo "StorageClass:"
kubectl get storageclass fast-storage 2>/dev/null || echo "  Not found"
echo ""
echo "PersistentVolume:"
kubectl get pv fast-pv 2>/dev/null || echo "  Not found"
echo ""
echo "PersistentVolumeClaim:"
kubectl get pvc fast-pvc -n default 2>/dev/null || echo "  Not found"
echo ""

# Additional guidance
if kubectl get pvc fast-pvc -n default &> /dev/null; then
    echo "💡 NEXT STEP: Test the Retain policy!"
    echo ""
    echo "Run these commands to test:"
    echo "  kubectl delete pvc fast-pvc"
    echo "  kubectl get pv fast-pv"
    echo ""
    echo "Expected: PV status should be 'Released' (not deleted)"
    echo "Then run validation again to verify!"
    echo ""
fi

# Show detailed info if available
echo "Detailed Information:"
echo ""
if kubectl get storageclass fast-storage &> /dev/null; then
    echo "StorageClass Details:"
    kubectl describe storageclass fast-storage | head -15
    echo ""
fi

if kubectl get pv fast-pv &> /dev/null; then
    echo "PersistentVolume Details:"
    kubectl get pv fast-pv
    echo ""
fi

exit 0
