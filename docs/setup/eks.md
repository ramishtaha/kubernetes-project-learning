# Setting up Kubernetes on Amazon EKS

Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service that makes it easy to run Kubernetes on AWS without needing to install and operate your own Kubernetes control plane.

## 🎯 What is EKS?

EKS provides:
- **Managed Control Plane**: AWS manages the Kubernetes masters
- **High Availability**: Control plane runs across multiple AZs
- **Security**: Integrated with AWS IAM and VPC
- **Scalability**: Auto-scaling for nodes and pods
- **AWS Integration**: Native integration with AWS services

## 💰 Cost Considerations

### EKS Pricing
- **Control Plane**: $0.10 per hour per cluster (~$73/month)
- **Worker Nodes**: Standard EC2 pricing
- **Fargate**: Pay per vCPU and memory used
- **Data Transfer**: Standard AWS rates

### Cost Optimization Tips
- Use Spot Instances for non-production workloads
- Right-size your instances
- Use Fargate for variable workloads
- Enable cluster autoscaler

## 🛠️ Prerequisites

### Required Tools
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/
```

### AWS Account Setup
```bash
# Configure AWS credentials
aws configure
# Enter your Access Key ID, Secret Access Key, region, and output format

# Verify configuration
aws sts get-caller-identity
```

## 🚀 Quick Setup (15 minutes)

### Create EKS Cluster with eksctl
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
  --managed

# This creates:
# - EKS cluster with managed control plane
# - Managed node group with 2 t3.medium instances
# - VPC with public and private subnets
# - Security groups and IAM roles
```

### Verify Setup
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name learning-cluster

# Test cluster access
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

## ⚙️ Advanced Setup

### Custom Cluster Configuration
```yaml
# cluster-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: advanced-learning-cluster
  region: us-west-2
  version: "1.28"

iam:
  withOIDC: true

addons:
- name: vpc-cni
  version: latest
- name: coredns
  version: latest
- name: kube-proxy
  version: latest
- name: aws-ebs-csi-driver
  version: latest

managedNodeGroups:
- name: general
  instanceType: t3.medium
  minSize: 1
  maxSize: 10
  desiredCapacity: 3
  volumeSize: 20
  ssh:
    allow: true
  labels:
    role: general
  tags:
    Environment: learning
    Project: kubernetes-projects

- name: compute-optimized
  instanceType: c5.large
  minSize: 0
  maxSize: 5
  desiredCapacity: 0
  volumeSize: 50
  labels:
    role: compute
  taints:
  - key: compute
    value: "true"
    effect: NoSchedule

fargateProfiles:
- name: serverless
  selectors:
  - namespace: fargate
  - namespace: kube-system
    labels:
      k8s-app: aws-load-balancer-controller

cloudWatch:
  clusterLogging:
    enable: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
```

Deploy with configuration:
```bash
eksctl create cluster -f cluster-config.yaml
```

## 🔧 Essential EKS Configurations

### Install AWS Load Balancer Controller
```bash
# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=learning-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name=AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

# Install controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=learning-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Setup EBS CSI Driver
```bash
# Create IAM service account for EBS CSI
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster learning-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/Amazon_EBS_CSI_DriverPolicy \
  --approve \
  --override-existing-serviceaccounts

# Install EBS CSI driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.24"
```

### Configure Cluster Autoscaler
```bash
# Create IAM policy for cluster autoscaler
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
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy \
  --policy-name AmazonEKSClusterAutoscalerPolicy \
  --policy-document file://cluster-autoscaler-policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=learning-cluster \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve

# Deploy cluster autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Update deployment to use correct cluster name
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"cluster-autoscaler","command":["./cluster-autoscaler","--v=4","--stderrthreshold=info","--cloud-provider=aws","--skip-nodes-with-local-storage=false","--expander=least-waste","--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/learning-cluster"]}]}}}}'
```

## 🧪 Testing Your EKS Cluster

### Deploy Sample Application
```bash
# Create namespace
kubectl create namespace eks-sample-app

# Deploy application
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eks-sample-app
  namespace: eks-sample-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: eks-sample-app
  template:
    metadata:
      labels:
        app: eks-sample-app
    spec:
      containers:
      - name: app
        image: public.ecr.aws/nginx/nginx:1.21
        ports:
        - containerPort: 80
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
  name: eks-sample-service
  namespace: eks-sample-app
