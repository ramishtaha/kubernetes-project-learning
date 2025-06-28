# Project 14: Edge Computing and IoT with Kubernetes

## Learning Objectives
- Deploy Kubernetes at the edge with K3s and MicroK8s
- Implement IoT device management and orchestration
- Configure edge-to-cloud connectivity
- Manage distributed edge deployments
- Handle offline-first applications and data sync

## Prerequisites
- Completed Projects 1-13
- Understanding of edge computing concepts
- Basic knowledge of IoT protocols (MQTT, CoAP)
- Familiarity with resource-constrained environments

## Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloud K8s     │◄──▶│   Edge K8s      │◄──▶│   IoT Devices   │
│   (Central)     │    │   (K3s/MicroK8s)│    │   (Sensors)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Centralized   │    │   Edge          │    │   Local         │
│   Management    │    │   Processing    │    │   Data          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Implementation Steps

### Step 1: Set up K3s Edge Cluster
```bash
# Install K3s on edge nodes
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Add worker nodes
curl -sfL https://get.k3s.io | K3S_URL=https://<master-ip>:6443 K3S_TOKEN=<node-token> sh -
```

### Step 2: Deploy Edge Applications
```bash
kubectl apply -f edge-apps/
```

### Step 3: Set up IoT Device Management
```bash
kubectl apply -f iot-management/
```

### Step 4: Configure Edge-to-Cloud Sync
```bash
kubectl apply -f sync/
```

## Files Structure
```
14-edge-computing/
├── README.md
├── k3s-setup/
│   ├── install-k3s.sh
│   ├── k3s-config.yaml
│   ├── edge-node-setup.sh
│   └── cluster-registration.yaml
├── edge-apps/
│   ├── data-collector.yaml
│   ├── edge-processor.yaml
│   ├── local-cache.yaml
│   └── offline-sync.yaml
├── iot-management/
│   ├── mqtt-broker.yaml
│   ├── device-manager.yaml
│   ├── sensor-gateway.yaml
│   └── protocol-adapters.yaml
├── sync/
│   ├── cloud-sync.yaml
│   ├── data-replication.yaml
│   ├── config-management.yaml
│   └── offline-first.yaml
├── monitoring/
│   ├── edge-metrics.yaml
│   ├── device-monitoring.yaml
│   └── connectivity-check.yaml
└── scripts/
    ├── setup-edge-cluster.sh
    ├── deploy-iot-stack.sh
    ├── sync-edge-data.sh
    └── monitor-edge-health.sh
```

## Key Concepts

### Edge Computing Patterns
- **Data Locality**: Process data close to source
- **Offline Operation**: Function without cloud connectivity
- **Bandwidth Optimization**: Minimize data transfer
- **Latency Reduction**: Real-time processing at edge

### K3s Features
- **Lightweight**: Minimal resource footprint
- **Simplified**: Single binary installation
- **Edge Optimized**: Designed for resource-constrained environments
- **HA Support**: High availability at the edge

### IoT Integration
- **Protocol Support**: MQTT, CoAP, HTTP/REST
- **Device Management**: Registration, updates, monitoring
- **Data Pipeline**: Ingestion, processing, forwarding
- **Security**: Device authentication and encryption

## K3s Cluster Setup

### Master Node Installation
```bash
#!/bin/bash
# install-k3s-master.sh

# Install K3s server
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb" sh -s - \
  --write-kubeconfig-mode 644 \
  --cluster-cidr 10.42.0.0/16 \
  --service-cidr 10.43.0.0/16 \
  --cluster-dns 10.43.0.10

# Get join token
sudo cat /var/lib/rancher/k3s/server/node-token

# Configure kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
```

### Worker Node Setup
```bash
#!/bin/bash
# install-k3s-worker.sh

MASTER_IP="192.168.1.100"
NODE_TOKEN="K10xxx..." # Token from master node

curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${NODE_TOKEN} sh -

# Verify node joined
kubectl get nodes
```

### Edge-Optimized Configuration
```yaml
# k3s-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: k3s-config
  namespace: kube-system
data:
  config.yaml: |
    disable:
      - traefik
      - servicelb
      - local-storage
    flannel-backend: host-gw
    cluster-cidr: 10.42.0.0/16
    service-cidr: 10.43.0.0/16
    cluster-dns: 10.43.0.10
    disable-cloud-controller: true
    disable-network-policy: false
```

## IoT Device Management

### MQTT Broker Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mosquitto-broker
  namespace: iot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mosquitto
  template:
    metadata:
      labels:
        app: mosquitto
    spec:
      containers:
      - name: mosquitto
        image: eclipse-mosquitto:2.0
        ports:
        - containerPort: 1883
        - containerPort: 9001
        volumeMounts:
        - name: mosquitto-config
          mountPath: /mosquitto/config
        - name: mosquitto-data
          mountPath: /mosquitto/data
        - name: mosquitto-log
          mountPath: /mosquitto/log
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: mosquitto-config
        configMap:
          name: mosquitto-config
      - name: mosquitto-data
        emptyDir: {}
      - name: mosquitto-log
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: mosquitto-service
  namespace: iot
