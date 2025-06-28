#!/bin/bash

echo "🚀 Deploying Health Probe Demo Application..."
echo "=============================================="

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster is not accessible"
    echo "Please ensure your cluster is running and kubectl is configured"
    exit 1
fi

print_success "Kubernetes cluster is accessible"

# Apply manifests in order
print_status "Creating namespace and configuration..."
kubectl apply -f manifests/00-namespace-config.yaml

print_status "Deploying the application..."
kubectl apply -f manifests/01-deployment.yaml

print_status "Creating services..."
kubectl apply -f manifests/02-service.yaml

print_status "Waiting for namespace to be active..."
kubectl wait --for=condition=Active namespace/health-demo --timeout=30s

print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/health-demo -n health-demo

# Get deployment status
echo ""
echo "📋 Deployment Status:"
echo "===================="
kubectl get all -n health-demo

echo ""
echo "🔍 Pod Details:"
echo "==============="
kubectl get pods -n health-demo -o wide

echo ""
echo "📊 Probe Status:"
echo "================"
POD_NAME=$(kubectl get pods -n health-demo -l app=health-demo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ ! -z "$POD_NAME" ]; then
    echo "Checking probe status for pod: $POD_NAME"
    kubectl describe pod $POD_NAME -n health-demo | grep -A 10 -B 2 "Probe"
else
    print_warning "No pods found yet, they may still be starting"
fi

echo ""
echo "✅ Health Probe Demo Application deployed successfully!"
echo ""
echo "🌐 Access the application:"
echo "========================="
echo "1. Port-forward to access via localhost:"
echo "   kubectl port-forward service/health-app-service 8080:80 -n health-demo"
echo "   Then visit: http://localhost:8080"
echo ""
echo "2. Or access via NodePort (if supported):"
echo "   minikube service health-app-nodeport -n health-demo"
echo "   Or visit: http://<node-ip>:30080"
echo ""
echo "🔍 Monitoring Commands:"
echo "======================"
echo "• Watch pod status: kubectl get pods -n health-demo -w"
echo "• View probe details: kubectl describe pod <pod-name> -n health-demo"
echo "• Check events: kubectl get events -n health-demo --sort-by='.lastTimestamp'"
echo "• View logs: kubectl logs <pod-name> -n health-demo -c health-demo"
echo ""
echo "🧪 Testing Commands:"
echo "==================="
echo "• Test health endpoint: kubectl exec <pod-name> -n health-demo -- curl -f http://localhost/health"
echo "• Test readiness: kubectl exec <pod-name> -n health-demo -- curl -f http://localhost/ready"
echo "• Simulate failure: kubectl exec <pod-name> -n health-demo -- rm -f /shared/healthy"
echo ""
echo "🎯 Learning Objectives:"
echo "======================"
echo "• Observe startup probe behavior during pod initialization"
echo "• Monitor liveness probe preventing traffic to unhealthy pods"
echo "• Test readiness probe removing pods from service endpoints"
echo "• Understand different probe mechanisms (exec, HTTP, TCP)"

# Check if minikube is being used
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo ""
    print_status "Detected minikube environment"
    echo "💡 Quick access command: minikube service health-app-nodeport -n health-demo"
fi

echo ""
echo "📚 Next steps: Follow the README.md for detailed learning exercises!"
