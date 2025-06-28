# Project 15: Enterprise Kubernetes Platform

## Learning Objectives
- Build a complete enterprise-grade Kubernetes platform
- Implement multi-tenancy and governance
- Set up cost management and resource optimization
- Deploy comprehensive monitoring and compliance
- Establish enterprise security and operational excellence

## Prerequisites
- Completed Projects 1-14
- Advanced understanding of Kubernetes
- Knowledge of enterprise requirements
- Experience with cloud-native technologies

## Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Governance    │───▶│   Platform      │───▶│   Workloads     │
│   & Compliance  │    │   Services      │    │   & Apps        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Security &    │    │   Monitoring &  │    │   Cost Mgmt &   │
│   Identity      │    │   Observability │    │   Optimization  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Implementation Steps

### Step 1: Platform Foundation
```bash
# Install platform foundation components
./scripts/setup-platform-foundation.sh
```

### Step 2: Multi-Tenancy Setup
```bash
kubectl apply -f multi-tenancy/
```

### Step 3: Governance and Compliance
```bash
kubectl apply -f governance/
```

### Step 4: Enterprise Security
```bash
kubectl apply -f security/
```

### Step 5: Cost Management
```bash
kubectl apply -f cost-management/
```

## Files Structure
```
15-enterprise-platform/
├── README.md
├── platform-foundation/
│   ├── cluster-api/
│   ├── gitops/
│   ├── service-mesh/
│   └── observability/
├── multi-tenancy/
│   ├── namespace-management.yaml
│   ├── resource-quotas.yaml
│   ├── network-policies.yaml
│   └── tenant-isolation.yaml
├── governance/
│   ├── policy-engine/
│   ├── compliance-checks/
│   ├── audit-logging/
│   └── approval-workflows/
├── security/
│   ├── identity-management/
│   ├── secrets-management/
│   ├── vulnerability-scanning/
│   └── runtime-security/
├── cost-management/
│   ├── resource-optimization/
│   ├── chargeback/
│   ├── rightsizing/
│   └── cost-monitoring/
├── monitoring/
│   ├── platform-metrics/
│   ├── business-metrics/
│   ├── sli-slo-monitoring/
│   └── alerting/
└── scripts/
    ├── setup-platform-foundation.sh
    ├── deploy-tenant.sh
    ├── backup-platform.sh
    └── disaster-recovery.sh
```

## Platform Foundation

### Cluster API Management
```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: enterprise-workload-cluster
  namespace: cluster-management
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["192.168.0.0/16"]
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: AWSCluster
    name: enterprise-workload-cluster
  controlPlaneRef:
    kind: KubeadmControlPlane
    apiVersion: controlplane.cluster.x-k8s.io/v1beta1
    name: enterprise-workload-cluster-control-plane
---
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: KubeadmControlPlane
metadata:
  name: enterprise-workload-cluster-control-plane
  namespace: cluster-management
spec:
  replicas: 3
  machineTemplate:
    infrastructureRef:
      kind: AWSMachineTemplate
      apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
      name: enterprise-workload-cluster-control-plane
  kubeadmConfigSpec:
    initConfiguration:
      nodeRegistration:
        kubeletExtraArgs:
          cloud-provider: aws
    clusterConfiguration:
      apiServer:
        extraArgs:
          cloud-provider: aws
          audit-log-maxage: "30"
          audit-log-maxbackup: "10"
          audit-log-maxsize: "100"
          audit-log-path: /var/log/audit.log
          audit-policy-file: /etc/kubernetes/audit-policy.yaml
        extraVolumes:
        - name: audit-policy
          hostPath: /etc/kubernetes/audit-policy.yaml
          mountPath: /etc/kubernetes/audit-policy.yaml
          readOnly: true
          pathType: File
      controllerManager:
        extraArgs:
          cloud-provider: aws
```

### GitOps Platform Management
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-apps
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://github.com/your-org/platform-manifests
    targetRevision: HEAD
    path: platform
  destination:
    server: https://kubernetes.default.svc
    namespace: platform-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### Service Mesh (Istio)
```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: enterprise-control-plane
  namespace: istio-system
spec:
  values:
    global:
      meshID: enterprise-mesh
      network: enterprise-network
      hub: gcr.io/istio-enterprise
    pilot:
      env:
        EXTERNAL_ISTIOD: true
        ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION: true
  components:
    pilot:
      k8s:
        resources:
          requests:
            cpu: 500m
            memory: 2048Mi
        hpaSpec:
          minReplicas: 2
          maxReplicas: 5
          metrics:
          - type: Resource
            resource:
              name: cpu
              target:
                type: Utilization
                averageUtilization: 80
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          type: LoadBalancer
          loadBalancerSourceRanges:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
        hpaSpec:
          minReplicas: 2
          maxReplicas: 10
```

