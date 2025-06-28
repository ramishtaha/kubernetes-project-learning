# 🔐 Project 26: Cluster Security Hardening

**Difficulty**: � Advanced  
**Time Estimate**: 6-8 hours  
**Prerequisites**: Projects 01-25 completed, security concepts, policy frameworks  

## 📋 Overview

Implement comprehensive Kubernetes cluster security hardening! This project demonstrates advanced security techniques using admission controllers, Pod Security Standards, network policies, and policy-as-code frameworks. You'll learn to implement defense-in-depth security strategies to protect your cluster from threats and vulnerabilities.

## 🎯 Learning Objectives

By completing this project, you will:
- Understand admission controllers and their role in cluster security
- Implement Pod Security Standards for runtime security
- Use policy-as-code with Kyverno for governance
- Configure network segmentation with NetworkPolicies
- Set up application availability controls with PodDisruptionBudgets
- Recognize and prevent common security misconfigurations
- Learn container image security and supply chain protection

## 📚 Concepts Covered

### 1. **Admission Controllers**
Admission controllers are plugins that govern and enforce how the cluster is used. They can **mutate** or **validate** requests to the Kubernetes API server.

**Types:**
- **Mutating Admission Controllers**: Modify objects before they're stored
- **Validating Admission Controllers**: Validate objects against policies

**Common Built-in Controllers:**
- `NamespaceLifecycle`: Prevents creation of objects in terminating namespaces
- `ResourceQuota`: Enforces resource usage limits
- `PodSecurityPolicy`: Validates pod security contexts (deprecated in 1.25+)
- `ImagePolicyWebhook`: Validates container images

### 2. **Pod Security Standards**
Pod Security Standards define three policies to broadly cover the security spectrum:

**Privileged (Most Permissive):**
- Unrestricted policy, providing the widest possible level of permissions
- Allows known privilege escalations

**Baseline (Minimally Restrictive):**
- Prevents known privilege escalations
- Allows default (minimally specified) Pod configuration

**Restricted (Most Restrictive):**
- Heavily restricted policy, following current Pod hardening best practices
- Requires security best practices

### 3. **Policy-as-Code with Kyverno**
Kyverno is a policy engine designed for Kubernetes that:
- Uses YAML for policy definition (no new language to learn)
- Validates, mutates, and generates Kubernetes resources
- Provides policy reporting and violation alerts

**Policy Types:**
- **Validate**: Check resource configurations against rules
- **Mutate**: Modify resources to comply with standards
- **Generate**: Create additional resources automatically

### 4. **Network Security**
**NetworkPolicies** provide network-level security by:
- Controlling traffic flow between pods
- Implementing micro-segmentation
- Following principle of least privilege
- Supporting ingress and egress rules

## 🏗️ Project Architecture

```
Security Hardening Components:
┌─────────────────────────────────────────────────────────┐
│                    Admission Control                    │
├─────────────────────────────────────────────────────────┤
│  Kyverno Policies  │  Pod Security  │  Built-in        │
│  • Resource Limits │  Standards     │  Controllers     │
│  • No Privileged   │  • Baseline    │  • ResourceQuota │
│  • Required Labels │  • Restricted  │  • LimitRanger   │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│                   Network Security                      │
├─────────────────────────────────────────────────────────┤
│  NetworkPolicies   │  Service Mesh  │  Ingress         │
│  • Default Deny    │  • mTLS        │  • TLS           │
│  • Namespace       │  • Traffic     │  • WAF           │
│    Isolation       │    Policies    │  • Rate Limiting │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│                Application Resilience                   │
├─────────────────────────────────────────────────────────┤
│  PodDisruption     │  Resource      │  Health          │
│  Budgets           │  Management    │  Checks          │
│  • Min Available   │  • Limits      │  • Probes        │
│  • Max Unavailable │  • Requests    │  • Graceful      │
│                    │  • QoS Classes │    Shutdown      │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Prerequisites

- Kubernetes cluster (v1.24+) with admin access
- `kubectl` configured
- Basic understanding of Kubernetes security concepts
- Familiarity with YAML and networking concepts

## 📁 Project Structure

```
26-security-hardening/
├── README.md                           # This file
├── manifests/
│   ├── 01-namespace.yaml              # Secure namespace setup
│   ├── 02-network-policy.yaml         # Default-deny network policy
│   ├── 03-pod-disruption-budget.yaml  # Application availability
│   ├── 04-insecure-pod.yaml          # Pod that violates policies
│   ├── 05-secure-pod.yaml            # Compliant pod example
│   └── 06-resource-quota.yaml         # Namespace resource limits
├── policies/
│   ├── kyverno-cluster-policy.yaml    # Kyverno governance policies
│   ├── pod-security-standards.yaml    # PSS enforcement
│   └── image-security-policy.yaml     # Container image policies
└── scripts/
    ├── deploy.sh                      # Setup and deployment
    ├── test-policies.sh               # Test security policies
    ├── cleanup.sh                     # Cleanup resources
    └── setup-kyverno.sh              # Install Kyverno
```

## 🚀 Quick Start

### 1. **Install Kyverno**
```bash
# Run the setup script
./scripts/setup-kyverno.sh

