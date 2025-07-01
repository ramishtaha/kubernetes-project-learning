# 🚀 Setting up Kubernetes on Amazon EKS

Amazon Elastic Kubernetes Service (EKS) is AWS's fully managed Kubernetes service that eliminates the complexity of managing Kubernetes control planes while providing enterprise-grade security, scalability, and reliability.

## 🎯 What is Amazon EKS?

Amazon EKS provides a robust, production-ready Kubernetes platform with:

### 🔧 **Core Features**
- **🎛️ Managed Control Plane**: AWS manages Kubernetes masters across multiple AZs
- **🏗️ High Availability**: 99.95% SLA with automatic failover
- **🔒 Enterprise Security**: Deep integration with AWS IAM, VPC, and security services
- **📈 Auto-Scaling**: Intelligent scaling for both nodes and pods
- **🔗 Native AWS Integration**: Seamless connection to 200+ AWS services
- **🛡️ Compliance Ready**: SOC, PCI, ISO, FedRAMP, HIPAA compliant

### 🌟 **EKS Advantages**
- **No Kubernetes expertise required** for control plane management
- **Automatic updates** and security patches
- **Multi-AZ deployment** for maximum availability
- **Native AWS service mesh** and observability
- **Cost-effective** pay-as-you-use model

## 💰 Cost Breakdown & Optimization

### 📊 **EKS Pricing Structure**
| Component | Cost | Details |
|-----------|------|---------|
| **Control Plane** | $0.10/hour | ~$73/month per cluster |
| **Worker Nodes** | EC2 pricing | t3.medium: ~$30/month |
| **Fargate** | $0.04048/vCPU/hour | Pay per pod resource usage |
| **Data Transfer** | Standard AWS rates | Cross-AZ: $0.01/GB |
| **Load Balancers** | $16.20/month | Application Load Balancer |

### 💡 **Cost Optimization Strategies**
- ✅ **Spot Instances**: Save up to 90% for non-critical workloads
- ✅ **Right-sizing**: Use AWS Compute Optimizer recommendations
- ✅ **Fargate**: Perfect for variable/unpredictable workloads
- ✅ **Cluster Autoscaler**: Automatic scale-down during low usage
- ✅ **Reserved Instances**: 30-60% savings for predictable workloads

## 🛠️ Prerequisites & Account Setup

### 📋 **AWS Account Requirements**
- ✅ **Active AWS Account** with billing configured
- ✅ **IAM User** with AdministratorAccess policy (for setup)
- ✅ **VPC** with public/private subnets (can be auto-created)
- ✅ **Key Pair** for EC2 access (optional but recommended)

### 🔧 **Required Tools Installation**

#### **Windows Setup**
```powershell
# Install AWS CLI v2
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
Start-Process -FilePath msiexec.exe -ArgumentList "/i AWSCLIV2.msi /quiet" -Wait

# Install kubectl using Chocolatey
choco install kubernetes-cli

# Install eksctl
choco install eksctl

# Verify installations
aws --version
kubectl version --client
eksctl version
```

#### **macOS Setup**
```bash
# Install using Homebrew
brew install awscli kubectl eksctl

# Or using curl for AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

#### **Linux Setup**
```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

### 🔐 **AWS Credentials Configuration**
```bash
# Configure AWS credentials (interactive)
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Verify configuration
aws sts get-caller-identity
aws eks list-clusters --region us-west-2
```

## 🌐 Method 1: AWS Management Console (Web GUI)

### 📊 **Step 1: Create EKS Cluster via AWS Console**

#### **1.1 Navigate to EKS Service**
1. 🔗 **Login to AWS Console**: Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. 🔍 **Search for EKS**: Type "EKS" in the search bar or navigate to **Services > Containers > Elastic Kubernetes Service**
3. 🎯 **Select Region**: Ensure you're in your desired region (e.g., `us-west-2`)

#### **1.2 Create Cluster**
1. 🆕 **Click "Create cluster"**
2. 📝 **Configure Cluster Basics**:
   ```
   Cluster name: learning-cluster
   Kubernetes version: 1.28 (latest stable)
   Cluster service role: EKSClusterServiceRole (create if doesn't exist)
   ```

3. 🔐 **Create EKS Service Role** (if needed):
   - Click **"Create role"** next to Cluster service role
   - Navigate to **IAM > Roles > Create role**
   - Choose **AWS service > EKS > EKS - Cluster**
   - Attach policy: `AmazonEKSClusterPolicy`
   - Role name: `EKSClusterServiceRole`

#### **1.3 Configure Networking**
1. 🌐 **VPC Settings**:
   ```
   VPC: Create new VPC or select existing
   Subnets: Select 2+ subnets in different AZs
   Security groups: Default EKS security group
   ```

2. 🔧 **Cluster Endpoint Access**:
   ```
   Public: ✅ Enabled (for learning)
   Private: ✅ Enabled (recommended)
   Public access CIDR: 0.0.0.0/0 (restrict in production)
   ```

3. 🏷️ **Control Plane Logging**:
   ```
   ✅ API server
   ✅ Audit
   ✅ Authenticator
   ✅ Controller manager
   ✅ Scheduler
   ```

#### **1.4 Configure Add-ons**
1. 🔌 **Core Add-ons** (select latest versions):
   ```
   ✅ Amazon VPC CNI
   ✅ CoreDNS
   ✅ kube-proxy
   ✅ Amazon EBS CSI Driver
   ```

2. ⚙️ **Advanced Configuration**:
   - Leave default settings for learning environment
   - Click **"Next"** through configuration options

#### **1.5 Review and Create**
1. 📋 **Review Configuration**:
   - Verify cluster name, version, and networking
   - Check that all required add-ons are selected
   - Estimated cost: ~$73/month for control plane

2. 🚀 **Create Cluster**:
   - Click **"Create"**
   - ⏱️ **Wait 10-15 minutes** for cluster creation
   - Status will change from "Creating" to "Active"

### 👥 **Step 2: Create Node Groups via AWS Console**

#### **2.1 Configure Node Group Basics**
1. 📍 **Navigate to your cluster** → **"Compute"** tab → **"Add node group"**
2. 📝 **Basic Configuration**:
   ```
   Node group name: standard-workers
   Node IAM role: EKSNodeInstanceRole (create if needed)
   ```

3. 🔐 **Create Node Instance Role** (if needed):
   - Go to **IAM > Roles > Create role**
   - Choose **AWS service > EC2**
   - Attach policies:
     - `AmazonEKSWorkerNodePolicy`
     - `AmazonEKS_CNI_Policy`
     - `AmazonEC2ContainerRegistryReadOnly`

#### **2.2 Node Group Compute Configuration**
1. 💻 **Instance Configuration**:
   ```
   AMI type: Amazon Linux 2 (AL2_x86_64)
   Capacity type: On-Demand (or Spot for cost savings)
   Instance types: t3.medium (2 vCPU, 4GB RAM)
   Disk size: 20 GB
   ```

2. 📊 **Scaling Configuration**:
   ```
   Desired size: 2 nodes
   Minimum size: 1 node
   Maximum size: 4 nodes
   ```

3. 🔄 **Update Configuration**:
   ```
   Max unavailable: 1
   ```

#### **2.3 Node Group Networking**
1. 🌐 **Subnets**: Select private subnets (recommended for workers)
2. 🔒 **Remote Access** (optional):
   ```
   ✅ Enable SSH access
   EC2 Key Pair: Select your key pair
   Source security groups: Default
   ```

#### **2.4 Review and Create Node Group**
1. 📋 **Review settings**
2. 🚀 **Click "Create"**
3. ⏱️ **Wait 5-10 minutes** for nodes to join cluster

### 🎛️ **Step 3: Configure kubectl Access**

