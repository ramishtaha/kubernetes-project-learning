# 🏗️ Project 11: Microservices Architecture

**Difficulty**: 🟡 Intermediate  
**Time Estimate**: 3-4 hours  
**Prerequisites**: Projects 01-06 completed, distributed systems concepts  

## 📋 Overview

Build a complete e-commerce microservices application! This project demonstrates how to design, deploy, and manage a distributed system using microservices patterns. You'll implement service-to-service communication, API gateways, and distributed tracing for a production-ready architecture.

## 🎯 Learning Objectives

By the end of this project, you will:
- Design and deploy a microservices architecture
- Implement service-to-service communication patterns
- Use API Gateway for external access
- Implement distributed tracing and observability
- Handle service discovery and load balancing
- Understand the challenges and benefits of microservices
- Learn inter-service security and authentication

## 📋 Project Overview

You'll build a complete e-commerce microservices application with:
- **API Gateway**: Single entry point for external requests
- **User Service**: User management and authentication
- **Product Service**: Product catalog management
- **Order Service**: Order processing and management
- **Inventory Service**: Stock management
- **Notification Service**: Email/SMS notifications
- **Redis Cache**: Distributed caching layer
- **Service Mesh**: Inter-service communication (Istio)

### What We'll Build
- A distributed e-commerce application
- API Gateway with request routing
- Multiple independent microservices
- Service mesh for observability and security
- Distributed caching and messaging
- End-to-end tracing with Jaeger

## 🏗️ Architecture

```
Internet → Ingress → API Gateway → [User Service]
                                  → [Product Service] → Redis Cache
                                  → [Order Service] ↔ [Inventory Service]
                                  → [Notification Service]
                                       ↓
                               Service Mesh (Istio)
                                       ↓
                              Observability Stack
                            (Prometheus, Grafana, Jaeger)
```

## 🚀 Implementation Steps

### Step 1: Set up the Namespace and RBAC

Create dedicated namespace and permissions:

```bash
kubectl apply -f manifests/01-namespace-rbac.yaml
```

### Step 2: Deploy Redis Cache

Set up distributed caching:

```bash
kubectl apply -f manifests/02-redis.yaml
```

### Step 3: Install Istio Service Mesh

Install Istio for service mesh capabilities:

```bash
# Download and install Istio
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-*/bin:$PATH

# Install Istio
istioctl install --set values.defaultRevision=default -y

# Enable sidecar injection for our namespace
kubectl label namespace ecommerce istio-injection=enabled
```

### Step 4: Deploy Core Services

Deploy all microservices:

```bash
kubectl apply -f manifests/03-user-service.yaml
kubectl apply -f manifests/04-product-service.yaml
kubectl apply -f manifests/05-inventory-service.yaml
kubectl apply -f manifests/06-order-service.yaml
kubectl apply -f manifests/07-notification-service.yaml
```

### Step 5: Deploy API Gateway

Deploy the API Gateway for external access:

```bash
kubectl apply -f manifests/08-api-gateway.yaml
```

### Step 6: Configure Istio Gateway and Virtual Services

Set up traffic routing:

```bash
kubectl apply -f manifests/09-istio-gateway.yaml
kubectl apply -f manifests/10-virtual-services.yaml
```

### Step 7: Deploy Observability Stack

Set up monitoring and tracing:

```bash
kubectl apply -f manifests/11-observability.yaml
```

### Step 8: Access the Application

Get the gateway URL:

```bash
# For minikube
minikube tunnel
export GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test the API
curl $GATEWAY_URL/api/health
```

## 🔍 Understanding Microservices Patterns

### Service Communication Patterns

#### 1. Synchronous Communication (HTTP/REST)
```yaml
# Direct service-to-service calls
- name: ORDER_SERVICE_URL
  value: "http://order-service:8080"
- name: INVENTORY_SERVICE_URL
  value: "http://inventory-service:8080"
```

#### 2. Asynchronous Communication (Message Queues)
```yaml
# Using Redis for pub/sub
- name: REDIS_URL
  value: "redis://redis-service:6379"
```

#### 3. Event-Driven Architecture
```yaml
# Events for order processing
events:
  - order.created
  - inventory.updated
  - notification.sent
```

### Data Management Patterns

#### 1. Database per Service
Each service has its own database to ensure loose coupling.

#### 2. Shared Data via API
Services access other services' data only through APIs.

#### 3. Event Sourcing
Store events rather than current state for audit and recovery.

