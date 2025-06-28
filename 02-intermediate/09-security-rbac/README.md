# Project 9: Security and RBAC

## Learning Objectives
- Implement Role-Based Access Control (RBAC)
- Configure Pod Security Standards
- Set up Network Policies for micro-segmentation
- Implement secrets management
- Configure security contexts and admission controllers

## Prerequisites
- Completed Projects 1-8
- Understanding of Kubernetes security model
- Basic knowledge of authentication and authorization

## Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      Users      │───▶│  Authentication │───▶│  Authorization  │
│   (kubectl)     │    │   (API Server)  │    │     (RBAC)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Service       │    │   Pod Security  │    │    Network      │
│   Accounts      │    │   Standards     │    │   Policies      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Implementation Steps

### Step 1: Create Service Accounts and Roles
```bash
kubectl apply -f rbac/
```

### Step 2: Configure Pod Security Standards
```bash
kubectl apply -f security/pod-security.yaml
```

### Step 3: Implement Network Policies
```bash
kubectl apply -f network-policies/
```

### Step 4: Deploy Secure Applications
```bash
kubectl apply -f manifests/
```

## Files Structure
```
09-security-rbac/
├── README.md
├── rbac/
│   ├── serviceaccounts.yaml
│   ├── roles.yaml
│   ├── rolebindings.yaml
│   └── clusterroles.yaml
├── security/
│   ├── pod-security.yaml
│   ├── security-contexts.yaml
│   └── admission-controllers.yaml
├── network-policies/
│   ├── default-deny.yaml
│   ├── frontend-policy.yaml
│   └── backend-policy.yaml
├── manifests/
│   ├── secure-app.yaml
│   └── secrets.yaml
└── scripts/
    ├── setup-rbac.sh
    └── test-permissions.sh
```

## Key Concepts

### RBAC Components
- **ServiceAccount**: Identity for pods
- **Role/ClusterRole**: Define permissions
- **RoleBinding/ClusterRoleBinding**: Assign roles to subjects

### Security Features
- **Pod Security Standards**: Baseline, Restricted, Privileged
- **Security Contexts**: User ID, capabilities, read-only filesystem
- **Network Policies**: Traffic filtering between pods

### Secrets Management
- **Secret Types**: Opaque, TLS, Docker registry
- **Secret Rotation**: Automated secret updates
- **External Secrets**: Integration with external secret stores

## Experiments to Try

### 1. Test RBAC Permissions
```bash
# Test as different service accounts
kubectl auth can-i get pods --as=system:serviceaccount:default:reader
kubectl auth can-i create deployments --as=system:serviceaccount:default:developer
```

### 2. Network Policy Testing
```bash
# Test network connectivity
kubectl exec -it frontend-pod -- curl backend-service
kubectl exec -it test-pod -- curl frontend-service
```

### 3. Security Context Validation
```bash
# Check security context enforcement
kubectl describe pod secure-app
kubectl exec -it secure-app -- whoami
```

### 4. Secret Management
```bash
# Create and mount secrets
kubectl create secret generic app-secret --from-literal=password=mysecret
kubectl get secret app-secret -o yaml
```

## Troubleshooting

### Common Issues

1. **RBAC permission denied**
   ```bash
   # Check current permissions
   kubectl auth can-i --list --as=system:serviceaccount:namespace:serviceaccount
   
   # Debug RBAC
   kubectl describe rolebinding -n namespace
   ```

2. **Pod security policy violations**
   ```bash
   # Check pod security standards
   kubectl get events --field-selector reason=FailedCreate
   
   # Validate security context
   kubectl describe pod problematic-pod
   ```

3. **Network policy blocking traffic**
   ```bash
   # Check network policies
   kubectl get networkpolicy -A
   
   # Debug connectivity
   kubectl exec -it pod -- nslookup service-name
   ```

### Security Scanning
```bash
# Use tools like kube-bench for CIS benchmarks
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# Use kube-hunter for penetration testing
kubectl create -f https://raw.githubusercontent.com/aquasecurity/kube-hunter/main/job.yaml
```

## Security Best Practices

### 1. Principle of Least Privilege
- Create specific roles for each use case
- Avoid using cluster-admin role
- Regular audit of permissions

### 2. Pod Security
- Use non-root users
- Enable read-only root filesystem
- Drop unnecessary capabilities
- Use security contexts

### 3. Network Security
- Implement default deny network policies
- Segment traffic by namespace
- Use encrypted communication (TLS)

### 4. Secrets Management
- Never store secrets in container images
- Use external secret management systems
- Implement secret rotation
- Encrypt secrets at rest

## Advanced Security Features

### 1. Admission Controllers
```yaml
# OPA Gatekeeper for policy enforcement
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.10/deploy/gatekeeper.yaml
```

### 2. Image Security
```yaml
# ImagePolicyWebhook for image scanning
apiVersion: v1
kind: ConfigMap
metadata:
  name: image-policy-config
data:
  policy.json: |
    {
      "imagePolicy": {
        "kubeConfigFile": "/etc/kubernetes/image-policy-kubeconfig",
        "allowTTL": 30,
        "denyTTL": 30,
        "retryBackoff": 500,
        "defaultAllow": false
      }
    }
```

### 3. Runtime Security
```bash
# Deploy Falco for runtime security monitoring
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco --namespace falco --create-namespace
```

## Compliance and Auditing

### 1. Audit Logging
```yaml
# Enable audit logging in API server
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
```

### 2. CIS Benchmarks
- Regular security assessments
- Automated compliance checking
- Documentation of exceptions

### 3. Vulnerability Management
- Regular image scanning
- Base image updates
- Security patch management

## Next Steps
- Implement service mesh security (Istio/Linkerd)
- Advanced threat detection
- Zero-trust networking
- Certificate management with cert-manager

## Cleanup
```bash
# Remove RBAC resources
kubectl delete -f rbac/

# Remove network policies
kubectl delete -f network-policies/

# Remove security policies
kubectl delete -f security/
```

## Additional Resources
- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policy Recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes)
- [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
