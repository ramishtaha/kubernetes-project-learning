#!/bin/bash

echo "🚀 Deploying WebApp Operator..."

# Create namespace
kubectl apply -f manifests/01-namespace.yaml

# Install CRD
kubectl apply -f crds/webapp-crd.yaml

# Setup RBAC
kubectl apply -f manifests/02-rbac.yaml

# Deploy operator configuration
kubectl apply -f manifests/03-config.yaml

# Deploy the operator
kubectl apply -f operator/operator-deployment.yaml

echo "Waiting for operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/webapp-operator -n webapp-operator-system

echo "✅ WebApp Operator deployed successfully!"
echo ""
echo "📋 Access the operator dashboard:"
echo "kubectl port-forward -n webapp-operator-system svc/webapp-operator-metrics 8080:8080"
echo "Then visit: http://localhost:8080"
echo ""
echo "🧪 Try creating WebApp resources:"
echo "kubectl apply -f samples/sample-webapps.yaml"
echo ""
echo "🔍 Monitor WebApp resources:"
echo "kubectl get webapps"
echo "kubectl describe webapp sample-frontend"
echo ""
echo "📊 Check operator logs:"
echo "kubectl logs -n webapp-operator-system deployment/webapp-operator"
echo ""
echo "📝 Available commands:"
echo "kubectl get wa                    # List WebApps (short name)"
echo "kubectl get webapp -o wide        # Detailed WebApp list"
echo "kubectl describe webapp <name>    # WebApp details"
echo "kubectl delete webapp <name>      # Delete WebApp"
