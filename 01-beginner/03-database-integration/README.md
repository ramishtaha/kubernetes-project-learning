# 🗄️ Project 03: Database Integration

**Difficulty**: 🟢 Beginner  
**Time Estimate**: 90-120 minutes  
**Prerequisites**: Projects 01-02 completed, basic SQL knowledge  

## 📋 Overview

Deploy a complete application stack with persistent data storage! This project introduces stateful applications, persistent storage, and database integration patterns in Kubernetes. You'll learn how to deploy databases, manage persistent data, and connect applications to stateful services.

## 🎯 Learning Objectives

By the end of this project, you will:
- Deploy stateful applications using StatefulSets
- Implement persistent data storage with PersistentVolumes
- Connect applications to databases running in Kubernetes
- Understand storage classes and dynamic provisioning
- Implement database initialization and migration strategies
- Handle data backup and recovery scenarios
- Learn database security and access patterns

### What We'll Build
- A full-stack todo application with persistent data
- PostgreSQL database with persistent volumes
- API server with database connections
- Database initialization and seeding
- Backup and recovery mechanisms

## 🏗️ Architecture

```
Frontend (React) → Backend API (Node.js) → PostgreSQL Database
                                              ↓
                                         PersistentVolume
                                              ↓
                                         Storage Class
```

## 🚀 Implementation Steps

### Step 1: Create Storage Class and PersistentVolume

First, set up storage for the database:

```bash
kubectl apply -f manifests/01-storage.yaml
```

### Step 2: Deploy PostgreSQL Database

Deploy PostgreSQL using a StatefulSet:

```bash
kubectl apply -f manifests/02-database.yaml
```

Monitor the StatefulSet deployment:
```bash
kubectl get statefulsets
kubectl get pods -l app=postgres
kubectl get pvc
```

### Step 3: Initialize Database Schema

Run a Kubernetes Job to set up the database schema:

```bash
kubectl apply -f manifests/03-db-init-job.yaml
```

Check the job status:
```bash
kubectl get jobs
kubectl logs job/db-init-job
```

### Step 4: Deploy the Backend API

Deploy the Node.js API that connects to PostgreSQL:

```bash
kubectl apply -f manifests/04-backend.yaml
```

### Step 5: Deploy the Frontend Application

Deploy the React frontend:

```bash
kubectl apply -f manifests/05-frontend.yaml
```

### Step 6: Create Services to Connect Everything

```bash
kubectl apply -f manifests/06-services.yaml
```

### Step 7: Access Your Application

Get the frontend URL:
```bash
minikube service frontend-service --url
```

## 🔍 Understanding StatefulSets vs Deployments

### StatefulSets
- **Ordered deployment**: Pods are created/deleted in order
- **Stable network identity**: Each Pod gets a persistent hostname
- **Persistent storage**: Each Pod gets its own PersistentVolume
- **Use cases**: Databases, distributed systems, stateful applications

### Deployments
- **Parallel deployment**: Pods can be created simultaneously
- **Interchangeable Pods**: Any Pod can handle any request
- **Shared storage**: All Pods can share the same volume
- **Use cases**: Stateless applications, web servers, APIs

## 🗄️ Persistent Volumes Deep Dive

### Storage Classes
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
```

### PersistentVolumeClaims
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 10Gi
```

## 🧪 Experiments to Try

### Experiment 1: Test Data Persistence
```bash
# Add some data to the database
kubectl exec -it postgres-0 -- psql -U postgres -d todoapp -c "INSERT INTO todos (title, completed) VALUES ('Test persistence', false);"

# Delete the Pod
kubectl delete pod postgres-0

# Wait for StatefulSet to recreate the Pod
kubectl get pods -l app=postgres -w

# Check if data is still there
kubectl exec -it postgres-0 -- psql -U postgres -d todoapp -c "SELECT * FROM todos;"
```

### Experiment 2: Scale the StatefulSet
```bash
# Scale to 3 replicas (creating a cluster)
kubectl scale statefulset postgres --replicas=3

# Watch the ordered creation
kubectl get pods -l app=postgres -w

# Each Pod gets its own storage
kubectl get pvc
```

