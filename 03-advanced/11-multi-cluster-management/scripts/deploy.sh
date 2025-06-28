#!/bin/bash

echo "🚀 Setting up Multi-Cluster Management Demo..."

# Create namespace
kubectl apply -f manifests/01-namespace.yaml

# Setup RBAC
kubectl apply -f manifests/04-rbac.yaml

# Create cluster secrets (demo - replace with real kubeconfigs)
kubectl apply -f manifests/02-cluster-secrets.yaml

# Deploy configuration
kubectl apply -f manifests/05-config.yaml

# Deploy multi-cluster controller
kubectl apply -f manifests/03-controller.yaml

echo "Waiting for controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/multi-cluster-controller -n multi-cluster

echo "✅ Multi-cluster management setup complete!"
echo ""
echo "📋 Access the dashboard:"
echo "kubectl port-forward -n multi-cluster svc/multi-cluster-controller 8080:80"
echo "Then visit: http://localhost:8080"
echo ""
echo "🔍 Explore multi-cluster resources:"
echo "kubectl get all -n multi-cluster"
echo "kubectl get secrets -n multi-cluster"
echo ""
echo "📝 Next steps for real multi-cluster setup:"
echo "1. Install Cluster API: kubectl apply -f https://github.com/kubernetes-sigs/cluster-api/releases/latest/download/cluster-api-components.yaml"
echo "2. Install cloud provider (AWS): clusterctl init --infrastructure aws"
echo "3. Create workload clusters: kubectl apply -f cluster-api/"
echo "4. Install ArgoCD for GitOps: kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
echo "5. Setup cross-cluster networking with Submariner or Istio"
