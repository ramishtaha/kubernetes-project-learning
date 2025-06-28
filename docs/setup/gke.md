# Setting up Kubernetes on Google GKE

Google Kubernetes Engine (GKE) is a managed Kubernetes service that provides a fully managed control plane and streamlined workflow for deploying, managing, and scaling containerized applications.

## 🎯 What is GKE?

GKE provides:
- **Managed Control Plane**: Google manages the Kubernetes masters
- **Auto-scaling**: Automatic cluster and pod scaling
- **Security**: Integrated with Google Cloud security services
- **Networking**: Advanced networking with VPC-native clusters
- **Operations**: Integrated logging, monitoring, and debugging

## 💰 Cost Considerations

### GKE Pricing
- **Control Plane**: Free for standard clusters, $0.10/hour for Autopilot
- **Worker Nodes**: Standard Compute Engine pricing
- **GKE Autopilot**: Pay only for pods requested CPU/memory
- **Network**: Standard networking charges

### Cost Optimization Tips
- Use Preemptible instances for development
- Enable cluster autoscaler
- Use GKE Autopilot for hands-off management
- Right-size your node pools

## 🛠️ Prerequisites

### Required Tools
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install kubectl (if not already installed)
gcloud components install kubectl

# Install gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin
```

### Google Cloud Setup
```bash
# Initialize gcloud
gcloud init

# Set default project and region
gcloud config set project YOUR_PROJECT_ID
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage-api.googleapis.com
```

## 🚀 Quick Setup (10 minutes)

### Create Standard GKE Cluster
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

### Node Pools Configuration
```bash
# Add GPU node pool
gcloud container node-pools create gpu-pool \
  --cluster learning-cluster \
  --zone us-central1-a \
  --machine-type n1-standard-2 \
  --accelerator type=nvidia-tesla-k80,count=1 \
  --num-nodes 0 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 3 \
  --enable-autorepair \
  --enable-autoupgrade

# Add preemptible node pool for cost savings
gcloud container node-pools create preemptible-pool \
  --cluster learning-cluster \
  --zone us-central1-a \
  --machine-type e2-medium \
  --preemptible \
  --num-nodes 0 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 5

# Add high-memory node pool
gcloud container node-pools create high-memory-pool \
  --cluster learning-cluster \
  --zone us-central1-a \
  --machine-type n2-highmem-2 \
  --num-nodes 0 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 2 \
  --node-taints=workload=memory-intensive:NoSchedule
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

## 🧪 Testing Your GKE Cluster

### Deploy Horizontal Pod Autoscaler
```bash
# Deploy HPA
kubectl apply -f - << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gke-sample-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gke-sample-app
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF

# Generate load to test autoscaling
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod:
# while true; do wget -q -O- http://gke-sample-service/; done

# Watch scaling
kubectl get hpa -w
```

### Test Cluster Autoscaling
```bash
# Create resource-intensive deployment
kubectl apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-intensive
spec:
  replicas: 10
  selector:
    matchLabels:
      app: resource-intensive
  template:
    metadata:
      labels:
        app: resource-intensive
    spec:
      containers:
      - name: app
        image: nginx
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
EOF

# Watch nodes being added
kubectl get nodes -w

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 💾 Storage Configuration

### Create Storage Classes
```yaml
# SSD Storage Class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
  zones: us-central1-a,us-central1-b
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

### Test Persistent Volumes
```bash
# Create PVC
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 10Gi
EOF

# Create pod using PVC
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-container
    image: nginx
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-pvc
EOF

# Verify volume is mounted
kubectl exec test-pod -- df -h /data
```

## 🔐 Security Configuration

### Enable Binary Authorization
```bash
# Enable Binary Authorization
gcloud container binauthz policy import policy.yaml

# Create attestor
gcloud container binauthz attestors create prod-attestor \
  --attestation-authority-note=projects/PROJECT_ID/notes/prod-note \
  --attestation-authority-note-public-key=prod-key.pub
```

### Configure Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
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
```

### Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
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

## 📚 Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)

---

**Ready to start your projects on GKE?** Your cluster is now configured and ready for the Kubernetes learning projects. Head back to [Project 1](../../01-beginner/01-hello-kubernetes/) to begin!
