# Setting up Kubernetes with Minikube

Minikube is the easiest way to run Kubernetes locally for development and learning. This guide will help you set up minikube on different operating systems.

## 🎯 What is Minikube?

Minikube creates a local Kubernetes cluster on your machine, perfect for:
- Learning Kubernetes concepts
- Development and testing
- Running the projects in this repository
- Experimenting with Kubernetes features

## 💻 System Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **Memory**: 2GB RAM
- **Disk**: 20GB free space
- **Internet**: For downloading images

### Recommended
- **CPU**: 4+ cores
- **Memory**: 4GB+ RAM
- **Disk**: 40GB+ free space

## 🚀 Installation Guide

### Windows

#### Option 1: Using Chocolatey (Recommended)
```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install minikube
choco install minikube

# Install kubectl
choco install kubernetes-cli
```

#### Option 2: Direct Download
1. Download the latest minikube Windows installer from [GitHub releases](https://github.com/kubernetes/minikube/releases)
2. Run the installer as Administrator
3. Download kubectl from [Kubernetes releases](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

### macOS

#### Using Homebrew (Recommended)
```bash
# Install minikube
brew install minikube

# Install kubectl
brew install kubectl
```

#### Direct Download
```bash
# Download and install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube /usr/local/bin/

# Download and install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
sudo install kubectl /usr/local/bin/
```

### Linux

#### Using Package Manager

**Ubuntu/Debian:**
```bash
# Update package index
sudo apt update

# Install dependencies
sudo apt install -y curl wget apt-transport-https

# Download and install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube /usr/local/bin/

# Download and install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/
```

**CentOS/RHEL/Fedora:**
```bash
# Download and install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube /usr/local/bin/

# Download and install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/
```

## 🐳 Container Runtime Setup

Minikube needs a container runtime. Choose one:

### Docker (Recommended)
- **Windows/macOS**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Linux**: Install Docker CE following [official instructions](https://docs.docker.com/engine/install/)

### Alternative Runtimes
- **Podman**: Lightweight alternative to Docker
- **VirtualBox**: VM-based approach
- **KVM**: Linux virtualization

## 🏃‍♂️ Starting Minikube

### Basic Start
```bash
# Start minikube with default settings
minikube start

# Start with specific driver
minikube start --driver=docker

# Start with more resources
minikube start --memory=4096 --cpus=4
```

### Advanced Configuration
```bash
# Start with specific Kubernetes version
minikube start --kubernetes-version=v1.28.0

# Start with multiple nodes
minikube start --nodes=3

# Start with addons enabled
minikube start --addons=ingress,dashboard,metrics-server
```

## ✅ Verification

Check if everything is working:

```bash
# Check minikube status
minikube status

# Check cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods --all-namespaces
```

Expected output:
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## 🔧 Essential Commands

### Minikube Management
```bash
# Start minikube
minikube start

# Stop minikube
minikube stop

# Delete minikube cluster
minikube delete

# Check status
minikube status

# Get cluster IP
minikube ip

# SSH into minikube
minikube ssh
```

### Service Access
```bash
# Get service URL
minikube service <service-name> --url

# Open service in browser
minikube service <service-name>

# List all services
minikube service list
```

### Addons
```bash
# List available addons
minikube addons list

# Enable addon
minikube addons enable <addon-name>

# Disable addon
minikube addons disable <addon-name>

# Useful addons for learning
minikube addons enable dashboard
minikube addons enable ingress
minikube addons enable metrics-server
```

### Dashboard
```bash
# Start Kubernetes dashboard
minikube dashboard

# Get dashboard URL only
minikube dashboard --url
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Minikube Won't Start
```bash
# Check available drivers
minikube start --help | grep driver

# Try different driver
minikube start --driver=virtualbox
minikube start --driver=docker

# Clean start
minikube delete
minikube start
```

#### 2. Insufficient Resources
```bash
# Check current resources
minikube config view

# Increase resources
minikube config set memory 4096
minikube config set cpus 4
minikube delete
minikube start
```

#### 3. Docker Issues
```bash
# Check Docker is running
docker version

# Reset Docker to factory defaults (Docker Desktop)
# Or restart Docker service
sudo systemctl restart docker  # Linux
```

#### 4. Network Issues
```bash
# Check network connectivity
curl -I https://k8s.gcr.io/v2/

# Use different image repository
minikube start --image-repository=registry.aliyuncs.com/google_containers
```

### Getting Help
```bash
# View logs
minikube logs

# Get detailed status
minikube status -o json

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## ⚙️ Advanced Configuration

### Resource Allocation
```bash
# Set default memory and CPU
minikube config set memory 4096
minikube config set cpus 4

# View current configuration
minikube config view
```

### Persistent Configuration
Create `~/.minikube/config/config.json`:
```json
{
    "driver": "docker",
    "memory": 4096,
    "cpus": 4,
    "disk-size": "40g",
    "addons": [
        "dashboard",
        "ingress",
        "metrics-server"
    ]
}
```

### Multiple Profiles
```bash
# Create named profile
minikube start -p learning --memory=2048 --cpus=2

# Switch between profiles
minikube profile learning
minikube profile minikube

# List profiles
minikube profile list
```

## 🔄 Cleanup

When you're done:
```bash
# Stop minikube
minikube stop

# Delete cluster (removes all data)
minikube delete

# Remove all profiles
minikube delete --all
```

## 📚 Next Steps

Once minikube is running:
1. Verify with `kubectl cluster-info`
2. Try `kubectl get nodes`
3. Start with [Project 1: Hello Kubernetes](../../01-beginner/01-hello-kubernetes/)

## 🆘 Getting Help

If you encounter issues:
- Check the [official minikube documentation](https://minikube.sigs.k8s.io/docs/)
- Visit [minikube GitHub issues](https://github.com/kubernetes/minikube/issues)
- Join the [Kubernetes Slack](https://kubernetes.slack.com/)

---

**Ready to start learning?** Head over to the [first project](../../01-beginner/01-hello-kubernetes/) and begin your Kubernetes journey!
