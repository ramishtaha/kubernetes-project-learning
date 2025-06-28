# Project 12: Custom Controllers and Operators

## Learning Objectives
- Build custom Kubernetes controllers
- Create Custom Resource Definitions (CRDs)
- Implement the controller pattern
- Develop Kubernetes operators
- Understand the operator lifecycle management

## Prerequisites
- Completed Projects 1-11
- Go programming language basics
- Understanding of Kubernetes API concepts
- Knowledge of controller patterns

## Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Custom API     │───▶│   Controller    │───▶│   Managed       │
│  (CRD)          │    │   (Operator)    │    │   Resources     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Custom         │    │   Event         │    │   Reconcile     │
│  Resources      │    │   Watching      │    │   Loop          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Implementation Steps

### Step 1: Set up Development Environment
```bash
# Install required tools
go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest
go install sigs.k8s.io/kustomize/kustomize/v4@latest

# Initialize project
mkdir webapp-operator
cd webapp-operator
go mod init webapp-operator
```

### Step 2: Create Custom Resource Definition
```bash
kubectl apply -f crds/
```

### Step 3: Implement Controller Logic
```bash
# Build and deploy controller
make docker-build docker-push IMG=your-registry/webapp-operator:latest
make deploy IMG=your-registry/webapp-operator:latest
```

### Step 4: Test Operator Functionality
```bash
kubectl apply -f samples/
```

## Files Structure
```
12-custom-controllers/
├── README.md
├── webapp-operator/
│   ├── api/
│   │   └── v1/
│   │       ├── webapp_types.go
│   │       └── zz_generated.deepcopy.go
│   ├── controllers/
│   │   └── webapp_controller.go
│   ├── config/
│   │   ├── crd/
│   │   ├── rbac/
│   │   ├── manager/
│   │   └── samples/
│   ├── Dockerfile
│   ├── Makefile
│   ├── main.go
│   └── go.mod
├── crds/
│   └── webapp-crd.yaml
├── samples/
│   ├── webapp-simple.yaml
│   ├── webapp-complex.yaml
│   └── webapp-with-database.yaml
└── scripts/
    ├── setup-operator-sdk.sh
    ├── build-operator.sh
    └── test-operator.sh
```

## Key Concepts

### Custom Resource Definitions (CRDs)
- **Schema Definition**: OpenAPI v3 schema validation
- **Versions**: Multiple API versions support
- **Subresources**: Status and scale subresources
- **Conversion**: Webhook-based version conversion

### Controller Pattern
- **Reconcile Loop**: Desired vs actual state
- **Event Watching**: React to resource changes
- **Work Queues**: Efficient event processing
- **Error Handling**: Retry mechanisms

### Operator Patterns
- **Basic Operator**: Simple resource management
- **Advanced Operator**: Complex lifecycle management
- **Lifecycle Management**: Install, update, backup, restore
- **Capability Levels**: Level 1-5 operator maturity

## Sample Custom Resource

```go
// WebApp custom resource definition
type WebApp struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`
    
    Spec   WebAppSpec   `json:"spec,omitempty"`
    Status WebAppStatus `json:"status,omitempty"`
}

type WebAppSpec struct {
    Image    string            `json:"image"`
    Replicas *int32            `json:"replicas,omitempty"`
    Port     int32             `json:"port,omitempty"`
    Env      map[string]string `json:"env,omitempty"`
    Database *DatabaseSpec     `json:"database,omitempty"`
}

type WebAppStatus struct {
    Conditions []metav1.Condition `json:"conditions,omitempty"`
    Replicas   int32              `json:"replicas"`
    ReadyReplicas int32           `json:"readyReplicas"`
}
```

## Controller Implementation

```go
// WebApp controller reconcile logic
func (r *WebAppReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := r.Log.WithValues("webapp", req.NamespacedName)
    
    // Fetch the WebApp instance
    webapp := &webappv1.WebApp{}
    err := r.Get(ctx, req.NamespacedName, webapp)
    if err != nil {
        if errors.IsNotFound(err) {
            return ctrl.Result{}, nil
        }
        return ctrl.Result{}, err
    }
    
    // Reconcile Deployment
    if err := r.reconcileDeployment(ctx, webapp); err != nil {
        return ctrl.Result{}, err
    }
    
    // Reconcile Service
    if err := r.reconcileService(ctx, webapp); err != nil {
        return ctrl.Result{}, err
    }
    
    // Update status
    return ctrl.Result{}, r.updateStatus(ctx, webapp)
}
```

## Experiments to Try

### 1. Basic WebApp Operator
```yaml
# Simple web application
apiVersion: webapp.example.com/v1
kind: WebApp
metadata:
  name: simple-webapp
