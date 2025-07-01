# 🚀 Setting up Kubernetes on DigitalOcean DOKS

DigitalOcean Kubernetes Service (DOKS) is a fully managed Kubernetes platform that provides simple, scalable, and cost-effective clusters with integrated load balancers, storage, and monitoring.

## 🎯 What is DigitalOcean DOKS?

### 🔧 **Core Features**
- **🎛️ Managed Control Plane**: DigitalOcean manages Kubernetes masters
- **🏗️ High Availability**: Free control plane, optional HA for production
- **🔒 Security**: Integrated with DigitalOcean VPC and RBAC
- **📈 Auto-Scaling**: Node pool autoscaling
- **🔗 Native DO Integration**: Load balancers, block storage, monitoring
- **💸 Predictable Pricing**: Flat-rate, no surprises

### 🌟 **DOKS Advantages**
- **No control plane fees** for standard clusters
- **Simple, fast cluster creation**
- **Integrated with DigitalOcean developer tools**
- **Easy scaling and upgrades**

## 💰 Cost Breakdown & Optimization

| Component | Cost | Details |
|-----------|------|---------|
| **Control Plane** | Free | No charge for cluster management |
| **Worker Nodes** | Droplet pricing | s-2vcpu-4gb: ~$24/month |
| **Load Balancers** | $12/month | DigitalOcean Load Balancer |
| **Block Storage** | $0.10/GB/month | SSD Volumes |

### 💡 **Cost Optimization Strategies**
- ✅ **Auto-scaling node pools**: Scale down unused nodes
- ✅ **Right-sizing**: Use monitoring to optimize node size
- ✅ **Surge upgrades**: Minimize downtime during upgrades

## 🛠️ Prerequisites & Account Setup

### 📋 **DigitalOcean Account Requirements**
- ✅ **Active DigitalOcean Account**
- ✅ **API Token** with write access
- ✅ **doctl** and **kubectl** installed

### 🔧 **Required Tools Installation**

#### **Windows Setup**
```powershell
$url = "https://github.com/digitalocean/doctl/releases/latest/download/doctl-1.98.1-windows-amd64.zip"
Invoke-WebRequest -Uri $url -OutFile "doctl.zip"
Expand-Archive -Path "doctl.zip" -DestinationPath "C:\Program Files\doctl"
$env:PATH += ";C:\Program Files\doctl"
```

#### **macOS Setup**
```bash
brew install doctl
```

#### **Linux Setup**
```bash
wget https://github.com/digitalocean/doctl/releases/latest/download/doctl-1.98.1-linux-amd64.tar.gz
tar xf doctl-1.98.1-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin
```

### 🔐 **Authentication**
```bash
doctl auth init
doctl account get
```

## 🚦 Quick Start (Standard Cluster)

### Web Console (GUI)
1. Log in to [DigitalOcean Control Panel](https://cloud.digitalocean.com/kubernetes)
2. Click **Create > Kubernetes Cluster**
3. Fill in:
   - Name: `k8s-learning-cluster`
   - Region: `nyc1` (or your region)
   - Version: latest stable
   - Node pool: 3 nodes, `s-2vcpu-4gb`
   - Enable auto-upgrade and surge upgrade
4. Click **Create Cluster** and wait for provisioning
5. Click **Download Config** for `kubectl` setup

### Command Line (CLI)
```bash
doctl kubernetes cluster create k8s-learning-cluster \
  --region nyc1 \
  --version 1.28.2-do.0 \
  --count 3 \
  --size s-2vcpu-4gb \
  --auto-upgrade=true \
  --surge-upgrade=true

doctl kubernetes cluster kubeconfig save k8s-learning-cluster
kubectl get nodes
```

## ⚙️ Advanced Setup

### Custom Cluster Configuration (CLI)
```bash
doctl kubernetes cluster create advanced-learning-cluster \
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

### Multi-Node Pools
```bash
doctl kubernetes cluster node-pool create k8s-learning-cluster \
  --name worker-pool \
  --size s-4vcpu-8gb \
  --count 3 \
  --tag worker,production \
  --auto-scale \
  --min-nodes 1 \
  --max-nodes 5
```

## 🎛️ Essential DOKS Commands
```bash
doctl kubernetes cluster list
doctl kubernetes cluster get k8s-learning-cluster
doctl kubernetes cluster kubeconfig save k8s-learning-cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🧪 Testing Your DOKS Cluster
```bash
kubectl create deployment hello-doks --image=nginx
kubectl expose deployment hello-doks --type=LoadBalancer --port=80
kubectl get service hello-doks -w
curl http://<EXTERNAL-IP>
```

## 🐛 Troubleshooting
- **Cluster creation fails**: Check API token, quota, and region
- **Nodes not joining**: Check node pool status
- **Pod scheduling issues**: Check node resources and events
- **Network issues**: Check firewall and VPC settings

## 💡 Tips and Best Practices
- Use surge upgrades for zero-downtime
- Enable auto-upgrade for security
- Use tags for resource management
- Monitor with DigitalOcean Monitoring and Prometheus

## 📚 Learning Path & Resources
- [DOKS Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [DOKS Best Practices](https://docs.digitalocean.com/products/kubernetes/guides/best-practices/)
- [Kubernetes Learning Projects](../../01-beginner/01-hello-kubernetes/)

---

**Ready to start your projects on DOKS?** Your cluster is now configured and ready for the Kubernetes learning projects. Head back to [Project 1](../../01-beginner/01-hello-kubernetes/) to begin!
