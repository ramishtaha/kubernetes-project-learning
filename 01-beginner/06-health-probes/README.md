# Project 6: Managing Application Health 🏥

## 📚 Learning Objectives

By the end of this project, you will understand:
- The importance of health checks in Kubernetes applications
- The difference between liveness, readiness, and startup probes
- How to implement different probe mechanisms (HTTP, TCP, exec)
- Best practices for configuring health check parameters
- How to troubleshoot common health probe issues

## 🎯 Project Overview

This project demonstrates how to implement comprehensive health monitoring for applications running in Kubernetes. Health probes are essential for ensuring your applications are running correctly and can handle traffic appropriately.

### What We'll Build

- A web application deployment with all three types of probes
- Different probe mechanisms to showcase various health check strategies
- Monitoring and observing probe behavior

## 🔍 Understanding Health Probes

### Why Health Probes Matter

In production environments, applications can fail in various ways:
- **Process crashes**: The application stops running entirely
- **Deadlocks**: The application runs but becomes unresponsive
- **Resource exhaustion**: High memory/CPU usage causes performance issues
- **Dependencies failure**: Database or external service issues

Health probes help Kubernetes detect these issues and take appropriate action.

### Types of Health Probes

#### 1. **Liveness Probe** 💓
- **Purpose**: Determines if the application is running properly
- **Action**: Kubernetes restarts the container if the probe fails
- **Use Case**: Detect deadlocks, infinite loops, or corrupted application state
- **Example**: HTTP endpoint that checks core application functionality

#### 2. **Readiness Probe** 🚦
- **Purpose**: Determines if the application is ready to receive traffic
- **Action**: Kubernetes removes the pod from service endpoints if the probe fails
- **Use Case**: Application startup, dependency checks, temporary overload
- **Example**: Database connection check, external service availability

#### 3. **Startup Probe** 🚀
- **Purpose**: Determines if the application has started successfully
- **Action**: Disables liveness and readiness probes until startup succeeds
- **Use Case**: Slow-starting applications, initialization processes
- **Example**: Application bootstrap completion check

### Probe Mechanisms

#### HTTP GET (`httpGet`)
```yaml
httpGet:
  path: /health
  port: 8080
  httpHeaders:
  - name: Custom-Header
    value: Awesome
```

#### TCP Socket (`tcpSocket`)
```yaml
tcpSocket:
  port: 8080
```

#### Command Execution (`exec`)
```yaml
exec:
  command:
  - cat
  - /tmp/healthy
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│                 Service                     │
│          (health-app-service)               │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│              Deployment                     │
│            (health-app)                     │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │             Pod                     │   │
│  │                                     │   │
│  │  ┌─────────────────────────────┐   │   │
│  │  │        Container            │   │   │
│  │  │      (health-demo)          │   │   │
│  │  │                             │   │   │
│  │  │  • Startup Probe (exec)     │   │   │
│  │  │  • Liveness Probe (HTTP)    │   │   │
│  │  │  • Readiness Probe (TCP)    │   │   │
│  │  └─────────────────────────────┘   │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## 🚀 Getting Started

### Prerequisites
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- Basic understanding of Deployments and Services

### Quick Start

1. **Deploy the application**:
   ```bash
   cd 01-beginner/06-health-probes/
   ./scripts/deploy.sh
   ```

2. **Monitor the deployment**:
   ```bash
   kubectl get pods -n health-demo -w
   ```

3. **Check probe status**:
   ```bash
   kubectl describe pod <pod-name> -n health-demo
   ```

## 📋 Step-by-Step Implementation

### Step 1: Create the Namespace
```bash
kubectl create namespace health-demo
```

### Step 2: Deploy the Application
```bash
kubectl apply -f manifests/ -n health-demo
```

### Step 3: Monitor Pod Startup
Watch the pod startup process and observe how the probes behave:

```bash
# Watch pod status
kubectl get pods -n health-demo -w

# Check events for probe information
kubectl get events -n health-demo --sort-by='.lastTimestamp'
```

### Step 4: Test Probe Behavior

#### Test Startup Probe
The startup probe ensures the application initializes properly before other probes take effect.

#### Test Liveness Probe
Simulate an application failure:
```bash
# Get pod name
POD_NAME=$(kubectl get pods -n health-demo -l app=health-demo -o jsonpath='{.items[0].metadata.name}')

# Simulate failure by removing health file
kubectl exec -n health-demo $POD_NAME -- rm -f /tmp/healthy

