# 🚀 Setting up Kubernetes on Google GKE

Google Kubernetes Engine (GKE) is Google Cloud's fully managed Kubernetes service that provides enterprise-grade security, built-in monitoring, and seamless integration with Google Cloud services while eliminating the complexity of managing Kubernetes control planes.

## 🎯 What is Google GKE?

Google Kubernetes Engine offers a comprehensive managed Kubernetes platform with:

### 🔧 **Core Features**
- **🎛️ Fully Managed Control Plane**: Google manages masters across multiple zones
- **🏗️ High Availability**: 99.95% SLA with regional clusters
- **🔒 Enterprise Security**: Integrated with Google Cloud IAM, VPC, and security services
- **📈 Intelligent Auto-Scaling**: Pod, node, and cluster-level scaling
- **🔗 Native GCP Integration**: Seamless connection to 100+ Google Cloud services
- **🛡️ Compliance Ready**: SOC, PCI, ISO, HIPAA, FedRAMP compliant

### 🌟 **GKE Advantages**
- **Two Operating Modes**: Standard (full control) and Autopilot (hands-off)
- **Advanced Networking**: VPC-native clusters with Alias IP ranges
- **Built-in Monitoring**: Google Cloud Operations (formerly Stackdriver)
- **Binary Authorization**: Container image security and compliance
- **Workload Identity**: Secure pod-to-GCP service authentication

## 💰 Cost Breakdown & Optimization

### 📊 **GKE Pricing Structure**
| Component | Cost | Details |
|-----------|------|---------|
| **Standard Control Plane** | Free | No charge for cluster management |
| **Autopilot Control Plane** | $0.10/hour | ~$73/month for fully managed |
| **Worker Nodes** | Compute Engine pricing | e2-medium: ~$25/month |
| **Autopilot Pods** | $0.00445/vCPU/hour | Pay per pod resource usage |
| **Persistent Disks** | Storage pricing | Standard: $0.04/GB/month |
| **Load Balancers** | $18/month | Network Load Balancer |

### 💡 **Cost Optimization Strategies**
- ✅ **Preemptible Instances**: Save up to 80% for non-critical workloads
- ✅ **GKE Autopilot**: Eliminate node management overhead
- ✅ **Cluster Autoscaler**: Automatic scale-down during low usage
- ✅ **Committed Use Discounts**: 30-57% savings for predictable workloads
- ✅ **Right-sizing**: Use Google Cloud Recommender for optimization

## 🛠️ Prerequisites & Account Setup

### 📋 **Google Cloud Account Requirements**
- ✅ **Active Google Cloud Account** with billing enabled
- ✅ **Project** with Kubernetes Engine API enabled
- ✅ **IAM Permissions** for GKE cluster management
- ✅ **gcloud CLI** configured and authenticated

### 🔧 **Required Tools Installation**

#### **Windows Setup**
```powershell
# Install Google Cloud SDK
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe

# Install gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin

# Install kubectl
gcloud components install kubectl

# Verify installations
gcloud version
kubectl version --client
```

#### **macOS Setup**
```bash
# Install using Homebrew
brew install google-cloud-sdk

# Install gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin

# Install kubectl
gcloud components install kubectl

# Or install kubectl separately
brew install kubectl
```

#### **Linux Setup**
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin

# Install kubectl
gcloud components install kubectl

# Verify installations
gcloud version
kubectl version --client
```

### 🔐 **Google Cloud Setup & Authentication**
```bash
# Initialize gcloud and authenticate
gcloud init

# Set default project and region
gcloud config set project YOUR_PROJECT_ID
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage-api.googleapis.com

