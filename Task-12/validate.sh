#!/bin/bash

# Validation script for Task 12: Kustomize - Production Variants
# This script checks if production overlay has been configured correctly

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 12: Kustomize - Production Deployment"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=20

# Check 1: Production kustomization.yaml exists (3 points)
echo "Check 1: Does production kustomization.yaml exist?"
KUSTOMIZE_FILE="/home/student/kustomize/overlays/production/kustomization.yaml"

if [ -f "$KUSTOMIZE_FILE" ]; then
    echo "✓ Production kustomization.yaml exists (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Production kustomization.yaml not found"
    echo "  Expected: $KUSTOMIZE_FILE"
    echo ""
    echo "Create with:"
    echo "  mkdir -p /home/student/kustomize/overlays/production"
    echo "  cat > $KUSTOMIZE_FILE << 'EOF'"
    echo "  apiVersion: kustomize.config.k8s.io/v1beta1"
    echo "  kind: Kustomization"
    echo "  resources:"
    echo "  - ../../base"
    echo "  namePrefix: prod-"
    echo "  commonLabels:"
    echo "    environment: production"
    echo "  images:"
    echo "  - name: nginx"
    echo "    newTag: \"1.21\""
    echo "  EOF"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: namePrefix configured (3 points)
echo "Check 2: Is namePrefix configured?"
if grep -q "namePrefix.*prod-" "$KUSTOMIZE_FILE"; then
    echo "✓ namePrefix configured correctly (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ namePrefix not found or incorrect"
    echo "  Expected: namePrefix: prod-"
fi

# Check 3: commonLabels configured (4 points)
echo "Check 3: Are commonLabels configured?"
if grep -A 1 "commonLabels" "$KUSTOMIZE_FILE" | grep -q "environment.*production"; then
    echo "✓ commonLabels configured correctly (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ commonLabels not found or incorrect"
    echo "  Expected:"
    echo "    commonLabels:"
    echo "      environment: production"
fi

# Check 4: Image tag updated to 1.21 (4 points)
echo "Check 4: Is image tag updated to 1.21?"
if grep -A 2 "images:" "$KUSTOMIZE_FILE" | grep -q 'newTag.*"1.21"'; then
    echo "✓ Image tag updated to 1.21 (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
elif grep -A 2 "images:" "$KUSTOMIZE_FILE" | grep -q "newTag.*1.21"; then
    echo "✓ Image tag updated to 1.21 (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ Image tag not updated correctly"
    echo "  Expected:"
    echo "    images:"
    echo "    - name: nginx"
    echo "      newTag: \"1.21\""
fi

# Check 5: Deployment exists with correct name (3 points)
echo ""
echo "Check 5: Does deployment exist with correct name?"
if kubectl get deployment prod-nginx-app &>/dev/null; then
    echo "✓ Deployment 'prod-nginx-app' exists (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Deployment 'prod-nginx-app' not found"
    echo "  Apply with: kubectl apply -k overlays/production/"
fi

