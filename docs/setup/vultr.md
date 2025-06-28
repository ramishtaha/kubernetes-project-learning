# Vultr Kubernetes Engine (VKE) Setup Guide

This guide will help you set up a Vultr Kubernetes Engine (VKE) cluster for the Kubernetes Project-Based Learning repository.

## Prerequisites

### Required Tools
- **vultr-cli**: Vultr command-line interface
- **kubectl**: Kubernetes command-line tool
- **Vultr Account**: Active Vultr account

### Install vultr-cli

#### Windows
```powershell
# Download and install vultr-cli
$url = "https://github.com/vultr/vultr-cli/releases/latest/download/vultr-cli_windows_amd64.zip"
Invoke-WebRequest -Uri $url -OutFile "vultr-cli.zip"
Expand-Archive -Path "vultr-cli.zip" -DestinationPath "C:\Program Files\vultr-cli"
$env:PATH += ";C:\Program Files\vultr-cli"
```

#### macOS
```bash
# Install using Homebrew
brew install vultr-cli

# Or download directly
curl -sL https://github.com/vultr/vultr-cli/releases/latest/download/vultr-cli_darwin_amd64.tar.gz | tar -xzv
sudo mv vultr-cli /usr/local/bin
```

#### Linux
```bash
# Download and install vultr-cli
cd ~
wget https://github.com/vultr/vultr-cli/releases/latest/download/vultr-cli_linux_amd64.tar.gz
tar xf vultr-cli_linux_amd64.tar.gz
sudo mv vultr-cli /usr/local/bin
```

### Install kubectl
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## Authentication

### API Key Setup
```bash
# Get API key from Vultr Customer Portal
# Go to: Account > API > Generate API Key

# Configure vultr-cli
vultr-cli configure

# Verify authentication
vultr-cli account
```

### Environment Variables
```bash
# Alternative: set environment variable
export VULTR_API_KEY="your-api-key-here"

# Verify
vultr-cli account
```

## Cluster Creation

### Check Available Resources
```bash
# List available regions
vultr-cli regions list

# List available Kubernetes versions
vultr-cli kubernetes versions

# List available node pool plans
vultr-cli plans list --type vhf
```

### Basic VKE Cluster
```bash
# Create basic cluster
vultr-cli kubernetes create \
    --label "k8s-learning-cluster" \
    --region "ewr" \
    --version "v1.28.2+1" \
    --node-pools="quantity:3,plan:vhf-2c-4gb,label:worker-nodes,tag:production"
```

### Production-Ready VKE Cluster
```bash
# Create production cluster with multiple node pools
vultr-cli kubernetes create \
    --label "k8s-production-cluster" \
    --region "ewr" \
    --version "v1.28.2+1" \
    --node-pools="quantity:3,plan:vhf-4c-8gb,label:system-nodes,tag:system" \
    --node-pools="quantity:2,plan:vhf-8c-16gb,label:worker-nodes,tag:workers"
```

### High-Performance Cluster
```bash
# Create cluster with high-performance instances
vultr-cli kubernetes create \
    --label "k8s-hpc-cluster" \
    --region "ewr" \
    --version "v1.28.2+1" \
    --node-pools="quantity:3,plan:vhp-6c-32gb,label:compute-nodes,tag:hpc"
```

## Cluster Configuration

### Get Credentials
```bash
# List clusters
vultr-cli kubernetes list

# Get cluster ID
CLUSTER_ID=$(vultr-cli kubernetes list | grep "k8s-learning-cluster" | awk '{print $1}')

# Get kubeconfig
vultr-cli kubernetes config $CLUSTER_ID

# Save kubeconfig to file
vultr-cli kubernetes config $CLUSTER_ID > ~/.kube/vultr-config

# Set KUBECONFIG environment variable
export KUBECONFIG=~/.kube/vultr-config

# Verify connection
kubectl get nodes
kubectl cluster-info
```