# Verify authentication
gcloud auth list
gcloud projects list
```

## 🚀 Cluster Creation

### Option 1: Google Cloud Console (Web GUI)

#### Step 1: Access Google Cloud Console
1. Log in to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **Kubernetes Engine** → **Clusters**
4. Click **Create**

#### Step 2: Choose Cluster Mode
1. **GKE Standard**: Full control over cluster configuration
2. **GKE Autopilot**: Fully managed, hands-off experience (recommended for beginners)

#### For GKE Standard:

#### Step 3: Cluster Basics
1. **Name**: `learning-cluster`
2. **Location type**: 
   - **Zonal**: Single zone (cheaper, less available)
   - **Regional**: Multiple zones (recommended, more expensive)
3. **Region/Zone**: Choose your preferred location (e.g., `us-central1`)
4. **Master version**: Use default (latest stable)

#### Step 4: Node Pools
1. **Default pool configuration**:
   - **Name**: `default-pool`
   - **Number of nodes**: 3
   - **Enable autoscaling**: ✅
   - **Minimum nodes**: 1
   - **Maximum nodes**: 5

#### Step 5: Nodes Configuration
1. **Machine configuration**:
   - **Machine family**: General-purpose
   - **Machine type**: `e2-medium` (2 vCPU, 4 GB memory)
   - **Boot disk type**: Standard persistent disk
   - **Boot disk size**: 100 GB
2. **Node security**:
   - **Service account**: Compute Engine default service account
   - **Access scopes**: Allow default access

#### Step 6: Cluster Configuration
1. **Networking**:
   - **Network**: default
   - **Node subnet**: default
   - **Enable VPC-native**: ✅ (recommended)
   - **Authorized networks**: Leave default for full access
2. **Security**:
   - **Enable Shielded GKE nodes**: ✅
   - **Enable Workload Identity**: ✅ (recommended)
3. **Features**:
   - **Enable HTTP load balancing**: ✅
   - **Enable Network policy**: Optional
   - **Enable Istio**: Optional

#### Step 7: Create Cluster
1. Review configuration
2. Click **Create**
3. **Wait for creation**: 5-10 minutes

#### For GKE Autopilot:

#### Step 3: Autopilot Configuration
1. **Name**: `learning-autopilot`
2. **Region**: Choose your preferred region (e.g., `us-central1`)
3. **Network**: default VPC
4. **Authorized networks**: Leave default
5. **Enable Workload Identity**: ✅
6. Click **Create**

#### Step 8: Configure kubectl Access
```bash
# For Standard cluster
gcloud container clusters get-credentials learning-cluster --zone us-central1-a

# For Autopilot cluster
gcloud container clusters get-credentials learning-autopilot --region us-central1

# Verify access
kubectl cluster-info
kubectl get nodes
```

### Option 2: Command Line Interface (gcloud)

#### Create Standard GKE Cluster
```bash
# Create cluster with default settings
gcloud container clusters create learning-cluster \
  --zone us-central1-a \
  --machine-type e2-medium \
  --num-nodes 3 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 5 \
  --enable-autorepair \
  --enable-autoupgrade \
  --disk-size 20GB \
  --disk-type pd-standard

# This creates:
# - GKE cluster with 3 e2-medium nodes
# - Auto-scaling enabled (1-5 nodes)
# - Auto-repair and auto-upgrade enabled
# - 20GB persistent disks per node
```

### Get Cluster Credentials
```bash
# Configure kubectl
gcloud container clusters get-credentials learning-cluster --zone us-central1-a

# Verify setup
kubectl cluster-info
kubectl get nodes
```

## ⚡ GKE Autopilot Setup

### Create Autopilot Cluster
```bash
# Create Autopilot cluster (fully managed)
gcloud container clusters create-auto learning-autopilot \
  --region us-central1

# Get credentials
gcloud container clusters get-credentials learning-autopilot --region us-central1

# Verify setup
kubectl get nodes
```

## ⚙️ Advanced Setup

### Custom Standard Cluster
```bash
# Create advanced standard cluster
gcloud container clusters create advanced-learning-cluster \
  --zone us-central1-a \
  --cluster-version latest \
  --machine-type e2-standard-4 \
  --num-nodes 2 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 10 \
  --disk-size 50GB \
  --disk-type pd-ssd \
  --enable-network-policy \
  --enable-ip-alias \
  --enable-autoupgrade \
  --enable-autorepair \
  --max-surge 1 \
  --max-unavailable 0 \
  --enable-shielded-nodes \
  --shielded-secure-boot \
  --shielded-integrity-monitoring \
  --workload-pool=PROJECT_ID.svc.id.goog \
  --enable-autoprovisioning \
  --max-cpu 64 \
  --max-memory 256 \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS,ConfigConnector
