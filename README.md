# Kubernetes Project-Based Learning 🚀

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28+-blue.svg)](https://kubernetes.io/)
[![Projects](https://img.shields.io/badge/Projects-16-green.svg)](#project-structure)
[![Difficulty](https://img.shields.io/badge/Difficulty-Beginner%20to%20Advanced-orange.svg)](#learning-path-overview)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Contributions](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)](CONTRIBUTING.md)

A comprehensive collection of hands-on Kubernetes projects designed to take you from beginner to advanced practitioner through real-world scenarios and practical implementations.

## 🎯 Quick Start

1. **Setup Environment**: Run `./scripts/setup-check.sh` (Linux/macOS) or `scripts\setup-check.bat` (Windows)
2. **Start Learning**: Begin with [Project 1: Hello Kubernetes](./01-beginner/01-hello-kubernetes/)
3. **Follow the Path**: Complete projects in order for the best learning experience
4. **Need Help?**: Check our [FAQ](./docs/FAQ.md) or [Contributing Guide](./CONTRIBUTING.md)

## 📚 Learning Path Overview

This repository contains **16 progressively challenging projects** that will teach you Kubernetes concepts through hands-on experience. Each project builds upon previous knowledge while introducing new concepts and best practices.

### 🎯 What You'll Learn

- **Container Orchestration**: Deploy, scale, and manage containerized applications
- **Service Discovery & Networking**: Implement service meshes and networking policies
- **Storage Management**: Handle persistent volumes and data management
- **Security**: Implement RBAC, network policies, and security best practices
- **Monitoring & Observability**: Set up comprehensive monitoring solutions
- **CI/CD Integration**: Build deployment pipelines with GitOps
- **Multi-cluster Management**: Handle complex enterprise scenarios

## 🗂️ Project Structure

> **Note**: This repository uses a [section-based numbering system](./docs/PROJECT_NUMBERING.md) that allows for easy expansion without renumbering existing projects.

### 🟢 **Beginner Level (Projects 01-06)**
Perfect for those new to Kubernetes or containerization.

| Project | Description | Key Concepts |
|---------|-------------|--------------|
| [01-Hello-Kubernetes](./01-beginner/01-hello-kubernetes/) | Deploy your first application | Pods, Deployments, Services |
| [02-Multi-Container-App](./01-beginner/02-multi-container-app/) | Full-stack web application | ConfigMaps, Secrets, Volumes |
| [03-Database-Integration](./01-beginner/03-database-integration/) | Persistent data storage | PersistentVolumes, StatefulSets |
| [04-Load-Balancing](./01-beginner/04-load-balancing/) | Traffic distribution and scaling | Ingress, HPA, Load Balancers |
| [05-Configuration-Management](./01-beginner/05-configuration-management/) | Environment-specific deployments | Helm, Kustomize, Namespaces |
| [06-Health-Probes](./01-beginner/06-health-probes/) | Application health monitoring | Liveness, Readiness, Startup Probes |

### 🟡 **Intermediate Level (Projects 11-15)**
For developers comfortable with basic Kubernetes concepts.

| Project | Description | Key Concepts |
|---------|-------------|--------------|
| [11-Microservices-Architecture](./02-intermediate/11-microservices-architecture/) | Deploy microservices ecosystem | Service Mesh, API Gateway |
| [12-CI-CD-Pipeline](./02-intermediate/12-cicd-pipeline/) | Automated deployment pipeline | GitOps, ArgoCD, Jenkins |
| [13-Monitoring-Logging](./02-intermediate/13-monitoring-logging/) | Comprehensive monitoring setup | Prometheus, Grafana, ELK Stack |
| [14-Security-RBAC](./02-intermediate/14-security-rbac/) | Implement security best practices | RBAC, Network Policies, PSP |
| [15-Disaster-Recovery](./02-intermediate/15-disaster-recovery/) | Backup and recovery strategies | Velero, Cluster Backup |

### 🔴 **Advanced Level (Projects 21-25)**
Enterprise-grade scenarios and complex architectures.

| Project | Description | Key Concepts |
|---------|-------------|--------------|
| [21-Multi-Cluster-Management](./03-advanced/21-multi-cluster-management/) | Manage multiple Kubernetes clusters | Cluster API, Multi-cluster Service Mesh |
| [22-Custom-Controllers](./03-advanced/22-custom-controllers/) | Build custom Kubernetes operators | CRDs, Controllers, Operators |
| [23-ML-Pipeline](./03-advanced/23-ml-pipeline/) | Machine learning workflow on K8s | Kubeflow, Model Serving, GPU Scheduling |
| [24-Edge-Computing](./03-advanced/24-edge-computing/) | Edge and IoT deployments | K3s, Edge Computing Patterns |
| [25-Enterprise-Platform](./03-advanced/25-enterprise-platform/) | Complete enterprise platform | Multi-tenancy, Cost Management, Governance |
| [26-Security-Hardening](./03-advanced/26-security-hardening/) | Comprehensive cluster security | Admission Controllers, Pod Security, Kyverno |

## 🛠️ Prerequisites

### Required Knowledge
- Basic understanding of containers (Docker)
- Command line proficiency
- Basic networking concepts
- YAML syntax familiarity

### Required Tools
- **Kubernetes Cluster**: minikube, kind, or cloud provider (EKS, GKE, AKS)
- **kubectl**: Kubernetes command-line tool
- **Docker**: Container runtime
- **Git**: Version control
- **Code Editor**: VS Code, Vim, or your preferred editor

### Optional Tools (introduced in projects)
- Helm
- Kustomize
- ArgoCD
- Prometheus & Grafana
- Istio
- And many more...

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ramishtaha/kubernetes-project-learning.git
   cd kubernetes-project-learning
   ```

2. **Set up your Kubernetes cluster**:
   - For local development: [minikube installation guide](./docs/setup/minikube.md)
   - For cloud providers:
     - [Amazon EKS](./docs/setup/eks.md)
     - [Google GKE](./docs/setup/gke.md)
     - [Azure AKS](./docs/setup/aks.md)
     - [DigitalOcean DOKS](./docs/setup/digitalocean.md)
     - [Vultr VKE](./docs/setup/vultr.md)
     - [Linode LKE](./docs/setup/linode.md)

3. **Verify your setup**:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

4. **Start with Project 1**:
   ```bash
   cd 01-beginner/01-hello-kubernetes/
   ```

## 📋 Project Guidelines

Each project follows a consistent structure:

```
project-name/
├── README.md              # Project overview and instructions
├── docs/                  # Detailed documentation
│   ├── architecture.md    # System architecture
│   ├── implementation.md  # Step-by-step guide
│   └── troubleshooting.md # Common issues and solutions
├── manifests/             # Kubernetes YAML files
├── src/                   # Application source code (if applicable)
├── scripts/               # Automation scripts
└── tests/                 # Validation and testing scripts
```

### 🎯 Learning Objectives
Each project clearly defines:
- **Learning Goals**: What you'll accomplish
- **Prerequisites**: Required knowledge from previous projects
- **Time Estimate**: Expected completion time
- **Difficulty**: Complexity rating
- **Real-world Context**: How this applies to production scenarios

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](./CONTRIBUTING.md) for details on:
- Adding new projects
- Improving existing content
- Reporting issues
- Suggesting enhancements

## 📖 Additional Resources

### Documentation
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Cloud Native Computing Foundation](https://www.cncf.io/)
- [Kubernetes Best Practices](./docs/best-practices/)

### Community
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [r/kubernetes](https://www.reddit.com/r/kubernetes/)
- [Stack Overflow - Kubernetes](https://stackoverflow.com/questions/tagged/kubernetes)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## ⭐ Acknowledgments

- Kubernetes community for excellent documentation
- Cloud Native Computing Foundation
- Contributors who make this resource better

---

**Ready to start your Kubernetes journey?** 🎉

Begin with [Project 1: Hello Kubernetes](./01-beginner/01-hello-kubernetes/) and work your way through the learning path. Each project builds upon the previous one, ensuring you develop a solid foundation while progressing to advanced topics.

**Questions or stuck?** Check the [FAQ](./docs/FAQ.md) or open an [issue](https://github.com/ramishtaha/kubernetes-project-learning/issues).