### Merge with Existing Kubeconfig
```bash
# Merge with existing kubeconfig
KUBECONFIG=~/.kube/config:~/.kube/vultr-config kubectl config view --merge --flatten > ~/.kube/merged-config
mv ~/.kube/merged-config ~/.kube/config

# Switch context
kubectl config get-contexts
kubectl config use-context vultr-k8s-learning-cluster
```

## Storage Configuration

### Vultr Block Storage
```bash
# Install Vultr CSI driver
kubectl apply -f https://raw.githubusercontent.com/vultr/vultr-csi/master/deploy/vultr-csi.yaml

# Apply default storage class
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vultr-block-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: block.csi.vultr.com
parameters:
  type: high_perf
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### Storage Class Options
```bash
# High-performance storage
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vultr-high-perf
provisioner: block.csi.vultr.com
parameters:
  type: high_perf
  fstype: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF

# Standard storage (more cost-effective)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vultr-standard
provisioner: block.csi.vultr.com
parameters:
  type: standard
  fstype: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

## Networking Configuration

### Load Balancer Configuration
```bash
# Install Vultr CCM (Cloud Controller Manager)
kubectl apply -f https://raw.githubusercontent.com/vultr/vultr-cloud-controller-manager/master/docs/releases/vultr-ccm.yaml

# Create load balancer service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: example-service
  annotations:
    service.beta.kubernetes.io/vultr-loadbalancer-protocol: "tcp"
    service.beta.kubernetes.io/vultr-loadbalancer-algorithm: "roundrobin"
    service.beta.kubernetes.io/vultr-loadbalancer-proxy-protocol: "false"
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
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for load balancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Get external IP
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $EXTERNAL_IP"
```

### DNS Configuration with Cert-Manager
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

## Node Pool Management

### Add Node Pool
```bash
# Add new node pool
vultr-cli kubernetes node-pool create $CLUSTER_ID \
    --node-quantity 2 \
    --plan "vhf-4c-8gb" \
    --label "new-worker-pool" \
    --tag "workers"
```

### Update Node Pool
```bash
# List node pools
vultr-cli kubernetes node-pool list $CLUSTER_ID

# Update node pool quantity
NODE_POOL_ID=$(vultr-cli kubernetes node-pool list $CLUSTER_ID | grep "new-worker-pool" | awk '{print $1}')
vultr-cli kubernetes node-pool update $CLUSTER_ID $NODE_POOL_ID --node-quantity 3
```

### Delete Node Pool
```bash
# Delete node pool
vultr-cli kubernetes node-pool delete $CLUSTER_ID $NODE_POOL_ID
```

## Monitoring and Logging

### Install Metrics Server
```bash
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
    --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=vultr-block-storage
```

### Centralized Logging
```bash
# Install Loki stack for logging
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack \
    --namespace logging \
    --create-namespace \
    --set grafana.enabled=true \
    --set prometheus.enabled=true \
    --set promtail.enabled=true \
    --set loki.persistence.enabled=true \
    --set loki.persistence.storageClassName=vultr-block-storage \
    --set loki.persistence.size=30Gi
```

## Security Configuration

### Network Policies
```bash
# Install Calico for network policies (if not using Vultr's CNI)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Apply network policy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
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
  namespace: default
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

### RBAC Configuration
```bash
# Create service account for applications
kubectl create serviceaccount app-service-account

# Create role with specific permissions
kubectl create role app-role --verb=get,list,watch --resource=pods,services

# Bind role to service account
kubectl create rolebinding app-rolebinding --role=app-role --serviceaccount=default:app-service-account
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

### Cluster Autoscaler
```bash
# Note: Vultr doesn't have built-in cluster autoscaler
# Use manual scaling or implement custom solutions
# Scale node pool manually:
vultr-cli kubernetes node-pool update $CLUSTER_ID $NODE_POOL_ID --node-quantity 5
```

## Backup and Disaster Recovery