spec:
  selector:
    app: mosquitto
  ports:
  - name: mqtt
    port: 1883
    targetPort: 1883
  - name: websocket
    port: 9001
    targetPort: 9001
  type: LoadBalancer
```

### Device Manager
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: device-manager
  namespace: iot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: device-manager
  template:
    metadata:
      labels:
        app: device-manager
    spec:
      containers:
      - name: device-manager
        image: python:3.9-slim
        command:
        - python
        - device_manager.py
        env:
        - name: MQTT_BROKER
          value: "mosquitto-service:1883"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: url
        volumeMounts:
        - name: device-config
          mountPath: /app/config
        - name: device-scripts
          mountPath: /app
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: device-config
        configMap:
          name: device-config
      - name: device-scripts
        configMap:
          name: device-scripts
```

### Sensor Data Gateway
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sensor-gateway
  namespace: iot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sensor-gateway
  template:
    metadata:
      labels:
        app: sensor-gateway
    spec:
      containers:
      - name: gateway
        image: node:16-alpine
        command:
        - node
        - gateway.js
        env:
        - name: MQTT_BROKER
          value: "mosquitto-service:1883"
        - name: REDIS_URL
          value: "redis://redis-service:6379"
        - name: CLOUD_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: cloud-credentials
              key: endpoint
        ports:
        - containerPort: 3000
        volumeMounts:
        - name: gateway-config
          mountPath: /app/config
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: gateway-config
        configMap:
          name: gateway-config
```

## Edge Applications

### Data Collector
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: data-collector
  namespace: edge
spec:
  selector:
    matchLabels:
      app: data-collector
  template:
    metadata:
      labels:
        app: data-collector
    spec:
      hostNetwork: true
      containers:
      - name: collector
        image: fluent/fluent-bit:1.9
        volumeMounts:
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
      volumes:
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### Edge Processor
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: edge-processor
  namespace: edge
spec:
  replicas: 1
  selector:
    matchLabels:
      app: edge-processor
  template:
    metadata:
      labels:
        app: edge-processor
    spec:
      containers:
      - name: processor
        image: python:3.9-slim
        command:
        - python
        - edge_processor.py
        env:
        - name: INPUT_STREAM
          value: "mqtt://mosquitto-service:1883/sensors"
        - name: OUTPUT_STREAM
          value: "mqtt://mosquitto-service:1883/processed"
        - name: PROCESSING_MODE
          value: "realtime"
        - name: BATCH_SIZE
          value: "100"
        - name: PROCESSING_INTERVAL
          value: "10"
        volumeMounts:
        - name: processor-config
          mountPath: /app/config
        - name: model-cache
          mountPath: /app/models
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: processor-config
        configMap:
          name: processor-config
      - name: model-cache
        emptyDir:
          sizeLimit: 1Gi
```

## Edge-to-Cloud Synchronization

### Cloud Sync Service
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloud-sync
  namespace: sync
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloud-sync
  template:
    metadata:
      labels:
        app: cloud-sync
    spec:
      containers:
      - name: sync
        image: golang:1.19-alpine
        command:
        - go
        - run
        - sync_service.go
        env:
        - name: CLOUD_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: cloud-credentials
              key: endpoint
        - name: SYNC_INTERVAL
          value: "300" # 5 minutes
        - name: BATCH_SIZE
          value: "1000"
        - name: RETRY_ATTEMPTS
          value: "3"
        - name: OFFLINE_STORAGE
          value: "/data/offline"
        volumeMounts:
        - name: sync-config
          mountPath: /app/config
        - name: offline-storage
          mountPath: /data/offline
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: sync-config
        configMap:
          name: sync-config
      - name: offline-storage
        persistentVolumeClaim:
          claimName: offline-storage-pvc
```

### Offline-First Data Store
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: edge-datastore
  namespace: edge
spec:
  serviceName: edge-datastore
  replicas: 1
  selector:
    matchLabels:
      app: edge-datastore
  template:
    metadata:
      labels:
        app: edge-datastore
    spec:
      containers:
      - name: datastore
        image: postgres:13-alpine
        env:
        - name: POSTGRES_DB
          value: edgedata
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## Experiments to Try

### 1. Distributed Edge Deployment
```bash
# Deploy applications across multiple edge locations
for location in factory-a factory-b warehouse-c; do
  kubectl apply -f edge-apps/ -l location=$location
done

# Monitor edge cluster health
kubectl get nodes -l node-role.kubernetes.io/edge=true
```

### 2. IoT Device Simulation
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: iot-simulator
  namespace: iot
spec:
  template:
    spec:
      containers:
      - name: simulator
        image: python:3.9-slim
        command:
        - python
        - iot_simulator.py
        env:
        - name: DEVICE_COUNT
          value: "100"
        - name: MQTT_BROKER
          value: "mosquitto-service:1883"
        - name: SIMULATION_DURATION
          value: "3600" # 1 hour
        - name: DATA_INTERVAL
          value: "10" # 10 seconds
      restartPolicy: Never
```

