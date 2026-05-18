#!/bin/bash

# Validation script for Task 6: Pod Security Standards
# This script checks if the namespace is properly configured with PSS

echo "════════════════════════════════════════════════════════════════"
echo "  Validating Task 6: Pod Security Standards"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Initialize scoring
TOTAL_POINTS=0
MAX_POINTS=18

# Check 1: Namespace exists (prerequisite, no points)
echo "Check 1: Does the namespace exist?"
if kubectl get namespace restricted-ns &> /dev/null; then
    echo "✓ Namespace 'restricted-ns' exists"
else
    echo "✗ Namespace 'restricted-ns' not found"
    echo ""
    echo "Run ./LabSetUp.bash to create the namespace"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 2: Namespace has PSS label (4 points)
echo "Check 2: Does the namespace have a Pod Security Standard label?"
PSS_LABELS=$(kubectl get namespace restricted-ns -o jsonpath='{.metadata.labels}' | grep -o "pod-security.kubernetes.io" | wc -l | tr -d ' ')

if [ "$PSS_LABELS" -gt 0 ]; then
    echo "✓ Namespace has Pod Security Standard label(s) (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
else
    echo "✗ Namespace does not have Pod Security Standard labels"
    echo ""
    echo "Add label with:"
    echo "  kubectl label namespace restricted-ns pod-security.kubernetes.io/enforce=restricted"
    echo ""
    echo "TOTAL SCORE: $TOTAL_POINTS/$MAX_POINTS"
    exit 1
fi

# Check 3: Enforce mode configured (3 points)
echo "Check 3: Is enforce mode configured?"
ENFORCE_LABEL=$(kubectl get namespace restricted-ns -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)

if [ -n "$ENFORCE_LABEL" ]; then
    echo "✓ Enforce mode is configured: $ENFORCE_LABEL (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
else
    echo "✗ Enforce mode not configured"
    echo "  Expected label: pod-security.kubernetes.io/enforce"
fi

# Check 4: Restricted level set (4 points)
echo "Check 4: Is the Restricted level set?"
if [ "$ENFORCE_LABEL" == "restricted" ]; then
    echo "✓ Restricted level is set (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
elif [ "$ENFORCE_LABEL" == "baseline" ]; then
    echo "✗ Baseline level is set (expected: restricted)"
    echo "  Baseline is less strict than required"
elif [ "$ENFORCE_LABEL" == "privileged" ]; then
    echo "✗ Privileged level is set (expected: restricted)"
    echo "  Privileged allows everything - not secure"
else
    echo "✗ Level is: '$ENFORCE_LABEL' (expected: restricted)"
fi

# Check 5: Privileged pod is rejected (4 points)
echo "Check 5: Are privileged pods rejected?"
echo "  Testing by attempting to create a privileged pod..."

PRIV_TEST_OUTPUT=$(kubectl run validation-priv-test \
  --image=nginx \
  --privileged \
  -n restricted-ns 2>&1)

if echo "$PRIV_TEST_OUTPUT" | grep -qi "forbidden\|violates"; then
    echo "✓ Privileged pod was rejected (4 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 4))
    echo "  Rejection message: $(echo "$PRIV_TEST_OUTPUT" | head -1)"
    
    # Clean up if it somehow got created
    kubectl delete pod validation-priv-test -n restricted-ns --force --grace-period=0 &>/dev/null
else
    echo "✗ Privileged pod was NOT rejected"
    echo "  This indicates PSS is not enforcing correctly"
    echo "  Output: $PRIV_TEST_OUTPUT"
    
    # Clean up the pod
    kubectl delete pod validation-priv-test -n restricted-ns --force --grace-period=0 &>/dev/null
fi

# Check 6: Restricted/compliant pod can be created (3 points)
echo "Check 6: Can a compliant pod be created?"
echo "  Testing by creating a restricted-compliant pod..."

