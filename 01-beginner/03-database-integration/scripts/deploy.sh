#!/bin/bash

echo "🚀 Deploying Database Integration Application..."

# Create namespace if it doesn't exist
kubectl create namespace database-app --dry-run=client -o yaml | kubectl apply -f -

# Apply all manifests
kubectl apply -f manifests/ -n database-app

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/web-app -n database-app

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod -l app=postgres -n database-app

# Get service information
echo "📋 Service Information:"
kubectl get services -n database-app

# Get pod status
echo "📦 Pod Status:"
kubectl get pods -n database-app

# Test database connection
echo "🔍 Testing database connection..."
kubectl exec -n database-app deployment/web-app -- curl -s http://localhost:3000/health || echo "Health check endpoint not available"

echo "✅ Database integration application deployed successfully!"
echo "🌐 Access the application using:"
echo "   kubectl port-forward service/web-app-service 3000:3000 -n database-app"
