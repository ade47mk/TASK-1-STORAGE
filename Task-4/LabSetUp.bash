#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 4: Horizontal Pod Autoscaling"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verify kubectl is working
echo "Verifying cluster connectivity..."
if kubectl get nodes &> /dev/null; then
    echo "✓ kubectl is working"
    kubectl get nodes
else
    echo "✗ kubectl is not working properly"
    exit 1
fi

# Check if Metrics Server is installed
echo ""
echo "Checking Metrics Server installation..."
if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    echo "✓ Metrics Server is installed"
    
    # Check if it's running
    READY=$(kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo "✓ Metrics Server is running"
    else
        echo "⚠ Metrics Server is installed but not ready"
        echo "  Waiting for Metrics Server to be ready..."
        kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system 2>/dev/null || echo "  Still starting up..."
    fi
else
    echo "⚠ Metrics Server not found"
    echo ""
    echo "  HPA requires Metrics Server to collect CPU/memory metrics."
    echo ""
    echo "  For Killercoda CKA playground, Metrics Server is usually pre-installed."
    echo "  If not, you can install it with:"
    echo ""
    echo "    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
    echo ""
    echo "  For local clusters (minikube, kind), enable it:"
    echo "    minikube addons enable metrics-server"
    echo ""
fi

# Clean up any existing resources
echo ""
echo "Cleaning up any previous attempts..."

# Delete HPA if exists
if kubectl get hpa cpu-demo-hpa 2>/dev/null; then
    echo "  Removing old HPA..."
    kubectl delete hpa cpu-demo-hpa 2>/dev/null
fi

# Delete deployment if exists
if kubectl get deployment cpu-demo 2>/dev/null; then
    echo "  Removing old deployment..."
    kubectl delete deployment cpu-demo 2>/dev/null
fi

# Wait for cleanup
sleep 3

# Create the cpu-demo deployment
echo ""
echo "Creating cpu-demo deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-demo
  labels:
    app: cpu-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-demo
  template:
    metadata:
      labels:
        app: cpu-demo
    spec:
      containers:
      - name: cpu-demo
        image: vish/stress
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "200m"
            memory: "100Mi"
        args:
        - "-cpus"
        - "2"
EOF

# Wait for deployment to be ready
echo ""
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/cpu-demo 2>/dev/null || echo "Still deploying..."
sleep 5

# Verify deployment
echo ""
if kubectl get deployment cpu-demo &> /dev/null; then
    echo "✓ Deployment 'cpu-demo' created successfully"
    kubectl get deployment cpu-demo
    echo ""
    kubectl get pods -l app=cpu-demo
else
    echo "✗ Failed to create deployment"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Metrics Server status checked"
echo "✓ Deployment 'cpu-demo' created (1 replica)"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Create HPA for cpu-demo deployment"
echo "  3. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Wait 1-2 minutes for metrics to be collected before creating HPA"
echo ""
echo "Good luck! 🚀"
echo ""
