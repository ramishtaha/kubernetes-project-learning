#!/bin/bash

# Cleanup Script for Security Hardening
# This script removes all resources created by the security hardening project

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

# Function to safely delete resources
safe_delete() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-""}
    
    local ns_flag=""
    if [[ -n "$namespace" ]]; then
        ns_flag="-n $namespace"
    fi
    
    if kubectl get "$resource_type" "$resource_name" $ns_flag >/dev/null 2>&1; then
        kubectl delete "$resource_type" "$resource_name" $ns_flag >/dev/null 2>&1
        print_success "Deleted $resource_type/$resource_name"
    else
        print_warning "$resource_type/$resource_name not found"
    fi
}

# Function to cleanup namespace resources
cleanup_namespace_resources() {
    local namespace=$1
    
    print_status "Cleaning up resources in namespace: $namespace"
    
    # Delete pods
    kubectl delete pods --all -n "$namespace" --timeout=60s >/dev/null 2>&1 || true
    
    # Delete services
    kubectl delete services --all -n "$namespace" >/dev/null 2>&1 || true
    
    # Delete configmaps (except default ones)
    kubectl delete configmaps -l 'app.kubernetes.io/part-of=security-hardening' -n "$namespace" >/dev/null 2>&1 || true
    kubectl delete configmap app-config nginx-config -n "$namespace" >/dev/null 2>&1 || true
    
    # Delete secrets (except default ones)
    kubectl delete secrets -l 'app.kubernetes.io/part-of=security-hardening' -n "$namespace" >/dev/null 2>&1 || true
    kubectl delete secret app-secret db-secret registry-credentials -n "$namespace" >/dev/null 2>&1 || true
    
    # Delete PVCs
    kubectl delete pvc --all -n "$namespace" >/dev/null 2>&1 || true
    
    print_success "Namespace resources cleaned up"
}

# Function to cleanup cluster-wide resources
cleanup_cluster_resources() {
    print_status "Cleaning up cluster-wide resources..."
    
    # Delete Kyverno policies
    print_status "Removing Kyverno policies..."
    safe_delete "clusterpolicy" "require-pod-resources"
    safe_delete "clusterpolicy" "disallow-privileged-containers"
    safe_delete "clusterpolicy" "disallow-host-namespaces"
    safe_delete "clusterpolicy" "require-non-root-user"
    safe_delete "clusterpolicy" "restrict-capabilities"
    safe_delete "clusterpolicy" "require-read-only-root-filesystem"
    safe_delete "clusterpolicy" "disallow-privilege-escalation"
    safe_delete "clusterpolicy" "require-pod-labels"
    safe_delete "clusterpolicy" "generate-network-policy"
    safe_delete "clusterpolicy" "disallow-latest-tag"
    safe_delete "clusterpolicy" "require-image-digest"
    safe_delete "clusterpolicy" "allowed-image-registries"
    safe_delete "clusterpolicy" "mutate-image-pull-policy"
    safe_delete "clusterpolicy" "block-unsigned-images"
    safe_delete "clusterpolicy" "image-vulnerability-scan"
    safe_delete "clusterpolicy" "generate-image-pull-secret"
    
    # Delete example namespaces created by Pod Security Standards
    safe_delete "namespace" "pss-baseline-example"
    safe_delete "namespace" "pss-restricted-example"
    
    print_success "Cluster-wide resources cleaned up"
}

# Function to cleanup policy reports
cleanup_policy_reports() {
    print_status "Cleaning up policy reports..."
    
    # Delete cluster policy reports
    kubectl delete clusterpolicyreport --all >/dev/null 2>&1 || true
    
    # Delete namespaced policy reports
    kubectl delete policyreport --all -A >/dev/null 2>&1 || true
    
    print_success "Policy reports cleaned up"
}

