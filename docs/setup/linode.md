# Linode Kubernetes Engine (LKE) Setup Guide

This guide will help you set up a Linode Kubernetes Engine (LKE) cluster for the Kubernetes Project-Based Learning repository.

## Prerequisites

### Required Tools
- **linode-cli**: Linode command-line interface
- **kubectl**: Kubernetes command-line tool
- **Linode Account**: Active Linode account

### Install linode-cli

#### Windows
```powershell
# Install Python and pip first, then install linode-cli
pip install linode-cli

# Or use pipx for isolated installation
pip install pipx
pipx install linode-cli
```

#### macOS
```bash
# Install using Homebrew
brew install linode-cli

# Or using pip
pip3 install linode-cli
```

#### Linux
```bash
# Install using pip
pip3 install linode-cli

# For Ubuntu/Debian
sudo apt update
sudo apt install python3-pip
pip3 install linode-cli

# For CentOS/RHEL
sudo yum install python3-pip
pip3 install linode-cli
```

### Install kubectl
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## Authentication

### API Token Setup
```bash
# Get Personal Access Token from Linode Cloud Manager
# Go to: Profile > API Tokens > Create A Personal Access Token

# Configure linode-cli
linode-cli configure

# Or set environment variable
export LINODE_CLI_TOKEN="your-personal-access-token"

# Verify authentication
linode-cli profile view
```

### Initial Configuration
```bash
# Configure default settings
linode-cli configure --token

# Verify configuration
linode-cli regions list
linode-cli linodes types
```

## Cluster Creation

### Check Available Resources
```bash
# List available regions
linode-cli regions list

# List available Kubernetes versions
linode-cli lke versions-list

# List available node types
linode-cli linodes types --json | jq '.[] | select(.type_class == "standard") | {id, label, vcpus, memory, disk, price}'
```

### Basic LKE Cluster
```bash
# Create basic cluster
linode-cli lke cluster-create \
    --label k8s-learning-cluster \
    --region us-east \
    --k8s_version 1.28 \
    --node_pools.type g6-standard-2 \
    --node_pools.count 3
```

### Production-Ready LKE Cluster
```bash
# Create production cluster with multiple node pools
linode-cli lke cluster-create \
    --label k8s-production-cluster \
    --region us-east \
    --k8s_version 1.28 \
    --node_pools.type g6-standard-4 \
    --node_pools.count 3 \
    --node_pools.type g6-highmem-2 \
    --node_pools.count 2 \
    --tags production,kubernetes
```

### High-Performance Cluster
```bash
# Create cluster with dedicated CPU instances
linode-cli lke cluster-create \
    --label k8s-hpc-cluster \
    --region us-east \
    --k8s_version 1.28 \
    --node_pools.type g6-dedicated-8 \
    --node_pools.count 3 \
    --tags hpc,dedicated
```

## Cluster Configuration

### Get Credentials
```bash
# List clusters
linode-cli lke clusters-list

# Get cluster ID
CLUSTER_ID=$(linode-cli lke clusters-list --text --no-headers | grep "k8s-learning-cluster" | awk '{print $1}')

# Get kubeconfig
linode-cli lke kubeconfig-view $CLUSTER_ID --text --no-headers | base64 -d > ~/.kube/lke-config

# Set KUBECONFIG environment variable
export KUBECONFIG=~/.kube/lke-config

# Verify connection
kubectl get nodes
kubectl cluster-info
```

### Merge with Existing Kubeconfig
```bash
# Backup existing config
cp ~/.kube/config ~/.kube/config.backup

# Merge configurations
KUBECONFIG=~/.kube/config:~/.kube/lke-config kubectl config view --merge --flatten > ~/.kube/merged-config
mv ~/.kube/merged-config ~/.kube/config

# Switch context
kubectl config get-contexts
kubectl config use-context lke-k8s-learning-cluster
```

## Storage Configuration

### Linode Block Storage CSI
```bash
# Install Linode CSI driver (usually pre-installed in LKE)
kubectl apply -f https://raw.githubusercontent.com/linode/linode-blockstorage-csi-driver/master/pkg/linode-bs/deploy/releases/linode-blockstorage-csi-driver.yaml

# Apply default storage class
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: linode-block-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: linodebs.csi.linode.com
parameters:
  type: "ext4"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### Storage Class Options
```bash
# High-performance NVMe storage
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: linode-block-storage-hdd
provisioner: linodebs.csi.linode.com
parameters:
  type: "ext4"
  linodefs: "ext4"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF

# Retain policy for important data
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: linode-block-storage-retain
provisioner: linodebs.csi.linode.com
parameters:
  type: "ext4"
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

## Networking Configuration

### Load Balancer Configuration
```bash
# Install Linode CCM (Cloud Controller Manager) - usually pre-installed
kubectl apply -f https://raw.githubusercontent.com/linode/linode-cloud-controller-manager/master/deploy/ccm-linode.yaml

# Create load balancer service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: example-service
  annotations:
    service.beta.kubernetes.io/linode-loadbalancer-protocol: "tcp"
    service.beta.kubernetes.io/linode-loadbalancer-check-type: "connection"
    service.beta.kubernetes.io/linode-loadbalancer-check-path: "/"
    service.beta.kubernetes.io/linode-loadbalancer-check-body: ""
    service.beta.kubernetes.io/linode-loadbalancer-algorithm: "roundrobin"
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
    - dns01:
        linode:
          apiKeySecretRef:
            name: linode-api-key
            key: token
EOF

# Create Linode API key secret for DNS validation
kubectl create secret generic linode-api-key --from-literal=token=$LINODE_CLI_TOKEN
```