#### **3.1 Update Kubeconfig**
```bash
# Update kubeconfig to connect to your EKS cluster
aws eks update-kubeconfig --region us-west-2 --name learning-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

#### **3.2 Test Cluster Access**
```bash
# Check cluster status
kubectl get componentstatuses

# View cluster information
kubectl cluster-info

# List all namespaces
kubectl get namespaces

# Check node details
kubectl describe nodes
```

## 🖥️ Method 2: Command Line Interface (eksctl)

### 🚀 **Quick Setup (15 minutes)**

#### **2.1 Basic Cluster Creation**
```bash
# Create cluster with default settings
eksctl create cluster \
  --name learning-cluster \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed \
  --with-oidc \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub

# This automatically creates:
# ✅ EKS cluster with managed control plane
# ✅ Managed node group with 2 t3.medium instances
# ✅ VPC with public and private subnets
# ✅ Security groups and IAM roles
# ✅ OIDC identity provider for service accounts
```

#### **2.2 Verify Quick Setup**
```bash
# Update kubeconfig (usually done automatically)
aws eks update-kubeconfig --region us-west-2 --name learning-cluster

# Test cluster access
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Check cluster details
eksctl get cluster --name learning-cluster --region us-west-2
eksctl get nodegroup --cluster learning-cluster --region us-west-2
```

### ⚙️ **Advanced Configuration Setup**

#### **2.3 Custom Cluster with Configuration File**

Create a comprehensive cluster configuration:

```yaml
# cluster-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: advanced-learning-cluster
  region: us-west-2
  version: "1.28"
  tags:
    Environment: learning
    Project: kubernetes-projects
    Owner: "your-name"

# Enable OIDC for service accounts
iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true
  - metadata:
      name: ebs-csi-controller-sa
      namespace: kube-system
    wellKnownPolicies:
      ebsCSIController: true
  - metadata:
      name: cluster-autoscaler
      namespace: kube-system
    wellKnownPolicies:
      autoScaler: true

# VPC Configuration
vpc:
  cidr: "10.0.0.0/16"
  natMode: HighlyAvailable
  natGateway: 2
  dns:
    enableDnsHostnames: true
    enableDnsSupport: true
  clusterEndpoints:
    publicAccess: true
    privateAccess: true
    publicAccessCIDRs: ["0.0.0.0/0"]

# Essential Add-ons
addons:
- name: vpc-cni
  version: latest
  configurationValues: |-
    env:
      ENABLE_PREFIX_DELEGATION: "true"
      ENABLE_POD_ENI: "true"
- name: coredns
  version: latest
- name: kube-proxy
  version: latest
- name: aws-ebs-csi-driver
  version: latest
  wellKnownPolicies:
    ebsCSIController: true

# Node Groups
managedNodeGroups:
- name: general-purpose
  instanceType: t3.medium
  minSize: 1
  maxSize: 10
  desiredCapacity: 3
  volumeSize: 20
  volumeType: gp3
  volumeEncrypted: true
  amiFamily: AmazonLinux2
  ssh:
    allow: true
    publicKeyName: your-key-pair
  labels:
    role: general
    environment: learning
  tags:
    NodeGroup: general-purpose
    Environment: learning
  iam:
    attachPolicyARNs:
    - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
    - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
    - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
    - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

- name: compute-optimized
  instanceType: c5.large
  minSize: 0
  maxSize: 5
  desiredCapacity: 0
  volumeSize: 50
  volumeType: gp3
  amiFamily: AmazonLinux2
  labels:
    role: compute-intensive
    environment: learning
  taints:
  - key: compute-optimized
    value: "true"
    effect: NoSchedule
  tags:
    NodeGroup: compute-optimized

- name: spot-instances
  instanceTypes: ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
  spot: true
  minSize: 0
  maxSize: 10
  desiredCapacity: 2
  volumeSize: 20
  labels:
    role: spot-workers
    lifecycle: spot
  tags:
    NodeGroup: spot-instances

# Fargate Profiles
fargateProfiles:
- name: serverless-profile
  selectors:
  - namespace: fargate-namespace
  - namespace: kube-system
    labels:
      k8s-app: aws-load-balancer-controller
  subnets:
  - subnet-xxxxx  # Private subnet IDs
  - subnet-yyyyy
  tags:
    Environment: learning
    Profile: serverless

# CloudWatch Logging
cloudWatch:
  clusterLogging:
    enable: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    logRetentionInDays: 7

# Secrets Encryption
secretsEncryption:
  keyARN: arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012
```

#### **2.4 Deploy Advanced Configuration**
```bash
# Deploy with custom configuration
eksctl create cluster -f cluster-config.yaml

# Monitor creation progress
eksctl utils describe-stacks --region us-west-2 --cluster advanced-learning-cluster

# Get detailed cluster info
eksctl get cluster advanced-learning-cluster --region us-west-2 -o yaml
```

## 🎭 Method 3: Different Cluster Types & Use Cases

### 🏗️ **Development Cluster (Cost-Optimized)**

Perfect for learning and experimentation with minimal costs:

#### **Via AWS Console:**
```
Cluster Configuration:
├── Name: dev-learning-cluster
├── Version: 1.28
├── Node Group: 
│   ├── Instance Type: t3.small (2 vCPU, 2GB RAM)
│   ├── Desired Capacity: 1
│   ├── Min/Max: 1/3
│   └── Disk: 20GB GP3
└── Features: Basic add-ons only
```

#### **Via eksctl:**
```bash
eksctl create cluster \
  --name dev-learning-cluster \
  --region us-west-2 \
  --nodegroup-name dev-workers \
  --node-type t3.small \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed \
  --spot \
  --ssh-access
```

### 🏢 **Production-Ready Cluster (High Availability)**

Enterprise-grade setup with reliability and security:

#### **Production Configuration File:**
```yaml
# production-cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: production-cluster
  region: us-west-2
  version: "1.28"
  tags:
    Environment: production
    Compliance: required

iam:
  withOIDC: true

vpc:
  cidr: "10.0.0.0/16"
  natMode: HighlyAvailable
  clusterEndpoints:
    publicAccess: false
    privateAccess: true

managedNodeGroups:
- name: system-nodes
  instanceType: t3.medium
  minSize: 3
  maxSize: 6
  desiredCapacity: 3
  volumeSize: 100
  volumeEncrypted: true
  amiFamily: AmazonLinux2
  availabilityZones: ["us-west-2a", "us-west-2b", "us-west-2c"]
  labels:
    role: system
  taints:
  - key: system
    value: "true"
    effect: NoSchedule

- name: application-nodes
  instanceType: m5.large
  minSize: 2
  maxSize: 20
  desiredCapacity: 4
  volumeSize: 100
  labels:
    role: application

secretsEncryption:
  keyARN: arn:aws:kms:us-west-2:ACCOUNT:key/KEY-ID

cloudWatch:
  clusterLogging:
    enable: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    logRetentionInDays: 30
```

### 🤖 **Machine Learning Cluster (GPU-Enabled)**

Optimized for ML/AI workloads with GPU support:

#### **ML Cluster Configuration:**
```yaml
# ml-cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ml-cluster
  region us-west-2

managedNodeGroups:
- name: cpu-workers
  instanceType: c5.2xlarge
  minSize: 1
  maxSize: 5
  desiredCapacity: 2
  labels:
    workload: cpu-intensive

- name: gpu-workers
  instanceType: p3.2xlarge  # Tesla V100 GPU
  minSize: 0
  maxSize: 3
  desiredCapacity: 1
  amiFamily: AmazonLinux2GPU
  labels:
    workload: gpu
    accelerator: nvidia-tesla-v100
  taints:
  - key: nvidia.com/gpu
    value: "true"
    effect: NoSchedule

