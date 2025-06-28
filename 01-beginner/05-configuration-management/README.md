# Project 5: Configuration Management 🔧

**Difficulty**: 🟢 Beginner  
**Time Estimate**: 120-150 minutes  
**Prerequisites**: Projects 1-4 completed  

## 🎯 Learning Objectives

By the end of this project, you will:
- Use Helm for package management and templating
- Implement Kustomize for environment-specific configurations
- Organize applications using Namespaces effectively
- Manage configuration across multiple environments (dev/staging/prod)
- Implement GitOps workflows for configuration management
- Understand configuration best practices and security

## 📋 Project Overview

You'll deploy the same application across multiple environments with:
- **Helm Charts**: Parameterized application templates
- **Kustomize**: Environment-specific overlays
- **Namespaces**: Environment isolation
- **ConfigMaps and Secrets**: Environment-specific configurations
- **GitOps**: Configuration stored in Git repositories
- **Multi-Environment Pipeline**: Automated deployment across environments

### What We'll Build
- A multi-tier application deployed across dev, staging, and production
- Helm charts for application packaging
- Kustomize overlays for environment customization
- Namespace-based isolation
- Automated configuration management pipeline

## 🏗️ Architecture

```
Git Repository → CI/CD Pipeline → Environments
     ↓                              ↓
Helm Charts              [Dev Namespace]
Kustomize                [Staging Namespace] 
Base + Overlays          [Production Namespace]
```

## 🚀 Implementation Steps

### Step 1: Install Helm

Install Helm package manager:

**Windows:**
```powershell
choco install kubernetes-helm
```

**macOS:**
```bash
brew install helm
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Step 2: Create Base Application Structure

Set up the base application:

```bash
kubectl apply -f manifests/01-namespaces.yaml
```

### Step 3: Create Helm Chart

Create and deploy Helm chart:

```bash
# Create helm chart
helm create webapp-chart

# Customize the chart (see helm/ directory)
# Deploy to different environments
helm install webapp-dev helm/webapp-chart -n dev -f helm/webapp-chart/values-dev.yaml
helm install webapp-staging helm/webapp-chart -n staging -f helm/webapp-chart/values-staging.yaml
helm install webapp-prod helm/webapp-chart -n production -f helm/webapp-chart/values-prod.yaml
```

### Step 4: Set up Kustomize Structure

Deploy using Kustomize:

```bash
# Deploy base application
kubectl apply -k kustomize/base

# Deploy environment-specific overlays
kubectl apply -k kustomize/overlays/dev
kubectl apply -k kustomize/overlays/staging
kubectl apply -k kustomize/overlays/production
```

### Step 5: Compare Both Approaches

Examine the differences:

```bash
# List deployments across namespaces
kubectl get deployments --all-namespaces

# Compare configurations
kubectl get configmap -n dev
kubectl get configmap -n staging
kubectl get configmap -n production
```

## 🎁 Helm Deep Dive

### Chart Structure
```
webapp-chart/
├── Chart.yaml           # Chart metadata
├── values.yaml          # Default configuration values
├── values-dev.yaml      # Development environment values
├── values-staging.yaml  # Staging environment values
├── values-prod.yaml     # Production environment values
├── templates/           # Kubernetes manifest templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── _helpers.tpl     # Template helpers
├── charts/              # Chart dependencies
└── README.md           # Chart documentation
```

### Templating Examples

**Deployment Template:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp-chart.fullname" . }}
  labels:
    {{- include "webapp-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "webapp-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "webapp-chart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: {{ .Values.service.targetPort }}
        env:
        - name: ENVIRONMENT
          value: {{ .Values.environment }}
        - name: DATABASE_URL
          value: {{ .Values.database.url }}
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

**Values Files:**
```yaml
# values-dev.yaml
replicaCount: 1
environment: development
image:
  repository: webapp
  tag: "dev-latest"
database:
  url: "postgres://dev-db:5432/webapp"
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"

# values-prod.yaml
replicaCount: 3
environment: production
image:
  repository: webapp
  tag: "1.0.0"
database:
  url: "postgres://prod-db:5432/webapp"
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🔧 Kustomize Deep Dive

### Directory Structure
```
kustomize/
├── base/                # Base configuration
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── namespace.yaml
└── overlays/            # Environment-specific overlays
    ├── dev/
    │   ├── kustomization.yaml
    │   ├── replica-patch.yaml
    │   └── configmap-patch.yaml
    ├── staging/
    │   ├── kustomization.yaml
    │   ├── replica-patch.yaml
    │   └── ingress.yaml
    └── production/
        ├── kustomization.yaml
        ├── replica-patch.yaml
        ├── ingress.yaml
        └── hpa.yaml
```

### Base Configuration
```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- namespace.yaml
- deployment.yaml
- service.yaml
- configmap.yaml

commonLabels:
  app: webapp
  version: v1

commonAnnotations:
  managed-by: kustomize
```

### Environment Overlays
```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

resources:
- ../../base
- ingress.yaml
- hpa.yaml

patchesStrategicMerge:
- replica-patch.yaml

images:
- name: webapp
  newTag: 1.0.0

replicas:
- name: webapp-deployment
  count: 3

configMapGenerator:
- name: webapp-config
  behavior: merge
  literals:
  - ENVIRONMENT=production
  - LOG_LEVEL=warn
  - DATABASE_POOL_SIZE=20
```

## 🧪 Experiments to Try