## 🧪 Experiments to Try

### Experiment 1: Test Service Communication
```bash
# Create a user
curl -X POST $GATEWAY_URL/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"john","email":"john@example.com"}'

# Add a product
curl -X POST $GATEWAY_URL/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99,"stock":10}'

# Create an order
curl -X POST $GATEWAY_URL/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productId":1,"quantity":2}'
```

### Experiment 2: Observe Service Mesh Traffic
```bash
# View service mesh dashboard
istioctl dashboard kiali

# Check service graph
kubectl port-forward svc/kiali 20001:20001 -n istio-system
# Visit http://localhost:20001
```

### Experiment 3: Distributed Tracing
```bash
# Access Jaeger UI
kubectl port-forward svc/jaeger 16686:16686 -n istio-system
# Visit http://localhost:16686

# Generate some traffic and observe traces
for i in {1..10}; do
  curl $GATEWAY_URL/api/products
  sleep 1
done
```

### Experiment 4: Test Resilience
```bash
# Simulate service failure
kubectl scale deployment inventory-service --replicas=0 -n ecommerce

# Try to create an order (should fail gracefully)
curl -X POST $GATEWAY_URL/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productId":1,"quantity":2}'

# Restore service
kubectl scale deployment inventory-service --replicas=2 -n ecommerce
```

### Experiment 5: Load Testing
```bash
# Install k6 for load testing
kubectl apply -f manifests/12-load-test.yaml

# Run load test
kubectl logs -f job/load-test -n ecommerce
```

## 🔧 Service Mesh Configuration

### Traffic Management
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: product-service
spec:
  http:
  - match:
    - uri:
        prefix: /api/products
    route:
    - destination:
        host: product-service
        port:
          number: 8080
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
```

### Circuit Breaker
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: inventory-service
spec:
  host: inventory-service
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 3
      interval: 30s
      baseEjectionTime: 30s
```

### Rate Limiting
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-gateway
spec:
  host: api-gateway
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 10
```

## 📊 Monitoring and Observability

### Key Metrics to Monitor
1. **Request Rate**: Requests per second per service
2. **Error Rate**: Percentage of failed requests
3. **Response Time**: Latency percentiles (p50, p95, p99)
4. **Service Dependencies**: Service call topology
5. **Resource Usage**: CPU, memory, network per service

### Prometheus Queries
```promql
# Request rate
sum(rate(istio_requests_total[5m])) by (destination_service_name)

# Error rate
sum(rate(istio_requests_total{response_code!~"2.."}[5m])) by (destination_service_name)

# Response time
histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (destination_service_name, le))
```

### Distributed Tracing
```yaml
# Jaeger configuration for sampling
apiVersion: v1
kind: ConfigMap
metadata:
  name: jaeger-config
data:
  sampling_strategies.json: |
    {
      "default_strategy": {
        "type": "probabilistic",
        "param": 0.1
      }
    }
```

## 🔐 Security Best Practices

### Service-to-Service Authentication
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: ecommerce
spec:
  mtls:
    mode: STRICT
```

### Authorization Policies
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: inventory-access
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: inventory-service
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/ecommerce/sa/order-service"]
  - to:
    - operation:
        methods: ["GET", "POST"]
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ecommerce-netpol
  namespace: ecommerce
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: istio-system
    - podSelector: {}
```

## 🧹 Cleanup

Remove all resources:
```bash
kubectl delete namespace ecommerce
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```

## 🎯 Key Takeaways

1. **Microservices** enable independent development and deployment
2. **Service Mesh** provides observability, security, and traffic management
3. **API Gateway** serves as a single entry point and handles cross-cutting concerns
4. **Distributed Tracing** is essential for debugging microservices
5. **Circuit Breakers** and retries improve resilience
6. **Monitoring** becomes more complex but more granular
7. **Security** requires service-to-service authentication and authorization

## 📚 Next Steps

Ready for Project 7? Proceed to [CI/CD Pipeline](../07-cicd-pipeline/) where you'll learn:
- GitOps principles and ArgoCD
- Automated testing and deployment
- Blue-green and canary deployments
- Pipeline security and best practices

## 📖 Additional Reading

- [Microservices Patterns](https://microservices.io/patterns/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [Building Microservices](https://samnewman.io/books/building_microservices/)
- [The Twelve-Factor App](https://12factor.net/)

---

**Outstanding work!** 🎉 You've built a complete microservices architecture with observability and security. This represents the foundation of modern cloud-native applications.
