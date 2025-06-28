# 📊 Project 04: Load Balancing and Scaling

**Difficulty**: 🟢 Beginner  
**Time Estimate**: 90-120 minutes  
**Prerequisites**: Projects 01-03 completed, basic networking concepts  

## 📋 Overview

Build a scalable web application with automatic load balancing and scaling! This project introduces Ingress controllers, Horizontal Pod Autoscaling, and advanced service patterns. You'll learn how to handle traffic distribution and automatically scale applications based on demand.

## 🎯 Learning Objectives

By the end of this project, you will:
- Implement Ingress controllers for external traffic routing
- Configure Horizontal Pod Autoscaling (HPA) for automatic scaling
- Set up load balancing with multiple deployment strategies
- Understand different service types and their use cases
- Implement health checks and readiness probes
- Monitor application performance under load
- Learn traffic routing and SSL termination

### What We'll Build
- A scalable web application with multiple replicas
- Ingress routing with SSL termination
- Automatic scaling based on resource usage
- Load testing to demonstrate scaling behavior
- Performance monitoring and alerting

## 🏗️ Architecture

```
Internet → Ingress Controller → Service (Load Balancer) → Pods [1-10]
                ↓                           ↓
           SSL Certificate              Metrics Server
                                            ↓
                                   Horizontal Pod Autoscaler
```

## 🚀 Implementation Steps

### Step 1: Enable Ingress and Metrics

Enable required addons in minikube:

```bash
minikube addons enable ingress
minikube addons enable metrics-server
```

For other clusters, install NGINX Ingress:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### Step 2: Deploy the Application

Deploy a sample CPU-intensive application:

```bash
kubectl apply -f manifests/01-application.yaml
```

### Step 3: Create Service and Ingress

Set up service and ingress for external access:

```bash
kubectl apply -f manifests/02-service-ingress.yaml
```

### Step 4: Configure Horizontal Pod Autoscaler

Set up automatic scaling:

```bash
kubectl apply -f manifests/03-hpa.yaml
```

### Step 5: Deploy Load Testing Tools

Deploy tools to generate traffic:

```bash
kubectl apply -f manifests/04-load-test.yaml
```

### Step 6: Monitor and Test Scaling

Watch the scaling in action:

```bash
# Watch HPA status
kubectl get hpa -w

# Watch pod scaling
kubectl get pods -w

# Check resource usage
kubectl top pods
kubectl top nodes
```

## 🔍 Understanding Load Balancing

### Service Types

#### 1. ClusterIP (Default)
```yaml
apiVersion: v1
kind: Service
spec:
  type: ClusterIP  # Internal access only
  ports:
  - port: 80
    targetPort: 8080
```

#### 2. NodePort
```yaml
apiVersion: v1
kind: Service
spec:
  type: NodePort  # External access via node IP
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

#### 3. LoadBalancer
```yaml
apiVersion: v1
kind: Service
spec:
  type: LoadBalancer  # Cloud provider load balancer
  ports:
  - port: 80
    targetPort: 8080
```

#### 4. ExternalName
```yaml
apiVersion: v1
kind: Service
spec:
  type: ExternalName  # DNS alias
  externalName: external-service.example.com
```

### Ingress Patterns

#### Host-based Routing
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
spec:
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

#### Path-based Routing
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
spec:
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

## 🧪 Experiments to Try

### Experiment 1: Basic Load Testing
```bash
# Start load test
kubectl apply -f manifests/04-load-test.yaml

# Watch scaling happen
kubectl get hpa -w

# Check pod count
kubectl get pods | grep web-app
```

### Experiment 2: Different Scaling Metrics
```bash
# Scale based on memory usage
kubectl apply -f manifests/05-memory-hpa.yaml

# Scale based on custom metrics
kubectl apply -f manifests/06-custom-metrics-hpa.yaml
```

### Experiment 3: Test Ingress Routing
```bash
# Get ingress IP
kubectl get ingress

# Test different paths
curl http://<ingress-ip>/api/health
curl http://<ingress-ip>/api/stress
curl http://<ingress-ip>/api/memory
```

### Experiment 4: SSL Termination
```bash
# Create TLS secret
kubectl create secret tls web-app-tls \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem

# Apply HTTPS ingress
kubectl apply -f manifests/07-https-ingress.yaml

# Test HTTPS access
curl -k https://<ingress-ip>/
```

### Experiment 5: Advanced Load Balancing
```bash
# Test session affinity
kubectl apply -f manifests/08-session-affinity.yaml

# Test weighted routing
kubectl apply -f manifests/09-weighted-routing.yaml
```

## 📊 Horizontal Pod Autoscaling (HPA)

### CPU-based Scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Memory-based Scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-memory-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Custom Metrics Scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-custom-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
```

## 🎛️ Advanced Load Balancing Features

### Session Affinity
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-sticky
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
```

### Traffic Splitting
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-canary
            port:
              number: 80
```

### Rate Limiting
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limited-ingress
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app
            port:
              number: 80
```

## 🔧 Performance Tuning

### Resource Requests and Limits
```yaml
spec:
  containers:
  - name: web-app
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
```

### Health Checks
```yaml
spec:
  containers:
  - name: web-app
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      failureThreshold: 3
```

### Pod Disruption Budget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web-app
```

## 🐛 Troubleshooting

### HPA Not Scaling
```bash
# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Check HPA status
kubectl describe hpa web-app-hpa

# Check resource metrics
kubectl top pods
kubectl top nodes
```

### Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl describe ingress web-app-ingress

# Check service endpoints
kubectl get endpoints web-app-service
```

### Load Balancing Issues
```bash
# Check service configuration
kubectl describe service web-app-service

# Test direct pod access
kubectl port-forward pod/<pod-name> 8080:8080

# Check pod readiness
kubectl get pods -o wide
```

## 📈 Monitoring and Observability

### Key Metrics to Monitor
- **Request Rate**: Requests per second
- **Response Time**: Average and percentile latencies
- **Error Rate**: Percentage of failed requests
- **Resource Usage**: CPU and memory utilization
- **Pod Count**: Number of running replicas

### Useful Commands
```bash
# Watch HPA scaling
watch kubectl get hpa

# Monitor resource usage
watch kubectl top pods

# Check pod events
kubectl get events --sort-by=.metadata.creationTimestamp

# Load test results
kubectl logs -f job/load-test
```

## 🧹 Cleanup

Remove all resources:
```bash
kubectl delete -f manifests/
minikube addons disable ingress
minikube addons disable metrics-server
```

## 🎯 Key Takeaways

1. **Ingress Controllers** provide advanced routing and SSL termination
2. **HPA** automatically scales applications based on resource usage
3. **Service Types** determine how applications are exposed
4. **Health Checks** ensure only healthy pods receive traffic
5. **Load Testing** is essential for validating scaling behavior
6. **Resource Limits** prevent resource starvation and enable proper scaling
7. **Performance Monitoring** helps optimize scaling thresholds

## 📚 Next Steps

Ready for Project 5? Proceed to [Configuration Management](../05-configuration-management/) where you'll learn:
- Helm package management
- Kustomize for environment-specific configurations
- Namespace organization and multi-tenancy
- Advanced configuration patterns

## 📖 Additional Reading

- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Pod Disruption Budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)

---

**Excellent progress!** 🎉 You now understand how to scale and load balance applications in Kubernetes. These skills are crucial for building resilient, high-performance applications.
