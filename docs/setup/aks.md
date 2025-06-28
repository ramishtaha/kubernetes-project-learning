# Azure Kubernetes Service (AKS) Setup Guide

This guide will help you set up an Azure Kubernetes Service (AKS) cluster for the Kubernetes Project-Based Learning repository.

## Prerequisites

### Required Tools
- **Azure CLI**: Command-line interface for Azure
- **kubectl**: Kubernetes command-line tool
- **Azure Subscription**: Active Azure subscription

### Install Azure CLI

#### Windows
```powershell
# Download and install Azure CLI
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

#### macOS
```bash
# Install using Homebrew
brew install azure-cli
```

#### Linux (Ubuntu/Debian)
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Install kubectl
```bash
# Install kubectl via Azure CLI
az aks install-cli
```

## Authentication

### Login to Azure
```bash
# Interactive login
az login

# Login with service principal (for automation)
az login --service-principal -u <client-id> -p <client-secret> --tenant <tenant-id>

# Verify login
az account show
```

### Set Subscription
```bash
# List available subscriptions
az account list --output table

# Set active subscription
az account set --subscription "Your Subscription Name"
```

## Cluster Creation

### Basic AKS Cluster
```bash
# Create resource group
RESOURCE_GROUP="k8s-learning-rg"
LOCATION="eastus"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster
CLUSTER_NAME="k8s-learning-cluster"
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-count 3 \
    --node-vm-size Standard_D2s_v3 \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --enable-managed-identity
```

### Production-Ready AKS Cluster
```bash
# Create advanced AKS cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-count 3 \
    --min-count 1 \
    --max-count 10 \
    --enable-cluster-autoscaler \
    --node-vm-size Standard_D4s_v3 \
    --node-osdisk-size 100 \
    --node-osdisk-type Managed \
    --kubernetes-version 1.28.3 \
    --enable-addons monitoring,azure-policy,azure-keyvault-secrets-provider \
    --network-plugin azure \
    --network-policy azure \
    --service-cidr 10.0.0.0/16 \
    --dns-service-ip 10.0.0.10 \
    --pod-cidr 10.244.0.0/16 \
    --generate-ssh-keys \
    --enable-managed-identity \
    --enable-workload-identity \
    --enable-oidc-issuer
```

### Multi-Zone Cluster with Multiple Node Pools
```bash
# Create cluster with system node pool
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --zones 1 2 3 \
    --node-count 3 \
    --node-vm-size Standard_D2s_v3 \
    --nodepool-name systempool \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --enable-managed-identity

# Add user node pool
az aks nodepool add \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name userpool \
    --node-count 3 \
    --node-vm-size Standard_D4s_v3 \
    --zones 1 2 3 \
    --mode User \
    --node-taints CriticalAddonsOnly=true:NoSchedule
```

## Cluster Configuration

### Get Credentials
```bash
# Get cluster credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Verify connection
kubectl get nodes
kubectl cluster-info
```

### Enable Features
```bash
# Enable RBAC (if not enabled during creation)
az aks update --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --enable-rbac

# Enable Azure AD integration
az aks update \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --enable-aad \
    --aad-admin-group-object-ids <group-object-id>

# Enable secret store CSI driver
az aks enable-addons \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --addons azure-keyvault-secrets-provider
```

## Storage Configuration

### Azure Disk Storage Class
```bash
# Apply Azure Disk storage class
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-premium
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
  cachingmode: ReadOnly
  kind: Managed
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### Azure Files Storage Class
```bash
# Apply Azure Files storage class
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-premium
provisioner: file.csi.azure.com
parameters:
  skuName: Premium_LRS
allowVolumeExpansion: true
volumeBindingMode: Immediate
mountOptions:
- dir_mode=0777
- file_mode=0777
- uid=0
- gid=0
- mfsymlinks
- cache=strict
- actimeo=30
EOF
```

## Networking Configuration

### Load Balancer Configuration
```bash
# Create public IP for load balancer
az network public-ip create \
    --resource-group MC_${RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION} \
    --name k8s-learning-ip \
    --sku Standard \
    --allocation-method static

# Get public IP address
PUBLIC_IP=$(az network public-ip show --resource-group MC_${RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION} --name k8s-learning-ip --query ipAddress --output tsv)
echo "Public IP: $PUBLIC_IP"
```

### Ingress Controller Setup
```bash
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --set controller.service.loadBalancerIP=$PUBLIC_IP
```

## Security Configuration

