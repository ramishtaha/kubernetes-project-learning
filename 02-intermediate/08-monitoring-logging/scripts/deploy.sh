#!/bin/bash

echo "🚀 Deploying Monitoring & Logging Stack..."

# Create monitoring namespace if it doesn't exist
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Apply all monitoring manifests
kubectl apply -f manifests/ -n monitoring

# Apply logging manifests
kubectl apply -f logging/ -n monitoring

# Wait for deployments to be ready
echo "⏳ Waiting for monitoring stack to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
kubectl wait --for=condition=available --timeout=300s daemonset/fluentd -n monitoring

# Get service information
echo "📋 Service Information:"
kubectl get services -n monitoring

# Get pod status
echo "📦 Pod Status:"
kubectl get pods -n monitoring

echo "✅ Monitoring & Logging stack deployed successfully!"
echo ""
echo "📊 Access monitoring services:"
echo "   Prometheus: kubectl port-forward service/prometheus-service 9090:9090 -n monitoring"
echo "   Grafana: kubectl port-forward service/grafana-service 3000:3000 -n monitoring"
echo ""
echo "🔍 Default Grafana credentials:"
echo "   Username: admin"
echo "   Password: admin"