spec:
  selector:
    app: eks-sample-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

# Wait for load balancer
kubectl get service eks-sample-service -n eks-sample-app -w

# Test access
curl $(kubectl get service eks-sample-service -n eks-sample-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

### Test Autoscaling
```bash
# Deploy HPA
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
        averageUtilization: 70
EOF

# Generate load
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod:
# while true; do wget -q -O- http://eks-sample-service.eks-sample-app.svc.cluster.local; done

# Watch scaling
kubectl get hpa -n eks-sample-app -w
kubectl get pods -n eks-sample-app -w
```

## 💾 Storage Configuration

### EBS Storage Class
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

### EFS Storage Class
```bash
# Install EFS CSI driver
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"

# Create EFS filesystem
aws efs create-file-system \
  --performance-mode generalPurpose \
  --throughput-mode provisioned \
  --provisioned-throughput-in-mibps 500 \
  --encrypted

# Create storage class
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-xxxxxxxx  # Replace with your EFS ID
  directoryPerms: "700"
EOF
```

## 🔐 Security Best Practices

### Network Security
```bash
# Create security group for additional restrictions
aws ec2 create-security-group \
  --group-name eks-additional-sg \
  --description "Additional security group for EKS" \
  --vpc-id $(aws eks describe-cluster --name learning-cluster --query 'cluster.resourcesVpcConfig.vpcId' --output text)

# Add rules as needed
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxx \
  --protocol tcp \
  --port 443 \
  --source-group sg-xxxxxxxx
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

### RBAC Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: eks-developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: eks-developers
subjects:
- kind: User
  name: developer@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: eks-developer
  apiGroup: rbac.authorization.k8s.io
```

## 📊 Monitoring and Logging

### CloudWatch Container Insights
```bash
# Deploy CloudWatch agent
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/learning-cluster/;s/{{region_name}}/us-west-2/" | kubectl apply -f -

# Deploy FluentD
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/learning-cluster/;s/{{region_name}}/us-west-2/" | kubectl apply -f -
```

### Prometheus Monitoring
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123
```

## 🧹 Cleanup

### Delete Applications
```bash
# Delete sample application
kubectl delete namespace eks-sample-app

# Delete monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

### Delete EKS Cluster
```bash
# Delete the cluster (this may take 10-15 minutes)
eksctl delete cluster --name learning-cluster

# Verify deletion
aws eks list-clusters --region us-west-2
```

### Clean Up AWS Resources
```bash
# Delete EFS filesystem
aws efs delete-file-system --file-system-id fs-xxxxxxxx

# Delete custom policies
aws iam delete-policy --policy-arn arn:aws:iam::ACCOUNT:policy/AmazonEKSClusterAutoscalerPolicy
```

## 🐛 Troubleshooting

### Common Issues

#### Nodes Not Joining Cluster
```bash
# Check node group status
eksctl get nodegroup --cluster learning-cluster

# Check CloudFormation stack
aws cloudformation describe-stacks --stack-name eksctl-learning-cluster-nodegroup-standard-workers

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=eksctl-*"
```

#### Permission Issues
```bash
# Check IAM role trust relationships
aws iam get-role --role-name eksctl-learning-cluster-nodegroup-NodeInstanceRole

# Verify service account annotations
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
```

#### Load Balancer Issues
```bash
# Check controller logs
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp -A | grep LoadBalancer
```

## 💡 Tips and Best Practices

### Cost Optimization
- Use Spot Instances for development clusters
- Right-size your instances based on actual usage
- Enable cluster autoscaler to scale down unused nodes
- Use Fargate for batch workloads

### Security
- Enable CloudTrail for audit logging
- Use IAM roles for service accounts (IRSA)
- Implement network policies
- Regular security scanning with tools like kube-bench

### Performance
- Use GP3 EBS volumes for better price/performance
- Configure resource requests and limits
- Use horizontal pod autoscaler
- Monitor with CloudWatch Container Insights

## 📚 Additional Resources

- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [eksctl Documentation](https://eksctl.io/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [AWS Controllers for Kubernetes](https://aws-controllers-k8s.github.io/community/)

---

**Ready to start your projects on EKS?** Your cluster is now configured and ready for the Kubernetes learning projects. Head back to [Project 1](../../01-beginner/01-hello-kubernetes/) to begin!
