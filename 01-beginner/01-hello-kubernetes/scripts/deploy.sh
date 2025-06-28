#!/bin/bash

# Project 1: Hello Kubernetes - Deployment Script
# This script automates the deployment process for the Hello Kubernetes project

set -e

echo "🚀 Starting Hello Kubernetes Deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
echo "🔍 Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "Please ensure your cluster is running and kubectl is configured correctly"
    exit 1
fi

echo "✅ Connected to cluster successfully"

# Deploy resources
echo "📦 Deploying resources..."

echo "  - Creating Pod..."
kubectl apply -f manifests/01-pod.yaml

echo "  - Creating Deployment..."
kubectl apply -f manifests/02-deployment.yaml

echo "  - Creating Service..."
kubectl apply -f manifests/03-service.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/hello-deployment --timeout=300s

# Show status
echo "📊 Current status:"
echo ""
echo "Pods:"
kubectl get pods -l app=hello-kubernetes

echo ""
echo "Deployment:"
kubectl get deployment hello-deployment

echo ""
echo "Service:"
kubectl get service hello-service

# Get access URL
echo ""
echo "🌐 Access your application:"

# Check if minikube is available
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "Minikube detected. Get the URL with:"
    echo "  minikube service hello-service --url"
    echo ""
    echo "Or run this command to open in browser:"
    echo "  minikube service hello-service"
else
    NODE_PORT=$(kubectl get service hello-service -o jsonpath='{.spec.ports[0].nodePort}')
    echo "Access via NodePort: http://<node-ip>:${NODE_PORT}"
    echo "Get node IP with: kubectl get nodes -o wide"
fi

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🔍 Useful commands to explore:"
echo "  kubectl get pods -l app=hello-kubernetes"
echo "  kubectl logs -l app=hello-kubernetes"
echo "  kubectl describe deployment hello-deployment"
echo "  kubectl describe service hello-service"
