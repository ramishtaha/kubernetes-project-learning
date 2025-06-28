# Frequently Asked Questions (FAQ)

## 🎯 General Questions

### Q: What is the recommended learning path?
**A:** Start with the beginner projects (1-5) in order, then move to intermediate (6-10), and finally advanced (11-15). Each project builds upon concepts from previous ones.

### Q: How much time should I allocate for each project?
**A:** 
- **Beginner**: 30-120 minutes per project
- **Intermediate**: 1-4 hours per project  
- **Advanced**: 4+ hours per project

Plan for additional time if you want to experiment or if you encounter issues.

### Q: Do I need a cloud provider account?
**A:** No! All projects can be completed using local tools like minikube or kind. Cloud provider examples are included as optional advanced scenarios.

## 🛠️ Setup and Installation

### Q: Which Kubernetes distribution should I use?
**A:** For learning:
- **minikube**: Best for beginners, easy setup
- **kind**: Good for CI/CD and advanced users
- **Docker Desktop**: Convenient if you already use it
- **Cloud providers**: For production-like environments

### Q: My cluster won't start. What should I do?
**A:** Common solutions:
```bash
# For minikube
minikube delete
minikube start --driver=docker

# Check available resources
minikube status
kubectl cluster-info
```

### Q: How do I know if my cluster is ready?
**A:** Run these commands:
```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```
All should return without errors.

### Q: Can I use Windows for these projects?
**A:** Yes! All projects include Windows-compatible scripts and instructions. Use PowerShell or Command Prompt as indicated.

## 🐳 Container and Image Issues

### Q: I'm getting "ImagePullBackOff" errors. What's wrong?
**A:** This usually means:
1. **Image doesn't exist**: Check the image name and tag
2. **Network issues**: Verify internet connectivity
3. **Registry authentication**: For private registries, check credentials

```bash
# Debug the issue
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Q: Can I use my own container images?
**A:** Absolutely! Replace the image references in the manifests with your own. Make sure your images are:
- Publicly accessible, or
- Your cluster can access your private registry

### Q: How do I build and use local images?
**A:** For minikube:
```bash
# Set Docker environment to minikube
eval $(minikube docker-env)

# Build your image
docker build -t my-app:latest .

# Use imagePullPolicy: Never in manifests
```

## 🔧 Troubleshooting Common Issues

### Q: Pods are stuck in "Pending" state. Why?
**A:** Usually resource constraints:
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Check pod events
kubectl describe pod <pod-name>
```

### Q: Services are not accessible. How do I fix this?
**A:** Check these items:
1. **Service selector matches pod labels**
2. **Correct ports are exposed**
3. **Pod is running and ready**

```bash
# Debug service connectivity
kubectl get endpoints <service-name>
kubectl describe service <service-name>
```

### Q: How do I access applications in minikube?
**A:** Use minikube service command:
```bash
# Get URL
minikube service <service-name> --url

# Open in browser
minikube service <service-name>
```

### Q: Persistent volumes aren't working. What's wrong?
**A:** Check:
1. **Storage class exists**: `kubectl get storageclass`
2. **PVC is bound**: `kubectl get pvc`
3. **Node has sufficient storage**: `kubectl describe nodes`

## 📚 Learning and Concepts

