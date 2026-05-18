#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 13: Gateway API - HTTP Routing"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verify kubectl is working
echo "Verifying cluster connectivity..."
if kubectl get nodes &> /dev/null; then
    echo "✓ kubectl is working"
else
    echo "✗ kubectl is not working properly"
    exit 1
fi

# Create web-service and deployment for testing
echo ""
echo "Creating web-service for testing..."

# Create a simple nginx deployment
kubectl create deployment web-app --image=nginx:latest --port=80 2>/dev/null || echo "  Deployment might already exist"

# Wait a moment for deployment
sleep 2

# Expose as service
kubectl expose deployment web-app --name=web-service --port=80 --target-port=80 2>/dev/null || echo "  Service might already exist"

# Check service
echo ""
echo "Checking web-service..."
if kubectl get service web-service &> /dev/null; then
    echo "✓ web-service exists in default namespace"
    kubectl get service web-service
else
    echo "⚠ web-service not found"
fi

# Create GatewayClass
echo ""
echo "Creating GatewayClass (example-gw-class)..."
cat <<EOF | kubectl apply -f - 2>/dev/null
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: example-gw-class
spec:
  controllerName: example.com/gateway-controller
EOF

# Check GatewayClass
if kubectl get gatewayclass example-gw-class &> /dev/null; then
    echo "✓ GatewayClass 'example-gw-class' created"
else
    echo "⚠ GatewayClass creation may have failed"
fi

# Clean up any previous Gateway API resources
echo ""
echo "Cleaning up any previous Gateway API resources..."
kubectl delete httproute web-route 2>/dev/null || true
kubectl delete gateway web-gateway 2>/dev/null || true
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ web-service created (nginx on port 80)"
echo "✓ GatewayClass 'example-gw-class' available"
echo ""
echo "Current resources:"
echo ""
kubectl get service web-service 2>/dev/null || echo "  web-service not found"
echo ""
kubectl get gatewayclass example-gw-class 2>/dev/null || echo "  GatewayClass not found"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Create Gateway resource"
echo "  3. Create HTTPRoute resource"
echo "  4. Route hostname web.example.com to web-service"
echo "  5. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Gateway API uses Gateway + HTTPRoute resources"
echo ""
echo "Good luck! 🚀"
echo ""