## Multi-Tenancy Implementation

### Namespace Management
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-alpha
  labels:
    tenant: alpha
    environment: production
    cost-center: engineering
    security-tier: standard
  annotations:
    scheduler.alpha.kubernetes.io/node-selector: tenant=alpha
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-alpha-quota
  namespace: tenant-alpha
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    requests.storage: 500Gi
    persistentvolumeclaims: "20"
    pods: "100"
    services: "20"
    secrets: "50"
    configmaps: "50"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: tenant-alpha-limits
  namespace: tenant-alpha
spec:
  limits:
  - default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
  - max:
      cpu: 2
      memory: 4Gi
    min:
      cpu: 10m
      memory: 64Mi
    type: Container
  - max:
      storage: 100Gi
    min:
      storage: 1Gi
    type: PersistentVolumeClaim
```

### Network Isolation
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-alpha-isolation
  namespace: tenant-alpha
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: alpha
    - namespaceSelector:
        matchLabels:
          name: istio-system
    - namespaceSelector:
        matchLabels:
          name: platform-system
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tenant: alpha
  - to:
    - namespaceSelector:
        matchLabels:
          name: istio-system
  - to:
    - namespaceSelector:
        matchLabels:
          name: platform-system
  - to: [] # Allow external traffic
    ports:
    - protocol: TCP
      port: 443
    - protocol: UDP
      port: 53
```