addons:
- name: nvidia-device-plugin-daemonset
```

### 🔄 **CI/CD Cluster (Pipeline Optimized)**

Designed for continuous integration and deployment:

#### **CI/CD Configuration:**
```bash
# Create CI/CD optimized cluster
eksctl create cluster \
  --name cicd-cluster \
  --region us-west-2 \
  --nodegroup-name pipeline-workers \
  --node-type c5.large \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 10 \
  --managed \
  --spot \
  --with-oidc \
  --enable-ssm

# Add spot instances for cost optimization
eksctl create nodegroup \
  --cluster cicd-cluster \
  --region us-west-2 \
  --name spot-workers \
  --node-type m5.large \
  --nodes 1 \
  --nodes-min 0 \
  --nodes-max 5 \
  --spot \
  --spot-price 0.05
```

### 🌐 **Multi-Region Cluster Setup**

For global applications and disaster recovery:

#### **Primary Region (us-west-2):**
```bash
eksctl create cluster \
  --name primary-cluster \
  --region us-west-2 \
  --nodegroup-name primary-workers \
  --node-type t3.medium \
  --nodes 3 \
  --managed \
  --with-oidc
```

#### **Secondary Region (us-east-1):**
```bash
eksctl create cluster \
  --name secondary-cluster \
  --region us-east-1 \
  --nodegroup-name secondary-workers \
  --node-type t3.medium \
  --nodes 2 \
  --managed \
  --with-oidc
```

#### **Configure Cross-Region Networking:**
```bash
# Setup VPC peering between regions
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-primary \
  --peer-vpc-id vpc-secondary \
  --peer-region us-east-1

# Configure route tables and security groups
# (Additional networking configuration required)
```

## 🔧 Essential EKS Configurations & Add-ons

### 🚀 **AWS Load Balancer Controller**

#### **Method 1: Via AWS Console**
1. 📍 **Navigate to EKS Console** → Your Cluster → **"Add-ons"** tab
2. ➕ **Click "Add new"**
3. 🔍 **Search for**: `AWS Load Balancer Controller`
4. ⚙️ **Configuration**:
   ```
   Version: v2.6.1-eksbuild.1 (latest)
   Service account role: Create new IAM role
   Conflict resolution: Overwrite
   ```
5. 🎯 **IAM Role Creation**:
   - Role name: `AmazonEKSLoadBalancerControllerRole`
   - Trust policy: EKS service account
   - Permissions: `ElasticLoadBalancingFullAccess`

#### **Method 2: Via Command Line**
```bash
# Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.1/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=learning-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name=AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install via Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=learning-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-west-2 \
  --set vpcId=$(aws eks describe-cluster --name learning-cluster --query 'cluster.resourcesVpcConfig.vpcId' --output text)

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### 💾 **EBS CSI Driver Configuration**

#### **Via AWS Console:**
1. 🖥️ **EKS Console** → Cluster → **"Add-ons"** → **"Add new"**
2. 🔍 **Select**: `Amazon EBS CSI Driver`
3. ⚙️ **Configure**:
   ```
   Version: v1.24.0-eksbuild.1
   Service account: Create new IAM role
   Configuration: Default settings
   ```

#### **Via Command Line:**
```bash
# Create IAM service account for EBS CSI
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster learning-cluster \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/Amazon_EBS_CSI_DriverPolicy \
    --approve

# Install EBS CSI driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.24"

# Create storage classes
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF
```

### 📈 **Cluster Autoscaler Setup**

#### **Create IAM Policy:**
```bash
cat > cluster-autoscaler-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "eks:DescribeCluster",
                "eks:DescribeNodegroup"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Create policy and service account
aws iam create-policy --policy-name AmazonEKSClusterAutoscalerPolicy --policy-document file://cluster-autoscaler-policy.json

eksctl create iamserviceaccount \
  --cluster=learning-cluster \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve
```

#### **Deploy Cluster Autoscaler:**
```bash
# Download and apply cluster autoscaler
curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Modify the deployment to use your cluster name
sed -i 's/<YOUR CLUSTER NAME>/learning-cluster/g' cluster-autoscaler-autodiscover.yaml

kubectl apply -f cluster-autoscaler-autodiscover.yaml

# Patch deployment with safe-to-evict annotation
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'

# Add cluster-autoscaler image tag
kubectl set image deployment cluster-autoscaler \
  -n kube-system \
  cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.28.2

# Verify installation
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

### 🌐 **EFS CSI Driver (for Shared Storage)**

#### **Create EFS Filesystem:**
```bash
# Create EFS filesystem
EFS_ID=$(aws efs create-file-system \
  --performance-mode generalPurpose \
  --throughput-mode provisioned \
  --provisioned-throughput-in-mibps 100 \
  --encrypted \
  --tags Key=Name,Value=eks-learning-efs \
  --query 'FileSystemId' \
  --output text)

echo "EFS ID: $EFS_ID"