### Experiment 3: Database Backup and Restore
```bash
# Create a backup job
kubectl apply -f manifests/07-backup-job.yaml

# Check backup status
kubectl get jobs
kubectl logs job/db-backup-job

# List backups
kubectl exec -it postgres-0 -- ls -la /var/lib/postgresql/backups/
```

### Experiment 4: Connection Pooling and Load Testing
```bash
# Check database connections
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Test API endpoints
kubectl port-forward service/backend-service 8080:80
curl http://localhost:8080/api/todos
curl -X POST http://localhost:8080/api/todos -H "Content-Type: application/json" -d '{"title":"New todo","completed":false}'
```

## 🔧 Database Configuration Best Practices

### 1. Environment-Specific Configuration
```yaml
env:
- name: POSTGRES_DB
  value: "todoapp"
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: username
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: password
```

### 2. Resource Limits and Requests
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 3. Health Checks
```yaml
livenessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  initialDelaySeconds: 5
  periodSeconds: 5
```

## 🔐 Database Security Best Practices

### 1. Use Secrets for Credentials
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
data:
  username: cG9zdGdyZXM=  # postgres
  password: c2VjdXJlUGFzc3dvcmQ=  # securePassword
```

### 2. Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-netpol
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
```

### 3. Pod Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 999
  fsGroup: 999
  capabilities:
    drop:
    - ALL
```

## 📊 Monitoring and Maintenance

### Database Metrics
```bash
# Check database size
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('todoapp'));"

# Monitor connections
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Check slow queries
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT query, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

### Storage Usage
```bash
# Check PVC usage
kubectl get pvc
kubectl describe pvc postgres-pvc-postgres-0

# Storage metrics (if monitoring is set up)
kubectl top pods postgres-0
```

## 🐛 Troubleshooting

### Database Connection Issues
```bash
# Check if PostgreSQL is running
kubectl exec -it postgres-0 -- pg_isready -U postgres

# Check database logs
kubectl logs postgres-0

# Test connection from another Pod
kubectl run debug --image=postgres:13 --rm -it --restart=Never -- psql -h postgres-service -U postgres -d todoapp
```

### Storage Issues
```bash
# Check PVC status
kubectl describe pvc postgres-pvc-postgres-0

# Check if storage class exists
kubectl get storageclass

# Check node storage capacity
kubectl describe nodes
```

### StatefulSet Issues
```bash
# Check StatefulSet status
kubectl describe statefulset postgres

# Check Pod events
kubectl describe pod postgres-0

# Check if headless service exists
kubectl get service postgres-headless
```

## 💾 Backup and Recovery Strategies

### 1. Automated Backups with CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:13
            command: ["/bin/bash"]
            args:
              - -c
              - |
                pg_dump -h postgres-service -U postgres todoapp > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
          restartPolicy: OnFailure
```

### 2. Point-in-Time Recovery
```bash
# Enable WAL archiving in PostgreSQL config
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'
```

### 3. Volume Snapshots
```bash
# Create a volume snapshot (if supported by storage class)
kubectl apply -f manifests/08-volume-snapshot.yaml
```

## 🧹 Cleanup

Remove all resources:
```bash
kubectl delete -f manifests/
kubectl delete pvc --all
```

## 🎯 Key Takeaways

1. **StatefulSets** provide ordered deployment and stable identity for stateful applications
2. **PersistentVolumes** ensure data survives Pod restarts and rescheduling
3. **Storage Classes** enable dynamic provisioning of storage resources
4. **Database initialization** can be handled with Kubernetes Jobs
5. **Security** requires proper use of Secrets and Network Policies
6. **Monitoring and backup** strategies are essential for production databases

## 📚 Next Steps

Ready for Project 4? Proceed to [Load Balancing and Scaling](../04-load-balancing/) where you'll learn:
- Horizontal Pod Autoscaling (HPA)
- Ingress controllers and routing
- Load testing and performance optimization
- Advanced scaling strategies

## 📖 Additional Reading

- [StatefulSets Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Running PostgreSQL on Kubernetes](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/)

---

**Fantastic progress!** 🎉 You now understand how to handle stateful applications and persistent data in Kubernetes. These skills are crucial for real-world applications that need to store and manage data reliably.
