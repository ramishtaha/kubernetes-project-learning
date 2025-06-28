# DigitalOcean Kubernetes (DOKS) Setup Guide

This guide will help you set up a DigitalOcean Kubernetes Service (DOKS) cluster for the Kubernetes Project-Based Learning repository.

## Prerequisites

### Required Tools
- **doctl**: DigitalOcean command-line interface
- **kubectl**: Kubernetes command-line tool
- **DigitalOcean Account**: Active DigitalOcean account

### Install doctl

#### Windows
```powershell
# Download and install doctl
$url = "https://github.com/digitalocean/doctl/releases/latest/download/doctl-1.98.1-windows-amd64.zip"
Invoke-WebRequest -Uri $url -OutFile "doctl.zip"
Expand-Archive -Path "doctl.zip" -DestinationPath "C:\Program Files\doctl"
$env:PATH += ";C:\Program Files\doctl"
```

#### macOS
```bash
# Install using Homebrew
brew install doctl

# Or download directly
curl -sL https://github.com/digitalocean/doctl/releases/latest/download/doctl-1.98.1-darwin-amd64.tar.gz | tar -xzv
sudo mv doctl /usr/local/bin
```

#### Linux
```bash
# Download and install doctl
cd ~
wget https://github.com/digitalocean/doctl/releases/latest/download/doctl-1.98.1-linux-amd64.tar.gz
tar xf doctl-1.98.1-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin
```

### Install kubectl
```bash
# Install kubectl via doctl
doctl kubernetes cluster kubeconfig save <cluster-name>

# Or install directly
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## Authentication

### API Token Setup
```bash
# Get API token from DigitalOcean Control Panel
# Go to: API > Tokens/Keys > Generate New Token

# Authenticate doctl
doctl auth init

# Verify authentication
doctl account get
```

### Context Management
```bash
# List authentication contexts
doctl auth list

# Switch context
doctl auth switch --context <context-name>
```

## Cluster Creation

### Basic DOKS Cluster
```bash
# Create basic cluster
doctl kubernetes cluster create k8s-learning-cluster \
    --region nyc1 \
    --version 1.28.2-do.0 \
    --count 3 \
    --size s-2vcpu-4gb \
    --auto-upgrade=true \
    --surge-upgrade=true \
    --ha=false
```

### Production-Ready DOKS Cluster
```bash
# Create production cluster
doctl kubernetes cluster create k8s-production-cluster \
    --region nyc1 \
    --version 1.28.2-do.0 \
    --count 3 \
    --size s-4vcpu-8gb \
    --auto-upgrade=false \
    --surge-upgrade=true \
    --ha=true \
    --vpc-uuid $(doctl vpcs list --format ID --no-header | head -1) \
    --tag production,kubernetes
```

### Multi-Node Pool Cluster
```bash
# Create cluster with custom node pool
doctl kubernetes cluster create k8s-multi-pool \
    --region nyc1 \
    --version 1.28.2-do.0 \
    --count 2 \
    --size s-2vcpu-4gb \
    --node-pool-name system-pool \
    --auto-upgrade=true \
    --surge-upgrade=true

# Add additional node pool
doctl kubernetes cluster node-pool create k8s-multi-pool \
    --name worker-pool \
    --size s-4vcpu-8gb \
    --count 3 \
    --tag worker,production \
    --auto-scale \
    --min-nodes 1 \
    --max-nodes 5
```

## Cluster Configuration

### Get Credentials
```bash
# Get cluster credentials
doctl kubernetes cluster kubeconfig save k8s-learning-cluster

# Verify connection
kubectl get nodes
kubectl cluster-info
```

### Cluster Information
```bash
# List clusters
doctl kubernetes cluster list

# Get cluster details
doctl kubernetes cluster get k8s-learning-cluster

# Get cluster configuration
doctl kubernetes cluster kubeconfig show k8s-learning-cluster
```

## Storage Configuration

### DigitalOcean Block Storage
```bash
# Apply DigitalOcean CSI driver (pre-installed in DOKS)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: do-block-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: dobs.csi.digitalocean.com
parameters:
  type: gp2
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### DigitalOcean Spaces (S3-compatible)
```bash
# Create Spaces access credentials secret
kubectl create secret generic spaces-credentials \
    --from-literal=access-key-id=<your-spaces-key> \
    --from-literal=secret-access-key=<your-spaces-secret>

# Apply Spaces storage class
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: do-spaces
provisioner: kubernetes.io/no-provisioner
parameters:
  endpoint: nyc3.digitaloceanspaces.com
  bucket: your-bucket-name
volumeBindingMode: Immediate
EOF
```