# Create mount targets in each subnet
VPC_ID=$(aws eks describe-cluster --name learning-cluster --query 'cluster.resourcesVpcConfig.vpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --output text)

for subnet in $SUBNET_IDS; do
    aws efs create-mount-target --file-system-id $EFS_ID --subnet-id $subnet
done
```

#### **Install EFS CSI Driver:**
```bash
# Create IAM service account
eksctl create iamserviceaccount \
    --name efs-csi-controller-sa \
    --namespace kube-system \
    --cluster learning-cluster \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/Amazon_EFS_CSI_DriverPolicy \
    --approve

# Install EFS CSI driver
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"

# Create EFS storage class
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: $EFS_ID
  directoryPerms: "700"
  gidRangeStart: "1000"
  gidRangeEnd: "2000"
  basePath: "/dynamic_provisioning"
EOF
```

## 🧪 Testing Your EKS Cluster

### 🚀 **Deploy Comprehensive Sample Application**

#### **Create Multi-Tier Application:**
```bash
# Create dedicated namespace
kubectl create namespace eks-sample-app

# Deploy complete application stack
cat << EOF | kubectl apply -f -
# Redis Cache
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  namespace: eks-sample-app
  labels:
    app: redis-cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-cache
  template:
    metadata:
      labels:
        app: redis-cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cache
  namespace: eks-sample-app
spec:
  selector:
    app: redis-cache
  ports:
  - port: 6379
    targetPort: 6379
---
# Main Application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eks-sample-app
  namespace: eks-sample-app
  labels:
    app: eks-sample-app
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: eks-sample-app
  template:
    metadata:
      labels:
        app: eks-sample-app
        version: v1
    spec:
      containers:
      - name: app
        image: public.ecr.aws/nginx/nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: REDIS_URL
          value: "redis://redis-cache:6379"
        - name: APP_VERSION
          value: "v1.0.0"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
# Application Service
apiVersion: v1
kind: Service
metadata:
  name: eks-sample-service
  namespace: eks-sample-app
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  selector:
    app: eks-sample-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: LoadBalancer
---
# Ingress for ALB
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eks-sample-ingress
  namespace: eks-sample-app
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: eks-sample-service
            port:
              number: 80
EOF
```

#### **Monitor Deployment:**
```bash
# Watch pod creation
kubectl get pods -n eks-sample-app -w

# Check deployment status
kubectl rollout status deployment/eks-sample-app -n eks-sample-app
kubectl rollout status deployment/redis-cache -n eks-sample-app

# Get service details
kubectl get services -n eks-sample-app
kubectl get ingress -n eks-sample-app

# Wait for LoadBalancer to be ready
kubectl get service eks-sample-service -n eks-sample-app -w
```

#### **Test Application Access:**
```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get service eks-sample-service -n eks-sample-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "LoadBalancer URL: http://$LB_URL"

# Test connectivity
curl -I http://$LB_URL
curl http://$LB_URL

# Get ALB URL
ALB_URL=$(kubectl get ingress eks-sample-ingress -n eks-sample-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB URL: http://$ALB_URL"

# Test ALB connectivity
curl -I http://$ALB_URL
```

### 📊 **Test Horizontal Pod Autoscaling**

#### **Setup HPA:**
```bash
# Install metrics server (if not present)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Create HPA for sample app
kubectl apply -f - << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: eks-sample-app-hpa
  namespace: eks-sample-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: eks-sample-app
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
EOF

# Verify HPA
kubectl get hpa -n eks-sample-app
kubectl describe hpa eks-sample-app-hpa -n eks-sample-app
```

#### **Generate Load and Test Scaling:**
```bash
# Create load generator pod
kubectl run load-generator \
  --image=busybox:latest \
  --restart=Never \
  --namespace=eks-sample-app \
  --rm -i --tty -- /bin/sh

# Inside the load generator pod, run:
while true; do 
    wget -q -O- http://eks-sample-service/
    sleep 0.01
done

# In another terminal, watch scaling
kubectl get hpa -n eks-sample-app -w
kubectl get pods -n eks-sample-app -w
kubectl top pods -n eks-sample-app
```

### 🔄 **Test Cluster Autoscaling**

#### **Deploy Resource-Intensive Workload:**
```bash
# Create deployment that requires more resources
kubectl apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-intensive-app
  namespace: eks-sample-app
spec:
  replicas: 10
  selector:
    matchLabels:
      app: resource-intensive-app
  template:
    metadata:
      labels:
        app: resource-intensive-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
EOF

# Watch cluster autoscaling
kubectl get nodes -w
kubectl get pods -n eks-sample-app -w

# Check cluster autoscaler logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# Check node capacity
kubectl describe nodes
kubectl top nodes
```

### 💾 **Test Storage Functionality**

#### **Test EBS Persistent Volumes:**
```bash
# Create PVC using EBS
kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-test-pvc
  namespace: eks-sample-app
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-gp3
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ebs-test-app
  namespace: eks-sample-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ebs-test-app
  template:
    metadata:
      labels:
        app: ebs-test-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        volumeMounts:
        - name: data
          mountPath: /data
        command:
        - /bin/sh
        - -c
        - |
          echo "Writing to EBS volume..." > /data/test.txt
          tail -f /data/test.txt
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: ebs-test-pvc
EOF

# Verify PVC and pod
kubectl get pvc -n eks-sample-app
kubectl get pods -l app=ebs-test-app -n eks-sample-app
kubectl logs -f deployment/ebs-test-app -n eks-sample-app
```

#### **Test EFS Shared Storage:**
```bash
# Create EFS PVC and test pods
kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-test-pvc
  namespace: eks-sample-app
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: efs-writer
  namespace: eks-sample-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: efs-writer
  template:
    metadata:
      labels:
        app: efs-writer
    spec:
      containers:
      - name: writer
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          while true; do
            echo "$(date): Writer pod message" >> /shared/messages.log
            sleep 5
          done
        volumeMounts:
        - name: shared-data
          mountPath: /shared
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: efs-test-pvc
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: efs-reader
  namespace: eks-sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: efs-reader
  template:
    metadata:
      labels:
        app: efs-reader
    spec:
      containers:
      - name: reader
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          while true; do
            echo "=== Messages from shared storage ==="
            tail -5 /shared/messages.log 2>/dev/null || echo "No messages yet"
            sleep 10
          done
        volumeMounts:
        - name: shared-data
          mountPath: /shared
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: efs-test-pvc
EOF

# Monitor shared storage
kubectl logs -f deployment/efs-writer -n eks-sample-app
kubectl logs -f deployment/efs-reader -n eks-sample-app
```

## 💾 Advanced Storage Configurations

### 🏗️ **EBS Storage Classes for Different Use Cases**

#### **Performance-Optimized Storage:**
```yaml
# High-performance storage class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3-high-perf
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "16000"
  throughput: "1000"
  encrypted: "true"
  kmsKeyId: "alias/aws/ebs"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
---
# Database-optimized storage
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-io1-database
provisioner: ebs.csi.aws.com
parameters:
  type: io1
  iops: "20000"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Retain
---
# Cold storage class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc1-cold
provisioner: ebs.csi.aws.com
parameters:
  type: sc1
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

### 🌐 **EFS Configuration for Shared Storage**

#### **Multi-Mount EFS Setup:**
```bash
# Create EFS with multiple mount targets
EFS_ID=$(aws efs create-file-system \
  --performance-mode generalPurpose \
  --throughput-mode provisioned \
  --provisioned-throughput-in-mibps 500 \
  --encrypted \
  --tags Key=Name,Value=eks-shared-storage Key=Environment,Value=learning \
  --query 'FileSystemId' \
  --output text)

# Create access points for different applications
APP1_ACCESS_POINT=$(aws efs create-access-point \
  --file-system-id $EFS_ID \
  --posix-user Uid=1001,Gid=1001 \
  --root-directory Path="/app1",CreationInfo='{OwnerUid=1001,OwnerGid=1001,Permissions=755}' \
  --tags Key=Name,Value=app1-access-point \
  --query 'AccessPointId' \
  --output text)

APP2_ACCESS_POINT=$(aws efs create-access-point \
  --file-system-id $EFS_ID \
  --posix-user Uid=1002,Gid=1002 \
  --root-directory Path="/app2",CreationInfo='{OwnerUid=1002,OwnerGid=1002,Permissions=755}' \
  --tags Key=Name,Value=app2-access-point \
  --query 'AccessPointId' \
  --output text)

# Create storage classes for different access points
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-app1
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: $EFS_ID
  accessPointId: $APP1_ACCESS_POINT
  directoryPerms: "755"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-app2
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: $EFS_ID
  accessPointId: $APP2_ACCESS_POINT
  directoryPerms: "755"
EOF
```

### 🔄 **FSx for Lustre (High-Performance Computing)**

#### **Setup FSx for Lustre:**
```bash
# Create FSx Lustre filesystem
LUSTRE_ID=$(aws fsx create-file-system \
  --file-system-type LUSTRE \
  --lustre-configuration \
    ImportPath=s3://your-bucket/data,\
    ExportPath=s3://your-bucket/results,\
    WeeklyMaintenanceStartTime=1:05:00 \
  --storage-capacity 1200 \
  --subnet-ids subnet-12345678 \
  --security-group-ids sg-abcdef12 \
  --tags Key=Name,Value=eks-hpc-storage \
  --query 'FileSystem.FileSystemId' \
  --output text)

# Install FSx CSI driver
kubectl apply -k "github.com/kubernetes-sigs/aws-fsx-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-0.10"

# Create storage class for FSx Lustre
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fsx-lustre
provisioner: fsx.csi.aws.com
parameters:
  subnetId: subnet-12345678
  securityGroupIds: sg-abcdef12
  s3ImportPath: s3://your-bucket/data
  s3ExportPath: s3://your-bucket/results
  deploymentType: PERSISTENT_1
EOF
```

## 🔐 Advanced Security & Compliance

### 🛡️ **Network Security Configuration**

#### **VPC Security Groups:**
```bash
# Create custom security group for enhanced security
CLUSTER_SG=$(aws ec2 create-security-group \
  --group-name eks-enhanced-security \
  --description "Enhanced security group for EKS learning cluster" \
  --vpc-id $(aws eks describe-cluster --name learning-cluster --query 'cluster.resourcesVpcConfig.vpcId' --output text) \
  --query 'GroupId' \
  --output text)

# Configure inbound rules
aws ec2 authorize-security-group-ingress \
  --group-id $CLUSTER_SG \
  --protocol tcp \
  --port 443 \
  --source-group $CLUSTER_SG \
  --group-owner-id $(aws sts get-caller-identity --query Account --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $CLUSTER_SG \
  --protocol tcp \
  --port 22 \
  --cidr 10.0.0.0/8

# Apply to existing node groups
eksctl utils update-cluster-vpc-config \
  --cluster learning-cluster \
  --private-access=true \
  --public-access=true \
  --public-access-cidrs="YOUR_IP/32"
```

#### **Network Policies:**
```yaml
# Namespace isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: eks-sample-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow specific ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress
  namespace: eks-sample-app
spec:
  podSelector:
    matchLabels:
      app: eks-sample-app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
---
# Allow DNS resolution
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: eks-sample-app
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
```

### 🔒 **RBAC Configuration**

#### **Custom Roles and Bindings:**
```yaml
# Developer role
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: eks-developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["extensions", "networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
---
# Read-only role
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: eks-viewer
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps", "extensions", "networking.k8s.io", "autoscaling"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
---
# Bind developer role
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: eks-developers
subjects:
- kind: User
  name: developer@company.com
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: eks-developer
  apiGroup: rbac.authorization.k8s.io
```

#### **Service Account with IAM Roles:**
```bash
# Create service account with specific AWS permissions
eksctl create iamserviceaccount \
  --cluster=learning-cluster \
  --namespace=eks-sample-app \
  --name=app-service-account \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess \
  --override-existing-serviceaccounts \
  --approve

# Use in deployment
kubectl patch deployment eks-sample-app -n eks-sample-app -p '
{
  "spec": {
    "template": {
      "spec": {
        "serviceAccountName": "app-service-account"
      }
    }
  }
}'
```

### 🔍 **Pod Security Standards**

#### **Enforce Security Policies:**
```yaml
# Namespace with security policies
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# Security context deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-namespace
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: nginx:alpine
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-cache
          mountPath: /var/cache/nginx
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-cache
        emptyDir: {}
      - name: var-run
        emptyDir: {}
```

### 🔐 **Secrets Management**

#### **AWS Secrets Manager Integration:**
```bash
# Install AWS Secrets Store CSI Driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true

# Install AWS provider
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

# Create secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "eks-learning/app-secrets" \
  --description "Application secrets for EKS learning cluster" \
  --secret-string '{"username":"admin","password":"supersecret","api-key":"abc123"}'

# Create IAM policy for secrets access
cat > secrets-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "arn:aws:secretsmanager:us-west-2:*:secret:eks-learning/*"
        }
    ]
}
EOF

aws iam create-policy --policy-name EKSSecretsManagerPolicy --policy-document file://secrets-policy.json

# Create service account with secrets access
eksctl create iamserviceaccount \
  --cluster=learning-cluster \
  --namespace=eks-sample-app \
  --name=secrets-access-sa \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/EKSSecretsManagerPolicy \
  --approve
```

#### **Use Secrets in Applications:**
```yaml
# SecretProviderClass
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
  namespace: eks-sample-app
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "eks-learning/app-secrets"
        objectType: "secretsmanager"
        jmesPath:
          - path: "username"
            objectAlias: "db-username"
          - path: "password"
            objectAlias: "db-password"
          - path: "api-key"
            objectAlias: "api-key"
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: db-username
      key: username
    - objectName: db-password
      key: password
    - objectName: api-key
      key: api-key
---
# Deployment using secrets
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app-with-secrets
  namespace: eks-sample-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app-with-secrets
  template:
    metadata:
      labels:
        app: secure-app-with-secrets
    spec:
      serviceAccountName: secrets-access-sa
      containers:
      - name: app
        image: nginx:alpine
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: password
        volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets"
          readOnly: true
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "app-secrets"
```

## 📊 Comprehensive Monitoring & Observability

### 🔍 **CloudWatch Container Insights**

#### **Setup Container Insights:**
```bash
# Deploy CloudWatch agent and FluentBit
ClusterName=learning-cluster
RegionName=us-west-2
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'

# Download and apply CloudWatch configuration
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/' | kubectl apply -f -

# Verify deployment
kubectl get pods -n amazon-cloudwatch
kubectl logs -n amazon-cloudwatch -l name=cloudwatch-agent
```

#### **Custom CloudWatch Metrics:**
```yaml
# Custom metrics configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: cwagentconfig
  namespace: amazon-cloudwatch
data:
  cwagentconfig.json: |
    {
      "logs": {
        "metrics_collected": {
          "kubernetes": {
            "metrics_collection_interval": 60,
            "resources": [
              "namespace",
              "service",
              "node",
              "pod",
              "container"
            ]
          }
        },
        "force_flush_interval": 5
      },
      "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
          "cpu": {
            "measurement": [
              "cpu_usage_idle",
              "cpu_usage_iowait",
              "cpu_usage_user",
              "cpu_usage_system"
            ],
            "metrics_collection_interval": 60
          },
          "disk": {
            "measurement": [
              "used_percent"
            ],
            "metrics_collection_interval": 60,
            "resources": [
              "*"
            ]
          },
          "diskio": {
            "measurement": [
              "io_time"
            ],
            "metrics_collection_interval": 60,
            "resources": [
              "*"
            ]
          },
          "mem": {
            "measurement": [
              "mem_used_percent"
            ],
            "metrics_collection_interval": 60
          }
        }
      }
    }
```

### 📊 **Prometheus & Grafana Stack**

#### **Install Complete Monitoring Stack:**
```bash
# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus Operator with complete stack
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=ebs-gp3 \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=ebs-gp3 \
  --set grafana.persistence.size=10Gi \
  --set grafana.adminPassword=admin123 \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName=ebs-gp3 \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=10Gi

# Wait for deployment
kubectl get pods -n monitoring -w

# Get Grafana admin password
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

#### **Expose Grafana Dashboard:**
```bash
# Create LoadBalancer service for Grafana
kubectl apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: grafana-loadbalancer
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
  selector:
    app.kubernetes.io/name: grafana
EOF

# Get Grafana URL
GRAFANA_URL=$(kubectl get service grafana-loadbalancer -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Grafana Dashboard: http://$GRAFANA_URL"
echo "Username: admin"
echo "Password: admin123"
```

### 🚨 **Advanced Alerting Configuration**

#### **Custom AlertManager Configuration:**
```yaml
# Custom alerting rules
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: eks-custom-alerts
  namespace: monitoring
  labels:
    app: kube-prometheus-stack
    release: prometheus-stack
spec:
  groups:
  - name: eks-cluster-alerts
    rules:
    - alert: HighNodeCPUUsage
      expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on node {{ $labels.instance }}"
        description: "Node {{ $labels.instance }} has CPU usage above 80% for more than 5 minutes."
    
    - alert: HighPodMemoryUsage
      expr: (container_memory_working_set_bytes / container_spec_memory_limit_bytes) * 100 > 90
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "High memory usage in pod {{ $labels.pod }}"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is using more than 90% of its memory limit."
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently."
```

#### **Slack Integration:**
```yaml
# AlertManager configuration for Slack
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-slack-webhook
  namespace: monitoring
stringData:
  url: "YOUR_SLACK_WEBHOOK_URL"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      slack_api_url_file: /etc/alertmanager/secrets/alertmanager-slack-webhook/url
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'slack-notifications'
    
    receivers:
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#kubernetes-alerts'
        title: 'EKS Cluster Alert'
        text: 'Summary: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        actions:
        - type: button
          text: 'Runbook'
          url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
        - type: button
          text: 'Query'
          url: '{{ (index .Alerts 0).GeneratorURL }}'
```

### 📈 **Application Performance Monitoring (APM)**

#### **Install Jaeger for Distributed Tracing:**
```bash
# Install Jaeger operator
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.48.0/jaeger-operator.yaml -n observability

# Deploy Jaeger instance
kubectl apply -f - << EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger-production
  namespace: observability
spec:
  strategy: production
  storage:
    type: elasticsearch
    elasticsearch:
      nodeCount: 3
      storage:
        storageClassName: ebs-gp3
        size: 10Gi
  collector:
    maxReplicas: 5
    resources:
      limits:
        memory: 128Mi
      requests:
        memory: 64Mi
  query:
    resources:
      limits:
        memory: 128Mi
      requests:
        memory: 64Mi
EOF
```

#### **OpenTelemetry Collector:**
```bash
# Install OpenTelemetry operator
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

# Deploy collector
kubectl apply -f - << EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: observability
spec:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      
    processors:
      batch:
    
    exporters:
      jaeger:
        endpoint: jaeger-production-collector.observability.svc.cluster.local:14250
        tls:
          insecure: true
      
      prometheus:
        endpoint: "0.0.0.0:8889"
    
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [jaeger]
        metrics:
          receivers: [otlp]
          processors: [batch]
          exporters: [prometheus]
EOF
```

## 🧹 Cleanup & Cost Management

### 🗂️ **Cleanup Applications and Resources**

#### **Remove Sample Applications:**
```bash
# Delete sample applications
kubectl delete namespace eks-sample-app

# Remove load testing resources
kubectl delete deployment resource-intensive-app -n eks-sample-app --ignore-not-found
kubectl delete pod load-generator --ignore-not-found

# Clean up monitoring if desired
helm uninstall prometheus-stack -n monitoring
kubectl delete namespace monitoring

# Remove observability tools
kubectl delete namespace observability
```

#### **Clean Up Storage Resources:**
```bash
# Delete EFS filesystem and mount targets
EFS_ID="fs-xxxxxxxx"  # Replace with your EFS ID

# Delete mount targets first
aws efs describe-mount-targets --file-system-id $EFS_ID --query 'MountTargets[*].MountTargetId' --output text | xargs -I {} aws efs delete-mount-target --mount-target-id {}

# Wait for mount targets to be deleted, then delete filesystem
aws efs delete-file-system --file-system-id $EFS_ID

# Delete FSx filesystem if created
LUSTRE_ID="fs-xxxxxxxx"  # Replace with your FSx ID
aws fsx delete-file-system --file-system-id $LUSTRE_ID

# Clean up EBS volumes (will be cleaned automatically when PVCs are deleted)
kubectl get pv
kubectl delete pvc --all --all-namespaces
```

### 🗄️ **Delete EKS Cluster**

#### **Method 1: Via AWS Console**
1. 🖥️ **Navigate to EKS Console** → Select your cluster
2. 🗑️ **Delete Node Groups First**:
   - Go to **"Compute"** tab
   - Select each node group → **"Delete"**
   - Wait for deletion to complete (5-10 minutes)
3. 🗑️ **Delete Add-ons**:
   - Go to **"Add-ons"** tab
   - Delete all add-ons
4. 🗑️ **Delete Cluster**:
   - Click **"Delete cluster"**
   - Type cluster name to confirm
   - Wait for deletion (10-15 minutes)

#### **Method 2: Via eksctl (Recommended)**
```bash
# Delete cluster with all associated resources
eksctl delete cluster --name learning-cluster --region us-west-2

# For advanced cluster configurations
eksctl delete cluster -f cluster-config.yaml

# Check deletion progress
aws eks list-clusters --region us-west-2
aws cloudformation list-stacks --stack-status-filter DELETE_IN_PROGRESS
```

#### **Manual Cleanup (if needed):**
```bash
# Delete CloudFormation stacks if they remain
aws cloudformation delete-stack --stack-name eksctl-learning-cluster-cluster
aws cloudformation delete-stack --stack-name eksctl-learning-cluster-nodegroup-standard-workers

# Delete IAM roles and policies
aws iam detach-role-policy --role-name EKSClusterServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam delete-role --role-name EKSClusterServiceRole

aws iam detach-role-policy --role-name EKSNodeInstanceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name EKSNodeInstanceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam detach-role-policy --role-name EKSNodeInstanceRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam delete-role --role-name EKSNodeInstanceRole

# Delete custom policies
aws iam delete-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AmazonEKSClusterAutoscalerPolicy
aws iam delete-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy
aws iam delete-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/EKSSecretsManagerPolicy

# Clean up VPC if created by eksctl (optional)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eksctl-learning-cluster-cluster/VPC" --query 'Vpcs[0].VpcId' --output text)
if [ "$VPC_ID" != "None" ]; then
    aws ec2 delete-vpc --vpc-id $VPC_ID
fi
```

### 💰 **Cost Optimization Strategies**

#### **Development Environment Cost Reduction:**
```bash
# Use Spot Instances for significant savings
eksctl create nodegroup \
  --cluster learning-cluster \
  --name spot-workers \
  --node-type m5.large \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 5 \
  --spot \
  --spot-price 0.05

# Schedule cluster shutdown during non-working hours
# Create Lambda function to stop/start nodes
cat > cluster-scheduler.py << EOF
import boto3
import json

def lambda_handler(event, context):
    client = boto3.client('eks')
    
    cluster_name = 'learning-cluster'
    action = event.get('action', 'stop')
    
    if action == 'stop':
        # Scale down node groups to 0
        autoscaling = boto3.client('autoscaling')
        response = autoscaling.describe_auto_scaling_groups()
        
        for asg in response['AutoScalingGroups']:
            if cluster_name in asg['AutoScalingGroupName']:
                autoscaling.update_auto_scaling_group(
                    AutoScalingGroupName=asg['AutoScalingGroupName'],
                    MinSize=0,
                    DesiredCapacity=0
                )
    
    elif action == 'start':
        # Scale up node groups
        autoscaling = boto3.client('autoscaling')
        response = autoscaling.describe_auto_scaling_groups()
        
        for asg in response['AutoScalingGroups']:
            if cluster_name in asg['AutoScalingGroupName']:
                autoscaling.update_auto_scaling_group(
                    AutoScalingGroupName=asg['AutoScalingGroupName'],
                    MinSize=1,
                    DesiredCapacity=2
                )
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Cluster {action} completed')
    }
EOF
```

#### **Production Environment Cost Monitoring:**
```bash
# Setup cost allocation tags
aws eks tag-resource \
  --resource-arn arn:aws:eks:us-west-2:$(aws sts get-caller-identity --query Account --output text):cluster/learning-cluster \
  --tags Environment=production,Project=kubernetes-learning,CostCenter=IT

# Create billing alert
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "EKS-Monthly-Budget",
    "BudgetLimit": {
      "Amount": "100",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "Service": ["Amazon Elastic Kubernetes Service"]
    }
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "your-email@example.com"
        }
      ]
    }
  ]'