### Tenant RBAC
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: tenant-alpha
  name: tenant-alpha-admin
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies", "ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["security.istio.io"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-alpha-admin-binding
  namespace: tenant-alpha
subjects:
- kind: Group
  name: tenant-alpha-admins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: tenant-alpha-admin
  apiGroup: rbac.authorization.k8s.io
```

## Governance and Compliance

### Policy Engine (OPA Gatekeeper)
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        properties:
          labels:
            type: array
            items:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Missing required label: %v", [missing])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-tenant-label
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet", "DaemonSet"]
  parameters:
    labels: ["tenant", "environment", "cost-center"]
```

### Compliance Scanning
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: compliance-scan
  namespace: platform-system
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: compliance-scanner
          containers:
          - name: scanner
            image: aquasec/kube-bench:latest
            command:
            - sh
            - -c
            - |
              kube-bench run --targets node,policies,managedservices > /reports/compliance-$(date +%Y%m%d).json
              kubectl create configmap compliance-report-$(date +%Y%m%d) \
                --from-file=/reports/compliance-$(date +%Y%m%d).json \
                --dry-run=client -o yaml | kubectl apply -f -
            volumeMounts:
            - name: reports
              mountPath: /reports
          volumes:
          - name: reports
            emptyDir: {}
          restartPolicy: OnFailure
```

### Audit Log Management
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: audit-policy
  namespace: kube-system
data:
  audit-policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    # Log all requests at Metadata level
    - level: Metadata
      omitStages:
      - RequestReceived
      namespaces: ["tenant-alpha", "tenant-beta", "tenant-gamma"]
    
    # Log secret access at RequestResponse level
    - level: RequestResponse
      resources:
      - group: ""
        resources: ["secrets"]
      
    # Log policy violations at Request level
    - level: Request
      users: ["system:serviceaccount:gatekeeper-system:gatekeeper-admin"]
      
    # Log admin activities at RequestResponse level
    - level: RequestResponse
      userGroups: ["system:masters", "cluster-admins"]
```

## Enterprise Security

### Identity and Access Management
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: oidc-config
  namespace: kube-system
data:
  oidc.yaml: |
    apiServer:
      extraArgs:
        oidc-issuer-url: https://your-company.okta.com
        oidc-client-id: kubernetes
        oidc-username-claim: email
        oidc-groups-claim: groups
        oidc-username-prefix: "oidc:"
        oidc-groups-prefix: "oidc:"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: enterprise-developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  resourceNames: []
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: enterprise-developers
subjects:
- kind: Group
  name: oidc:developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: enterprise-developer
  apiGroup: rbac.authorization.k8s.io
```

### Secrets Management (External Secrets Operator)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: tenant-alpha
spec:
  provider:
    vault:
      server: "https://vault.company.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "tenant-alpha-role"
          serviceAccountRef:
            name: "vault-auth"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
  namespace: tenant-alpha
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: app-secrets
    creationPolicy: Owner
  data:
  - secretKey: database-password
    remoteRef:
      key: tenant-alpha/database
      property: password
  - secretKey: api-key
    remoteRef:
      key: tenant-alpha/external-api
      property: key
```

### Runtime Security (Falco)
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: falco
  namespace: security-system
spec:
  selector:
    matchLabels:
      app: falco
  template:
    metadata:
      labels:
        app: falco
    spec:
      serviceAccount: falco
      hostNetwork: true
      hostPID: true
      containers:
      - name: falco
        image: falcosecurity/falco:0.35.1
        securityContext:
          privileged: true
        args:
        - /usr/bin/falco
        - --cri=/run/containerd/containerd.sock
        - --k8s-api=https://kubernetes.default:443
        - --k8s-api-cert=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        - --k8s-api-token=/var/run/secrets/kubernetes.io/serviceaccount/token
        volumeMounts:
        - mountPath: /host/var/run/docker.sock
          name: docker-socket
        - mountPath: /host/run/containerd/containerd.sock
          name: containerd-socket
        - mountPath: /host/dev
          name: dev-fs
        - mountPath: /host/proc
          name: proc-fs
          readOnly: true
        - mountPath: /host/boot
          name: boot-fs
          readOnly: true
        - mountPath: /host/lib/modules
          name: lib-modules
          readOnly: true
        - mountPath: /host/usr
          name: usr-fs
          readOnly: true
        - mountPath: /host/etc
          name: etc-fs
          readOnly: true
        - mountPath: /etc/falco
          name: falco-config
      volumes:
      - name: docker-socket
        hostPath:
          path: /var/run/docker.sock
      - name: containerd-socket
        hostPath:
          path: /run/containerd/containerd.sock
      - name: dev-fs
        hostPath:
          path: /dev
      - name: proc-fs
        hostPath:
          path: /proc
      - name: boot-fs
        hostPath:
          path: /boot
      - name: lib-modules
        hostPath:
          path: /lib/modules
      - name: usr-fs
        hostPath:
          path: /usr
      - name: etc-fs
        hostPath:
          path: /etc
      - name: falco-config
        configMap:
          name: falco-config
```

## Cost Management and Optimization

### Resource Monitoring and Chargeback
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubecost
  namespace: cost-management
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kubecost
  template:
    metadata:
      labels:
        app: kubecost
    spec:
      containers:
      - name: cost-analyzer
        image: gcr.io/kubecost1/cost-analyzer:prod-1.105.0
        ports:
        - containerPort: 9090
        env:
        - name: PROMETHEUS_SERVER_ENDPOINT
          value: "http://prometheus.monitoring:9090"
        - name: CLOUD_PROVIDER_API_KEY
          valueFrom:
            secretKeyRef:
              name: cloud-credentials
              key: api-key
        volumeMounts:
        - name: persistent-configs
          mountPath: /var/configs
        resources:
          requests:
            cpu: 100m
            memory: 55Mi
          limits:
            cpu: 999m
            memory: 1.5Gi
      volumes:
      - name: persistent-configs
        persistentVolumeClaim:
          claimName: kubecost-cost-analyzer
```

### Cluster Autoscaler with Cost Optimization
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.27.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/enterprise-cluster
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        - --scale-down-delay-after-add=10m
        - --scale-down-unneeded-time=10m
        - --scale-down-delay-after-delete=10s
        - --scale-down-delay-after-failure=3m
        - --scale-down-utilization-threshold=0.5
        env:
        - name: AWS_REGION
          value: us-west-2
```

### Vertical Pod Autoscaler
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: tenant-alpha-vpa
  namespace: tenant-alpha
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sample-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 4Gi
      controlledResources: ["cpu", "memory"]
```

## Comprehensive Monitoring

### Platform SLI/SLO Monitoring
```yaml
apiVersion: sloth.slok.dev/v1
kind: PrometheusServiceLevel
metadata:
  name: platform-availability
  namespace: monitoring
spec:
  service: "platform-api"
  labels:
    team: platform
    tier: platform
  slos:
  - name: "api-availability"
    objective: 99.9
    description: "Platform API should be available 99.9% of the time"
    sli:
      events:
        error_query: sum(rate(http_requests_total{code=~"5.."}[5m]))
        total_query: sum(rate(http_requests_total[5m]))
    alerting:
      name: PlatformAPIHighErrorRate
      labels:
        severity: critical
      annotations:
        summary: Platform API error rate is too high
        description: "Platform API error rate is {{ $value }}%"
      page_alert:
        labels:
          severity: critical
          team: platform
      ticket_alert:
        labels:
          severity: warning
          team: platform
```

### Business Metrics Dashboard
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: business-metrics-dashboard
  namespace: monitoring
data:
  dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Enterprise Platform Business Metrics",
        "tags": ["platform", "business"],
        "timezone": "browser",
        "panels": [
          {
            "title": "Tenant Resource Utilization",
            "type": "graph",
            "targets": [
              {
                "expr": "sum by (tenant) (kube_pod_container_resource_requests{resource=\"cpu\"})",
                "legendFormat": "{{ tenant }} CPU Requests"
              }
            ]
          },
          {
            "title": "Cost by Tenant",
            "type": "piechart",
            "targets": [
              {
                "expr": "sum by (tenant) (kubecost_cluster_costs_hourly)",
                "legendFormat": "{{ tenant }}"
              }
            ]
          },
          {
            "title": "Platform Health Score",
            "type": "stat",
            "targets": [
              {
                "expr": "avg(up{job=\"platform-services\"})",
                "legendFormat": "Health Score"
              }
            ]
          }
        ]
      }
    }
