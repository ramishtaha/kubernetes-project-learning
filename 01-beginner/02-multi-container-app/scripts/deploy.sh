#!/bin/bash

echo "🚀 Deploying Multi-Container Application..."

# Create namespace if it doesn't exist
kubectl create namespace multi-container-app --dry-run=client -o yaml | kubectl apply -f -

# Apply all manifests
kubectl apply -f manifests/ -n multi-container-app

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n multi-container-app
kubectl wait --for=condition=available --timeout=300s deployment/backend -n multi-container-app
kubectl wait --for=condition=available --timeout=300s deployment/cache -n multi-container-app

# Get service information
echo "📋 Service Information:"
kubectl get services -n multi-container-app

# Get pod status
echo "📦 Pod Status:"
kubectl get pods -n multi-container-app

echo "✅ Multi-container application deployed successfully!"
echo "🌐 Access the frontend service using:"
echo "   kubectl port-forward service/frontend-service 8080:80 -n multi-container-app"
