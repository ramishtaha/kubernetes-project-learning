#!/bin/bash

# Security Hardening Deployment Script
# This script deploys all security hardening components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to wait for resources to be ready
wait_for_pods() {
    local namespace=$1
    local label_selector=$2
    local timeout=${3:-300}
    
    print_status "Waiting for pods in namespace '$namespace' with selector '$label_selector' to be ready..."
    kubectl wait --for=condition=Ready pods -l "$label_selector" -n "$namespace" --timeout="${timeout}s" || {
        print_error "Pods did not become ready within timeout"
        return 1
    }
}

# Function to check if Kyverno is installed
check_kyverno() {
    if kubectl get namespace kyverno >/dev/null 2>&1; then
        print_success "Kyverno namespace found"
        return 0
    else
        print_warning "Kyverno not found. Please install Kyverno first using ./scripts/setup-kyverno.sh"
        return 1
    fi
}

# Main deployment function
deploy_security_hardening() {
    print_status "Starting security hardening deployment..."
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # Check if Kyverno is installed
    if ! check_kyverno; then
        read -p "Would you like to install Kyverno now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./scripts/setup-kyverno.sh
        else
            print_error "Kyverno is required for this deployment. Exiting."
            exit 1
        fi
    fi
    
    print_status "Prerequisites check completed"
    
    # Deploy namespace and RBAC
    print_status "Creating secure namespace and RBAC..."
    kubectl apply -f manifests/01-namespace.yaml
    print_success "Namespace and RBAC configured"
    
    # Deploy resource quotas and limits
    print_status "Applying resource quotas and limits..."
    kubectl apply -f manifests/06-resource-quota.yaml
    print_success "Resource management configured"
    
    # Deploy network policies
    print_status "Configuring network security..."
    kubectl apply -f manifests/02-network-policy.yaml
    print_success "Network policies applied"
    
    # Deploy Pod Disruption Budgets
    print_status "Configuring application resilience..."
    kubectl apply -f manifests/03-pod-disruption-budget.yaml
    print_success "Pod Disruption Budgets configured"
    
    # Deploy Kyverno policies
    print_status "Applying Kyverno security policies..."
    kubectl apply -f policies/kyverno-cluster-policy.yaml
    
    # Wait for policies to be ready
    sleep 5
    kubectl wait --for=condition=Ready clusterpolicy --all --timeout=60s
    print_success "Kyverno policies applied and ready"
    
    # Apply Pod Security Standards
    print_status "Configuring Pod Security Standards..."
    kubectl apply -f policies/pod-security-standards.yaml
    print_success "Pod Security Standards configured"
    
    # Apply image security policies
    print_status "Applying image security policies..."
    kubectl apply -f policies/image-security-policy.yaml
    print_success "Image security policies applied"
    
    # Create some sample configuration resources
    print_status "Creating sample configuration resources..."
    
    # Create ConfigMap for application
    kubectl create configmap app-config \
        --from-literal=APP_ENV=production \
        --from-literal=LOG_LEVEL=info \
        --from-literal=API_TIMEOUT=30 \
        -n secure-namespace \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Secret for application (in a real scenario, use proper secret management)
    kubectl create secret generic app-secret \
        --from-literal=api-key=secure-api-key-here \
        --from-literal=db-password=secure-db-password \
        -n secure-namespace \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Secret for database
    kubectl create secret generic db-secret \
        --from-literal=username=appuser \
        --from-literal=password=secure-database-password \
        -n secure-namespace \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create nginx configuration
    kubectl create configmap nginx-config \
        --from-literal=default.conf="server { listen 8080; location / { return 200 'Secure App Running'; } location /health { return 200 'OK'; } location /ready { return 200 'Ready'; } }" \
        -n secure-namespace \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Configuration resources created"
    
    # Display deployment summary
    print_status "Deployment Summary:"
    echo "=========================="
    kubectl get namespace secure-namespace -o custom-columns="NAME:.metadata.name,LABELS:.metadata.labels"
    echo ""
    
    print_status "Resource Quotas:"
    kubectl get resourcequota -n secure-namespace
    echo ""
    
    print_status "Network Policies:"
    kubectl get networkpolicy -n secure-namespace
    echo ""
    
    print_status "Pod Disruption Budgets:"
    kubectl get pdb -n secure-namespace
    echo ""
    
    print_status "Kyverno Cluster Policies:"
    kubectl get clusterpolicy
    echo ""
    
    print_success "Security hardening deployment completed successfully!"
    print_status "Next steps:"
    echo "1. Test the policies by running: ./scripts/test-policies.sh"
    echo "2. Deploy secure applications using: kubectl apply -f manifests/05-secure-pod.yaml"
    echo "3. Monitor policy violations with: kubectl get policyreport -A"
}

# Function to show help
show_help() {
    echo "Security Hardening Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo ""
    echo "This script deploys:"
    echo "  - Secure namespace with Pod Security Standards"
    echo "  - Network policies for micro-segmentation"
    echo "  - Resource quotas and limits"
    echo "  - Pod disruption budgets"
    echo "  - Kyverno security policies"
    echo "  - Image security policies"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run the deployment
deploy_security_hardening