### Azure AD Workload Identity
```bash
# Create managed identity
IDENTITY_NAME="k8s-workload-identity"
az identity create --name $IDENTITY_NAME --resource-group $RESOURCE_GROUP

# Get identity details
IDENTITY_CLIENT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RESOURCE_GROUP --query clientId --output tsv)
IDENTITY_OBJECT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RESOURCE_GROUP --query principalId --output tsv)

# Create federated credential
OIDC_URL=$(az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query "oidcIssuerProfile.issuerUrl" --output tsv)

az identity federated-credential create \
    --name "k8s-federated-credential" \
    --identity-name $IDENTITY_NAME \
    --resource-group $RESOURCE_GROUP \
    --issuer $OIDC_URL \
    --subject "system:serviceaccount:default:workload-identity-sa"
```

### Azure Key Vault Integration
```bash
# Create Azure Key Vault
KEYVAULT_NAME="k8s-learning-kv-$(openssl rand -hex 4)"
az keyvault create \
    --name $KEYVAULT_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

# Add secret to Key Vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "database-password" --value "super-secret-password"

# Grant access to managed identity
az keyvault set-policy \
    --name $KEYVAULT_NAME \
    --object-id $IDENTITY_OBJECT_ID \
    --secret-permissions get
```

## Monitoring and Logging

### Enable Container Insights
```bash
# Enable monitoring addon (if not enabled during creation)
az aks enable-addons \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --addons monitoring
```

### Install Prometheus and Grafana
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.enabled=true \
    --set alertmanager.enabled=true
```

## Auto-scaling Configuration

### Horizontal Pod Autoscaler
```bash
# Install metrics server (usually pre-installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Vertical Pod Autoscaler
```bash
# Install VPA
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-up.sh
```

### Cluster Autoscaler (if not enabled during creation)
```bash
# Enable cluster autoscaler
az aks update \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 10
```

## Cost Optimization

### Node Pool Management
```bash
# Scale down node pool
az aks nodepool scale \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name nodepool1 \
    --node-count 1

# Stop cluster (deallocate nodes)
az aks stop --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Start cluster
az aks start --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

### Spot Node Pools
```bash
# Create spot node pool for cost savings
az aks nodepool add \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name spotpool \
    --priority Spot \
    --eviction-policy Delete \
    --spot-max-price -1 \
    --enable-cluster-autoscaler \
    --min-count 0 \
    --max-count 3 \
    --node-vm-size Standard_D2s_v3
```

## Backup and Disaster Recovery

### Enable Backup
```bash
# Create backup vault
BACKUP_VAULT_NAME="k8s-backup-vault"
az dataprotection backup-vault create \
    --resource-group $RESOURCE_GROUP \
    --vault-name $BACKUP_VAULT_NAME \
    --location $LOCATION \
    --type SystemAssigned

# Configure AKS backup (requires Azure Backup service)
az k8s-extension create \
    --name azure-aks-backup \
    --extension-type Microsoft.DataProtection.Kubernetes \
    --scope cluster \
    --cluster-name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP \
    --cluster-type managedClusters \
    --configuration-settings blobContainer=aksbackupcontainer storageAccount=aksbackupstorage
```

## Troubleshooting

### Common Issues

1. **Authentication failures**
   ```bash
   # Re-authenticate
   az login
   az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
   ```

2. **Node issues**
   ```bash
   # Check node status
   kubectl get nodes -o wide
   kubectl describe node <node-name>
   
   # Restart node pool
   az aks nodepool upgrade --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name nodepool1 --kubernetes-version $(az aks get-versions --location $LOCATION --query orchestrators[-1].orchestratorVersion --output tsv)
   ```

3. **Network connectivity issues**
   ```bash
   # Check network security groups
   az network nsg list --resource-group MC_${RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION}
   
   # Check route tables
   az network route-table list --resource-group MC_${RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION}
   ```

### Debugging Commands
```bash
# Get cluster information
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Check cluster health
kubectl get componentstatuses

# View cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check AKS logs
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --admin
```

## Cleanup

### Delete Cluster
```bash
# Delete AKS cluster
az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes --no-wait

# Delete resource group (removes all resources)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

### Partial Cleanup
```bash
# Delete specific node pool
az aks nodepool delete --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name userpool

# Delete public IP
az network public-ip delete --resource-group MC_${RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION} --name k8s-learning-ip
```

## Best Practices

### Security
- Enable Azure AD integration
- Use managed identities
- Implement network policies
- Regular security updates

### Performance
- Use multiple availability zones
- Configure appropriate node sizes
- Enable cluster autoscaler
- Monitor resource usage

### Cost Management
- Use spot instances for dev/test
- Implement cluster auto-stop
- Monitor costs with Azure Cost Management
- Right-size node pools

## Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Azure Monitor for Containers](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/)