```

## 🐛 Comprehensive Troubleshooting Guide

### 🔍 **Cluster Creation Issues**

#### **eksctl Creation Failures:**
```bash
# Check CloudFormation events for detailed errors
aws cloudformation describe-stack-events \
  --stack-name eksctl-learning-cluster-cluster \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[Timestamp,ResourceType,ResourceStatusReason]' \
  --output table

# Check IAM permissions
aws sts get-caller-identity
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME

# Verify VPC limits and quotas
aws ec2 describe-vpcs
aws ec2 describe-account-attributes --attribute-names max-instances

# Common fixes:
# 1. Increase EIP limit if needed
aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3

# 2. Request quota increase
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --desired-value 10
```

#### **Node Group Join Issues:**
```bash
# Check node group status
eksctl get nodegroup --cluster learning-cluster
aws eks describe-nodegroup --cluster-name learning-cluster --nodegroup-name standard-workers

# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:aws:eks:cluster-name,Values=learning-cluster" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,LaunchTime,PrivateIpAddress]' \
  --output table

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName,`learning-cluster`)].AutoScalingGroupName' --output text)

# Node troubleshooting
kubectl get nodes -o wide
kubectl describe node NODE_NAME

# Check kubelet logs on node
ssh -i ~/.ssh/your-key.pem ec2-user@NODE_IP
sudo journalctl -u kubelet -f
```

### 🌐 **Networking Problems**

#### **Pod-to-Pod Communication Issues:**
```bash
# Check CNI plugin status
kubectl get pods -n kube-system | grep aws-node
kubectl logs -n kube-system -l k8s-app=aws-node

