#!/bin/bash

# Validation script for Task 8: StatefulSets & Headless Services
# This script checks if the Headless Service and StatefulSet are configured correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 8: StatefulSets & Headless Services"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=25

# Check 1: Headless Service exists (4 points)
echo "Check 1: Does the Headless Service exist?"
if kubectl get service web &> /dev/null; then
    echo "✓ Service 'web' exists (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ Service 'web' not found"
    echo ""
    echo "Create Headless Service first!"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: Service is headless (clusterIP: None) (3 points)
echo "Check 2: Is the Service headless (clusterIP: None)?"
CLUSTER_IP=$(kubectl get service web -o jsonpath='{.spec.clusterIP}')

if [ "$CLUSTER_IP" == "None" ]; then
    echo "✓ Service is headless (clusterIP: None) (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Service is not headless (clusterIP: $CLUSTER_IP)"
    echo "  Expected: clusterIP: None"
fi

# Check 3: StatefulSet exists (3 points)
echo "Check 3: Does the StatefulSet exist?"
if kubectl get statefulset web &> /dev/null; then
    echo "✓ StatefulSet 'web' exists (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ StatefulSet 'web' not found"
    echo ""
    echo "Current StatefulSets:"
    kubectl get statefulsets
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 4: StatefulSet has 2 replicas (2 points)
echo "Check 4: Does the StatefulSet have 2 replicas?"
REPLICAS=$(kubectl get statefulset web -o jsonpath='{.spec.replicas}')

if [ "$REPLICAS" == "2" ]; then
    echo "✓ StatefulSet has 2 replicas (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ StatefulSet has $REPLICAS replicas (expected: 2)"
fi

# Check 5: StatefulSet uses nginx image (2 points)
echo "Check 5: Does the StatefulSet use nginx image?"
IMAGE=$(kubectl get statefulset web -o jsonpath='{.spec.template.spec.containers[0].image}')

if echo "$IMAGE" | grep -q "nginx"; then
    echo "✓ StatefulSet uses nginx image (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
else
    echo "✗ StatefulSet uses image: $IMAGE (expected: nginx)"
fi

# Check 6: VolumeClaimTemplate configured (4 points)
echo "Check 6: Is volumeClaimTemplates configured?"
if kubectl get statefulset web -o yaml | grep -q "volumeClaimTemplates"; then
    echo "✓ volumeClaimTemplates configured (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    
    # Show template details
    VCT_NAME=$(kubectl get statefulset web -o jsonpath='{.spec.volumeClaimTemplates[0].metadata.name}')
    echo "  Template name: $VCT_NAME"
else
    echo "✗ volumeClaimTemplates not configured"
    echo "  StatefulSet needs volumeClaimTemplates for persistent storage"
fi