## Networking Configuration

### Load Balancer Configuration
```bash
# DigitalOcean Load Balancer is automatically created for LoadBalancer services
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: example-service
  annotations:
    service.beta.kubernetes.io/do-loadbalancer-protocol: "http"
    service.beta.kubernetes.io/do-loadbalancer-algorithm: "round_robin"
    service.beta.kubernetes.io/do-loadbalancer-sticky-sessions-type: "cookies"
    service.beta.kubernetes.io/do-loadbalancer-sticky-sessions-cookie-name: "lb-cookie"
    service.beta.kubernetes.io/do-loadbalancer-sticky-sessions-cookie-ttl: "300"
spec:
  type: LoadBalancer
  selector:
    app: example-app
  ports:
  - port: 80
    targetPort: 8080
EOF
```

### Ingress Controller Setup
```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/do/deploy.yaml

# Wait for load balancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### Cert-Manager for TLS
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Create Let's Encrypt ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## Monitoring and Logging

### DigitalOcean Monitoring
```bash
# Enable cluster monitoring (done via DigitalOcean Control Panel)
# Go to: Kubernetes > Your Cluster > Insights

# Install metrics server (usually pre-installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Prometheus and Grafana Stack
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.enabled=true \
    --set alertmanager.enabled=true \
    --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
    --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=do-block-storage
```

### Centralized Logging with ELK
```bash
# Install Elasticsearch
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch \
    --namespace logging \
    --create-namespace \
    --set volumeClaimTemplate.resources.requests.storage=30Gi \
    --set volumeClaimTemplate.storageClassName=do-block-storage

# Install Kibana
helm install kibana elastic/kibana \
    --namespace logging

# Install Filebeat
helm install filebeat elastic/filebeat \
    --namespace logging
```

## Security Configuration

### RBAC Configuration
```bash
# Create service account for applications
kubectl create serviceaccount app-service-account

# Create role with specific permissions
kubectl create role app-role --verb=get,list,watch --resource=pods,services

# Bind role to service account
kubectl create rolebinding app-rolebinding --role=app-role --serviceaccount=default:app-service-account
```

### Network Policies
```bash
# Apply network policy for pod-to-pod communication
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
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
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: default
EOF
```

### Pod Security Standards
```bash
# Apply pod security standards
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
EOF
```

## Auto-scaling Configuration

### Horizontal Pod Autoscaler
```bash
# Deploy sample application with HPA
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hpa-example
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hpa-example
  template:
    metadata:
      labels:
        app: hpa-example
    spec:
      containers:
      - name: hpa-example
        image: nginx
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-example
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hpa-example
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
```

### Cluster Autoscaler (Node Pool Auto-scaling)
```bash
# Enable auto-scaling on existing node pool
doctl kubernetes cluster node-pool update k8s-learning-cluster system-pool \
    --auto-scale \
    --min-nodes 1 \
    --max-nodes 5
```

## Backup and Disaster Recovery

### Velero Backup Setup
```bash
# Create DigitalOcean Spaces bucket for backups
doctl compute ssh-key list # Get your SSH key ID
doctl spaces create velero-backups --region nyc3

# Install Velero
curl -fsSL -o velero-v1.12.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.12.1/velero-v1.12.1-linux-amd64.tar.gz
tar -xzf velero-v1.12.1-linux-amd64.tar.gz
sudo mv velero-v1.12.1-linux-amd64/velero /usr/local/bin/

# Create credentials file
cat > credentials-velero << EOF
[default]
aws_access_key_id=<your-spaces-key>
aws_secret_access_key=<your-spaces-secret>
EOF

# Install Velero server
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket velero-backups \
    --secret-file ./credentials-velero \
    --backup-location-config region=nyc3,s3ForcePathStyle="true",s3Url=https://nyc3.digitaloceanspaces.com
