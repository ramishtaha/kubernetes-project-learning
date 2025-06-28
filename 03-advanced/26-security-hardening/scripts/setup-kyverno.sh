#!/bin/bash

# Kyverno Setup Script
# This script installs and configures Kyverno policy engine

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KYVERNO_VERSION="${KYVERNO_VERSION:-v1.10.5}"
KYVERNO_NAMESPACE="kyverno"

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl >/dev/null 2>&1; then
        print_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # Check cluster version
    local server_version=$(kubectl version -o json | jq -r '.serverVersion.major + "." + .serverVersion.minor' | tr -d '"')
    print_status "Kubernetes server version: $server_version"
    
    # Check if user has cluster-admin permissions
    if ! kubectl auth can-i create clusterroles >/dev/null 2>&1; then
        print_error "Insufficient permissions. You need cluster-admin access to install Kyverno."
        exit 1
    fi
    
    # Check for existing Kyverno installation
    if kubectl get namespace "$KYVERNO_NAMESPACE" >/dev/null 2>&1; then
        print_warning "Kyverno namespace already exists"
        read -p "Do you want to proceed with the installation/upgrade? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled"
            exit 0
        fi
    fi
    
    print_success "Prerequisites check completed"
}

# Function to install Kyverno
install_kyverno() {
    print_status "Installing Kyverno version $KYVERNO_VERSION..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$KYVERNO_NAMESPACE" >/dev/null 2>&1 || true
    
    # Apply Kyverno installation manifest
    local kyverno_url="https://github.com/kyverno/kyverno/releases/download/$KYVERNO_VERSION/install.yaml"
    
    print_status "Downloading and applying Kyverno manifest from $kyverno_url"
    
    if ! curl -sSL "$kyverno_url" | kubectl apply -f -; then
        print_error "Failed to install Kyverno"
        exit 1
    fi
    
    print_success "Kyverno manifest applied"
}

# Function to wait for Kyverno to be ready
wait_for_kyverno() {
    print_status "Waiting for Kyverno to be ready..."
    
    # Wait for namespace to be active
    kubectl wait --for=condition=Active namespace/"$KYVERNO_NAMESPACE" --timeout=60s
    
    # Wait for Kyverno pods to be ready
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if kubectl get pods -n "$KYVERNO_NAMESPACE" -l app.kubernetes.io/name=kyverno >/dev/null 2>&1; then
            if kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=kyverno -n "$KYVERNO_NAMESPACE" --timeout=10s >/dev/null 2>&1; then
                break
            fi
        fi
        
        ((attempt++))
        print_status "Waiting for Kyverno pods... (attempt $attempt/$max_attempts)"
        sleep 10
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        print_error "Kyverno pods did not become ready within timeout"
        print_status "Current pod status:"
        kubectl get pods -n "$KYVERNO_NAMESPACE"
        return 1
    fi
    
    print_success "Kyverno is ready"
}

# Function to verify Kyverno installation
verify_kyverno() {
    print_status "Verifying Kyverno installation..."
    
    # Check if Kyverno pods are running
    local running_pods=$(kubectl get pods -n "$KYVERNO_NAMESPACE" -l app.kubernetes.io/name=kyverno --field-selector=status.phase=Running --no-headers | wc -l)
    
    if [[ $running_pods -eq 0 ]]; then
        print_error "No Kyverno pods are running"
        return 1
    fi
    
    print_success "$running_pods Kyverno pod(s) running"
    
    # Check if admission webhooks are configured
    local webhooks=$(kubectl get validatingadmissionwebhooks -l webhook.kyverno.io/managed-by=kyverno --no-headers | wc -l)
    
    if [[ $webhooks -eq 0 ]]; then
        print_warning "No Kyverno admission webhooks found"
    else
        print_success "$webhooks Kyverno admission webhook(s) configured"
    fi
    
    # Test basic functionality with a simple policy
    print_status "Testing Kyverno functionality..."
    
    cat > /tmp/test-policy.yaml << EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: test-policy
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: test-rule
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - test-kyverno-functionality
    validate:
      message: "This is a test policy"
      pattern:
        metadata:
          labels:
            test: "kyverno"
EOF
    
    # Create test namespace
    kubectl create namespace test-kyverno-functionality >/dev/null 2>&1 || true
    
    # Apply test policy
    if kubectl apply -f /tmp/test-policy.yaml >/dev/null 2>&1; then
        print_success "Test policy applied successfully"
        
        # Wait for policy to be ready
        sleep 5
        
        # Test that policy is enforced
        cat > /tmp/test-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: test-kyverno-functionality
spec:
  containers:
  - name: test
    image: nginx:alpine
EOF
        
        if ! kubectl apply -f /tmp/test-pod.yaml >/dev/null 2>&1; then
            print_success "Policy enforcement working correctly"
        else
            print_warning "Policy enforcement may not be working"
            kubectl delete pod test-pod -n test-kyverno-functionality >/dev/null 2>&1 || true
        fi
        
        # Cleanup test resources
        kubectl delete clusterpolicy test-policy >/dev/null 2>&1 || true
    else
        print_warning "Could not apply test policy"
    fi
    
    # Cleanup test namespace
    kubectl delete namespace test-kyverno-functionality >/dev/null 2>&1 || true
    rm -f /tmp/test-policy.yaml /tmp/test-pod.yaml
    
    print_success "Kyverno verification completed"
}

