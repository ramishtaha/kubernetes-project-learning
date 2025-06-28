# Project 11: Multi-Cluster Management 🌐

**Difficulty**: 🔴 Advanced  
**Time Estimate**: 6-8 hours  
**Prerequisites**: Projects 1-10 completed  

## 🎯 Learning Objectives

By the end of this project, you will:
- Manage multiple Kubernetes clusters with Cluster API
- Implement cross-cluster service discovery and communication
- Deploy multi-cluster service mesh with Istio
- Set up cluster federation and workload distribution
- Implement disaster recovery across clusters
- Monitor and observe multi-cluster environments

## 📋 Project Overview

You'll build a multi-cluster platform with:
- **Management Cluster**: Control plane for managing other clusters
- **Workload Clusters**: Production, staging, and development clusters
- **Service Mesh**: Cross-cluster service communication
- **GitOps**: Centralized configuration management
- **Monitoring**: Unified observability across all clusters
- **Disaster Recovery**: Automated failover and backup

### What We'll Build
- Three Kubernetes clusters (management, production, staging)
- Cluster API for cluster lifecycle management
- Multi-cluster Istio service mesh
- Cross-cluster service discovery
- Unified monitoring and logging
- Automated disaster recovery

## 🏗️ Architecture

```
Management Cluster (Control Plane)
├── Cluster API Controllers
├── ArgoCD (GitOps)
├── Prometheus (Monitoring)
└── Istio Control Plane
    ↓
Production Cluster ←→ Staging Cluster
├── Workloads        ├── Workloads
├── Istio Proxy      ├── Istio Proxy
└── Monitoring       └── Monitoring
```

## 🚀 Implementation Steps

### Step 1: Set up Management Cluster

Create the management cluster:

```bash
# Create management cluster
kind create cluster --name management --config manifests/01-management-cluster.yaml

# Switch context
kubectl config use-context kind-management
```

### Step 2: Install Cluster API

Install Cluster API on management cluster:

```bash
# Install clusterctl
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/latest/download/clusterctl-linux-amd64 -o clusterctl
sudo install clusterctl /usr/local/bin/

# Initialize Cluster API
export CLUSTER_TOPOLOGY=true
clusterctl init --infrastructure docker

# Verify installation
kubectl get pods -n capi-system
kubectl get pods -n capd-system
```

### Step 3: Create Workload Clusters

Deploy production and staging clusters:

```bash
# Create production cluster
kubectl apply -f manifests/02-production-cluster.yaml

# Create staging cluster
kubectl apply -f manifests/03-staging-cluster.yaml

# Wait for clusters to be ready
kubectl wait --for=condition=Ready cluster/production --timeout=600s
kubectl wait --for=condition=Ready cluster/staging --timeout=600s

# Get kubeconfig for workload clusters
clusterctl get kubeconfig production > production-kubeconfig.yaml
clusterctl get kubeconfig staging > staging-kubeconfig.yaml
```

### Step 4: Install Multi-Cluster Istio

Set up Istio across all clusters:

```bash
# Install Istio on management cluster
kubectl apply -f manifests/04-istio-management.yaml

# Install Istio on production cluster
kubectl --kubeconfig=production-kubeconfig.yaml apply -f manifests/05-istio-production.yaml

# Install Istio on staging cluster
kubectl --kubeconfig=staging-kubeconfig.yaml apply -f manifests/06-istio-staging.yaml

# Configure cross-cluster communication
kubectl apply -f manifests/07-istio-cross-cluster.yaml
```

### Step 5: Deploy Multi-Cluster ArgoCD

Set up GitOps for all clusters:

```bash
# Install ArgoCD on management cluster
kubectl apply -f manifests/08-argocd.yaml

# Configure cluster secrets
kubectl apply -f manifests/09-argocd-clusters.yaml

# Deploy applications across clusters
kubectl apply -f manifests/10-argocd-applications.yaml
```

### Step 6: Configure Monitoring

Set up unified monitoring:

```bash
# Install Prometheus federation
kubectl apply -f manifests/11-prometheus-federation.yaml

# Configure cross-cluster monitoring
kubectl apply -f manifests/12-monitoring-config.yaml
```

## 🛠️ Cluster API Deep Dive

