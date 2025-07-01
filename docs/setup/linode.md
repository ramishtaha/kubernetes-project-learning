# 🚀 Setting up Kubernetes on Linode LKE

Linode Kubernetes Engine (LKE) is a fully managed Kubernetes platform that provides simple, affordable, and scalable clusters with integrated load balancers, storage, and monitoring.

## 🎯 What is Linode LKE?

### 🔧 **Core Features**
- **🎛️ Managed Control Plane**: Linode manages Kubernetes masters
- **🏗️ High Availability**: Optional HA control plane
- **🔒 Security**: Integrated with Linode VPC and RBAC
- **📈 Auto-Scaling**: Node pool autoscaling
- **🔗 Native Linode Integration**: Load balancers, block storage, monitoring
- **💸 Predictable Pricing**: Flat-rate, no surprises

### 🌟 **LKE Advantages**
- **No control plane fees** for standard clusters
- **Simple, fast cluster creation**
- **Integrated with Linode developer tools**
- **Easy scaling and upgrades**

## 💰 Cost Breakdown & Optimization

| Component | Cost | Details |
|-----------|------|---------|
| **Control Plane** | Free | No charge for cluster management |
| **Worker Nodes** | Linode pricing | 2GB Standard: ~$10/month |
| **Load Balancers** | $10/month | Linode NodeBalancer |
| **Block Storage** | $0.10/GB/month | SSD Volumes |

### 💡 **Cost Optimization Strategies**
- ✅ **Auto-scaling node pools**: Scale down unused nodes
- ✅ **Right-sizing**: Use monitoring to optimize node size
- ✅ **HA only for production**: Save on dev/test

## 🛠️ Prerequisites & Account Setup

### 📋 **Linode Account Requirements**
- ✅ **Active Linode Account**
- ✅ **Personal Access Token** with write access
- ✅ **linode-cli** and **kubectl** installed

### 🔧 **Required Tools Installation**

#### **Windows Setup**
```powershell
pip install linode-cli
```

#### **macOS Setup**
```bash
brew install linode-cli
```

#### **Linux Setup**
```bash
pip3 install linode-cli
```

### 🔐 **Authentication**
```bash
linode-cli configure
linode-cli profile view
```

## 🚦 Quick Start (Standard Cluster)

### Web Console (GUI)
1. Log in to [Linode Cloud Manager](https://cloud.linode.com/)
2. Go to **Kubernetes > Create Cluster**
3. Fill in:
   - Label: `k8s-learning-cluster`
   - Region: your preferred region
   - Version: latest stable
   - Node pool: 3 nodes, 2GB Standard
   - HA: Disabled (for learning)
4. Click **Create Cluster** and wait for provisioning
5. Download kubeconfig for `kubectl` setup

### Command Line (CLI)
```bash
linode-cli lke cluster-create \
  --label k8s-learning-cluster \
  --region us-east \
  --k8s_version 1.28 \
  --node_pools.type g6-standard-2 \
  --node_pools.count 3

# Get kubeconfig
linode-cli lke kubeconfig-view k8s-learning-cluster > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl get nodes
```

## ⚙️ Advanced Setup

### Custom Cluster Configuration (CLI)
```bash
linode-cli lke cluster-create \
  --label advanced-learning-cluster \
  --region us-east \
  --k8s_version 1.28 \
  --node_pools.type g6-standard-4 \
  --node_pools.count 3 \
  --control_plane_ha true
```

### Multi-Node Pools
```bash
linode-cli lke node-pool-create k8s-learning-cluster \
  --type g6-standard-4 \
  --count 2
```

## 🎛️ Essential LKE Commands
```bash
linode-cli lke cluster-list
linode-cli lke cluster-view k8s-learning-cluster
linode-cli lke kubeconfig-view k8s-learning-cluster > kubeconfig.yaml
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🧪 Testing Your LKE Cluster
```bash
kubectl create deployment hello-lke --image=nginx
kubectl expose deployment hello-lke --type=LoadBalancer --port=80
kubectl get service hello-lke -w
curl http://<EXTERNAL-IP>
```

## 🐛 Troubleshooting
- **Cluster creation fails**: Check API token, quota, and region
- **Nodes not joining**: Check node pool status
- **Pod scheduling issues**: Check node resources and events
- **Network issues**: Check firewall and VPC settings

## 💡 Tips and Best Practices
- Use HA only for production
- Enable auto-upgrade for security
- Use tags for resource management
- Monitor with Linode Monitoring and Prometheus

## 📚 Learning Path & Resources
- [LKE Documentation](https://www.linode.com/docs/products/compute/kubernetes/)
- [LKE Best Practices](https://www.linode.com/docs/guides/linode-kubernetes-engine-best-practices/)
- [Kubernetes Learning Projects](../../01-beginner/01-hello-kubernetes/)

---

**Ready to start your projects on LKE?** Your cluster is now configured and ready for the Kubernetes learning projects. Head back to [Project 1](../../01-beginner/01-hello-kubernetes/) to begin!