# Watch Kubernetes restart the container
kubectl get pods -n health-demo -w
```

#### Test Readiness Probe
Simulate temporary unavailability:
```bash
# Make the application temporarily unready
kubectl exec -n health-demo $POD_NAME -- pkill -STOP nginx

# Check service endpoints
kubectl get endpoints -n health-demo

# Restore the application
kubectl exec -n health-demo $POD_NAME -- pkill -CONT nginx
```

### Step 5: Analyze Probe Configuration

#### View Current Configuration
```bash
kubectl get deployment health-demo -n health-demo -o yaml
```

#### Check Probe Status
```bash
kubectl describe pod $POD_NAME -n health-demo
```

Look for the probe status in the output:
- **Started**: Startup probe succeeded
- **Ready**: Readiness probe succeeded
- **Containers Ready**: All probes are healthy

## 📊 Monitoring and Observability

### Check Pod Events
```bash
kubectl describe pod $POD_NAME -n health-demo
```

### View Probe Metrics
```bash
# Check probe failure events
kubectl get events -n health-demo --field-selector reason=ProbeWarning

# Check restart count
kubectl get pods -n health-demo -o wide
```

### Debugging Commands
```bash
# Check container logs
kubectl logs $POD_NAME -n health-demo

# Execute into container
kubectl exec -it $POD_NAME -n health-demo -- /bin/bash

# Check process status
kubectl exec $POD_NAME -n health-demo -- ps aux
```

## 🔧 Configuration Best Practices

### Timing Parameters

#### Startup Probe
```yaml
startupProbe:
  initialDelaySeconds: 10    # Wait before first check
  periodSeconds: 10          # Check every 10 seconds
  timeoutSeconds: 5          # 5 seconds timeout
  failureThreshold: 30       # Allow 30 failures (5 minutes total)
  successThreshold: 1        # Only need 1 success
```

#### Liveness Probe
```yaml
livenessProbe:
  initialDelaySeconds: 30    # Wait after startup completes
  periodSeconds: 10          # Check every 10 seconds
  timeoutSeconds: 5          # 5 seconds timeout
  failureThreshold: 3        # 3 consecutive failures to restart
  successThreshold: 1        # Only need 1 success
```

#### Readiness Probe
```yaml
readinessProbe:
  initialDelaySeconds: 5     # Quick initial check
  periodSeconds: 5           # Frequent checks
  timeoutSeconds: 3          # Quick timeout
  failureThreshold: 3        # 3 failures to mark unready
  successThreshold: 1        # 1 success to mark ready
```

### Probe Selection Guidelines

| Probe Type | Use HTTP When | Use TCP When | Use Exec When |
|------------|---------------|--------------|---------------|
| **Startup** | App has HTTP health endpoint | Simple port check sufficient | Complex startup validation needed |
| **Liveness** | App can report internal health | Minimal overhead needed | Custom health logic required |
| **Readiness** | App can check dependencies | Basic connectivity test | Complex readiness logic |

## 🧪 Experiments and Learning

### Experiment 1: Probe Timing
Modify probe timings and observe behavior:

1. Set aggressive timing (fast checks)
2. Set conservative timing (slow checks)
3. Compare restart behavior and resource usage

### Experiment 2: Probe Failures
Intentionally cause probe failures:

1. Block the health endpoint
2. Stop the application process
3. Consume all available memory

### Experiment 3: Different Mechanisms
Try different probe mechanisms:

1. Change HTTP probe to TCP probe
2. Implement custom exec probe
3. Compare effectiveness and overhead

## 🎯 Key Takeaways

### Essential Concepts
1. **Startup probes** prevent premature liveness/readiness checks
2. **Liveness probes** detect and recover from application failures
3. **Readiness probes** manage traffic routing to healthy instances
4. **Different mechanisms** serve different use cases and performance requirements

### Best Practices
1. **Always implement** all three probe types for production applications
2. **Choose appropriate timings** based on application characteristics
3. **Use lightweight checks** to minimize overhead
4. **Test probe behavior** in development and staging environments
5. **Monitor probe metrics** in production

### Production Considerations
1. **Probe overhead**: Frequent checks consume resources
2. **False positives**: Overly sensitive probes cause unnecessary restarts
3. **False negatives**: Insensitive probes miss real issues
4. **Dependencies**: Consider external service availability
5. **Graceful degradation**: Design probes for partial functionality

## 🔍 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Pod Stuck in "ContainerCreating"
**Symptoms**: Pod never becomes ready, stuck in creation phase
**Causes**:
- Image pull issues
- Insufficient resources
- Storage mounting problems

**Solutions**:
```bash
# Check pod events
kubectl describe pod $POD_NAME -n health-demo