## Node Pool Management

### Add Node Pool
```bash
# Add new node pool
linode-cli lke pool-create $CLUSTER_ID \
    --type g6-standard-4 \
    --count 2
```

### Update Node Pool
```bash
# List node pools
linode-cli lke pools-list $CLUSTER_ID

# Update node pool count
POOL_ID=$(linode-cli lke pools-list $CLUSTER_ID --text --no-headers | head -1 | awk '{print $1}')
linode-cli lke pool-update $CLUSTER_ID $POOL_ID --count 4
```

### Delete Node Pool
```bash
# Delete node pool
linode-cli lke pool-delete $CLUSTER_ID $POOL_ID
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
    --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=linode-block-storage
```

### Longhorn for Distributed Storage and Backups
```bash
# Install Longhorn for distributed storage
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/deploy/longhorn.yaml

# Access Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

### Centralized Logging with ELK
```bash
# Install Elasticsearch
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch \
    --namespace logging \
    --create-namespace \
    --set volumeClaimTemplate.resources.requests.storage=30Gi \
    --set volumeClaimTemplate.storageClassName=linode-block-storage

# Install Kibana
helm install kibana elastic/kibana \
    --namespace logging

# Install Filebeat
helm install filebeat elastic/filebeat \
    --namespace logging
```

## Security Configuration

### Network Policies with Calico
```bash
# Install Calico for network policies
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
# Install cluster autoscaler
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=linode
        - --nodes=1:10:$POOL_ID
        env:
        - name: LINODE_TOKEN
          valueFrom:
            secretKeyRef:
              name: linode-token
              key: token
EOF

# Create secret for Linode token
kubectl create secret generic linode-token --from-literal=token=$LINODE_CLI_TOKEN -n kube-system
```

## Backup and Disaster Recovery

### Velero Backup Setup
```bash
# Install Velero
curl -fsSL -o velero-v1.12.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.12.1/velero-v1.12.1-linux-amd64.tar.gz
tar -xzf velero-v1.12.1-linux-amd64.tar.gz
sudo mv velero-v1.12.1-linux-amd64/velero /usr/local/bin/

# Create Linode Object Storage bucket
linode-cli object-storage buckets create velero-backups --cluster us-east-1

# Get Object Storage keys
linode-cli object-storage keys-list

# Create credentials file
cat > credentials-velero << EOF
[default]
aws_access_key_id=<your-object-storage-key>
aws_secret_access_key=<your-object-storage-secret>
EOF

# Install Velero server
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket velero-backups \
    --secret-file ./credentials-velero \
    --backup-location-config region=us-east-1,s3ForcePathStyle="true",s3Url=https://us-east-1.linodeobjects.com
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
# List available instance types and pricing
linode-cli linodes types --json | jq '.[] | {id, label, vcpus, memory, disk, price}'

# Scale down for cost savings
linode-cli lke pool-update $CLUSTER_ID $POOL_ID --count 1

# Use smaller instances for development
linode-cli lke pool-create $CLUSTER_ID \
    --type g6-nanode-1 \
    --count 1
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
   linode-cli lke clusters-list
   linode-cli lke cluster-view $CLUSTER_ID
   
   # Check available resources
   linode-cli linodes types
   linode-cli regions list
   ```

2. **Node issues**
   ```bash
   # List node pools
   linode-cli lke pools-list $CLUSTER_ID
   
   # Check node status
   kubectl get nodes -o wide
   kubectl describe nodes
   ```

3. **Load balancer issues**
   ```bash
   # Check Linode load balancers
   linode-cli nodebalancers list
   
   # Check service status
   kubectl get svc -o wide
   kubectl describe svc <service-name>
   ```

### Debugging Commands
```bash
# Get cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check cluster information
linode-cli lke cluster-view $CLUSTER_ID

# View node pool details
linode-cli lke pool-view $CLUSTER_ID $POOL_ID
```

## Cluster Upgrades

### Upgrade Cluster
```bash
# Check available versions
linode-cli lke versions-list

# Upgrade cluster
linode-cli lke cluster-update $CLUSTER_ID --k8s_version 1.28

# Check upgrade status
linode-cli lke cluster-view $CLUSTER_ID
```

## Cleanup

### Delete Cluster
```bash
# Delete entire cluster
linode-cli lke cluster-delete $CLUSTER_ID

# Delete node pool
linode-cli lke pool-delete $CLUSTER_ID $POOL_ID
```

### Clean Up Resources
```bash
# Delete load balancers
linode-cli nodebalancers list
linode-cli nodebalancers delete <nodebalancer-id>

# Delete volumes
linode-cli volumes list
linode-cli volumes delete <volume-id>

# Delete object storage
linode-cli object-storage buckets delete velero-backups
```

## Best Practices

### Security
- Use private node pools when available
- Implement network policies
- Regular security updates
- Use RBAC for access control

### Performance
- Choose appropriate instance types
- Use dedicated CPU for compute-intensive workloads
- Monitor resource usage
- Optimize container resource requests/limits

### Cost Management
- Right-size node pools
- Use shared CPU instances for development
- Regular cleanup of unused resources
- Monitor costs through Linode Cloud Manager

## Additional Resources

- [Linode Kubernetes Engine Documentation](https://www.linode.com/docs/kubernetes/)
- [Linode CLI Documentation](https://www.linode.com/docs/api/linode-cli/)
- [Linode API Documentation](https://www.linode.com/api/v4/)
- [Linode Community Resources](https://www.linode.com/community/)