### Cluster Definition
```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: production
  namespace: default
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["192.168.0.0/16"]
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: DockerCluster
    name: production
  controlPlaneRef:
    kind: KubeadmControlPlane
    apiVersion: controlplane.cluster.x-k8s.io/v1beta1
    name: production-control-plane
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: DockerCluster
metadata:
  name: production
  namespace: default
spec: {}
---
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: KubeadmControlPlane
metadata:
  name: production-control-plane
  namespace: default
spec:
  replicas: 3
  machineTemplate:
    infrastructureRef:
      kind: DockerMachineTemplate
      apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
      name: production-control-plane
  kubeadmConfigSpec:
    initConfiguration:
      nodeRegistration:
        criSocket: unix:///var/run/containerd/containerd.sock
        kubeletExtraArgs:
          cgroup-driver: systemd
    clusterConfiguration:
      controllerManager:
        extraArgs:
          enable-hostpath-provisioner: 'true'
    joinConfiguration:
      nodeRegistration:
        criSocket: unix:///var/run/containerd/containerd.sock
        kubeletExtraArgs:
          cgroup-driver: systemd
  version: v1.28.0
```

### Node Pool Configuration
```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineDeployment
metadata:
  name: production-workers
  namespace: default
spec:
  clusterName: production
  replicas: 3
  selector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: production
  template:
    spec:
      clusterName: production
      version: v1.28.0
      bootstrap:
        configRef:
          name: production-workers
          apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
          kind: KubeadmConfigTemplate
      infrastructureRef:
        name: production-workers
        apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
        kind: DockerMachineTemplate
```

## 🕸️ Multi-Cluster Service Mesh

### Cross-Cluster Service Discovery
```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: cross-cluster-service
  namespace: production
spec:
  hosts:
  - staging-service.staging.local
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  addresses:
  - 10.1.1.1  # Staging cluster service IP
  endpoints:
  - address: staging-cluster-endpoint
    ports:
      http: 80
```

### Multi-Cluster Gateway
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: cross-cluster-gateway
  namespace: istio-system
spec:
  selector:
    istio: eastwestgateway
  servers:
  - port:
      number: 15443
      name: tls
      protocol: TLS
    tls:
      mode: ISTIO_MUTUAL
    hosts:
    - "*.local"
```

### Traffic Routing
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: cross-cluster-routing
spec:
  hosts:
  - webapp.example.com
  gateways:
  - webapp-gateway
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: webapp-service.staging.local
      weight: 100
  - route:
    - destination:
        host: webapp-service.production.local
      weight: 100
```

## 🧪 Experiments to Try

### Experiment 1: Cross-Cluster Communication
```bash
# Deploy test applications
kubectl --kubeconfig=production-kubeconfig.yaml apply -f apps/production-app.yaml
kubectl --kubeconfig=staging-kubeconfig.yaml apply -f apps/staging-app.yaml

# Test cross-cluster connectivity
kubectl --kubeconfig=production-kubeconfig.yaml exec -it deployment/test-app -- \
  curl http://staging-service.staging.local/health
```

### Experiment 2: Cluster Scaling
```bash
# Scale production cluster nodes
kubectl patch machinedeployment production-workers --type='merge' -p='{"spec":{"replicas":5}}'

# Watch nodes being added
kubectl --kubeconfig=production-kubeconfig.yaml get nodes -w
```

### Experiment 3: Cluster Upgrade
```bash
# Upgrade control plane
kubectl patch kubeadmcontrolplane production-control-plane --type='merge' -p='{"spec":{"version":"v1.29.0"}}'

# Upgrade worker nodes
kubectl patch machinedeployment production-workers --type='merge' -p='{"spec":{"template":{"spec":{"version":"v1.29.0"}}}}'

# Monitor upgrade progress
clusterctl describe cluster production
```

### Experiment 4: Disaster Recovery
```bash
# Simulate production cluster failure
kubectl patch cluster production --type='merge' -p='{"spec":{"paused":true}}'

# Trigger failover to staging
kubectl apply -f disaster-recovery/failover-config.yaml

# Verify traffic routing
curl -H "Host: webapp.example.com" http://istio-gateway-ip/
```

### Experiment 5: Multi-Cluster Monitoring
```bash
# View unified metrics across clusters
kubectl port-forward -n monitoring svc/prometheus-federation 9090:9090

# Query cross-cluster metrics
# Visit http://localhost:9090 and run:
# sum by (cluster) (up{job="kubernetes-nodes"})
```

## 📊 Multi-Cluster Monitoring

### Prometheus Federation
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-federation-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    
    scrape_configs:
    - job_name: 'federate-production'
      scrape_interval: 15s
      honor_labels: true
      metrics_path: '/federate'
      params:
        'match[]':
          - '{job=~"kubernetes-.*"}'
          - '{__name__=~"up|prometheus_.*"}'
      static_configs:
        - targets:
          - 'production-prometheus.production.svc.cluster.local:9090'
    
    - job_name: 'federate-staging'
      scrape_interval: 15s
      honor_labels: true
      metrics_path: '/federate'
      params:
        'match[]':
          - '{job=~"kubernetes-.*"}'
          - '{__name__=~"up|prometheus_.*"}'
      static_configs:
        - targets:
          - 'staging-prometheus.staging.svc.cluster.local:9090'
