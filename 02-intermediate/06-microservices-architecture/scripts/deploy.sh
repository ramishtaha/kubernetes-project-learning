#!/bin/bash

echo "🚀 Deploying Microservices Architecture Demo..."

# Apply manifests in order
echo "Creating namespace..."
kubectl apply -f manifests/01-namespace.yaml

echo "Creating service configurations..."
kubectl apply -f manifests/07-frontend-configs.yaml
kubectl apply -f manifests/08-service-configs.yaml

echo "Creating backend services..."
kubectl apply -f manifests/04-user-service.yaml
kubectl apply -f manifests/05-order-service.yaml
kubectl apply -f manifests/06-product-service.yaml

echo "Creating API gateway..."
kubectl apply -f manifests/03-api-gateway.yaml

echo "Creating frontend..."
kubectl apply -f manifests/02-frontend.yaml

echo "Creating ingress..."
kubectl apply -f manifests/09-ingress.yaml

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/user-service -n microservices
kubectl wait --for=condition=available --timeout=300s deployment/order-service -n microservices
kubectl wait --for=condition=available --timeout=300s deployment/product-service -n microservices
kubectl wait --for=condition=available --timeout=300s deployment/api-gateway -n microservices
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n microservices

echo "✅ Deployment complete!"
echo ""
echo "📋 Access the application:"
echo "kubectl port-forward -n microservices svc/frontend-service 8080:80"
echo "Then visit: http://localhost:8080"
echo ""
echo "🔍 Check microservices:"
echo "kubectl get all -n microservices"
echo "kubectl get ingress -n microservices"
echo ""
echo "🧪 Test individual services:"
echo "kubectl port-forward -n microservices svc/api-service 8081:8080"
echo "kubectl port-forward -n microservices svc/user-service 8082:8080"