# Create a compliant pod
COMPLIANT_TEST=$(cat <<EOF | kubectl apply -f - 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: validation-compliant-test
  namespace: restricted-ns
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      runAsNonRoot: true
      runAsUser: 1000
EOF
)

if echo "$COMPLIANT_TEST" | grep -qi "created\|configured"; then
    echo "✓ Compliant pod was created successfully (3 points)"
    TOTAL_POINTS=$((TOTAL_POINTS + 3))
    
    # Clean up
    kubectl delete pod validation-compliant-test -n restricted-ns --force --grace-period=0 &>/dev/null
else
    echo "⚠ Compliant pod was rejected"
    echo "  This might indicate an issue with the pod configuration"
    echo "  Or PSS is too strict (shouldn't happen with 'restricted')"
    echo "  Output: $COMPLIANT_TEST"
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
    echo "✓ Pod Security Standard labels configured"
    echo "✓ Enforce mode enabled"
    echo "✓ Restricted level set"
    echo "✓ Privileged pods blocked"
    echo "✓ Compliant pods allowed"
    echo ""
elif [ $TOTAL_POINTS -ge 13 ]; then
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
echo "Namespace Configuration:"
echo ""
kubectl describe namespace restricted-ns | grep -A 5 "Labels:" || kubectl get namespace restricted-ns --show-labels
echo ""

echo "Pod Security Standard Labels:"
echo ""
kubectl get namespace restricted-ns -o jsonpath='{.metadata.labels}' | grep -o "pod-security[^,]*" | sed 's/:/: /g' || echo "  No PSS labels found"
echo ""
echo ""

# Show all PSS-related labels
echo "All PSS Labels on Namespace:"
kubectl get namespace restricted-ns -o json | jq -r '.metadata.labels | to_entries[] | select(.key | contains("pod-security")) | "\(.key): \(.value)"' 2>/dev/null || echo "  (jq not available, use kubectl describe)"
echo ""

# Additional guidance
if [ $TOTAL_POINTS -lt $MAX_POINTS ]; then
    echo "💡 TROUBLESHOOTING TIPS:"
    echo ""
    
    if [ -z "$ENFORCE_LABEL" ]; then
        echo "No enforce label found:"
        echo "  kubectl label namespace restricted-ns \\"
        echo "    pod-security.kubernetes.io/enforce=restricted"
        echo ""
    elif [ "$ENFORCE_LABEL" != "restricted" ]; then
        echo "Wrong security level:"
        echo "  Current: $ENFORCE_LABEL"
        echo "  Expected: restricted"
        echo ""
        echo "  Fix with:"
        echo "  kubectl label namespace restricted-ns \\"
        echo "    pod-security.kubernetes.io/enforce=restricted --overwrite"
        echo ""
    fi
    
    echo "Verification commands:"
    echo "  kubectl get namespace restricted-ns --show-labels"
    echo "  kubectl describe namespace restricted-ns"
    echo ""
    echo "Test privileged rejection:"
    echo "  kubectl run test --image=nginx --privileged -n restricted-ns"
    echo "  # Should be rejected with 'forbidden' error"
    echo ""
fi

echo "💡 Quick Reference:"
echo ""
echo "Correct label:"
echo "  kubectl label namespace restricted-ns \\"
echo "    pod-security.kubernetes.io/enforce=restricted"
echo ""
echo "Verify:"
echo "  kubectl get ns restricted-ns --show-labels | grep pod-security"
echo ""
echo "Test (should fail):"
echo "  kubectl run test --image=nginx --privileged -n restricted-ns"
echo ""
echo "Expected error message:"
echo "  'Error from server (Forbidden): pods \"test\" is forbidden:"
echo "   violates PodSecurity \"restricted:latest\": privileged'"
echo ""

# Show example of properly labeled namespace
echo "Example of correctly configured namespace:"
echo ""
echo "apiVersion: v1"
echo "kind: Namespace"
echo "metadata:"
echo "  name: restricted-ns"
echo "  labels:"
echo "    pod-security.kubernetes.io/enforce: restricted"
echo ""

exit 0
