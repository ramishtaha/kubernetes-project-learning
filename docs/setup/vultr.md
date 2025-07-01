# 🚀 Setting up Kubernetes on Vultr Kubernetes Engine (VKE)

Vultr Kubernetes Engine (VKE) is a fully managed Kubernetes platform that provides affordable, scalable clusters with integrated load balancers, block storage, and a global network.

## 🎯 What is Vultr VKE?

### 🔧 **Core Features**
- **🎛️ Managed Control Plane**: Vultr manages Kubernetes masters
- **🏗️ High Availability**: Free control plane, multi-region support
- **🔒 Security**: Integrated with Vultr VPC and RBAC
- **📈 Auto-Scaling**: Node pool autoscaling
- **🔗 Native Vultr Integration**: Load balancers, block storage, monitoring
- **💸 Predictable Pricing**: Flat-rate, no surprises

### 🌟 **VKE Advantages**
- **No control plane fees** for standard clusters
- **Simple, fast cluster creation**
- **Integrated with Vultr developer tools**
- **Easy scaling and upgrades**

## 💰 Cost Breakdown & Optimization

| Component | Cost | Details |
|-----------|------|---------|
| **Control Plane** | Free | No charge for cluster management |
| **Worker Nodes** | Vultr pricing | 2 vCPU, 4GB: ~$24/month |
| **Load Balancers** | $10/month | Vultr Load Balancer |
| **Block Storage** | $1/month per 10GB | SSD Volumes |

### 💡 **Cost Optimization Strategies**
- ✅ **Auto-scaling node pools**: Scale down unused nodes
- ✅ **Right-sizing**: Use monitoring to optimize node size
- ✅ **HA only for production**: Save on dev/test

## 🛠️ Prerequisites & Account Setup

### 📋 **Vultr Account Requirements**
- ✅ **Active Vultr Account**
- ✅ **API Key** with write access
- ✅ **vultr-cli** and **kubectl** installed

### 🔧 **Required Tools Installation**

#### **Windows Setup**
```powershell
choco install vultr-cli
```

#### **macOS Setup**
```bash
brew install vultr/vultr/vultr-cli
```

#### **Linux Setup**
```bash
curl -s https://raw.githubusercontent.com/vultr/vultr-cli/master/install.sh | sudo bash
```

### 🔐 **Authentication**
```bash
vultr-cli auth login
vultr-cli account info
```

## 🚦 Quick Start (Standard Cluster)

### Web Console (GUI)
1. Log in to [Vultr Control Panel](https://my.vultr.com/kubernetes/)
2. Click **Deploy Kubernetes Cluster**
3. Fill in:
   - Name: `k8s-learning-cluster`
   - Region: your preferred region
   - Version: latest stable
   - Node pool: 3 nodes, 2 vCPU, 4GB
4. Click **Deploy Now** and wait for provisioning
5. Download kubeconfig for `kubectl` setup

### Command Line (CLI)
```bash
vultr-cli kubernetes cluster create \
  --label k8s-learning-cluster \
  --region ewr \
  --version 1.28 \
  --node-pool-plan vc2-2c-4gb \
  --node-pool-count 3

# Get kubeconfig
vultr-cli kubernetes cluster kubeconfig k8s-learning-cluster > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl get nodes
```

## ⚙️ Advanced Setup

### Custom Cluster Configuration (CLI)
```bash
vultr-cli kubernetes cluster create \
  --label advanced-learning-cluster \
  --region ewr \
  --version 1.28 \
  --node-pool-plan vc2-4c-8gb \
  --node-pool-count 3 \
  --high-availability true
```

### Multi-Node Pools
```bash
vultr-cli kubernetes node-pool create k8s-learning-cluster \
  --plan vc2-4c-8gb \
  --count 2
```

## 🎛️ Essential VKE Commands
```bash
vultr-cli kubernetes cluster list
vultr-cli kubernetes cluster info k8s-learning-cluster
vultr-cli kubernetes cluster kubeconfig k8s-learning-cluster > kubeconfig.yaml
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🧪 Testing Your VKE Cluster
```bash
kubectl create deployment hello-vke --image=nginx
kubectl expose deployment hello-vke --type=LoadBalancer --port=80
kubectl get service hello-vke -w
curl http://<EXTERNAL-IP>
```

## 🐛 Troubleshooting
- **Cluster creation fails**: Check API key, quota, and region
- **Nodes not joining**: Check node pool status
- **Pod scheduling issues**: Check node resources and events
- **Network issues**: Check firewall and VPC settings

## 💡 Tips and Best Practices
- Use HA only for production
- Enable auto-upgrade for security
- Use tags for resource management
- Monitor with Vultr Monitoring and Prometheus

## 📚 Learning Path & Resources
- [VKE Documentation](https://www.vultr.com/docs/vultr-kubernetes-engine/)
- [VKE Best Practices](https://www.vultr.com/docs/guides/vultr-kubernetes-engine-best-practices/)
- [Kubernetes Learning Projects](../../01-beginner/01-hello-kubernetes/)

---

**Ready to start your projects on VKE?** Your cluster is now configured and ready for the Kubernetes learning projects. Head back to [Project 1](../../01-beginner/01-hello-kubernetes/) to begin!