```

### Multi-Zone Cluster
```bash
# Create regional cluster across multiple zones
gcloud container clusters create multi-zone-cluster \
  --region us-central1 \
  --machine-type e2-standard-2 \
  --num-nodes 1 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 3 \
  --enable-network-policy \
  --enable-ip-alias
```

### Node Pools, GPU, and Preemptible Nodes
```bash
# Add GPU node pool
gcloud container node-pools create gpu-pool \
  --cluster learning-cluster --zone us-central1-a \
  --machine-type n1-standard-2 --accelerator type=nvidia-tesla-k80,count=1 \
  --num-nodes 0 --enable-autoscaling --min-nodes 0 --max-nodes 3

# Add preemptible node pool
gcloud container node-pools create preemptible-pool \
  --cluster learning-cluster --zone us-central1-a \
  --machine-type e2-medium --preemptible --num-nodes 0 \
  --enable-autoscaling --min-nodes 0 --max-nodes 5
```

## 🎛️ Essential GKE Commands
```bash
# List clusters
gcloud container clusters list
# Get cluster credentials
gcloud container clusters get-credentials learning-cluster --zone us-central1-a
# List nodes and pods
kubectl get nodes
kubectl get pods --all-namespaces
# View cluster info
kubectl cluster-info
```

## 🧪 Testing Your GKE Cluster
```bash
# Deploy a sample app
kubectl create deployment hello-gke --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-gke --type=LoadBalancer --port=80 --target-port=8080
# Wait for external IP
kubectl get service hello-gke -w
# Test access
curl http://<EXTERNAL-IP>
```

## 🔧 Essential GKE Configurations

### Install NGINX Ingress Controller
```bash
# Install using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalTrafficPolicy=Local
```

### Configure Workload Identity
```bash
# Enable Workload Identity on cluster
gcloud container clusters update learning-cluster \
  --zone us-central1-a \
  --workload-pool=PROJECT_ID.svc.id.goog

# Enable on node pool
gcloud container node-pools update default-pool \
  --cluster learning-cluster \
  --zone us-central1-a \
  --workload-metadata=GKE_METADATA

# Create Google Service Account
gcloud iam service-accounts create gke-workload-sa \
  --display-name "GKE Workload Service Account"

# Create Kubernetes Service Account
kubectl create serviceaccount gke-workload-ksa \
  --namespace default

# Bind the accounts
gcloud iam service-accounts add-iam-policy-binding \
  gke-workload-sa@PROJECT_ID.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:PROJECT_ID.svc.id.goog[default/gke-workload-ksa]"

# Annotate Kubernetes service account
kubectl annotate serviceaccount gke-workload-ksa \
  iam.gke.io/gcp-service-account=gke-workload-sa@PROJECT_ID.iam.gserviceaccount.com
```

### Setup Google Cloud Load Balancer
```bash
# Deploy sample application with load balancer
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gke-sample-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gke-sample-app
  template:
    metadata:
      labels:
        app: gke-sample-app
    spec:
      containers:
      - name: app
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: gke-sample-service
  annotations:
    cloud.google.com/load-balancer-type: "External"
spec:
  selector:
    app: gke-sample-app
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
EOF

# Wait for external IP
kubectl get service gke-sample-service -w
```

## 📊 Monitoring and Logging

### Enable Google Cloud Operations
```bash
# Operations suite is enabled by default on GKE
# Check monitoring
kubectl get pods -n kube-system | grep gke-metrics-agent

# Check logging
kubectl get pods -n kube-system | grep fluentbit-gke
```

### Install Prometheus
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus with GKE optimizations
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false
```

### Configure Cloud Logging
```bash
# Create custom log sink
gcloud logging sinks create gke-sink \
  storage.googleapis.com/my-gke-logs-bucket \
  --log-filter='resource.type="k8s_container"'

# View logs
gcloud logging read 'resource.type="k8s_container"' --limit 10
```

## 🌐 Networking Features

### Configure Ingress with Google Cloud Load Balancer
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gke-ingress
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.global-static-ip-name: "web-static-ip"
    networking.gke.io/managed-certificates: "web-ssl-cert"
    kubernetes.io/ingress.allow-http: "false"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gke-sample-service
            port:
              number: 80