```

### Grafana Dashboard
```json
{
  "dashboard": {
    "title": "Multi-Cluster Overview",
    "panels": [
      {
        "title": "Cluster Health",
        "type": "stat",
        "targets": [
          {
            "expr": "count by (cluster) (up{job=\"kubernetes-nodes\"} == 1)",
            "legendFormat": "{{ cluster }} - Healthy Nodes"
          }
        ]
      },
      {
        "title": "Cross-Cluster Traffic",
        "type": "graph",
        "targets": [
          {
            "expr": "sum by (source_cluster, destination_cluster) (istio_requests_total)",
            "legendFormat": "{{ source_cluster }} → {{ destination_cluster }}"
          }
        ]
      },
      {
        "title": "Resource Usage by Cluster",
        "type": "heatmap",
        "targets": [
          {
            "expr": "sum by (cluster) (node_cpu_seconds_total)",
            "legendFormat": "{{ cluster }}"
          }
        ]
      }
    ]
  }
}
```

## 🔄 GitOps for Multi-Cluster

### ArgoCD Application Sets
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-cluster-apps
  namespace: argocd
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: production
  - clusters:
      selector:
        matchLabels:
          environment: staging
  template:
    metadata:
      name: '{{name}}-webapp'
    spec:
      project: default
      source:
        repoURL: https://github.com/company/multi-cluster-apps
        targetRevision: HEAD
        path: 'apps/webapp/overlays/{{metadata.labels.environment}}'
      destination:
        server: '{{server}}'
        namespace: webapp
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

### Cluster Registration
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: production-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    environment: production
type: Opaque
stringData:
  name: production
  server: https://production-cluster-endpoint
  config: |
    {
      "bearerToken": "...",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "..."
      }
    }
```

## 🔐 Multi-Cluster Security

### Cross-Cluster RBAC
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cross-cluster-reader
rules:
- apiGroups: [""]
  resources: ["services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.istio.io"]
  resources: ["serviceentries", "virtualservices"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cross-cluster-readers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cross-cluster-reader
subjects:
- kind: ServiceAccount
  name: istio-reader-service-account
  namespace: istio-system
```

### Service Mesh Security Policies
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: cross-cluster-policy
  namespace: production
spec:
  selector:
    matchLabels:
      app: webapp
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/staging/sa/webapp-service-account"]
  - to:
    - operation:
        methods: ["GET", "POST"]
```

## 🚨 Disaster Recovery

### Automated Failover
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: multi-cluster-rollout
spec:
  replicas: 5
  strategy:
    canary:
      trafficRouting:
        istio:
          virtualService:
            name: webapp-vs
      steps:
      - setWeight: 20
      - pause: {}
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
        image: webapp:v2.0.0
```

### Backup Strategy
```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: multi-cluster-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"
  template:
    includedNamespaces:
    - production
    - staging
    excludedResources:
    - secrets
    storageLocation: aws-s3-backup
    ttl: 720h0m0s
```

## 🧹 Cleanup

### Delete Workload Clusters
```bash
# Delete applications first
kubectl --kubeconfig=production-kubeconfig.yaml delete --all deployments,services,pods
kubectl --kubeconfig=staging-kubeconfig.yaml delete --all deployments,services,pods

# Delete clusters via Cluster API
kubectl delete cluster production staging

# Wait for deletion
kubectl wait --for=delete cluster/production --timeout=600s
kubectl wait --for=delete cluster/staging --timeout=600s
```

### Delete Management Cluster
```bash
# Delete management cluster
kind delete cluster --name management

# Clean up generated files
rm -f production-kubeconfig.yaml staging-kubeconfig.yaml
```

## 🎯 Key Takeaways

1. **Cluster API** enables declarative cluster lifecycle management
2. **Multi-cluster service mesh** provides secure cross-cluster communication
3. **Federation** allows unified monitoring and policy management
4. **GitOps** scales effectively across multiple clusters
5. **Disaster recovery** requires automated failover mechanisms
6. **Security** becomes more complex with multiple trust domains
7. **Observability** needs federation and correlation across clusters

## 📚 Next Steps

Ready for Project 12? Proceed to [Custom Controllers and Operators](../12-custom-controllers/) where you'll learn:
- Building custom Kubernetes controllers
- Implementing operators with complex logic
- CRD design and versioning
- Controller patterns and best practices

## 📖 Additional Reading

- [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)
- [Istio Multi-Cluster](https://istio.io/latest/docs/setup/install/multicluster/)
- [ArgoCD Cluster Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters)
- [Multi-Cluster Service Mesh](https://istio.io/latest/docs/concepts/deployment-models/)

---

**Impressive achievement!** 🎉 You've mastered enterprise-grade multi-cluster management. This knowledge is essential for operating Kubernetes at scale in production environments.