# Verify VPC CNI configuration
kubectl describe configmap -n kube-system aws-node

# Check security groups
aws ec2 describe-security-groups --group-ids $(aws eks describe-cluster --name learning-cluster --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)

# Test pod networking
kubectl run network-test --image=busybox:latest --restart=Never --rm -it -- /bin/sh
# Inside pod: nslookup kubernetes.default.svc.cluster.local

# Check DNS resolution
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup kubernetes.default
```

#### **Load Balancer Issues:**
```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify service annotation
kubectl describe service YOUR_SERVICE -n YOUR_NAMESPACE

# Check ALB/NLB creation
aws elbv2 describe-load-balancers
aws elb describe-load-balancers

# Common ALB troubleshooting
kubectl get events --field-selector involvedObject.kind=Service -n YOUR_NAMESPACE
kubectl describe ingress YOUR_INGRESS -n YOUR_NAMESPACE
```

### 🔐 **Authentication & Authorization Issues**

#### **kubectl Access Problems:**
```bash
# Verify kubeconfig
kubectl config view
kubectl config current-context

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name learning-cluster

# Check cluster endpoint accessibility
aws eks describe-cluster --name learning-cluster --query 'cluster.endpoint'

# Test cluster connectivity
kubectl cluster-info
kubectl auth can-i get pods --all-namespaces