### Velero Backup Setup
```bash
# Install Velero
curl -fsSL -o velero-v1.12.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.12.1/velero-v1.12.1-linux-amd64.tar.gz
tar -xzf velero-v1.12.1-linux-amd64.tar.gz
sudo mv velero-v1.12.1-linux-amd64/velero /usr/local/bin/

# Create Vultr Object Storage bucket for backups
vultr-cli object-storage create --cluster-id 1 --label "velero-backups"

# Create credentials file for Vultr Object Storage
cat > credentials-velero << EOF
[default]
aws_access_key_id=<your-vultr-object-storage-key>
aws_secret_access_key=<your-vultr-object-storage-secret>
EOF

# Install Velero server
velero install \
    --provider aws \
    --plugins veltr/velero-plugin-for-aws:v1.8.0 \
    --bucket velero-backups \
    --secret-file ./credentials-velero \
    --backup-location-config region=us-east-1,s3ForcePathStyle="true",s3Url=https://ewr1.vultrobjects.com
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

### Node Pool Cost Management
```bash
# List available plans and their costs
vultr-cli plans list --type vhf

# Scale down for cost savings
vultr-cli kubernetes node-pool update $CLUSTER_ID $NODE_POOL_ID --node-quantity 1

# Use smaller instances for development
vultr-cli kubernetes node-pool create $CLUSTER_ID \
    --node-quantity 1 \
    --plan "vhf-1c-1gb" \
    --label "dev-pool" \
    --tag "development"
```

### Resource Monitoring
```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check resource requests vs limits
kubectl describe nodes
```

## Troubleshooting

### Common Issues

1. **Cluster creation failures**
   ```bash
   # Check cluster status
   vultr-cli kubernetes list
   vultr-cli kubernetes get $CLUSTER_ID
   
   # Check available resources
   vultr-cli plans list --type vhf
   vultr-cli regions list
   ```

2. **Node issues**
   ```bash
   # List node pools
   vultr-cli kubernetes node-pool list $CLUSTER_ID
   
   # Check node status
   kubectl get nodes -o wide
   kubectl describe nodes
   ```

3. **Load balancer issues**
   ```bash
   # Check Vultr load balancers
   vultr-cli load-balancer list
   
   # Check service status
   kubectl get svc -o wide
   kubectl describe svc <service-name>
   ```

### Debugging Commands
```bash
# Get cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check cluster information
vultr-cli kubernetes get $CLUSTER_ID

# View node pool details
vultr-cli kubernetes node-pool get $CLUSTER_ID $NODE_POOL_ID
```

## Cluster Upgrades

### Manual Upgrade
```bash
# Check available versions
vultr-cli kubernetes versions

# Upgrade cluster (not currently supported via CLI)
# Use Vultr Customer Portal for cluster upgrades
```

## Cleanup

### Delete Cluster
```bash
# Delete entire cluster
vultr-cli kubernetes delete $CLUSTER_ID

# Delete node pool
vultr-cli kubernetes node-pool delete $CLUSTER_ID $NODE_POOL_ID
```

### Clean Up Resources
```bash
# Delete load balancers
vultr-cli load-balancer list
vultr-cli load-balancer delete <lb-id>

# Delete block storage
vultr-cli block-storage list
vultr-cli block-storage delete <volume-id>

# Delete object storage
vultr-cli object-storage list
vultr-cli object-storage delete <storage-id>
```

## Best Practices

### Security
- Use private networks when possible
- Implement network policies
- Regular security updates
- Use RBAC for access control

### Performance
- Choose appropriate instance types
- Monitor resource usage
- Use high-performance storage for databases
- Optimize container resource requests/limits

### Cost Management
- Right-size node pools
- Regular cleanup of unused resources
- Monitor costs through Vultr portal
- Use appropriate storage types

## Additional Resources

- [Vultr Kubernetes Documentation](https://www.vultr.com/docs/vultr-kubernetes-engine/)
- [Vultr CLI Documentation](https://github.com/vultr/vultr-cli)
- [Vultr API Documentation](https://www.vultr.com/api/)
- [Vultr Community Resources](https://www.vultr.com/docs/)
