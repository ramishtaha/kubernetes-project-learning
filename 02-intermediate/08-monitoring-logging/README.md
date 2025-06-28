# Project 8: Monitoring and Logging

## Learning Objectives
- Deploy Prometheus for metrics collection
- Set up Grafana for visualization
- Implement centralized logging with ELK/EFK stack
- Configure alerting and notification systems
- Monitor application and cluster health

## Prerequisites
- Completed Projects 1-7
- Understanding of observability concepts
- Basic knowledge of time-series databases

## Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───▶│   Prometheus    │───▶│     Grafana     │
│    Metrics      │    │    (Metrics)    │    │ (Visualization) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                              │
         ▼                                              ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───▶│   Fluentd/      │───▶│  Elasticsearch  │
│      Logs       │    │   Fluent Bit    │    │    (Storage)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │     Kibana      │
                                               │ (Log Analysis)  │
                                               └─────────────────┘
```

## Implementation Steps

### Step 1: Deploy Prometheus Stack
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus with Grafana
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.enabled=true \
  --set alertmanager.enabled=true
```

### Step 2: Deploy Sample Application with Metrics
```bash
kubectl apply -f manifests/
```

### Step 3: Configure Custom Dashboards
- Import pre-built dashboards
- Create custom application dashboards
- Set up alerting rules

### Step 4: Deploy ELK Stack for Logging
```bash
# Deploy Elasticsearch
kubectl apply -f logging/elasticsearch.yaml

# Deploy Fluentd DaemonSet
kubectl apply -f logging/fluentd.yaml

# Deploy Kibana
kubectl apply -f logging/kibana.yaml
```

## Files Structure
```
08-monitoring-logging/
├── README.md
├── manifests/
│   ├── app-with-metrics.yaml
│   ├── servicemonitor.yaml
│   └── prometheusrule.yaml
├── logging/
│   ├── elasticsearch.yaml
│   ├── fluentd.yaml
│   └── kibana.yaml
├── grafana-dashboards/
│   ├── application-dashboard.json
│   └── kubernetes-dashboard.json
└── scripts/
    ├── deploy-monitoring.sh
    └── setup-logging.sh
```

## Key Concepts

### Metrics Collection
- **ServiceMonitor**: Defines how Prometheus scrapes metrics
- **PodMonitor**: Monitors individual pods
- **PrometheusRule**: Defines alerting rules

### Logging Pipeline
- **Fluentd**: Log collection and forwarding
- **Elasticsearch**: Log storage and indexing
- **Kibana**: Log visualization and analysis

### Alerting
- **AlertManager**: Handles alerts from Prometheus
- **Notification Channels**: Slack, email, PagerDuty integration

## Experiments to Try

### 1. Custom Metrics
```yaml
# Add custom metrics to your application
apiVersion: v1
kind: Service
metadata:
  name: app-metrics
  labels:
    app: sample-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

### 2. Log Parsing
- Configure Fluentd parsers for different log formats
- Set up log routing based on namespaces
- Implement log sampling for high-volume applications

### 3. Alert Testing
- Create test alerts for CPU/memory usage
- Set up alert silencing and inhibition
- Test notification channels

### 4. Dashboard Customization
- Create business-specific dashboards
- Set up dashboard variables and templating
- Implement drill-down capabilities

## Troubleshooting

### Common Issues

1. **Prometheus not scraping metrics**
   ```bash
   # Check ServiceMonitor configuration
   kubectl get servicemonitor -n monitoring
   
   # Verify endpoint discovery
   kubectl get endpoints -n your-namespace
   ```

2. **Grafana dashboard not loading**
   ```bash
   # Check Grafana logs
   kubectl logs -n monitoring deployment/monitoring-grafana
   
   # Verify data source configuration
   ```

3. **Logs not appearing in Kibana**
   ```bash
   # Check Fluentd logs
   kubectl logs -n kube-system daemonset/fluentd
   
   # Verify Elasticsearch indices
   kubectl exec -it elasticsearch-0 -- curl localhost:9200/_cat/indices
   ```

### Performance Optimization
- Configure retention policies for metrics and logs
- Set up log rotation and compression
- Optimize Elasticsearch cluster configuration

## Security Considerations
- Enable RBAC for monitoring components
- Secure Grafana with authentication
- Encrypt logs in transit and at rest
- Regular security updates for all components

## Best Practices
- Use resource limits for monitoring components
- Implement high availability for critical monitoring
- Regular backup of dashboards and configurations
- Monitor the monitoring stack itself

## Next Steps
- Integrate with external monitoring systems
- Set up distributed tracing (Jaeger/Zipkin)
- Implement custom exporters for specific applications
- Advanced alerting with machine learning

## Cleanup
```bash
# Remove monitoring stack
helm uninstall monitoring -n monitoring

# Remove logging components
kubectl delete -f logging/

# Clean up namespace
kubectl delete namespace monitoring
```

## Additional Resources
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Elasticsearch Documentation](https://www.elastic.co/guide/)
- [Kubernetes Monitoring Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/monitoring/)