spec:
  image: nginx:latest
  replicas: 3
  port: 80
```

### 2. Complex Application with Database
```yaml
# Web application with database
apiVersion: webapp.example.com/v1
kind: WebApp
metadata:
  name: complex-webapp
spec:
  image: myapp:v1.0.0
  replicas: 5
  port: 8080
  env:
    ENV: production
    DEBUG: "false"
  database:
    type: postgresql
    size: 10Gi
    version: "13"
```

### 3. Operator Testing
```bash
# Create test instances
kubectl apply -f samples/webapp-simple.yaml

# Verify reconciliation
kubectl get webapp simple-webapp -o yaml

# Check managed resources
kubectl get deployment,service -l app.kubernetes.io/managed-by=webapp-operator
```

### 4. Operator Upgrade Testing
```bash
# Update operator image
kubectl patch deployment webapp-operator-controller-manager -p '{"spec":{"template":{"spec":{"containers":[{"name":"manager","image":"webapp-operator:v2.0.0"}]}}}}'

# Test backward compatibility
kubectl get webapp --all-namespaces
```

## Advanced Features

### 1. Finalizers and Cleanup
```go
// Add finalizer for cleanup
const webappFinalizer = "webapp.example.com/finalizer"

func (r *WebAppReconciler) handleFinalizer(ctx context.Context, webapp *webappv1.WebApp) error {
    if webapp.ObjectMeta.DeletionTimestamp.IsZero() {
        // Add finalizer if not present
        if !controllerutil.ContainsFinalizer(webapp, webappFinalizer) {
            controllerutil.AddFinalizer(webapp, webappFinalizer)
            return r.Update(ctx, webapp)
        }
    } else {
        // Handle deletion
        if controllerutil.ContainsFinalizer(webapp, webappFinalizer) {
            if err := r.cleanupResources(ctx, webapp); err != nil {
                return err
            }
            controllerutil.RemoveFinalizer(webapp, webappFinalizer)
            return r.Update(ctx, webapp)
        }
    }
    return nil
}
```

### 2. Status Conditions
```go
// Update status with conditions
func (r *WebAppReconciler) updateStatus(ctx context.Context, webapp *webappv1.WebApp) error {
    deployment := &appsv1.Deployment{}
    err := r.Get(ctx, types.NamespacedName{
        Name:      webapp.Name,
        Namespace: webapp.Namespace,
    }, deployment)
    
    if err != nil {
        meta.SetStatusCondition(&webapp.Status.Conditions, metav1.Condition{
            Type:    "Ready",
            Status:  metav1.ConditionFalse,
            Reason:  "DeploymentNotFound",
            Message: "Deployment not found",
        })
    } else {
        webapp.Status.Replicas = deployment.Status.Replicas
        webapp.Status.ReadyReplicas = deployment.Status.ReadyReplicas
        
        if deployment.Status.ReadyReplicas == deployment.Status.Replicas {
            meta.SetStatusCondition(&webapp.Status.Conditions, metav1.Condition{
                Type:    "Ready",
                Status:  metav1.ConditionTrue,
                Reason:  "DeploymentReady",
                Message: "All replicas are ready",
            })
        }
    }
    
    return r.Status().Update(ctx, webapp)
}
```

### 3. Webhooks and Validation
```go
// Admission webhook for validation
func (w *WebAppWebhook) ValidateCreate(ctx context.Context, obj runtime.Object) error {
    webapp := obj.(*webappv1.WebApp)
    
    if webapp.Spec.Replicas != nil && *webapp.Spec.Replicas < 1 {
        return fmt.Errorf("replicas must be greater than 0")
    }
    
    if webapp.Spec.Port < 1 || webapp.Spec.Port > 65535 {
        return fmt.Errorf("port must be between 1 and 65535")
    }
    
    return nil
}
```

## Testing Strategies

### 1. Unit Testing
```go
func TestWebAppController_Reconcile(t *testing.T) {
    scheme := runtime.NewScheme()
    _ = webappv1.AddToScheme(scheme)
    _ = appsv1.AddToScheme(scheme)
    _ = corev1.AddToScheme(scheme)
    
    webapp := &webappv1.WebApp{
        ObjectMeta: metav1.ObjectMeta{
            Name:      "test-webapp",
            Namespace: "default",
        },
        Spec: webappv1.WebAppSpec{
            Image:    "nginx:latest",
            Replicas: &[]int32{3}[0],
            Port:     80,
        },
    }
    
    client := fake.NewClientBuilder().WithScheme(scheme).WithObjects(webapp).Build()
    
    reconciler := &WebAppReconciler{
        Client: client,
        Scheme: scheme,
    }
    
    _, err := reconciler.Reconcile(context.TODO(), ctrl.Request{
        NamespacedName: types.NamespacedName{
            Name:      "test-webapp",
            Namespace: "default",
        },
    })
    
    assert.NoError(t, err)
}
```

### 2. Integration Testing
```bash
# Run tests against real cluster
make test-integration

