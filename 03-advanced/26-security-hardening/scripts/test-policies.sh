#!/bin/bash

# Policy Testing Script
# This script tests security policies by attempting to create various pod configurations

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

print_test_result() {
    local test_name=$1
    local expected=$2
    local actual=$3
    
    if [[ "$expected" == "$actual" ]]; then
        print_success "✓ $test_name: Expected $expected, got $actual"
        return 0
    else
        print_error "✗ $test_name: Expected $expected, got $actual"
        return 1
    fi
}

# Function to test policy enforcement
test_policy() {
    local test_name=$1
    local manifest_file=$2
    local expected_result=$3  # "ALLOWED" or "DENIED"
    local timeout=${4:-10}
    
    print_status "Testing: $test_name"
    
    # Try to apply the manifest
    if timeout "$timeout" kubectl apply -f "$manifest_file" >/dev/null 2>&1; then
        actual_result="ALLOWED"
        # Clean up if creation succeeded
        kubectl delete -f "$manifest_file" >/dev/null 2>&1 || true
    else
        actual_result="DENIED"
    fi
    
    print_test_result "$test_name" "$expected_result" "$actual_result"
}

# Function to test network connectivity
test_network_connectivity() {
    local test_name=$1
    local source_pod=$2
    local source_namespace=$3
    local target=$4
    local expected_result=$5
    
    print_status "Testing network connectivity: $test_name"
    
    # Create test pod if it doesn't exist
    if ! kubectl get pod "$source_pod" -n "$source_namespace" >/dev/null 2>&1; then
        kubectl run "$source_pod" --image=nginx:alpine -n "$source_namespace" >/dev/null 2>&1
        kubectl wait --for=condition=Ready pod/"$source_pod" -n "$source_namespace" --timeout=60s >/dev/null 2>&1
    fi
    
    # Test connectivity
    if kubectl exec -n "$source_namespace" "$source_pod" -- wget -qO- --timeout=5 "$target" >/dev/null 2>&1; then
        actual_result="ALLOWED"
    else
        actual_result="DENIED"
    fi
    
    print_test_result "$test_name" "$expected_result" "$actual_result"
}

# Function to check policy violations
check_policy_violations() {
    print_status "Checking for policy violations..."
    
    # Check for PolicyReports
    if kubectl get policyreport -A >/dev/null 2>&1; then
        local violation_count=$(kubectl get policyreport -A -o json | jq -r '.items[].status.summary.fail // 0' | awk '{sum += $1} END {print sum}')
        
        if [[ "$violation_count" -gt 0 ]]; then
            print_warning "Found $violation_count policy violations"
            kubectl get policyreport -A -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,PASS:.status.summary.pass,FAIL:.status.summary.fail,WARN:.status.summary.warn,ERROR:.status.summary.error,SKIP:.status.summary.skip"
        else
            print_success "No policy violations found"
        fi
    else
        print_warning "PolicyReports not available"
    fi
}