# Or manually install
kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml
```

### 2. **Deploy Security Hardening**
```bash
# Deploy all security configurations
./scripts/deploy.sh

# Test policies with insecure pod
./scripts/test-policies.sh
```

### 3. **Verify Security Policies**
```bash
# Check Kyverno policies
kubectl get cpol

# View policy violations
kubectl get policyreport -A

# Test network connectivity
kubectl exec -n secure-namespace test-pod -- wget -qO- --timeout=5 external-service
```

## 📋 Step-by-Step Implementation

### Step 1: Create Secure Namespace
```bash
kubectl apply -f manifests/01-namespace.yaml
```

### Step 2: Implement Network Security
```bash
# Apply default-deny network policy
kubectl apply -f manifests/02-network-policy.yaml

# Verify network isolation
kubectl get networkpolicy -n secure-namespace
```

### Step 3: Deploy Kyverno Policies
```bash
# Apply cluster-wide security policies
kubectl apply -f policies/kyverno-cluster-policy.yaml

# Check policy status
kubectl get cpol require-pod-resources -o yaml
```

### Step 4: Test Policy Enforcement
```bash
# Try to create insecure pod (should fail)
kubectl apply -f manifests/04-insecure-pod.yaml

# Create compliant pod (should succeed)
kubectl apply -f manifests/05-secure-pod.yaml
```

### Step 5: Configure Application Resilience
```bash
# Apply pod disruption budget
kubectl apply -f manifests/03-pod-disruption-budget.yaml

# Apply resource quotas
kubectl apply -f manifests/06-resource-quota.yaml
```

## 🧪 Testing and Validation

### **Test Network Policies**
```bash
# Test pod-to-pod communication
kubectl run test-pod --image=nginx -n secure-namespace
kubectl run external-pod --image=nginx -n default

# Test connectivity (should fail due to default-deny)
kubectl exec -n secure-namespace test-pod -- wget -qO- --timeout=5 external-pod.default.svc.cluster.local
```

### **Test Admission Policies**
```bash
# Test privileged container rejection
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-test
  namespace: secure-namespace
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: true
EOF
```

### **Test Resource Policies**
```bash
# Test pod without resource limits (should fail)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: no-limits-test
  namespace: secure-namespace
spec:
  containers:
  - name: app
    image: nginx
EOF
```

## 🔍 Monitoring and Observability

### **Policy Violations**
```bash
# View policy reports
kubectl get policyreport -A

# Get detailed violation information
kubectl describe policyreport -n secure-namespace
```

### **Security Events**
```bash
# Monitor admission controller events
kubectl get events --field-selector reason=PolicyViolation

# Check Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
```

## 🏆 Success Criteria

- [ ] Kyverno policies successfully installed and active
- [ ] NetworkPolicy blocks unauthorized traffic
- [ ] Insecure pod creation is blocked by admission policies
- [ ] Secure pod deploys successfully
- [ ] PodDisruptionBudget prevents excessive pod evictions
- [ ] Resource quotas enforce namespace limits
- [ ] Policy violations are logged and reported

## 🔧 Troubleshooting

### **Common Issues**

**Policy Not Enforcing:**
```bash
# Check Kyverno installation
kubectl get pods -n kyverno

# Verify policy syntax
kubectl describe cpol require-pod-resources
```

**Network Policy Not Working:**
```bash
# Ensure CNI supports NetworkPolicies
kubectl get nodes -o wide

# Check policy application
kubectl describe networkpolicy -n secure-namespace
```

**Pod Creation Blocked:**
```bash
# Check admission webhook
kubectl get validatingadmissionwebhooks

# Review policy violations
kubectl get events --field-selector type=Warning
```

## 📚 Advanced Concepts

### **1. Custom Admission Controllers**
Create webhooks for organization-specific policies:
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: custom-policy-webhook
webhooks:
- name: validate.custom.io
  clientConfig:
    service:
      name: custom-webhook-service
      namespace: webhook-system
      path: "/validate"
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

### **2. OPA Gatekeeper Alternative**
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        properties:
          labels:
            type: array
            items:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Missing required label: %v", [missing])
        }
```

### **3. Image Security Scanning**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-scanning
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: check-image-scan
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Image must be scanned and approved"
      pattern:
        spec:
          containers:
          - image: "*/scanned/*"
```

## 🎓 Learning Extensions

1. **Implement Pod Security Standards enforcement**
2. **Create custom Kyverno policies for your organization**
3. **Set up Falco for runtime security monitoring**
4. **Configure service mesh security with Istio**
5. **Implement image vulnerability scanning with Trivy**

## 📖 Additional Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Kyverno Documentation](https://kyverno.io/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

## 🤝 Contributing

Found an issue or want to improve this project? Please read our [Contributing Guide](../../CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

---

**⚠️ Security Note:** This project demonstrates security hardening techniques for educational purposes. Always review and adapt security policies according to your organization's specific requirements and threat model.

**🏷️ Tags:** `kubernetes` `security` `admission-controllers` `kyverno` `network-policies` `pod-security-standards` `policy-as-code` `advanced`