```

### Managed SSL Certificates
```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: web-ssl-cert
spec:
  domains:
  - example.com
  - www.example.com
```

## 🔄 CI/CD Integration

### Cloud Build Integration
```yaml
# cloudbuild.yaml
steps:
# Build container image
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/$PROJECT_ID/app:$COMMIT_SHA', '.']

# Push to Container Registry
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'gcr.io/$PROJECT_ID/app:$COMMIT_SHA']

# Deploy to GKE
- name: 'gcr.io/cloud-builders/gke-deploy'
  args:
  - run
  - --filename=k8s/
  - --image=gcr.io/$PROJECT_ID/app:$COMMIT_SHA
  - --location=us-central1-a
  - --cluster=learning-cluster
```

### Configure Cloud Build Trigger
```bash
# Create trigger for GitHub repository
gcloud builds triggers create github \
  --repo-name=your-repo \
  --repo-owner=ramishtaha \
  --branch-pattern="main" \
  --build-config=cloudbuild.yaml
```

## 🧹 Cleanup

### Delete Applications
```bash
# Delete sample applications
kubectl delete deployment gke-sample-app resource-intensive
kubectl delete service gke-sample-service
kubectl delete hpa gke-sample-app-hpa
kubectl delete pod test-pod
kubectl delete pvc test-pvc

# Delete monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

### Delete Node Pools
```bash
# Delete additional node pools
gcloud container node-pools delete gpu-pool \
  --cluster learning-cluster \
  --zone us-central1-a \
  --quiet

gcloud container node-pools delete preemptible-pool \
  --cluster learning-cluster \
  --zone us-central1-a \
  --quiet
```

### Delete Clusters
```bash
# Delete standard cluster
gcloud container clusters delete learning-cluster \
  --zone us-central1-a \
  --quiet

# Delete Autopilot cluster
gcloud container clusters delete learning-autopilot \
  --region us-central1 \
  --quiet

# Delete advanced cluster
gcloud container clusters delete advanced-learning-cluster \
  --zone us-central1-a \
  --quiet
```

## 🐛 Troubleshooting

### Common Issues

#### Cluster Creation Fails
```bash
# Check quotas
gcloud compute project-info describe --project=PROJECT_ID

# Check available zones
gcloud compute zones list --filter="region=us-central1"

# Check service account permissions
gcloud projects get-iam-policy PROJECT_ID
```

#### Pods Stuck in Pending
```bash
# Check node resources
kubectl describe nodes

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check cluster autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

#### Workload Identity Issues
```bash
# Check service account binding
gcloud iam service-accounts get-iam-policy \
  gke-workload-sa@PROJECT_ID.iam.gserviceaccount.com

# Verify annotation
kubectl describe serviceaccount gke-workload-ksa
```

### Debug Commands
```bash
# Check cluster status
gcloud container clusters describe learning-cluster --zone us-central1-a

# View cluster operations
gcloud container operations list

# Check node pool status
gcloud container node-pools describe default-pool \
  --cluster learning-cluster \
  --zone us-central1-a
```

## 💡 Tips and Best Practices

### Cost Optimization
- Use preemptible instances for development workloads
- Enable cluster autoscaler
- Use appropriate machine types for your workload
- Consider GKE Autopilot for hands-off management

### Security
- Enable Workload Identity for pod-to-GCP authentication
- Use Binary Authorization for container image security
- Implement network policies
- Enable Shielded GKE nodes

### Performance
- Use SSD persistent disks for I/O intensive workloads
- Configure appropriate resource requests and limits
- Use regional persistent disks for high availability
- Enable horizontal pod autoscaling

### Operations
- Use Google Cloud Operations for monitoring and logging
- Set up alerting policies in Cloud Monitoring
- Use Cloud Build for CI/CD pipelines
- Implement proper RBAC

## 📚 Learning Path & Resources
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Kubernetes Learning Projects](../../01-beginner/01-hello-kubernetes/)

---

**Ready to start your projects on GKE?** Your cluster is now configured and ready for the Kubernetes learning projects. Head back to [Project 1](../../01-beginner/01-hello-kubernetes/) to begin!