### 3. Edge ML Inference
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: edge-ml-inference
  namespace: edge
spec:
  replicas: 1
  selector:
    matchLabels:
      app: edge-ml-inference
  template:
    metadata:
      labels:
        app: edge-ml-inference
    spec:
      containers:
      - name: inference
        image: tensorflow/serving:2.8.0-gpu
        ports:
        - containerPort: 8501
        env:
        - name: MODEL_NAME
          value: "edge_model"
        - name: MODEL_BASE_PATH
          value: "/models"
        volumeMounts:
        - name: model-storage
          mountPath: /models
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: model-storage
        persistentVolumeClaim:
          claimName: model-storage-pvc
```

### 4. Network Resilience Testing
```bash
# Simulate network partitions
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: simulate-partition
  namespace: edge
spec:
  podSelector:
    matchLabels:
      app: cloud-sync
  policyTypes:
  - Egress
  egress: []
EOF

# Monitor offline behavior
kubectl logs -f deployment/cloud-sync -n sync
```

## Troubleshooting

### Common Issues

1. **K3s installation failures**
   ```bash
   # Check system requirements
   free -h # At least 512MB RAM
   df -h # At least 1GB disk space
   
   # Check firewall rules
   sudo ufw status
   sudo iptables -L
   
   # Restart K3s
   sudo systemctl restart k3s
   ```

2. **IoT connectivity issues**
   ```bash
   # Test MQTT connectivity
   mosquitto_pub -h <broker-ip> -t test/topic -m "hello"
   mosquitto_sub -h <broker-ip> -t test/topic
   
   # Check broker logs
   kubectl logs deployment/mosquitto-broker -n iot
   ```

3. **Edge-to-cloud sync failures**
   ```bash
   # Check network connectivity
   kubectl exec -it deployment/cloud-sync -- ping google.com
   
   # Check sync service logs
   kubectl logs deployment/cloud-sync -n sync
   
   # Verify credentials
   kubectl get secret cloud-credentials -o yaml
   ```

### Performance Optimization

1. **Resource Optimization**
   ```bash
   # Monitor resource usage
   kubectl top nodes
   kubectl top pods --all-namespaces
   
   # Optimize resource requests
   kubectl set resources deployment/edge-processor --requests=cpu=50m,memory=128Mi
   ```

2. **Network Optimization**
   ```bash
   # Use local DNS caching
   kubectl apply -f https://k8s.io/examples/admin/dns/nodelocaldns.yaml
   
   # Optimize for edge networks
   kubectl patch deployment coredns -n kube-system -p '{"spec":{"template":{"spec":{"containers":[{"name":"coredns","resources":{"limits":{"memory":"70Mi"},"requests":{"cpu":"50m","memory":"70Mi"}}}]}}}}'
   ```

## Security Considerations

### 1. Edge Security
```yaml
# Secure communication between edge and cloud
apiVersion: v1
kind: Secret
metadata:
  name: edge-tls-cert
  namespace: sync
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

### 2. Device Authentication
```yaml
# MQTT broker with authentication
apiVersion: v1
kind: ConfigMap
metadata:
  name: mosquitto-config
  namespace: iot
data:
  mosquitto.conf: |
    listener 1883 0.0.0.0
    protocol mqtt
    allow_anonymous false
    password_file /mosquitto/config/passwd
    
    listener 8883 0.0.0.0
    protocol mqtt
    cafile /mosquitto/config/ca.crt
    certfile /mosquitto/config/server.crt
    keyfile /mosquitto/config/server.key
    require_certificate true
```

### 3. Network Segmentation
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: iot-network-policy
  namespace: iot
spec:
  podSelector:
    matchLabels:
      app: mosquitto
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: iot
    - namespaceSelector:
        matchLabels:
          name: edge
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: sync
```

## Best Practices

### 1. Resource Management
- Use resource limits for all containers
- Implement node affinity for critical workloads
- Monitor resource usage continuously
- Plan for resource constraints

### 2. Data Management
- Implement data compression for transmission
- Use local caching for frequently accessed data
- Implement data retention policies
- Plan for offline operation

### 3. Deployment Strategy
- Use blue-green deployments for critical updates
- Implement health checks for all services
- Plan for rollback scenarios
- Test edge scenarios thoroughly

### 4. Monitoring and Maintenance
- Implement comprehensive monitoring
- Set up alerting for edge disconnection
- Plan for remote maintenance
- Monitor device health and connectivity

## Next Steps
- Implement advanced edge AI/ML capabilities
- Set up multi-cluster edge management
- Integrate with 5G networks
- Implement edge computing for autonomous systems

## Cleanup
```bash
# Uninstall K3s
sudo /usr/local/bin/k3s-uninstall.sh

# Remove edge applications
kubectl delete namespace edge iot sync

# Clean up persistent volumes
kubectl delete pvc --all
```

## Additional Resources
- [K3s Documentation](https://k3s.io/)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [Eclipse Mosquitto](https://mosquitto.org/)
- [Edge Computing with Kubernetes](https://kubernetes.io/docs/concepts/cluster-administration/)