```

### Automated Backup Schedule
```bash
# Create daily backup schedule
velero schedule create daily-backup \
    --schedule="0 2 * * *" \
    --ttl 720h0m0s

# Create weekly backup with longer retention
velero schedule create weekly-backup \
    --schedule="0 1 * * 0" \
    --ttl 2160h0m0s \
    --include-namespaces "*"
```

## Cost Optimization

### Node Pool Management
```bash
# Scale down node pool
doctl kubernetes cluster node-pool update k8s-learning-cluster system-pool --count 1

# Delete unused node pool
doctl kubernetes cluster node-pool delete k8s-learning-cluster worker-pool

# List node pool costs
doctl kubernetes cluster node-pool list k8s-learning-cluster
```

### Resource Optimization
```bash
# Enable auto-scaling for cost optimization
doctl kubernetes cluster node-pool update k8s-learning-cluster system-pool \
    --auto-scale \
    --min-nodes 0 \
    --max-nodes 3

# Use smaller instance types for development
doctl kubernetes cluster node-pool create k8s-learning-cluster \
    --name dev-pool \
    --size s-1vcpu-2gb \
    --count 1 \
    --auto-scale \
    --min-nodes 0 \
    --max-nodes 2
```

## Troubleshooting

### Common Issues

1. **Cluster creation failures**
   ```bash
   # Check cluster status
   doctl kubernetes cluster get k8s-learning-cluster
   
   # Check available regions and sizes
   doctl kubernetes options regions
   doctl kubernetes options sizes
   ```

2. **Node issues**
   ```bash
   # List node pools
   doctl kubernetes cluster node-pool list k8s-learning-cluster
   
   # Get node pool details
   doctl kubernetes cluster node-pool get k8s-learning-cluster system-pool
   
   # Replace problematic nodes
   doctl kubernetes cluster node-pool recycle k8s-learning-cluster system-pool
   ```

3. **Load balancer issues**
   ```bash
   # Check load balancer status
   doctl compute load-balancer list
   
   # Get load balancer details
   kubectl get svc -o wide
   ```

### Debugging Commands
```bash
# Get cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check node status
kubectl describe nodes

# View cluster information
doctl kubernetes cluster get k8s-learning-cluster --format ID,Name,Status,Version,Region,NodePools
```

## Cluster Upgrades

### Manual Upgrade
```bash
# Check available versions
doctl kubernetes options versions

# Upgrade cluster
doctl kubernetes cluster upgrade k8s-learning-cluster --version 1.28.3-do.0

# Upgrade node pool
doctl kubernetes cluster node-pool upgrade k8s-learning-cluster system-pool --version 1.28.3-do.0
```

### Auto-upgrade Configuration
```bash
# Enable auto-upgrade
doctl kubernetes cluster update k8s-learning-cluster --auto-upgrade=true --surge-upgrade=true
```

## Cleanup

### Delete Cluster
```bash
# Delete entire cluster
doctl kubernetes cluster delete k8s-learning-cluster

# Delete specific node pool
doctl kubernetes cluster node-pool delete k8s-learning-cluster worker-pool
```

### Clean Up Resources
```bash
# Delete load balancers (if not automatically cleaned)
doctl compute load-balancer list
doctl compute load-balancer delete <lb-id>

# Delete volumes (if not automatically cleaned)
doctl compute volume list
doctl compute volume delete <volume-id>

# Delete Spaces bucket
doctl spaces delete velero-backups --force
```

## Best Practices

### Security
- Use private node pools for sensitive workloads
- Implement network policies
- Regular security updates
- Use RBAC for access control

### Performance
- Choose appropriate node sizes
- Use auto-scaling for variable workloads
- Monitor resource usage
- Optimize container resource requests/limits

### Cost Management
- Use auto-scaling to minimize costs
- Regular cleanup of unused resources
- Monitor usage with DigitalOcean monitoring
- Consider spot instances for dev/test (when available)

## Additional Resources

- [DigitalOcean Kubernetes Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [doctl CLI Reference](https://docs.digitalocean.com/reference/doctl/)
- [DOKS Best Practices](https://docs.digitalocean.com/products/kubernetes/how-to/)
- [DigitalOcean Community Tutorials](https://www.digitalocean.com/community/tags/kubernetes)