# Function to configure Kyverno
configure_kyverno() {
    print_status "Configuring Kyverno..."
    
    # Create configuration for Kyverno
    cat > /tmp/kyverno-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kyverno
  namespace: kyverno
data:
  # Generate policy reports
  generateSuccessEvents: "true"
  
  # Background scan interval
  backgroundScan: "true"
  backgroundScanWorkers: "2"
  backgroundScanInterval: "1h"
  
  # Webhook configurations
  webhookTimeoutSeconds: "10"
  
  # Logging
  logging.verbosity: "2"
  logging.format: "text"
EOF
    
    # Apply configuration
    kubectl apply -f /tmp/kyverno-config.yaml >/dev/null 2>&1 || true
    
    # Restart Kyverno pods to pick up configuration
    kubectl rollout restart deployment/kyverno -n "$KYVERNO_NAMESPACE" >/dev/null 2>&1 || true
    
    # Wait for rollout to complete
    kubectl rollout status deployment/kyverno -n "$KYVERNO_NAMESPACE" --timeout=120s >/dev/null 2>&1 || true
    
    rm -f /tmp/kyverno-config.yaml
    
    print_success "Kyverno configured"
}

# Function to display installation summary
display_summary() {
    print_status "Installation Summary:"
    echo "====================="
    
    # Display Kyverno pods
    print_status "Kyverno Pods:"
    kubectl get pods -n "$KYVERNO_NAMESPACE" -l app.kubernetes.io/name=kyverno
    echo ""
    
    # Display admission webhooks
    print_status "Admission Webhooks:"
    kubectl get validatingadmissionwebhooks -l webhook.kyverno.io/managed-by=kyverno
    echo ""
    
    # Display any existing policies
    if kubectl get clusterpolicy >/dev/null 2>&1; then
        print_status "Existing Cluster Policies:"
        kubectl get clusterpolicy
        echo ""
    fi
    
    print_success "Kyverno installation completed successfully!"
    print_status "Next steps:"
    echo "1. Apply security policies: kubectl apply -f policies/"
    echo "2. Test policies: ./scripts/test-policies.sh"
    echo "3. Monitor policy reports: kubectl get policyreport -A"
    echo ""
    echo "Useful commands:"
    echo "- View Kyverno logs: kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno"
    echo "- List policies: kubectl get clusterpolicy"
    echo "- View policy reports: kubectl get policyreport -A"
}

# Function to uninstall Kyverno
uninstall_kyverno() {
    print_warning "This will completely remove Kyverno from your cluster"
    read -p "Are you sure you want to uninstall Kyverno? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
    
    print_status "Uninstalling Kyverno..."
    
    # Delete all cluster policies
    kubectl delete clusterpolicy --all >/dev/null 2>&1 || true
    
    # Delete all policy reports
    kubectl delete clusterpolicyreport --all >/dev/null 2>&1 || true
    kubectl delete policyreport --all -A >/dev/null 2>&1 || true
    
    # Delete Kyverno installation
    local kyverno_url="https://github.com/kyverno/kyverno/releases/download/$KYVERNO_VERSION/install.yaml"
    curl -sSL "$kyverno_url" | kubectl delete -f - >/dev/null 2>&1 || true
    
    # Force delete namespace if needed
    kubectl delete namespace "$KYVERNO_NAMESPACE" --timeout=60s >/dev/null 2>&1 || {
        print_warning "Forcing namespace deletion..."
        kubectl patch namespace "$KYVERNO_NAMESPACE" -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1 || true
    }
    
    print_success "Kyverno uninstalled"
}

# Function to show help
show_help() {
    echo "Kyverno Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -v, --version    Specify Kyverno version (default: $KYVERNO_VERSION)"
    echo "  -u, --uninstall  Uninstall Kyverno"
    echo "  -c, --check      Check Kyverno status only"
    echo "  --verbose        Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install Kyverno with default version"
    echo "  $0 -v v1.9.0         # Install specific version"
    echo "  $0 --check           # Check current installation"
    echo "  $0 --uninstall       # Remove Kyverno"
}

# Parse command line arguments
UNINSTALL=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            KYVERNO_VERSION="$2"
            shift 2
            ;;
        -u|--uninstall)
            UNINSTALL=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        --verbose)
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

# Main execution
if [[ "$UNINSTALL" == "true" ]]; then
    uninstall_kyverno
elif [[ "$CHECK_ONLY" == "true" ]]; then
    print_status "Checking Kyverno installation..."
    if kubectl get namespace "$KYVERNO_NAMESPACE" >/dev/null 2>&1; then
        verify_kyverno
        display_summary
    else
        print_error "Kyverno is not installed"
        exit 1
    fi
else
    # Install Kyverno
    check_prerequisites
    install_kyverno
    wait_for_kyverno
    configure_kyverno
    verify_kyverno
    display_summary
fi
