# Project 1: Hello Kubernetes 👋

**Difficulty**: 🟢 Beginner  
**Time Estimate**: 30-45 minutes  
**Prerequisites**: Basic Docker knowledge  

## 🎯 Learning Objectives

By the end of this project, you will:
- Understand Kubernetes basic concepts: Pods, Deployments, and Services
- Deploy your first application on Kubernetes
- Learn to interact with your cluster using `kubectl`
- Understand the relationship between containers, pods, and deployments

## 📋 Project Overview

You'll deploy a simple "Hello World" web application to Kubernetes and expose it to external traffic. This project introduces the fundamental building blocks of Kubernetes applications.

### What We'll Build
- A simple web application running in a Pod
- A Deployment to manage the Pod lifecycle
- A Service to expose the application
- Understanding of basic Kubernetes networking

## 🏗️ Architecture

```
Internet → NodePort Service → Pod (Hello App Container)
```

## 🚀 Implementation Steps

### Step 1: Verify Your Cluster

First, ensure your Kubernetes cluster is running:

```bash
kubectl cluster-info
kubectl get nodes
```

Expected output:
```
Kubernetes control plane is running at https://...
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1d    v1.28.3
```

### Step 2: Create Your First Pod

Create a Pod that runs a simple web server:

```bash
kubectl apply -f manifests/01-pod.yaml
```

Check if the Pod is running:
```bash
kubectl get pods
kubectl describe pod hello-pod
```

### Step 3: Create a Deployment

While Pods are the basic unit, Deployments provide better management:

```bash
kubectl apply -f manifests/02-deployment.yaml
```

Verify the Deployment:
```bash
kubectl get deployments
kubectl get pods -l app=hello-kubernetes
```

### Step 4: Expose with a Service

Create a Service to make your application accessible:

```bash
kubectl apply -f manifests/03-service.yaml
```

Check the Service:
```bash
kubectl get services
```

### Step 5: Access Your Application

Get the URL to access your application:

**For Minikube:**
```bash
minikube service hello-service --url
```

**For other clusters:**
```bash
kubectl get service hello-service
# Note the NodePort and access via <node-ip>:<nodeport>
```

Visit the URL in your browser - you should see "Hello, Kubernetes!"

## 🔍 Understanding What Happened

### Pods
- **What**: Smallest deployable unit in Kubernetes
- **Contains**: One or more containers that share storage and network
- **Lifecycle**: Created, running, terminated (ephemeral)

### Deployments
- **What**: Manages a set of identical Pods
- **Benefits**: Scaling, rolling updates, rollbacks
- **Declarative**: You describe desired state, Kubernetes maintains it

### Services
- **What**: Stable network endpoint for Pods
- **Types**: ClusterIP, NodePort, LoadBalancer
- **Purpose**: Pods are ephemeral, Services provide consistent access

## 🧪 Experiments to Try

### Experiment 1: Scale Your Application
```bash
kubectl scale deployment hello-deployment --replicas=3
kubectl get pods -l app=hello-kubernetes
```

### Experiment 2: Update Your Application
```bash
kubectl set image deployment/hello-deployment hello-container=nginx:1.21
kubectl rollout status deployment/hello-deployment
```

### Experiment 3: View Application Logs
```bash
kubectl logs -l app=hello-kubernetes
kubectl logs -f deployment/hello-deployment
```

### Experiment 4: Delete and Recreate
```bash
kubectl delete pod <pod-name>
kubectl get pods -l app=hello-kubernetes
# Notice how Deployment creates a new Pod automatically
```

## 🐛 Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Service Not Accessible
```bash
kubectl get endpoints hello-service
kubectl describe service hello-service
```

### Common Issues
1. **ImagePullBackOff**: Check if the Docker image exists and is accessible
2. **Pending Pod**: Check node resources with `kubectl describe nodes`
3. **Service not found**: Verify Service selector matches Pod labels

## 🧹 Cleanup

Remove all resources created in this project:

```bash
kubectl delete -f manifests/
# Or individually:
# kubectl delete service hello-service
# kubectl delete deployment hello-deployment
# kubectl delete pod hello-pod
```

## 🎯 Key Takeaways

1. **Pods** are the basic unit but rarely created directly
2. **Deployments** provide Pod management and scaling capabilities
3. **Services** provide stable networking for your applications
4. **Labels and Selectors** are crucial for connecting resources
5. **kubectl** is your primary tool for interacting with Kubernetes

## 📚 Next Steps

Ready for the next challenge? Proceed to [Project 2: Multi-Container Application](../02-multi-container-app/) where you'll:
- Work with multiple containers in a single Pod
- Learn about ConfigMaps and Secrets
- Implement a full-stack application with a database

## 📖 Additional Reading

- [Kubernetes Pods Documentation](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Congratulations!** 🎉 You've successfully deployed your first application to Kubernetes. You now understand the fundamental building blocks that make up all Kubernetes applications.
