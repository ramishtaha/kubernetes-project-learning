# Project 2: Multi-Container Application 🐳

**Difficulty**: 🟢 Beginner  
**Time Estimate**: 60-90 minutes  
**Prerequisites**: Project 1 completed  

## 🎯 Learning Objectives

By the end of this project, you will:
- Deploy applications with multiple containers in a single Pod
- Use ConfigMaps for configuration management
- Implement Secrets for sensitive data
- Work with Volumes for data sharing between containers
- Understand sidecar pattern and init containers

## 📋 Project Overview

You'll deploy a full-stack web application consisting of:
- **Frontend**: React application serving the UI
- **Backend**: Node.js API server
- **Sidecar**: Nginx proxy for request routing
- **Init Container**: Database schema initialization

### What We'll Build
- A multi-tier web application with frontend and backend
- Shared configuration using ConfigMaps
- Secure credentials management with Secrets
- Inter-container communication within a Pod
- Data persistence with Volumes

## 🏗️ Architecture

```
Internet → Service → Pod [Nginx Proxy → Frontend (React) + Backend (Node.js)]
                         ↓
                      ConfigMap (App Config)
                         ↓
                      Secret (DB Credentials)
```

## 🚀 Implementation Steps

### Step 1: Create ConfigMaps for Application Configuration

ConfigMaps store non-sensitive configuration data:

```bash
kubectl apply -f manifests/01-configmap.yaml
```

Verify the ConfigMap:
```bash
kubectl get configmaps
kubectl describe configmap app-config
```

### Step 2: Create Secrets for Sensitive Data

Secrets store sensitive information like passwords and API keys:

```bash
kubectl apply -f manifests/02-secret.yaml
```

View the Secret (data will be base64 encoded):
```bash
kubectl get secrets
kubectl describe secret app-secrets
```

### Step 3: Deploy the Multi-Container Application

Deploy the Pod with multiple containers:

```bash
kubectl apply -f manifests/03-multi-container-pod.yaml
```

Check the Pod status:
```bash
kubectl get pods
kubectl describe pod webapp-pod
```

### Step 4: Create a Service to Expose the Application

```bash
kubectl apply -f manifests/04-service.yaml
```

### Step 5: Deploy Using a Deployment for Better Management

```bash
kubectl apply -f manifests/05-deployment.yaml
```

### Step 6: Access Your Application

Get the application URL:
```bash
minikube service webapp-service --url
```

## 🔍 Understanding Multi-Container Patterns

### Sidecar Pattern
- **Purpose**: Enhance or extend the main container's functionality
- **Example**: Logging agent, monitoring agent, proxy
- **Communication**: Shared network and storage

### Init Containers
- **Purpose**: Run to completion before app containers start
- **Use Cases**: Database migration, configuration setup, dependency waiting
- **Lifecycle**: Must complete successfully for Pod to start

### Ambassador Pattern
- **Purpose**: Proxy connections to external services
- **Benefits**: Service discovery, load balancing, retry logic

## 🧪 Experiments to Try

### Experiment 1: Examine Container Logs
```bash
# View logs from specific container
kubectl logs webapp-pod -c frontend
kubectl logs webapp-pod -c backend
kubectl logs webapp-pod -c nginx-proxy

# Follow logs in real-time
kubectl logs -f webapp-pod -c backend
```

### Experiment 2: Execute Commands in Containers
```bash
# Access the frontend container
kubectl exec -it webapp-pod -c frontend -- /bin/sh

# Check Nginx configuration
kubectl exec -it webapp-pod -c nginx-proxy -- cat /etc/nginx/nginx.conf

# View environment variables
kubectl exec -it webapp-pod -c backend -- env
```

### Experiment 3: Test ConfigMap and Secret Updates
```bash
# Update ConfigMap
kubectl patch configmap app-config -p '{"data":{"API_URL":"http://new-api.example.com"}}'

# Restart Pod to pick up changes
kubectl delete pod webapp-pod
# If using Deployment, it will recreate automatically
```

### Experiment 4: Volume Sharing Between Containers
```bash
# Check shared volume content
kubectl exec -it webapp-pod -c frontend -- ls -la /shared-data
kubectl exec -it webapp-pod -c backend -- ls -la /shared-data

# Create a file in one container and verify in another
kubectl exec -it webapp-pod -c frontend -- touch /shared-data/test-file
kubectl exec -it webapp-pod -c backend -- ls -la /shared-data/test-file
```

## 🔧 Configuration Management Deep Dive

### ConfigMaps
```yaml
# Environment Variables
env:
- name: API_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: api_url

# Volume Mounts
volumes:
- name: config-volume
  configMap:
    name: app-config
```

### Secrets
```yaml
# Environment Variables
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secrets
      key: db_password

# Volume Mounts
volumes:
- name: secret-volume
  secret:
    secretName: app-secrets
```

## 🐛 Troubleshooting

### Pod Stuck in Init State
```bash
kubectl describe pod webapp-pod
kubectl logs webapp-pod -c init-container
```

### Container Communication Issues
```bash
# Check container processes
kubectl exec -it webapp-pod -c nginx-proxy -- ps aux

# Test network connectivity
kubectl exec -it webapp-pod -c nginx-proxy -- wget -qO- localhost:3000
```

### Configuration Not Loading
```bash
# Verify ConfigMap mounting
kubectl exec -it webapp-pod -c backend -- cat /etc/config/app.properties

# Check environment variables
kubectl exec -it webapp-pod -c backend -- printenv | grep API
```

## 🔐 Security Best Practices

### 1. Use Secrets for Sensitive Data
```yaml
# ❌ Don't do this
env:
- name: DB_PASSWORD
  value: "plaintext-password"

# ✅ Do this instead
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secrets
      key: db_password
```

### 2. Set Resource Limits
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

### 3. Use Non-Root Users
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
```

## 🧹 Cleanup

Remove all resources:
```bash
kubectl delete -f manifests/
```

## 🎯 Key Takeaways

1. **Multi-container Pods** enable complex application patterns
2. **ConfigMaps** store non-sensitive configuration data
3. **Secrets** provide secure storage for sensitive information
4. **Volumes** enable data sharing between containers
5. **Init containers** handle setup tasks before main containers start
6. **Sidecar pattern** extends functionality without modifying main containers

## 📚 Next Steps

Ready for Project 3? Proceed to [Database Integration](../03-database-integration/) where you'll learn:
- StatefulSets for stateful applications
- PersistentVolumes for data persistence
- Database deployment and management
- Data backup and recovery strategies

## 📖 Additional Reading

- [Multi-container Pod Patterns](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns/)
- [ConfigMaps Documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

---

**Excellent work!** 🎉 You've mastered multi-container applications and configuration management. These patterns form the foundation of complex Kubernetes applications.
