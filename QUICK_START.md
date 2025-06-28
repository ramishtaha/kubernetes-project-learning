# Quick Start Guide 🚀

Get up and running with Kubernetes project-based learning in minutes!

## ⚡ Quick Setup (5 minutes)

### 1. Install Prerequisites
Choose your platform:

**Windows (PowerShell as Administrator):**
```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install minikube kubernetes-cli docker-desktop -y
```

**macOS:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install minikube kubectl docker
```

**Linux (Ubuntu/Debian):**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install kubectl and minikube
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube /usr/local/bin/
```

### 2. Start Kubernetes Cluster
```bash
# Start minikube
minikube start --memory=4096 --cpus=4

# Verify installation
kubectl cluster-info
kubectl get nodes
```

### 3. Run Your First Project
```bash
# Clone this repository
git clone https://github.com/ramishtaha/kubernetes-project-learning.git
cd kubernetes-project-learning

# Go to first project
cd 01-beginner/01-hello-kubernetes

# Deploy the application
kubectl apply -f manifests/

# Access the application
minikube service hello-service
```

## 🎯 Learning Path

### Phase 1: Foundation (Projects 1-5) - 4-6 hours
- ✅ **Project 1**: Hello Kubernetes - Basic concepts
- ✅ **Project 2**: Multi-Container App - ConfigMaps, Secrets
- ✅ **Project 3**: Database Integration - StatefulSets, Persistence
- 🚧 **Project 4**: Load Balancing - Ingress, HPA
- 🚧 **Project 5**: Configuration Management - Helm, Kustomize

### Phase 2: Real-World (Projects 6-10) - 12-16 hours
- ✅ **Project 6**: Microservices Architecture - Service Mesh
- 🚧 **Project 7**: CI/CD Pipeline - GitOps, ArgoCD
- 🚧 **Project 8**: Monitoring & Observability - Prometheus, Grafana
- 🚧 **Project 9**: Security Hardening - RBAC, Network Policies
- 🚧 **Project 10**: Disaster Recovery - Backup, Restore

### Phase 3: Advanced (Projects 11-15) - 20+ hours
- 🚧 **Project 11**: Multi-Cluster Management
- 🚧 **Project 12**: Custom Controllers & Operators
- 🚧 **Project 13**: ML Pipeline on Kubernetes
- 🚧 **Project 14**: Edge Computing
- 🚧 **Project 15**: Enterprise Platform

## 🛠️ Essential Commands

### Cluster Management
```bash
# Start/stop cluster
minikube start
minikube stop
minikube delete

# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### Application Deployment
```bash
# Apply manifests
kubectl apply -f manifest.yaml
kubectl apply -f manifests/

# Check resources
kubectl get pods
kubectl get services
kubectl get deployments

# Describe resources
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Service Access
```bash
# Local access (minikube)
minikube service <service-name>
minikube service <service-name> --url

# Port forwarding
kubectl port-forward service/<service-name> 8080:80
```

### Debugging
```bash
# Pod logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # follow

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/bash

# Events and troubleshooting
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe pod <pod-name>
```

## 📁 Project Structure

Each project follows this consistent structure:
```
project-name/
├── README.md              # Complete guide
├── manifests/             # Kubernetes YAML files
│   ├── 01-*.yaml         # Numbered for order
│   ├── 02-*.yaml
│   └── ...
├── scripts/               # Automation scripts
│   ├── deploy.sh         # Linux/macOS
│   └── deploy.bat        # Windows
└── docs/                  # Additional documentation
```

## 🔧 Troubleshooting Quick Fixes

### Minikube Won't Start
```bash
minikube delete
minikube start --driver=docker
```

### Pods Stuck in Pending
```bash
kubectl describe nodes  # Check resources
kubectl describe pod <pod-name>  # Check events
```

### Can't Access Services
```bash
minikube service list  # See all services
kubectl get svc  # Check service configuration
```

### Images Won't Pull
```bash
kubectl describe pod <pod-name>  # Check events
# Usually network connectivity or image name issues
```

## 📚 Learning Resources

### Documentation
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

### Community
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [r/kubernetes](https://www.reddit.com/r/kubernetes/)
- [CNCF YouTube](https://www.youtube.com/c/CloudNativeComputingFoundation)

## 🎯 Success Criteria

You'll know you're making progress when you can:

**After Project 1-2:**
- [ ] Deploy applications to Kubernetes
- [ ] Use kubectl confidently
- [ ] Understand Pods, Services, Deployments

**After Project 3-5:**
- [ ] Handle persistent data
- [ ] Manage configuration and secrets
- [ ] Scale applications

**After Project 6-10:**
- [ ] Design microservices architectures
- [ ] Implement CI/CD pipelines
- [ ] Monitor and secure applications

**After Project 11-15:**
- [ ] Manage enterprise Kubernetes
- [ ] Build custom operators
- [ ] Handle complex scenarios

## 🆘 Getting Help

1. **Check the FAQ**: [docs/FAQ.md](docs/FAQ.md)
2. **Project-specific troubleshooting**: Each project has a troubleshooting section
3. **Open an issue**: [GitHub Issues](https://github.com/ramishtaha/kubernetes-project-learning/issues)
4. **Join the community**: Links in documentation

## 🎉 What's Next?

Ready to start? Here are your options:

### 🟢 **Complete Beginner**
Start with [Project 1: Hello Kubernetes](01-beginner/01-hello-kubernetes/)

### 🟡 **Some Docker Experience**
Jump to [Project 2: Multi-Container App](01-beginner/02-multi-container-app/)

### 🔴 **Kubernetes Basics Known**
Try [Project 6: Microservices Architecture](02-intermediate/06-microservices-architecture/)

---

**Let's start your Kubernetes journey!** 🚀

Remember: It's better to thoroughly complete fewer projects than to rush through many. Take your time, experiment, and make sure you understand each concept before moving forward.
