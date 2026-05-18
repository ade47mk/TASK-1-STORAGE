#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  Setting up Task 12: Kustomize - Production Variants"
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

# Check if kustomize is available (built into kubectl)
echo ""
echo "Checking Kustomize availability..."
if kubectl kustomize --help &> /dev/null; then
    echo "✓ Kustomize is available (kubectl kustomize)"
else
    echo "⚠ Kustomize not available"
fi

# Create base directory structure
echo ""
echo "Creating base manifests directory..."
mkdir -p /home/student/kustomize/base
mkdir -p /home/student/kustomize/overlays/production

# Create base Deployment
echo ""
echo "Creating base Deployment manifest..."
cat > /home/student/kustomize/base/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
EOF

# Create base Service
echo "Creating base Service manifest..."
cat > /home/student/kustomize/base/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Create base kustomization.yaml
echo "Creating base kustomization.yaml..."
cat > /home/student/kustomize/base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml

commonLabels:
  app: nginx
EOF

# Clean up any previous deployments
echo ""
echo "Cleaning up any previous deployments..."
kubectl delete deployment prod-nginx-app 2>/dev/null || true
kubectl delete service prod-nginx-service 2>/dev/null || true
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ Cluster is ready"
echo "✓ Base manifests created at /home/student/kustomize/base/"
echo ""
echo "Base manifests:"
echo "  - deployment.yaml (nginx:1.19, 2 replicas)"
echo "  - service.yaml (ClusterIP)"
echo "  - kustomization.yaml"
echo ""
echo "Next steps:"
echo "  1. Read the question: cat Question.bash"
echo "  2. Create production overlay directory"
echo "  3. Create production kustomization.yaml with:"
echo "     - namePrefix: prod-"
echo "     - commonLabels: environment: production"
echo "     - images: nginx:1.21"
echo "  4. Apply with: kubectl apply -k overlays/production"
echo "  5. Validate your solution: ./validate.sh"
echo ""
echo "💡 TIP: Use kustomize overlays to customize base manifests"
echo ""
echo "Good luck! 🚀"
echo ""
