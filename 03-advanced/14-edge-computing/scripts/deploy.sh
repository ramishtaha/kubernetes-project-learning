#!/bin/bash

echo "🚀 Deploying Edge Computing Demo..."

# Create namespace
kubectl apply -f manifests/01-namespace.yaml

# Deploy configurations
kubectl apply -f manifests/02-configs.yaml

# Deploy IoT workloads
kubectl apply -f edge-apps/iot-workloads.yaml

# Deploy edge agent
kubectl apply -f edge-apps/edge-agent.yaml

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mqtt-broker -n edge-computing
kubectl wait --for=condition=available --timeout=300s deployment/iot-data-processor -n edge-computing

echo "✅ Edge Computing deployment complete!"
echo ""
echo "📋 Access edge services:"
echo "# Edge Agent Dashboard"
echo "kubectl port-forward -n edge-computing svc/edge-agent-service 8080:80"
echo ""
echo "# MQTT Broker"
echo "kubectl port-forward -n edge-computing svc/mqtt-broker-service 1883:1883"
echo ""
echo "🔍 Monitor edge workloads:"
echo "kubectl get all -n edge-computing"
echo "kubectl get daemonset -n edge-computing"
echo ""
echo "📊 Check IoT data processing:"
echo "kubectl logs -n edge-computing deployment/iot-data-processor"
echo ""
echo "🌐 For real edge deployment:"
echo "1. Install K3s on edge nodes: ./k3s-setup/install-k3s.sh"
echo "2. Configure edge-specific labels and taints"
echo "3. Deploy edge-optimized workloads"
