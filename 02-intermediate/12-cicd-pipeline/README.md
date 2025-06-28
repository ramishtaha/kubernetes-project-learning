# 🔄 Project 12: CI/CD Pipeline with GitOps

**Difficulty**: 🟡 Intermediate  
**Time Estimate**: 4-5 hours  
**Prerequisites**: Projects 01-11 completed, Git workflows, basic CI/CD concepts  

## 📋 Overview

Build a complete CI/CD pipeline with GitOps workflows! This project demonstrates how to implement automated testing, building, and deployment using GitHub Actions and ArgoCD. You'll learn modern deployment strategies and pipeline security practices for production-ready applications.

## 🎯 Learning Objectives

By the end of this project, you will:
- Implement GitOps workflows with ArgoCD
- Build automated CI/CD pipelines with GitHub Actions
- Configure automated testing and deployment
- Implement blue-green and canary deployment strategies
- Set up pipeline security and compliance
- Monitor deployment health and rollback capabilities
- Learn multi-environment promotion workflows

## 📋 Project Overview

You'll build a complete CI/CD pipeline with:
- **GitHub Actions**: Automated testing and building
- **ArgoCD**: GitOps continuous deployment
- **Image Registry**: Container image management
- **Deployment Strategies**: Blue-green and canary deployments
- **Quality Gates**: Automated testing and security scanning
- **Monitoring**: Pipeline observability and alerts

### What We'll Build
- Automated CI pipeline with testing and security scanning
- GitOps-based CD pipeline with ArgoCD
- Multi-environment promotion workflow
- Advanced deployment strategies
- Complete pipeline monitoring and alerting

## 🏗️ Architecture

```
Developer → Git Push → GitHub Actions CI → Container Registry
                            ↓                    ↓
                      Quality Gates         ArgoCD Sync
                            ↓                    ↓
                    Security Scanning    Dev → Staging → Production
                            ↓                    ↓
                      Test Results         Health Monitoring
```

## 🚀 Implementation Steps

### Step 1: Set up Git Repository Structure

Create the GitOps repository structure:

```bash
# Create directory structure
mkdir -p gitops-demo/{applications,infrastructure,clusters}
cd gitops-demo

# Initialize git repository
git init
git remote add origin https://github.com/ramishtaha/gitops-demo.git
```

### Step 2: Install ArgoCD

Install ArgoCD in your cluster:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Step 3: Configure GitHub Actions CI Pipeline

Create CI pipeline configuration:

```bash
mkdir -p .github/workflows
# Create workflow files (see .github/workflows/ directory)
```

### Step 4: Set up Application Manifests

Deploy application manifests:

```bash
kubectl apply -f applications/webapp/base/
```

### Step 5: Create ArgoCD Applications

Configure ArgoCD applications:

```bash
kubectl apply -f argocd/applications/
```

### Step 6: Test the Complete Pipeline

Trigger the pipeline:

```bash
# Make a code change
echo "console.log('Hello CI/CD');" > src/app.js

# Commit and push
git add .
git commit -m "feat: update application"
git push origin main

# Watch ArgoCD sync
kubectl get applications -n argocd -w
```

## 🔄 GitOps with ArgoCD

### ArgoCD Application Definition
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp-dev
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/ramishtaha/gitops-demo
    targetRevision: HEAD
    path: applications/webapp/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
```

### Progressive Delivery
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: webapp-rollout
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: webapp:latest
        ports:
        - containerPort: 8080
```

## 🏭 CI Pipeline Implementation

### GitHub Actions Workflow
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/webapp

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Run linting
      run: npm run lint
    
    - name: Run security audit
      run: npm audit --audit-level=high

  security-scan:
    runs-on: ubuntu-latest
    needs: test
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build-and-push:
    runs-on: ubuntu-latest
    needs: [test, security-scan]
    permissions:
      contents: read
      packages: write
    steps:
    - uses: actions/checkout@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
    
    - name: Update manifest
      if: github.ref == 'refs/heads/main'
      run: |
        # Update image tag in GitOps repo
        sed -i "s|image: .*|image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}|" \
          applications/webapp/overlays/dev/kustomization.yaml
        
        # Commit and push changes
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add applications/webapp/overlays/dev/kustomization.yaml
        git commit -m "Update image to ${{ github.sha }}"
        git push
```

## 🚦 Deployment Strategies

### Blue-Green Deployment
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: webapp-blue-green
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: webapp-active
      previewService: webapp-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: webapp-preview
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: webapp-active
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: webapp:latest
        ports:
        - containerPort: 8080
```

### Canary Deployment with Analysis
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 30s
    count: 5
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring.svc.cluster.local:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="destination",destination_service_name="{{args.service-name}}",response_code!~"5.*"}[2m]
          )) / sum(irate(
            istio_requests_total{reporter="destination",destination_service_name="{{args.service-name}}"}[2m]
          ))
```

## 🧪 Experiments to Try

### Experiment 1: Test Automated Deployment
```bash
# Make a code change
echo "New feature" > src/new-feature.js

# Commit and push
git add .
git commit -m "feat: add new feature"
git push origin main