# Check 7: PVCs created (3 points)
echo "Check 7: Are PVCs created for the pods?"
PVC_COUNT=$(kubectl get pvc -l app=nginx --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$PVC_COUNT" -ge 2 ]; then
    echo "✓ PVCs created (found $PVC_COUNT) (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
    
    # Check for expected PVC names
    if kubectl get pvc www-web-0 &> /dev/null && kubectl get pvc www-web-1 &> /dev/null; then
        echo "  ✓ Found expected PVCs: www-web-0, www-web-1"
    fi
else
    echo "⚠ Only $PVC_COUNT PVC(s) found (expected: 2)"
    echo "  PVCs may still be creating or pods not ready"
fi

# Check 8: PVCs are 1Gi (2 points)
echo "Check 8: Are PVCs 1Gi in size?"
if kubectl get pvc www-web-0 &> /dev/null; then
    PVC_SIZE=$(kubectl get pvc www-web-0 -o jsonpath='{.spec.resources.requests.storage}')
    if [ "$PVC_SIZE" == "1Gi" ]; then
        echo "✓ PVCs are 1Gi (2 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 2))
    else
        echo "✗ PVC size is: $PVC_SIZE (expected: 1Gi)"
    fi
else
    echo "⚠ PVC www-web-0 not found yet"
fi

# Check 9: Pods are running (2 points)
echo "Check 9: Are the StatefulSet pods running?"
READY_REPLICAS=$(kubectl get statefulset web -o jsonpath='{.status.readyReplicas}')

if [ "$READY_REPLICAS" == "2" ]; then
    echo "✓ All 2 pods are running (2 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 2))
    
    # Show pod details
    kubectl get pods -l app=nginx
elif [ -n "$READY_REPLICAS" ] && [ "$READY_REPLICAS" -gt 0 ]; then
    echo "⚠ $READY_REPLICAS out of 2 pods ready"
    echo "  Pods may still be starting"
    TOTAL_POINTS=$((TOTAL_POINTS + 1))
else
    echo "⚠ No pods ready yet"
    echo "  Check pod status:"
    kubectl get pods -l app=nginx
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
    echo "✓ Headless Service configured"
    echo "✓ StatefulSet with 2 replicas"
    echo "✓ VolumeClaimTemplates configured"
    echo "✓ PVCs created and bound"
    echo "✓ All pods running"
    echo ""
elif [ $TOTAL_POINTS -ge 18 ]; then
    echo "✅ PASSED! Good work!"
    echo ""
    echo "Review the output above for areas to improve."
    echo ""
elif [ $TOTAL_POINTS -ge 15 ]; then
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

echo "Service:"
kubectl get service web 2>/dev/null || echo "  Not found"
echo ""

echo "StatefulSet:"
kubectl get statefulset web 2>/dev/null || echo "  Not found"
echo ""

echo "Pods:"
kubectl get pods -l app=nginx 2>/dev/null || echo "  No pods found"
echo ""

echo "PVCs:"
kubectl get pvc 2>/dev/null | grep -E "NAME|www-web" || echo "  No PVCs found"
echo ""

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if ! kubectl get service web &> /dev/null; then
        echo "Service not found:"
        echo "  Create Headless Service first"
        echo "  kubectl apply -f web-service.yaml"
        echo ""
    elif [ "$CLUSTER_IP" != "None" ]; then
        echo "Service is not headless:"
        echo "  Add: clusterIP: None to service spec"
        echo ""
    fi
    
    if ! kubectl get statefulset web &> /dev/null; then
        echo "StatefulSet not found:"
        echo "  Create StatefulSet after Service"
        echo "  kubectl apply -f web-statefulset.yaml"
        echo ""
    fi
    
    if [ "$PVC_COUNT" -lt 2 ]; then
        echo "PVCs not created:"
        echo "  Check volumeClaimTemplates in StatefulSet"
        echo "  Ensure StorageClass is available"
        echo "  kubectl get storageclass"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl describe service web"
    echo "  kubectl describe statefulset web"
    echo "  kubectl get pods -l app=nginx --watch"
    echo "  kubectl describe pvc www-web-0"
    echo ""
fi

echo "💡 Quick Reference:"
echo ""
echo "Headless Service:"
echo "  apiVersion: v1"
echo "  kind: Service"
echo "  metadata:"
echo "    name: web"
echo "  spec:"
echo "    clusterIP: None"
echo "    selector:"
echo "      app: nginx"
echo "    ports:"
echo "    - port: 80"
echo ""
echo "StatefulSet (with volumeClaimTemplates):"
echo "  apiVersion: apps/v1"
echo "  kind: StatefulSet"
echo "  metadata:"
echo "    name: web"
echo "  spec:"
echo "    serviceName: web"
echo "    replicas: 2"
echo "    selector:"
echo "      matchLabels:"
echo "        app: nginx"
echo "    template:"
echo "      metadata:"
echo "        labels:"
echo "          app: nginx"
echo "      spec:"
echo "        containers:"
echo "        - name: nginx"
echo "          image: nginx"
echo "          volumeMounts:"
echo "          - name: www"
echo "            mountPath: /usr/share/nginx/html"
echo "    volumeClaimTemplates:"
echo "    - metadata:"
echo "        name: www"
echo "      spec:"
echo "        accessModes: [ \"ReadWriteOnce\" ]"
echo "        resources:"
echo "          requests:"
echo "            storage: 1Gi"
echo ""

# Show detailed info if resources exist
if kubectl get statefulset web &> /dev/null; then
    echo "StatefulSet Details:"
    echo ""
    kubectl describe statefulset web | head -30
    echo ""
fi

echo "💡 Remember:"
echo "  1. Create Service BEFORE StatefulSet"
echo "  2. Service must be headless (clusterIP: None)"
echo "  3. Pods created sequentially: web-0, then web-1"
echo "  4. PVCs named: www-web-0, www-web-1"
echo ""

exit 0
