#!/bin/bash

echo "🚀 Deploying Configuration Management Demo..."

# Apply manifests in order
echo "Creating namespace..."
kubectl apply -f manifests/01-namespace.yaml

echo "Creating secrets..."
kubectl apply -f manifests/02-secrets.yaml

echo "Creating configmaps..."
kubectl apply -f manifests/03-configmap.yaml
kubectl apply -f manifests/05-html-config.yaml

echo "Creating deployment..."
kubectl apply -f manifests/04-deployment.yaml

echo "Creating service..."
kubectl apply -f manifests/06-service.yaml

echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/config-app -n config-management

echo "✅ Deployment complete!"
echo ""
echo "📋 Access the application:"
echo "kubectl port-forward -n config-management svc/config-service 8080:80"
echo "Then visit: http://localhost:8080"
echo ""
echo "🔍 Explore configuration:"
echo "kubectl get configmaps -n config-management"
echo "kubectl get secrets -n config-management"
echo "kubectl describe pod -l app=config-demo -n config-management"
echo ""
echo "🧪 Test configuration changes:"
echo "kubectl edit configmap app-config -n config-management"