# Check 6: Resources running (3 points)
echo "Check 6: Are resources running?"
if kubectl get deployment prod-nginx-app &>/dev/null; then
    READY=$(kubectl get deployment prod-nginx-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    DESIRED=$(kubectl get deployment prod-nginx-app -o jsonpath='{.spec.replicas}' 2>/dev/null)
    
    if [ "$READY" == "$DESIRED" ] && [ "$READY" -ge 1 ]; then
        echo "✓ Resources running ($READY/$DESIRED replicas ready) (3 points)"
        TOTAL_POINTS=$((TOTAL_POINTS + 3))
    else
        echo "⚠ Resources not fully ready ($READY/$DESIRED replicas)"
        echo "  Wait for pods to be ready"
    fi
else
    echo "✗ Deployment not found"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VALIDATION RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Score: $TOTAL_POINTS / $MAX_POINTS"
echo ""

if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 PERFECT SCORE! Excellent Kustomize configuration!"
    echo ""
    echo "✓ Production kustomization.yaml exists"
    echo "✓ namePrefix configured"
    echo "✓ commonLabels configured"
    echo "✓ Image tag updated to 1.21"
    echo "✓ Deployment exists and running"
    echo ""
elif [ $TOTAL_POINTS -ge 14 ]; then
    echo "✅ PASSED! Kustomize overlay configured correctly!"
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

# Show current configuration
if [ -f "$KUSTOMIZE_FILE" ]; then
    echo "Current Production Kustomization:"
    echo ""
    cat "$KUSTOMIZE_FILE"
    echo ""
fi

# Show resources
echo "Deployed Resources:"
echo ""
echo "Deployments:"
kubectl get deployment prod-nginx-app 2>/dev/null || echo "  prod-nginx-app not found"
echo ""
echo "Services:"
kubectl get service prod-nginx-service 2>/dev/null || echo "  prod-nginx-service not found"
echo ""

# Show labels
if kubectl get deployment prod-nginx-app &>/dev/null; then
    echo "Resource Labels (prod-nginx-app):"
    kubectl get deployment prod-nginx-app -o jsonpath='{.metadata.labels}' 2>/dev/null | grep -o '"[^"]*"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)"/  \1: \2/'
    echo ""
    echo ""
fi

# Show image
if kubectl get deployment prod-nginx-app &>/dev/null; then
    echo "Container Image:"
    IMAGE=$(kubectl get deployment prod-nginx-app -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    echo "  $IMAGE"
    
    if echo "$IMAGE" | grep -q "1.21"; then
        echo "  ✓ Correct version (1.21)"
    else
        echo "  ✗ Wrong version (expected 1.21)"
    fi
    echo ""
fi

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if [ ! -f "$KUSTOMIZE_FILE" ]; then
        echo "Kustomization file missing:"
        echo "  mkdir -p /home/student/kustomize/overlays/production"
        echo "  Create kustomization.yaml in that directory"
        echo ""
    fi
    
    if ! grep -q "namePrefix.*prod-" "$KUSTOMIZE_FILE" 2>/dev/null; then
        echo "namePrefix not configured:"
        echo "  Add to kustomization.yaml:"
        echo "    namePrefix: prod-"
        echo ""
    fi
    
    if ! grep -A 1 "commonLabels" "$KUSTOMIZE_FILE" 2>/dev/null | grep -q "environment.*production"; then
        echo "commonLabels not configured:"
        echo "  Add to kustomization.yaml:"
        echo "    commonLabels:"
        echo "      environment: production"
        echo ""
    fi
    
    if ! grep -A 2 "images:" "$KUSTOMIZE_FILE" 2>/dev/null | grep -q "newTag.*1.21"; then
        echo "Image tag not updated:"
        echo "  Add to kustomization.yaml:"
        echo "    images:"
        echo "    - name: nginx"
        echo "      newTag: \"1.21\""
        echo ""
    fi
    
    if ! kubectl get deployment prod-nginx-app &>/dev/null; then
        echo "Resources not deployed:"
        echo "  kubectl apply -k /home/student/kustomize/overlays/production/"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl kustomize /home/student/kustomize/overlays/production/"
    echo "  kubectl apply -k /home/student/kustomize/overlays/production/"
    echo "  kubectl get deployment prod-nginx-app"
    echo "  kubectl get all -l environment=production"
    echo ""
fi

echo "💡 Complete Solution:"
echo ""
echo "# Create overlay directory"
echo "mkdir -p /home/student/kustomize/overlays/production"
echo ""
echo "# Create kustomization.yaml"
echo "cat > /home/student/kustomize/overlays/production/kustomization.yaml << 'EOF'"
echo "apiVersion: kustomize.config.k8s.io/v1beta1"
echo "kind: Kustomization"
echo ""
echo "resources:"
echo "- ../../base"
echo ""
echo "namePrefix: prod-"
echo ""
echo "commonLabels:"
echo "  environment: production"
echo ""
echo "images:"
echo "- name: nginx"
echo "  newTag: \"1.21\""
echo "EOF"
echo ""
echo "# Apply"
echo "kubectl apply -k /home/student/kustomize/overlays/production/"
echo ""
echo "# Verify"
echo "kubectl get deployment prod-nginx-app"
echo "kubectl get service prod-nginx-service"
echo "kubectl get all -l environment=production"
echo ""

exit 0
