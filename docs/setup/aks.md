# 🚀 Setting up Kubernetes on Azure AKS

Azure Kubernetes Service (AKS) is Microsoft Azure's fully managed Kubernetes platform, providing enterprise-grade security, integrated monitoring, and seamless Azure service integration while eliminating the complexity of managing Kubernetes control planes.

## 🎯 What is Azure AKS?

### 🔧 **Core Features**
- **🎛️ Managed Control Plane**: Azure manages Kubernetes masters
- **🏗️ High Availability**: Multi-zone support and 99.95% SLA
- **🔒 Enterprise Security**: Azure AD, RBAC, and managed identities
- **📈 Auto-Scaling**: Node and pod autoscaling
- **🔗 Native Azure Integration**: Connects to Azure Monitor, Key Vault, and more
- **🛡️ Compliance Ready**: SOC, PCI, ISO, HIPAA, FedRAMP compliant

### 🌟 **AKS Advantages**
- **No Kubernetes expertise required** for control plane
- **Automatic updates** and security patches
- **Integrated Azure networking and storage**
- **Cost-effective** pay-as-you-use model

## 💰 Cost Breakdown & Optimization

| Component | Cost | Details |
|-----------|------|---------|
| **Control Plane** | Free | No charge for cluster management |
| **Worker Nodes** | VM pricing | Standard_D2s_v3: ~$50/month |
| **Load Balancers** | $18/month | Standard Load Balancer |
| **Storage** | Standard Azure rates | Premium SSD: $0.12/GB/month |

### 💡 **Cost Optimization Strategies**
- ✅ **Spot Node Pools**: Save up to 90% for dev/test
- ✅ **Cluster Autoscaler**: Scale down unused nodes
- ✅ **Right-sizing**: Use Azure Advisor recommendations
- ✅ **Auto-stop**: Pause clusters when not in use

## 🛠️ Prerequisites & Account Setup

### 📋 **Azure Account Requirements**
- ✅ **Active Azure Subscription**
- ✅ **Resource Group** for AKS
- ✅ **Azure CLI** and **kubectl** installed

### 🔧 **Required Tools Installation**

#### **Windows Setup**
```powershell
# Install Azure CLI
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# Install kubectl
az aks install-cli

# Verify installations
az version
kubectl version --client
```

#### **macOS Setup**
```bash
brew install azure-cli
az aks install-cli
```

#### **Linux Setup**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az aks install-cli
```

### 🔐 **Azure Authentication**
```bash
az login
az account set --subscription "Your Subscription Name"
```

## 🚦 Quick Start (Standard Cluster)

### Web Portal (GUI)
1. Log in to [Azure Portal](https://portal.azure.com/)
2. Go to **Kubernetes Services > Create**
3. Fill in:
   - Resource group: `k8s-learning-rg`
   - Cluster name: `k8s-learning-cluster`
   - Region: `East US` (or your region)
   - Node pool: 3 nodes, `Standard_D2s_v3`
   - Enable auto-upgrade, monitoring, and RBAC
4. Click **Review + Create** and wait for provisioning
5. Go to the cluster and click **Connect** for CLI setup

### Command Line (CLI)
```bash
RESOURCE_GROUP="k8s-learning-rg"
LOCATION="eastus"
CLUSTER_NAME="k8s-learning-cluster"
az group create --name $RESOURCE_GROUP --location $LOCATION
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --enable-managed-identity
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
kubectl get nodes
```

## ⚙️ Advanced Setup

### Custom Cluster Configuration (CLI)
```bash
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name advanced-learning-cluster \
  --node-count 3 \
  --min-count 1 --max-count 10 \
  --enable-cluster-autoscaler \
  --node-vm-size Standard_D4s_v3 \
  --node-osdisk-size 100 \
  --kubernetes-version 1.28 \
  --enable-addons monitoring,azure-policy,azure-keyvault-secrets-provider \
  --network-plugin azure \
  --enable-managed-identity \
  --enable-workload-identity
```

### Multi-Zone and Node Pools
```bash
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --zones 1 2 3 \
  --node-count 3 \
  --nodepool-name systempool \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --enable-managed-identity
az aks nodepool add \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $CLUSTER_NAME \
  --name userpool \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --zones 1 2 3 \
  --mode User
```

## 🎛️ Essential AKS Commands
```bash
az aks list
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
```

## 🧪 Testing Your AKS Cluster
```bash
kubectl create deployment hello-aks --image=mcr.microsoft.com/azuredocs/aks-helloworld:v1
kubectl expose deployment hello-aks --type=LoadBalancer --port=80 --target-port=80
kubectl get service hello-aks -w
curl http://<EXTERNAL-IP>
```

## 🐛 Troubleshooting
- **Cluster creation fails**: Check Azure subscription, quotas, and permissions
- **Nodes not joining**: Check node pool status and VM quotas
- **Pod scheduling issues**: Check node resources and taints
- **Network issues**: Check NSGs and route tables

## 💡 Tips and Best Practices
- Use managed identities and Azure AD for security
- Enable autoscaler and monitoring
- Use spot node pools for dev/test
- Monitor with Azure Monitor and Prometheus

## 📚 Learning Path & Resources
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Kubernetes Learning Projects](../../01-beginner/01-hello-kubernetes/)

---

**Ready to start your projects on AKS?** Your cluster is now configured and ready for the Kubernetes learning projects. Head back to [Project 1](../../01-beginner/01-hello-kubernetes/) to begin!