# Debug authentication
kubectl auth can-i get pods --as=system:serviceaccount:default:default
```

#### **RBAC Issues:**
```bash
# Check user/service account permissions
kubectl auth can-i create pods --as=USER_NAME
kubectl describe rolebinding -n NAMESPACE
kubectl describe clusterrolebinding

# Check service account token
kubectl get serviceaccount ACCOUNT_NAME -o yaml
kubectl describe secret $(kubectl get serviceaccount ACCOUNT_NAME -o jsonpath='{.secrets[0].name}')
```

### 💾 **Storage Problems**

#### **EBS CSI Driver Issues:**
```bash
# Check EBS CSI driver status
kubectl get pods -n kube-system | grep ebs-csi
kubectl logs -n kube-system -l app=ebs-csi-controller

# Verify storage class
kubectl get storageclass
kubectl describe storageclass ebs-gp3

# Check PVC status
kubectl get pvc -A
kubectl describe pvc PVC_NAME -n NAMESPACE

# EBS volume troubleshooting
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/learning-cluster,Values=owned"
```

#### **EFS Mount Issues:**
```bash
# Check EFS CSI driver
kubectl get pods -n kube-system | grep efs-csi
kubectl logs -n kube-system -l app=efs-csi-controller

# Verify EFS filesystem and mount targets
aws efs describe-file-systems
aws efs describe-mount-targets --file-system-id fs-XXXXXXXX

# Test EFS connectivity from node
ssh -i ~/.ssh/your-key.pem ec2-user@NODE_IP
sudo mount -t efs fs-XXXXXXXX:/ /mnt/efs
```

### 📊 **Performance Issues**

#### **Resource Constraints:**
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check resource requests/limits
kubectl describe node NODE_NAME | grep -A 10 "Allocated resources"

# Identify resource-hungry pods
kubectl get pods -A --sort-by='.spec.containers[0].resources.requests.memory'

# Check cluster autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler
kubectl describe configmap cluster-autoscaler-status -n kube-system
```

#### **Application Performance:**
```bash
# Check application logs
kubectl logs -f deployment/YOUR_APP -n YOUR_NAMESPACE

# Check pod events
kubectl describe pod POD_NAME -n NAMESPACE

# Monitor resource usage over time
kubectl top pod POD_NAME --containers -n NAMESPACE
```

### 🚨 **Common Error Solutions**

#### **Error: "nodes are available: pod didn't trigger scale-up"**
```bash
# Check cluster autoscaler configuration
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml

# Verify node group configuration
eksctl get nodegroup --cluster learning-cluster

# Check for taints or node selectors
kubectl describe nodes | grep -i taint
kubectl describe deployment YOUR_DEPLOYMENT | grep -i nodeSelector
```

#### **Error: "failed to get ECR login token"**
```bash
# Update IAM policies for nodes
aws iam attach-role-policy \
  --role-name eksctl-learning-cluster-nodegroup-NodeInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Check ECR repository permissions
aws ecr describe-repositories
aws ecr get-login-password --region us-west-2
```

#### **Error: "ELB subnets must be in different Availability Zones"**
```bash
# Check subnet configuration
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(aws eks describe-cluster --name learning-cluster --query 'cluster.resourcesVpcConfig.vpcId' --output text)"

# Tag subnets correctly for load balancers
aws ec2 create-tags --resources subnet-XXXXXXXX --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources subnet-YYYYYYYY --tags Key=kubernetes.io/role/internal-elb,Value=1
```

### 🛠️ **Emergency Recovery Procedures**

#### **Cluster Unresponsive:**
```bash
# Check cluster status
aws eks describe-cluster --name learning-cluster --query 'cluster.status'

# Force update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name learning-cluster --force

# Check control plane health
kubectl get componentstatuses
kubectl get nodes

# Restart critical pods
kubectl delete pod -n kube-system -l k8s-app=kube-dns
kubectl delete pod -n kube-system -l k8s-app=aws-node
```

#### **Node Group Recovery:**
```bash
# Drain problematic nodes
kubectl drain NODE_NAME --ignore-daemonsets --delete-emptydir-data

# Scale down and up node group
eksctl scale nodegroup --cluster=learning-cluster --name=standard-workers --nodes=0
sleep 60
eksctl scale nodegroup --cluster=learning-cluster --name=standard-workers --nodes=2

# Replace specific instances
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id i-XXXXXXXXX \
  --should-decrement-desired-capacity
```

## 💡 Best Practices & Production Tips

### 🏗️ **Architecture Best Practices**

#### **Cluster Design Principles:**
- ✅ **Multi-AZ Deployment**: Distribute nodes across 3+ availability zones
- ✅ **Separate Node Groups**: Different workload types on dedicated node groups
- ✅ **Right-Sizing**: Use appropriate instance types for workload requirements
- ✅ **Reserved Instances**: Plan for predictable workloads with RI purchases
- ✅ **Spot Instances**: Use for fault-tolerant, stateless applications

#### **Security Hardening:**
```bash
# Enable envelope encryption
aws kms create-key --description "EKS Secrets Encryption Key"
KMS_KEY_ARN=$(aws kms create-key --description "EKS Secrets Encryption Key" --query 'KeyMetadata.Arn' --output text)

# Update cluster with encryption
aws eks update-cluster-config \
  --name learning-cluster \
  --encryption-config resources=secrets,provider='{keyArn='$KMS_KEY_ARN'}'

# Restrict API server access
aws eks update-cluster-config \
  --name learning-cluster \
  --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs="YOUR_IP/32",endpointPrivateAccess=true
```