```

## Disaster Recovery and Backup

### Platform Backup Strategy
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: platform-backup
  namespace: platform-system
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: backup-operator
          containers:
          - name: backup
            image: velero/velero:v1.12.0
            command:
            - sh
            - -c
            - |
              # Backup platform components
              velero backup create platform-backup-$(date +%Y%m%d) \
                --include-namespaces platform-system,istio-system,monitoring,security-system \
                --ttl 720h0m0s
              
              # Backup tenant data
              for tenant in $(kubectl get namespaces -l tenant -o name | cut -d/ -f2); do
                velero backup create ${tenant}-backup-$(date +%Y%m%d) \
                  --include-namespaces ${tenant} \
                  --ttl 168h0m0s
              done
              
              # Export cluster state
              kubectl get all --all-namespaces -o yaml > /backup/cluster-state-$(date +%Y%m%d).yaml
              aws s3 cp /backup/cluster-state-$(date +%Y%m%d).yaml s3://platform-backups/
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            emptyDir: {}
          restartPolicy: OnFailure
```

## Experiments to Try

### 1. Multi-Cluster Platform
```bash
# Deploy platform across multiple clusters
for cluster in prod-east prod-west staging-central; do
  kubectl config use-context $cluster
  kubectl apply -f platform-foundation/
done

# Set up cross-cluster service mesh
istioctl x create-remote-secret --context=prod-east --name=prod-east | kubectl apply -f - --context=prod-west
```

### 2. Advanced Cost Optimization
```bash
# Implement spot instance optimization
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spot-optimizer
spec:
  template:
    spec:
      nodeSelector:
        node.kubernetes.io/instance-type: "spot"
      tolerations:
      - key: "spot"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
EOF
```

### 3. Compliance Automation
```bash
# Automated policy deployment based on environment
kubectl apply -f governance/policies/production/ -l environment=production
kubectl apply -f governance/policies/development/ -l environment=development
```

### 4. Advanced Security Scanning
```bash
# Deploy comprehensive security scanning
helm install security-stack ./security/comprehensive-scanning/
kubectl create job --from=cronjob/vulnerability-scan security-scan-manual
```

## Best Practices

### 1. Platform Operations
- Implement infrastructure as code for all components
- Use GitOps for configuration management
- Establish clear SLOs for platform services
- Regular security assessments and penetration testing

### 2. Multi-Tenancy
- Enforce strong tenant isolation
- Implement fair resource sharing
- Provide self-service capabilities
- Monitor and enforce compliance

### 3. Cost Management
- Implement chargeback and showback
- Regular rightsizing exercises
- Optimize for reserved instances/committed use
- Monitor and alert on cost anomalies

### 4. Security
- Zero-trust network architecture
- Regular security updates and patches
- Comprehensive audit logging
- Incident response procedures

## Troubleshooting

### Platform Health Checks
```bash
# Check platform service health
kubectl get pods -n platform-system
kubectl get pods -n istio-system
kubectl get pods -n monitoring

# Verify tenant isolation
kubectl auth can-i create pods --as=system:serviceaccount:tenant-alpha:default -n tenant-beta

# Check cost management
kubectl get metering -A
kubectl logs deployment/kubecost -n cost-management
```

### Performance Monitoring
```bash
# Monitor platform performance
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl get hpa -A

# Check network policies
kubectl get networkpolicy -A
kubectl describe networkpolicy tenant-alpha-isolation -n tenant-alpha
```

## Cleanup
```bash
# Remove platform (use with caution!)
kubectl delete namespace platform-system istio-system monitoring security-system cost-management
kubectl delete crd --all
kubectl delete clusterrole --all
kubectl delete clusterrolebinding --all
```

## Additional Resources
- [CNCF Cloud Native Trail Map](https://github.com/cncf/trailmap)
- [Kubernetes Enterprise Patterns](https://kubernetes.io/docs/concepts/cluster-administration/)
- [Multi-Tenancy Best Practices](https://kubernetes.io/docs/concepts/security/multi-tenancy/)
- [Cost Optimization Guide](https://cloud.google.com/kubernetes-engine/docs/how-to/cost-optimization)
