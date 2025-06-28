#!/bin/bash

echo "🚀 Deploying Security & RBAC Demo..."

# Apply RBAC configuration
echo "🔐 Setting up RBAC..."
kubectl apply -f rbac/

# Apply security policies
echo "🛡️ Setting up security policies..."
kubectl apply -f security/

# Apply application manifests
echo "📦 Deploying secure application..."
kubectl apply -f manifests/

# Wait for pod to be ready
echo "⏳ Waiting for secure application to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod/secure-web-app -n secure-app

# Get deployment status
echo "📋 Deployment Status:"
kubectl get all -n secure-app

# Test RBAC permissions
echo "🔍 Testing RBAC permissions..."
echo "Testing developer user permissions:"
kubectl auth can-i get pods --as=system:serviceaccount:secure-app:developer-sa -n secure-app
kubectl auth can-i create deployments --as=system:serviceaccount:secure-app:developer-sa -n secure-app
kubectl auth can-i delete secrets --as=system:serviceaccount:secure-app:developer-sa -n secure-app

echo "Testing viewer user permissions:"
kubectl auth can-i get pods --as=system:serviceaccount:secure-app:viewer-sa -n secure-app
kubectl auth can-i create pods --as=system:serviceaccount:secure-app:viewer-sa -n secure-app

# Test pod security
echo "🔒 Testing pod security context..."
kubectl exec -n secure-app secure-web-app -- id
kubectl exec -n secure-app secure-web-app -- ls -la /

echo "✅ Security & RBAC demo deployed successfully!"
echo ""
echo "🌐 Access the secure application:"
echo "   kubectl port-forward service/secure-web-service 8080:80 -n secure-app"
