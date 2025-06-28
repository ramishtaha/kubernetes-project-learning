#!/bin/bash

echo "🧹 Cleaning up Health Probe Demo Application..."
echo "==============================================="

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Kubernetes cluster is not accessible"
    echo "Please ensure your cluster is running and kubectl is configured"
    exit 1
fi

print_success "Kubernetes cluster is accessible"

# Check if namespace exists
if ! kubectl get namespace health-demo &> /dev/null; then
    print_warning "Namespace 'health-demo' does not exist, nothing to clean up"
    exit 0
fi

print_status "Found health-demo namespace, proceeding with cleanup..."

# Show current resources before cleanup
echo ""
echo "📋 Current Resources in health-demo namespace:"
echo "=============================================="
kubectl get all -n health-demo

echo ""
print_status "Deleting services..."
kubectl delete service --all -n health-demo --ignore-not-found=true

print_status "Deleting deployments..."
kubectl delete deployment --all -n health-demo --ignore-not-found=true

print_status "Deleting configmaps..."
kubectl delete configmap --all -n health-demo --ignore-not-found=true

print_status "Deleting secrets..."
kubectl delete secret --all -n health-demo --ignore-not-found=true

print_status "Waiting for pods to terminate..."
kubectl wait --for=delete pods --all -n health-demo --timeout=60s 2>/dev/null || true

print_status "Deleting namespace..."
kubectl delete namespace health-demo --ignore-not-found=true

# Wait for namespace deletion
print_status "Waiting for namespace deletion to complete..."
timeout=60
counter=0
while kubectl get namespace health-demo &> /dev/null && [ $counter -lt $timeout ]; do
    echo -n "."
    sleep 1
    ((counter++))
done

echo ""

if kubectl get namespace health-demo &> /dev/null; then
    print_warning "Namespace deletion is taking longer than expected"
    print_status "You can check status with: kubectl get namespace health-demo"
else
    print_success "Namespace 'health-demo' has been deleted successfully"
fi

echo ""
echo "✅ Health Probe Demo cleanup completed!"
echo ""
echo "🔍 Verification:"
echo "==============="
echo "• Check remaining resources: kubectl get all -n health-demo"
echo "• Verify namespace deletion: kubectl get namespaces | grep health-demo"
echo ""
echo "📚 If you want to redeploy:"
echo "=========================="
echo "• Run: ./scripts/deploy.sh"
echo "• Or follow the step-by-step instructions in README.md"

# Final verification
if ! kubectl get namespace health-demo &> /dev/null; then
    echo ""
    print_success "✨ All health-demo resources have been successfully removed!"
else
    echo ""
    print_warning "⚠️  Some resources may still be cleaning up. Check with 'kubectl get all -n health-demo'"
fi