# Main testing function
run_policy_tests() {
    print_status "Starting security policy tests..."
    
    local passed_tests=0
    local total_tests=0
    
    # Test 1: Privileged container should be denied
    ((total_tests++))
    cat > /tmp/test-privileged.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged
  namespace: secure-namespace
spec:
  containers:
  - name: test
    image: nginx:alpine
    securityContext:
      privileged: true
EOF
    
    if test_policy "Privileged container denial" "/tmp/test-privileged.yaml" "DENIED"; then
        ((passed_tests++))
    fi
    
    # Test 2: Container without resource limits should be denied
    ((total_tests++))
    cat > /tmp/test-no-resources.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-no-resources
  namespace: secure-namespace
  labels:
    app: test
    version: v1.0.0
    environment: test
spec:
  containers:
  - name: test
    image: nginx:alpine
EOF
    
    if test_policy "No resource limits denial" "/tmp/test-no-resources.yaml" "DENIED"; then
        ((passed_tests++))
    fi
    
    # Test 3: Container running as root should be denied
    ((total_tests++))
    cat > /tmp/test-root-user.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-root-user
  namespace: secure-namespace
  labels:
    app: test
    version: v1.0.0
    environment: test
spec:
  containers:
  - name: test
    image: nginx:alpine
    securityContext:
      runAsUser: 0
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
EOF
    
    if test_policy "Root user denial" "/tmp/test-root-user.yaml" "DENIED"; then
        ((passed_tests++))
    fi
    
    # Test 4: Container with dangerous capabilities should be denied
    ((total_tests++))
    cat > /tmp/test-capabilities.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-capabilities
  namespace: secure-namespace
  labels:
    app: test
    version: v1.0.0
    environment: test
spec:
  containers:
  - name: test
    image: nginx:alpine
    securityContext:
      capabilities:
        add:
        - SYS_ADMIN
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
EOF
    
    if test_policy "Dangerous capabilities denial" "/tmp/test-capabilities.yaml" "DENIED"; then
        ((passed_tests++))
    fi
    
    # Test 5: Pod without required labels should be denied
    ((total_tests++))
    cat > /tmp/test-no-labels.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-no-labels
  namespace: secure-namespace
spec:
  containers:
  - name: test
    image: nginx:alpine
    securityContext:
      runAsNonRoot: true
      runAsUser: 1001
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
EOF
    
    if test_policy "Missing required labels denial" "/tmp/test-no-labels.yaml" "DENIED"; then
        ((passed_tests++))
    fi
    
    # Test 6: Secure pod should be allowed
    ((total_tests++))
    if test_policy "Secure pod acceptance" "manifests/05-secure-pod.yaml" "ALLOWED"; then
        ((passed_tests++))
    fi
    
    # Test 7: Test network policies
    print_status "Testing network policies..."
    
    # Create test pods for network testing
    kubectl run test-pod-1 --image=nginx:alpine -n secure-namespace --labels="app=test,version=v1.0.0,environment=test" >/dev/null 2>&1 || true
    kubectl run test-pod-2 --image=nginx:alpine -n default >/dev/null 2>&1 || true
    
    # Wait for pods to be ready
    kubectl wait --for=condition=Ready pod/test-pod-1 -n secure-namespace --timeout=60s >/dev/null 2>&1 || true
    kubectl wait --for=condition=Ready pod/test-pod-2 -n default --timeout=60s >/dev/null 2>&1 || true
    
    # Test intra-namespace communication (should be allowed)
    ((total_tests++))
    if test_network_connectivity "Intra-namespace communication" "test-pod-1" "secure-namespace" "test-pod-1.secure-namespace.svc.cluster.local" "ALLOWED"; then
        ((passed_tests++))
    fi
    
    # Test cross-namespace communication (should be denied by default)
    ((total_tests++))
    if test_network_connectivity "Cross-namespace communication" "test-pod-1" "secure-namespace" "test-pod-2.default.svc.cluster.local" "DENIED"; then
        ((passed_tests++))
    fi
    
    # Test DNS resolution (should be allowed)
    ((total_tests++))
    if test_network_connectivity "DNS resolution" "test-pod-1" "secure-namespace" "kubernetes.default.svc.cluster.local" "ALLOWED"; then
        ((passed_tests++))
    fi
    
    # Cleanup test resources
    print_status "Cleaning up test resources..."
    kubectl delete pod test-pod-1 -n secure-namespace >/dev/null 2>&1 || true
    kubectl delete pod test-pod-2 -n default >/dev/null 2>&1 || true
    rm -f /tmp/test-*.yaml
    
    # Check for policy violations
    check_policy_violations
    
    # Display test results
    echo ""
    print_status "Test Results Summary:"
    echo "=========================="
    print_status "Passed: $passed_tests/$total_tests"
    
    if [[ $passed_tests -eq $total_tests ]]; then
        print_success "All tests passed! Security policies are working correctly."
        return 0
    else
        local failed_tests=$((total_tests - passed_tests))
        print_error "$failed_tests tests failed. Please review the security configuration."
        return 1
    fi
}

# Function to test resource quotas
test_resource_quotas() {
    print_status "Testing resource quotas..."
    
    # Check current resource usage
    kubectl describe resourcequota -n secure-namespace
    
    # Try to create a pod that would exceed resource limits
    cat > /tmp/test-resource-quota.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: resource-hog
  namespace: secure-namespace
  labels:
    app: test
    version: v1.0.0
    environment: test
spec:
  containers:
  - name: memory-hog
    image: nginx:alpine
    resources:
      requests:
        memory: 20Gi  # This should exceed quota
        cpu: 10       # This should exceed quota
      limits:
        memory: 20Gi
        cpu: 10
EOF
    
    print_status "Testing resource quota enforcement..."
    if kubectl apply -f /tmp/test-resource-quota.yaml >/dev/null 2>&1; then
        print_error "Resource quota not enforced - pod creation should have failed"
        kubectl delete -f /tmp/test-resource-quota.yaml >/dev/null 2>&1 || true
    else
        print_success "Resource quota properly enforced"
    fi
    
    rm -f /tmp/test-resource-quota.yaml
}

# Function to show help
show_help() {
    echo "Security Policy Testing Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -q, --quota     Test only resource quotas"
    echo "  -n, --network   Test only network policies"
    echo "  -v, --verbose   Enable verbose output"
    echo ""
    echo "This script tests:"
    echo "  - Admission controller policies (Kyverno)"
    echo "  - Pod Security Standards"
    echo "  - Network policies"
    echo "  - Resource quotas"
    echo "  - Policy violation reporting"
}

# Parse command line arguments
TEST_QUOTAS_ONLY=false
TEST_NETWORK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quota)
            TEST_QUOTAS_ONLY=true
            shift
            ;;
        -n|--network)
            TEST_NETWORK_ONLY=true
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

# Run tests based on options
if [[ "$TEST_QUOTAS_ONLY" == "true" ]]; then
    test_resource_quotas
elif [[ "$TEST_NETWORK_ONLY" == "true" ]]; then
    # Run only network-related tests
    print_status "Running network policy tests only..."
    # Implementation would go here
    print_warning "Network-only testing not yet implemented"
else
    # Run all tests
    run_policy_tests
    echo ""
    test_resource_quotas
fi