# Main cleanup function
cleanup_security_hardening() {
    print_status "Starting security hardening cleanup..."
    
    # Ask for confirmation
    read -p "This will delete all security hardening resources. Are you sure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
    
    # Cleanup secure namespace resources first
    if kubectl get namespace secure-namespace >/dev/null 2>&1; then
        cleanup_namespace_resources "secure-namespace"
        
        # Delete the namespace itself
        print_status "Deleting secure-namespace..."
        kubectl delete namespace secure-namespace --timeout=120s >/dev/null 2>&1 || {
            print_warning "Namespace deletion timed out, forcing deletion..."
            kubectl patch namespace secure-namespace -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1 || true
        }
        print_success "secure-namespace deleted"
    else
        print_warning "secure-namespace not found"
    fi
    
    # Cleanup cluster resources
    cleanup_cluster_resources
    
    # Cleanup policy reports
    cleanup_policy_reports
    
    # Clean up any remaining test resources
    print_status "Cleaning up test resources..."
    kubectl delete pod test-pod-1 -n default >/dev/null 2>&1 || true
    kubectl delete pod test-pod-2 -n default >/dev/null 2>&1 || true
    kubectl delete pod test-privileged -n default >/dev/null 2>&1 || true
    kubectl delete pod test-no-resources -n default >/dev/null 2>&1 || true
    kubectl delete pod test-root-user -n default >/dev/null 2>&1 || true
    kubectl delete pod test-capabilities -n default >/dev/null 2>&1 || true
    kubectl delete pod test-no-labels -n default >/dev/null 2>&1 || true
    
    # Remove temporary files
    rm -f /tmp/test-*.yaml >/dev/null 2>&1 || true
    
    print_success "Test resources cleaned up"
    
    print_success "Security hardening cleanup completed!"
    
    # Display remaining resources (for verification)
    print_status "Remaining Kyverno policies:"
    kubectl get clusterpolicy 2>/dev/null || print_warning "No cluster policies found"
    
    print_status "Remaining policy reports:"
    kubectl get policyreport -A 2>/dev/null || print_warning "No policy reports found"
}

# Function to cleanup only policies (keep namespace and resources)
cleanup_policies_only() {
    print_status "Cleaning up only security policies..."
    
    read -p "This will delete all Kyverno policies. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Policy cleanup cancelled"
        exit 0
    fi
    
    cleanup_cluster_resources
    cleanup_policy_reports
    
    print_success "Security policies cleanup completed!"
}

# Function to cleanup only the namespace (keep policies)
cleanup_namespace_only() {
    print_status "Cleaning up only the secure namespace..."
    
    read -p "This will delete the secure-namespace and its resources. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Namespace cleanup cancelled"
        exit 0
    fi
    
    if kubectl get namespace secure-namespace >/dev/null 2>&1; then
        cleanup_namespace_resources "secure-namespace"
        kubectl delete namespace secure-namespace --timeout=120s
        print_success "secure-namespace deleted"
    else
        print_warning "secure-namespace not found"
    fi
}

# Function to show help
show_help() {
    echo "Security Hardening Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -p, --policies   Clean up only policies (keep namespace)"
    echo "  -n, --namespace  Clean up only namespace (keep policies)"
    echo "  -f, --force      Force cleanup without confirmation"
    echo "  -v, --verbose    Enable verbose output"
    echo ""
    echo "Default behavior (no options): Clean up everything"
    echo ""
    echo "This script removes:"
    echo "  - secure-namespace and all its resources"
    echo "  - Kyverno cluster policies"
    echo "  - Policy reports"
    echo "  - Test namespaces and resources"
}

# Parse command line arguments
POLICIES_ONLY=false
NAMESPACE_ONLY=false
FORCE_CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--policies)
            POLICIES_ONLY=true
            shift
            ;;
        -n|--namespace)
            NAMESPACE_ONLY=true
            shift
            ;;
        -f|--force)
            FORCE_CLEANUP=true
            shift
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

# Check for conflicting options
if [[ "$POLICIES_ONLY" == "true" && "$NAMESPACE_ONLY" == "true" ]]; then
    print_error "Cannot specify both --policies and --namespace options"
    exit 1
fi

# Set force mode if specified
if [[ "$FORCE_CLEANUP" == "true" ]]; then
    REPLY="y"
fi

# Run cleanup based on options
if [[ "$POLICIES_ONLY" == "true" ]]; then
    cleanup_policies_only
elif [[ "$NAMESPACE_ONLY" == "true" ]]; then
    cleanup_namespace_only
else
    cleanup_security_hardening
fi