# Watch ArgoCD application
kubectl get applications -n argocd -w

# Check rollout status
kubectl argo rollouts get rollout webapp-rollout --watch
```

### Experiment 2: Trigger Rollback
```bash
# Promote a canary deployment manually
kubectl argo rollouts promote webapp-rollout

# Abort a deployment
kubectl argo rollouts abort webapp-rollout

# Rollback to previous version
kubectl argo rollouts undo webapp-rollout
```

### Experiment 3: Test Multi-Environment Promotion
```bash
# Promote from dev to staging
git checkout staging
git merge main
git push origin staging

# Watch staging deployment
kubectl get applications -n argocd | grep staging
```

### Experiment 4: Security Gate Testing
```bash
# Add a vulnerable dependency
npm install lodash@4.17.15

# Commit and watch pipeline fail
git add package.json package-lock.json
git commit -m "Add vulnerable dependency"
git push origin main

# Check GitHub Actions for security failures
```

### Experiment 5: Performance Testing Integration
```bash
# Run load test after deployment
kubectl apply -f performance-tests/load-test.yaml

# Watch test results
kubectl logs -f job/load-test
```

## 📊 Pipeline Monitoring

### Metrics Collection
```yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Alerting Rules
```yaml
groups:
- name: argocd
  rules:
  - alert: ArgoAppNotSynced
    expr: argocd_app_info{sync_status!="Synced"} == 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "ArgoCD application not synced"
      description: "Application {{ $labels.name }} is not synced for more than 5 minutes"
  
  - alert: ArgoAppNotHealthy
    expr: argocd_app_info{health_status!="Healthy"} == 1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "ArgoCD application not healthy"
      description: "Application {{ $labels.name }} is not healthy for more than 5 minutes"
```

### Dashboard Configuration
```json
{
  "dashboard": {
    "title": "CI/CD Pipeline Dashboard",
    "panels": [
      {
        "title": "Deployment Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(argocd_app_reconcile_count{phase=\"Succeeded\"}[5m])) / sum(rate(argocd_app_reconcile_count[5m]))",
            "legendFormat": "Success Rate"
          }
        ]
      },
      {
        "title": "Pipeline Duration",
        "type": "graph",
        "targets": [
          {
            "expr": "github_actions_workflow_run_duration_seconds",
            "legendFormat": "{{ workflow_name }}"
          }
        ]
      }
    ]
  }
}
```

## 🔐 Security and Compliance

### RBAC for ArgoCD
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow
    p, role:admin, repositories, *, *, allow
    
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, sync, dev/*, allow
    p, role:developer, applications, action/*, dev/*, allow
    
    g, developers, role:developer
    g, admins, role:admin
```

### Secret Management
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: pipeline-secrets
  namespace: argocd
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: pipeline-secrets
    creationPolicy: Owner
  data:
  - secretKey: github-token
    remoteRef:
      key: pipeline/github
      property: token
  - secretKey: registry-password
    remoteRef:
      key: pipeline/registry
      property: password
```

### Admission Controllers
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-signature
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: check-image-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "ghcr.io/your-org/*"
      attestors:
      - entries:
        - keys:
            secret:
              name: cosign-public-key
              namespace: kyverno
```

## 🐛 Troubleshooting

### ArgoCD Issues
```bash
# Check ArgoCD application status
kubectl describe application webapp-dev -n argocd

# View ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd

# Check sync errors
kubectl get events -n argocd | grep Error
```

### Pipeline Failures
```bash
# Check GitHub Actions logs
gh run list --repo ramishtaha/gitops-demo
gh run view RUN_ID --log

# Test image build locally
docker build -t webapp:test .
docker run --rm webapp:test
```

### Deployment Issues
```bash
# Check rollout status
kubectl argo rollouts get rollout webapp-rollout

# View rollout events
kubectl describe rollout webapp-rollout

# Check analysis results
kubectl describe analysisrun webapp-rollout-canary-analysis
```

## 🧹 Cleanup

Remove all resources:
```bash
# Delete ArgoCD applications
kubectl delete applications --all -n argocd

# Delete ArgoCD
kubectl delete namespace argocd

# Clean up namespaces
kubectl delete namespace dev staging production
```

## 🎯 Key Takeaways

1. **GitOps** provides declarative, version-controlled deployments
2. **ArgoCD** enables automated synchronization and drift detection
3. **Progressive delivery** reduces deployment risks
4. **Automated testing** catches issues early in the pipeline
5. **Security scanning** should be integrated into every pipeline
6. **Monitoring and alerting** are essential for pipeline reliability
7. **RBAC and compliance** ensure secure deployment practices

## 📚 Next Steps

Ready for Project 8? Proceed to [Monitoring and Observability](../08-monitoring-observability/) where you'll learn:
- Comprehensive monitoring with Prometheus and Grafana
- Distributed tracing with Jaeger
- Log aggregation and analysis
- SLI/SLO implementation and alerting

## 📖 Additional Reading

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Excellent work!** 🎉 You've implemented a production-grade CI/CD pipeline with GitOps. This foundation enables reliable, secure, and automated deployments at scale.