# Check resource quotas
kubectl describe resourcequota -n health-demo

# Check node resources
kubectl top nodes
```

#### Issue 2: Pod Continuously Restarting
**Symptoms**: High restart count, CrashLoopBackOff status
**Causes**:
- Liveness probe failing too quickly
- Application startup time exceeds probe timeout
- Resource constraints

**Solutions**:
```bash
# Check restart count
kubectl get pods -n health-demo

# Check probe configuration
kubectl describe pod $POD_NAME -n health-demo

# Adjust probe timing
kubectl patch deployment health-demo -n health-demo -p '{"spec":{"template":{"spec":{"containers":[{"name":"health-demo","livenessProbe":{"initialDelaySeconds":60}}]}}}}'
```

#### Issue 3: Pod Not Receiving Traffic
**Symptoms**: Service exists but no traffic reaches the pod
**Causes**:
- Readiness probe failing
- Service selector mismatch
- Network policies blocking traffic

**Solutions**:
```bash
# Check service endpoints
kubectl get endpoints -n health-demo

# Check readiness probe status
kubectl describe pod $POD_NAME -n health-demo

# Test direct pod access
kubectl port-forward $POD_NAME 8080:80 -n health-demo
```

#### Issue 4: Startup Probe Never Succeeds
**Symptoms**: Pod stuck in "Running" but not ready
**Causes**:
- Startup probe too restrictive
- Application takes longer to start than expected
- Incorrect probe configuration

**Solutions**:
```bash
# Check startup probe logs
kubectl describe pod $POD_NAME -n health-demo

# Increase failure threshold
kubectl patch deployment health-demo -n health-demo -p '{"spec":{"template":{"spec":{"containers":[{"name":"health-demo","startupProbe":{"failureThreshold":60}}]}}}}'

# Test probe manually
kubectl exec $POD_NAME -n health-demo -- curl -f http://localhost:80/health
```

#### Issue 5: False Positive Probe Failures
**Symptoms**: Healthy application being restarted unnecessarily
**Causes**:
- Network latency
- Temporary resource spikes
- Overly aggressive probe timing

**Solutions**:
```bash
# Increase timeout and failure threshold
kubectl patch deployment health-demo -n health-demo -p '{"spec":{"template":{"spec":{"containers":[{"name":"health-demo","livenessProbe":{"timeoutSeconds":10,"failureThreshold":5}}]}}}}'

# Monitor resource usage
kubectl top pods -n health-demo

# Check probe endpoint performance
kubectl exec $POD_NAME -n health-demo -- time curl http://localhost:80/health
```

### Debugging Commands Reference

```bash
# Pod status and events
kubectl get pods -n health-demo -o wide
kubectl describe pod $POD_NAME -n health-demo
kubectl get events -n health-demo --sort-by='.lastTimestamp'

# Probe testing
kubectl exec $POD_NAME -n health-demo -- curl -f http://localhost:80/health
kubectl exec $POD_NAME -n health-demo -- netstat -tuln
kubectl exec $POD_NAME -n health-demo -- ps aux

# Resource monitoring
kubectl top pods -n health-demo
kubectl describe nodes

# Configuration inspection
kubectl get deployment health-demo -n health-demo -o yaml
kubectl get service health-app-service -n health-demo -o yaml
```

## 🧹 Cleanup

To clean up all resources created in this project:

```bash
./scripts/cleanup.sh
```

Or manually:
```bash
kubectl delete namespace health-demo
```

## 📚 Next Steps

After completing this project, you should:

1. **Move to Project 7**: Advanced configuration management techniques
2. **Explore further**: 
   - Custom health check endpoints
   - Prometheus metrics for probe monitoring
   - Advanced probe configurations
3. **Practice**: Implement health probes in your own applications

## 🔗 Additional Resources

- [Kubernetes Probes Documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Health Check Best Practices](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)
- [Monitoring Application Health](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/)
- [Troubleshooting Applications](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application-introspection/)

---

**🎉 Congratulations!** You've successfully learned how to implement and manage application health probes in Kubernetes. This knowledge is crucial for building resilient, production-ready applications.