# E2E testing with kind
kind create cluster --name operator-test
make deploy IMG=webapp-operator:test
kubectl apply -f config/samples/
kubectl wait --for=condition=Ready webapp/webapp-sample --timeout=300s
```

### 3. Performance Testing
```bash
# Scale testing
for i in {1..100}; do
  kubectl apply -f - <<EOF
apiVersion: webapp.example.com/v1
kind: WebApp
metadata:
  name: webapp-$i
spec:
  image: nginx:latest
  replicas: 1
  port: 80
EOF
done

# Monitor controller performance
kubectl top pod -n webapp-operator-system
```

## Operator Lifecycle Management

### 1. Operator Hub Integration
```yaml
# ClusterServiceVersion for OLM
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  name: webapp-operator.v1.0.0
spec:
  displayName: WebApp Operator
  description: Manages web applications on Kubernetes
  version: 1.0.0
  maturity: alpha
  provider:
    name: Example Corp
  installModes:
  - type: OwnNamespace
    supported: true
  - type: SingleNamespace
    supported: true
  - type: MultiNamespace
    supported: false
  - type: AllNamespaces
    supported: true
```

### 2. Operator Metrics
```go
// Prometheus metrics for operator
var (
    webappsTotal = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "webapp_operator_webapps_total",
            Help: "Total number of WebApp resources",
        },
        []string{"namespace"},
    )
    
    reconcileErrors = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "webapp_operator_reconcile_errors_total",
            Help: "Total number of reconcile errors",
        },
        []string{"controller"},
    )
)
```

### 3. Operator Security
```yaml
# RBAC for operator
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: webapp-operator-manager-role
rules:
- apiGroups:
  - webapp.example.com
  resources:
  - webapps
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - webapp.example.com
  resources:
  - webapps/status
  verbs:
  - get
  - patch
  - update
```

## Troubleshooting

### Common Issues

1. **CRD registration failures**
   ```bash
   # Check CRD status
   kubectl get crd webapps.webapp.example.com -o yaml
   
   # Validate CRD schema
   kubectl apply --dry-run=server -f config/crd/bases/webapp.example.com_webapps.yaml
   ```

2. **Controller not reconciling**
   ```bash
   # Check controller logs
   kubectl logs -n webapp-operator-system deployment/webapp-operator-controller-manager
   
   # Verify RBAC permissions
   kubectl auth can-i create deployments --as=system:serviceaccount:webapp-operator-system:webapp-operator-controller-manager
   ```

3. **Resource creation failures**
   ```bash
   # Check events
   kubectl get events --sort-by='.lastTimestamp'
   
   # Debug resource status
   kubectl describe webapp webapp-name
   ```

## Best Practices

### 1. Controller Design
- Keep reconcile logic idempotent
- Handle partial failures gracefully
- Use proper error handling and retries
- Implement proper cleanup with finalizers

### 2. CRD Design
- Use semantic versioning for API versions
- Provide comprehensive validation schemas
- Include helpful descriptions and examples
- Plan for future extensibility

### 3. Testing
- Write comprehensive unit tests
- Include integration tests
- Test upgrade scenarios
- Validate edge cases

## Next Steps
- Implement advanced operator patterns
- Add multi-tenancy support
- Integrate with service mesh
- Develop operator marketplace listing

## Cleanup
```bash
# Remove custom resources
kubectl delete webapp --all

# Remove operator
make undeploy

# Remove CRDs
kubectl delete crd webapps.webapp.example.com
```

## Additional Resources
- [Kubebuilder Documentation](https://book.kubebuilder.io/)
- [Operator SDK Documentation](https://sdk.operatorframework.io/)
- [Kubernetes API Concepts](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/)
- [Controller Runtime](https://pkg.go.dev/sigs.k8s.io/controller-runtime)