### Experiment 1: Helm Chart Management
```bash
# List installed charts
helm list --all-namespaces

# Upgrade a release
helm upgrade webapp-dev helm/webapp-chart -n dev -f helm/webapp-chart/values-dev.yaml

# Rollback a release
helm rollback webapp-dev 1 -n dev

# Check release history
helm history webapp-dev -n dev
```

### Experiment 2: Kustomize Customization
```bash
# Preview generated manifests
kubectl kustomize kustomize/overlays/production

# Apply with dry-run
kubectl apply -k kustomize/overlays/production --dry-run=client -o yaml

# Compare environments
diff <(kubectl kustomize kustomize/overlays/dev) <(kubectl kustomize kustomize/overlays/production)
```

### Experiment 3: Configuration Updates
```bash
# Update ConfigMap via Helm
helm upgrade webapp-dev helm/webapp-chart -n dev \
  --set config.logLevel=debug \
  --set config.debugMode=true

# Update ConfigMap via Kustomize
# Edit kustomize/overlays/dev/kustomization.yaml and apply
kubectl apply -k kustomize/overlays/dev
```

### Experiment 4: Environment Promotion
```bash
# Promote from dev to staging
# Tag the image
docker tag webapp:dev-latest webapp:staging-v1.1.0

# Update staging values
helm upgrade webapp-staging helm/webapp-chart -n staging \
  --set image.tag=staging-v1.1.0

# Or with Kustomize
# Update kustomize/overlays/staging/kustomization.yaml
kubectl apply -k kustomize/overlays/staging
```

### Experiment 5: Multi-Environment Monitoring
```bash
# Compare resource usage across environments
kubectl top pods -n dev
kubectl top pods -n staging
kubectl top pods -n production

# Check configuration differences
kubectl get configmap webapp-config -n dev -o yaml
kubectl get configmap webapp-config -n staging -o yaml
kubectl get configmap webapp-config -n production -o yaml
```

## 🏢 Namespace Organization

### Environment-based Isolation
```yaml
# Development namespace
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
    team: backend
  annotations:
    description: "Development environment for testing new features"

---
# Resource quotas per namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "4"
    services: "10"
    secrets: "10"
    configmaps: "10"
```

### Network Policies for Isolation
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
```

## 🔐 Security and Best Practices

### Secret Management
```yaml
# Using external-secrets operator
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: production
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "production-role"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: production
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: db-secret
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: database/production
      property: username
  - secretKey: password
    remoteRef:
      key: database/production
      property: password
```

### RBAC for Namespaces
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: dev-developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-developers
  namespace: dev
subjects:
- kind: User
  name: developer@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: dev-developer
  apiGroup: rbac.authorization.k8s.io
```

## 🔄 GitOps Workflow

### Directory Structure
```
gitops-repo/
├── applications/
│   ├── webapp/
│   │   ├── base/
│   │   └── overlays/
│   │       ├── dev/
│   │       ├── staging/
│   │       └── production/
├── infrastructure/
│   ├── ingress-nginx/
│   ├── cert-manager/
│   └── monitoring/
└── clusters/
    ├── dev-cluster/
    ├── staging-cluster/
    └── production-cluster/
```

### ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/gitops-repo
    targetRevision: HEAD
    path: applications/webapp/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## 🐛 Troubleshooting

### Helm Issues
```bash
# Debug template rendering
helm template webapp-dev helm/webapp-chart -f helm/webapp-chart/values-dev.yaml

# Check release status
helm status webapp-dev -n dev

# Get values for installed release
helm get values webapp-dev -n dev
```

### Kustomize Issues
```bash
# Validate kustomization
kubectl kustomize kustomize/overlays/production --validate=true

# Check for syntax errors
kubeval <(kubectl kustomize kustomize/overlays/production)

# Debug resource generation
kubectl kustomize kustomize/overlays/production | kubectl apply --dry-run=client -f -
```

### Configuration Issues
```bash
# Check configmap content
kubectl describe configmap webapp-config -n production

# Compare across environments
kubectl get configmap webapp-config -o yaml --export -n dev > dev-config.yaml
kubectl get configmap webapp-config -o yaml --export -n production > prod-config.yaml
diff dev-config.yaml prod-config.yaml
```

## 🧹 Cleanup

Remove all resources:
```bash
# Remove Helm releases
helm uninstall webapp-dev -n dev
helm uninstall webapp-staging -n staging
helm uninstall webapp-prod -n production

# Remove Kustomize resources
kubectl delete -k kustomize/overlays/dev
kubectl delete -k kustomize/overlays/staging
kubectl delete -k kustomize/overlays/production

# Remove namespaces
kubectl delete namespace dev staging production
```

## 🎯 Key Takeaways

1. **Helm** provides powerful templating and package management
2. **Kustomize** offers declarative configuration customization
3. **Namespaces** enable environment isolation and resource organization
4. **GitOps** ensures configuration consistency and auditability
5. **Environment-specific configurations** handle different deployment requirements
6. **Security policies** should be enforced at the namespace level
7. **Both tools have their place** - choose based on your needs

## 📚 Next Steps

Congratulations on completing the beginner projects! 🎉 

You're now ready for intermediate challenges. Proceed to [Project 6: Microservices Architecture](../../02-intermediate/06-microservices-architecture/) where you'll learn:
- Service mesh architectures
- Distributed tracing and observability
- Advanced networking patterns
- Production-scale deployments

## 📖 Additional Reading

- [Helm Documentation](https://helm.sh/docs/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [Namespace Best Practices](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [GitOps Principles](https://www.gitops.tech/)

---

**Outstanding achievement!** 🎉 You've mastered the fundamentals of Kubernetes configuration management. You're now ready to tackle more complex, real-world scenarios in the intermediate projects.