#### **Network Security:**
```bash
# Implement network segmentation
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
EOF
```

### 📊 **Performance Optimization**

#### **Resource Management:**
```yaml
# Resource quotas and limits
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "5"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: production
spec:
  limits:
  - default:
      memory: "512Mi"
      cpu: "500m"
    defaultRequest:
      memory: "256Mi"
      cpu: "100m"
    type: Container
```

#### **Auto-scaling Configuration:**
```yaml
# Vertical Pod Autoscaler
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: webapp-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: webapp
      maxAllowed:
        cpu: 2
        memory: 4Gi
      minAllowed:
        cpu: 100m
        memory: 128Mi
```

### 🔄 **DevOps Integration**

#### **GitOps with ArgoCD:**
```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### **CI/CD Pipeline Integration:**
```yaml
# GitHub Actions workflow for EKS deployment
name: Deploy to EKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Update kubeconfig
      run: aws eks update-kubeconfig --name learning-cluster
    
    - name: Deploy to EKS
      run: |
        kubectl apply -f k8s/
        kubectl rollout status deployment/webapp -n production
```

### 🔒 **Compliance & Governance**

#### **Pod Security Standards:**
```yaml
# Enforce restricted security policy
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-pod-security-standards
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: check-security-context
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Security context is required"
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
```

#### **Audit Logging:**
```bash
# Enable comprehensive audit logging
aws eks update-cluster-config \
  --name learning-cluster \
  --logging '{
    "clusterLogging": {
      "enable": ["api", "audit", "authenticator", "controllerManager", "scheduler"],
      "disable": []
    }
  }'

# Query audit logs in CloudWatch
aws logs filter-log-events \
  --log-group-name "/aws/eks/learning-cluster/cluster" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern '{ $.verb = "create" || $.verb = "delete" }'
```

### 💰 **Cost Optimization Strategies**

#### **Automated Cost Management:**
```bash
# Install Cluster Proportional Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/cluster-proportional-autoscaler/master/examples/cluster-proportional-autoscaler.yaml

# Configure HPA with custom metrics
kubectl apply -f - << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 2
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
EOF
```

#### **Cost Monitoring Dashboard:**
```bash
# Create cost allocation tags
aws eks tag-resource \
  --resource-arn arn:aws:eks:us-west-2:$(aws sts get-caller-identity --query Account --output text):cluster/learning-cluster \
  --tags \
    Environment=production \
    Team=platform \
    Application=webapp \
    CostCenter=engineering
```

## 📚 Additional Resources & Learning Path

### 🎓 **Learning Progression**

#### **Beginner Resources:**
- 📖 [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/) - Official AWS documentation
- 🎥 [AWS EKS Workshop](https://www.eksworkshop.com/) - Hands-on learning modules
- 📊 [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) - Best practices
- 🔧 [eksctl Documentation](https://eksctl.io/) - Command-line tool reference

#### **Intermediate Resources:**
- 📖 [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- 🎯 [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/) - Comprehensive guide
- 🔒 [AWS Security Best Practices](https://d1.awsstatic.com/whitepapers/Security/DDoS_White_Paper.pdf)
- 🛠️ [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/)

#### **Advanced Resources:**
- 🏗️ [Multi-Cluster Management](https://aws.amazon.com/blogs/containers/multi-cluster-management-for-kubernetes-with-cluster-api-and-argo-cd/)
- 🤖 [Kubernetes Operators Development](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
- 🌐 [Service Mesh with Istio on EKS](https://aws.amazon.com/blogs/opensource/getting-started-istio-eks/)
- 📊 [GitOps with Flux v2](https://fluxcd.io/docs/get-started/)

### 🔗 **Essential Tools & Extensions**

#### **Command Line Tools:**
```bash
# Install additional useful tools
# k9s - Kubernetes CLI dashboard
curl -sS https://webinstall.dev/k9s | bash

# kubectx & kubens - context and namespace switching
curl -sS https://webinstall.dev/kubectx | bash

# helm - package manager
curl -sS https://webinstall.dev/helm | bash

# stern - multi-pod log tailing
curl -sS https://webinstall.dev/stern | bash
```

#### **VS Code Extensions:**
- 🔧 **Kubernetes** - Official Kubernetes extension
- 🐳 **Docker** - Docker integration
- 📝 **YAML** - YAML language support
- 🔍 **GitLens** - Git integration
- 🚀 **AWS Toolkit** - AWS resource management

### 🎯 **Next Steps After Setup**

#### **Immediate Tasks:**
1. ✅ **Complete** [Project 01: Hello Kubernetes](../../01-beginner/01-hello-kubernetes/)
2. ✅ **Deploy** a sample application with persistent storage
3. ✅ **Configure** monitoring and alerting
4. ✅ **Set up** CI/CD pipeline integration

#### **Advanced Exploration:**
1. 🔄 **Implement** GitOps workflows with ArgoCD or Flux
2. 🔒 **Configure** comprehensive security policies
3. 🌐 **Set up** service mesh for microservices
4. 📊 **Create** custom operators for specific use cases

### 🤝 **Community & Support**

#### **Getting Help:**
- 💬 [AWS re:Post](https://repost.aws/) - AWS community forum
- 🗨️ [Kubernetes Slack](https://kubernetes.slack.com/) - Join #aws-eks channel
- 📺 [CNCF YouTube](https://www.youtube.com/c/cloudnativefdn) - Cloud Native content
- 📖 [Stack Overflow](https://stackoverflow.com/questions/tagged/amazon-eks) - Technical Q&A

#### **Stay Updated:**
- 📰 [AWS Container Blog](https://aws.amazon.com/blogs/containers/)
- 🐦 [AWS Containers Twitter](https://twitter.com/awscontainers)
- 📧 [CNCF Newsletter](https://www.cncf.io/newsletter/)
- 🎙️ [PodCTL Podcast](https://podctl.com/) - Kubernetes and container topics

### 🎉 **Certification Path**

#### **AWS Certifications:**
- 🏅 **AWS Certified Cloud Practitioner** - Foundation level
- 🥈 **AWS Certified Solutions Architect Associate** - Infrastructure focus
- 🥇 **AWS Certified DevOps Engineer Professional** - Advanced automation

#### **Kubernetes Certifications:**
- ⭐ **Certified Kubernetes Application Developer (CKAD)** - Application development
- 🛠️ **Certified Kubernetes Administrator (CKA)** - Cluster administration
- 🔒 **Certified Kubernetes Security Specialist (CKS)** - Security focus

---

## 🚀 Ready to Begin Your Kubernetes Journey?

Your Amazon EKS cluster is now configured and ready for production-grade workloads! This comprehensive setup provides:

### ✅ **What You've Accomplished:**
- 🎛️ **Fully managed Kubernetes cluster** with enterprise-grade security
- 🔧 **Complete toolchain** with monitoring, logging, and auto-scaling
- 🛡️ **Security hardening** with RBAC, network policies, and secrets management
- 💾 **Multiple storage options** including EBS, EFS, and FSx
- 📊 **Comprehensive monitoring** with CloudWatch, Prometheus, and Grafana
- 🔄 **CI/CD ready** infrastructure for modern development workflows

### 🎯 **Your Next Steps:**
1. 🏁 **Start with [Project 01: Hello Kubernetes](../../01-beginner/01-hello-kubernetes/)** - Deploy your first application
2. 📖 **Explore the [Project Roadmap](../../README.md#-project-roadmap)** - Plan your learning journey
3. 💡 **Join our community** - Share your progress and get help when needed
4. 🌟 **Contribute back** - Help improve this learning resource

**Happy learning, and welcome to the exciting world of Kubernetes on AWS! 🌟**