### Q: I don't understand a concept. Where can I learn more?
**A:** Each project includes links to official documentation. Also check:
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
- [CNCF Landscape](https://landscape.cncf.io/)

### Q: Should I memorize all the kubectl commands?
**A:** No! Focus on understanding concepts. Use:
```bash
# Get help
kubectl --help
kubectl <command> --help

# Use aliases and autocomplete
alias k=kubectl
source <(kubectl completion bash)
```

### Q: What's the difference between Deployment and StatefulSet?
**A:** 
- **Deployment**: For stateless applications, pods are interchangeable
- **StatefulSet**: For stateful applications, each pod has a unique identity
- See Project 3 for detailed comparison

### Q: When should I use ConfigMaps vs Secrets?
**A:**
- **ConfigMaps**: Non-sensitive configuration data
- **Secrets**: Passwords, tokens, keys, certificates
- Both can be mounted as files or environment variables

## 🔐 Security Questions

### Q: Are these projects production-ready?
**A:** No, they're designed for learning. For production:
- Use proper RBAC
- Implement network policies
- Use private registries
- Enable admission controllers
- Follow security best practices

### Q: How do I handle sensitive data properly?
**A:** 
1. **Never commit secrets to Git**
2. **Use Kubernetes Secrets**
3. **Consider external secret management**
4. **Enable encryption at rest**

```bash
# Create secret from command line
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123
```

## 🚀 Advanced Topics

### Q: How do I deploy to a real cluster?
**A:** 
1. **Get cluster credentials** from your cloud provider
2. **Update kubeconfig**: `kubectl config use-context <context-name>`
3. **Modify manifests** for production settings
4. **Use proper resource limits and requests**

### Q: Can I use Helm instead of raw manifests?
**A:** Yes! Projects 5+ introduce Helm. You can also convert earlier projects to Helm charts as an exercise.

### Q: How do I monitor my applications?
**A:** Project 8 covers monitoring with Prometheus and Grafana. For basic monitoring:
```bash
# Built-in metrics
kubectl top pods
kubectl top nodes

# Pod logs
kubectl logs <pod-name> -f
```

### Q: What about CI/CD integration?
**A:** Project 7 covers GitOps with ArgoCD. General principles:
1. **Store manifests in Git**
2. **Use automated testing**
3. **Implement proper deployment strategies**
4. **Monitor deployment health**

## 🌐 Multi-Environment Setup

### Q: How do I manage different environments (dev/staging/prod)?
**A:** Several approaches:
- **Namespaces**: Separate resources within same cluster
- **Clusters**: Separate clusters per environment
- **Kustomize**: Environment-specific configurations
- **Helm**: Values files per environment

### Q: Can I run multiple projects simultaneously?
**A:** Yes, but use different namespaces:
```bash
# Create namespace
kubectl create namespace project-2

# Deploy to specific namespace
kubectl apply -f manifests/ -n project-2
```

## 💡 Best Practices

### Q: What are the most important Kubernetes best practices?
**A:**
1. **Always set resource requests and limits**
2. **Use health checks (liveness/readiness probes)**
3. **Don't run as root user**
4. **Use specific image tags, not 'latest'**
5. **Implement proper logging and monitoring**

### Q: How do I organize my Kubernetes manifests?
**A:** 
- **By resource type**: deployments/, services/, configmaps/
- **By application**: app1/, app2/, shared/
- **By environment**: base/, overlays/dev/, overlays/prod/

### Q: Should I use YAML or JSON for manifests?
**A:** YAML is preferred because:
- More human-readable
- Supports comments
- Less verbose
- Standard in Kubernetes community

## 🆘 Getting Help

### Q: I'm stuck and can't figure out what's wrong. What should I do?
**A:** 
1. **Check the troubleshooting section** of the specific project
2. **Look at pod events**: `kubectl describe pod <pod-name>`
3. **Check logs**: `kubectl logs <pod-name>`
4. **Open an issue** on the GitHub repository with:
   - Your environment details
   - Steps to reproduce
   - Error messages
   - Relevant logs

### Q: Where can I ask questions about Kubernetes in general?
**A:**
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/kubernetes)
- [Reddit r/kubernetes](https://www.reddit.com/r/kubernetes/)
- [CNCF Community](https://www.cncf.io/community/)

### Q: How do I stay updated with Kubernetes changes?
**A:**
- [Kubernetes Blog](https://kubernetes.io/blog/)
- [CNCF Newsletter](https://www.cncf.io/newsletter/)
- [Kubernetes Release Notes](https://github.com/kubernetes/kubernetes/releases)
- Follow [@kubernetesio](https://twitter.com/kubernetesio) on Twitter

---

**Still have questions?** Feel free to [open an issue](https://github.com/ramishtaha/kubernetes-project-learning/issues) and we'll help you out!
