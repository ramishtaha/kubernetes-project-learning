# Project 13: Machine Learning Pipeline on Kubernetes

## Learning Objectives
- Deploy machine learning workflows on Kubernetes
- Implement MLOps practices with Kubeflow
- Set up model training and serving pipelines
- Configure GPU scheduling for ML workloads
- Manage ML model lifecycle and versioning

## Prerequisites
- Completed Projects 1-12
- Understanding of machine learning concepts
- Basic knowledge of Python and ML frameworks
- Familiarity with data processing workflows

## Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Source   │───▶│   Data Prep     │───▶│   Training      │
│   (Storage)     │    │   Pipeline      │    │   Pipeline      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Model         │    │   Experiment    │    │   Model         │
│   Registry      │    │   Tracking      │    │   Serving       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Implementation Steps

### Step 1: Install Kubeflow
```bash
# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Clone Kubeflow manifests
git clone https://github.com/kubeflow/manifests.git
cd manifests

# Install Kubeflow
while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
```

### Step 2: Set up GPU Support
```bash
kubectl apply -f gpu/
```

### Step 3: Deploy ML Pipeline Components
```bash
kubectl apply -f pipelines/
```

### Step 4: Deploy Sample ML Application
```bash
kubectl apply -f models/
```

## Files Structure
```
13-ml-pipeline/
├── README.md
├── kubeflow/
│   ├── install-kubeflow.sh
│   ├── kustomization.yaml
│   └── manifests/
├── gpu/
│   ├── nvidia-device-plugin.yaml
│   ├── gpu-node-affinity.yaml
│   └── gpu-resource-quota.yaml
├── pipelines/
│   ├── data-preprocessing.yaml
│   ├── training-pipeline.yaml
│   ├── model-evaluation.yaml
│   └── model-deployment.yaml
├── models/
│   ├── tensorflow-serving.yaml
│   ├── pytorch-serving.yaml
│   ├── model-storage.yaml
│   └── inference-service.yaml
├── monitoring/
│   ├── ml-metrics.yaml
│   ├── model-monitoring.yaml
│   └── drift-detection.yaml
└── scripts/
    ├── setup-ml-environment.sh
    ├── train-model.py
    ├── serve-model.py
    └── monitor-pipeline.sh
```

## Key Concepts

### MLOps Pipeline Components
- **Data Ingestion**: Automated data collection and validation
- **Feature Engineering**: Data preprocessing and transformation
- **Model Training**: Distributed training with hyperparameter tuning
- **Model Validation**: Automated testing and validation
- **Model Deployment**: Automated deployment and rollback

### Kubeflow Components
- **Kubeflow Pipelines**: Workflow orchestration
- **Katib**: Hyperparameter tuning and neural architecture search
- **KFServing**: Model serving and inference
- **Training Operators**: Distributed training jobs

### GPU Scheduling
- **Node Selectors**: Schedule pods on GPU nodes
- **Resource Limits**: Manage GPU allocation
- **Fractional GPUs**: Share GPU resources
- **Multi-GPU Training**: Distributed training across GPUs

## Sample ML Pipeline

### Data Preprocessing Pipeline
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: data-preprocessing
spec:
  entrypoint: preprocess-data
  templates:
  - name: preprocess-data
    steps:
    - - name: load-data
        template: load-data-step
    - - name: clean-data
        template: clean-data-step
        arguments:
          artifacts:
          - name: raw-data
            from: "{{steps.load-data.outputs.artifacts.dataset}}"
    - - name: feature-engineering
        template: feature-engineering-step
        arguments:
          artifacts:
          - name: clean-data
            from: "{{steps.clean-data.outputs.artifacts.dataset}}"
  
  - name: load-data-step
    container:
      image: python:3.9
      command: [python]
      source: |
        import pandas as pd
        import os
        
        # Load dataset
        data = pd.read_csv('/data/input/dataset.csv')
        data.to_csv('/data/output/raw_data.csv', index=False)
      volumeMounts:
      - name: data-volume
        mountPath: /data
    outputs:
      artifacts:
      - name: dataset
        path: /data/output/raw_data.csv
```

### Training Pipeline with GPU
```yaml
apiVersion: "kubeflow.org/v1"
kind: PyTorchJob
metadata:
  name: pytorch-distributed-training
spec:
  pytorchReplicaSpecs:
    Master:
      replicas: 1
      restartPolicy: OnFailure
      template:
        spec:
          containers:
          - name: pytorch
            image: pytorch/pytorch:1.12.0-cuda11.3-cudnn8-devel
            command:
            - python
            - /workspace/train.py
            - --epochs=100
            - --batch-size=32
            - --learning-rate=0.001
            resources:
              limits:
                nvidia.com/gpu: 1
              requests:
                nvidia.com/gpu: 1
            volumeMounts:
            - name: model-storage
              mountPath: /workspace/models
            - name: data-storage
              mountPath: /workspace/data
          volumes:
          - name: model-storage
            persistentVolumeClaim:
              claimName: model-storage-pvc
          - name: data-storage
            persistentVolumeClaim:
              claimName: data-storage-pvc
    Worker:
      replicas: 2
      restartPolicy: OnFailure
      template:
        spec:
          containers:
          - name: pytorch
            image: pytorch/pytorch:1.12.0-cuda11.3-cudnn8-devel
            command:
            - python
            - /workspace/train.py
            resources:
              limits:
                nvidia.com/gpu: 1
              requests:
                nvidia.com/gpu: 1
```

## Experiments to Try

### 1. Hyperparameter Tuning with Katib
```yaml
apiVersion: kubeflow.org/v1beta1
kind: Experiment
metadata:
  name: hyperparameter-tuning
spec:
  algorithm:
    algorithmName: random
  objective:
    type: maximize
    objectiveMetricName: accuracy
  parameters:
  - name: learning-rate
    parameterType: double
    feasibleSpace:
      min: "0.001"
      max: "0.1"
  - name: batch-size
    parameterType: int
    feasibleSpace:
      min: "16"
      max: "128"
  trialTemplate:
    primaryContainerName: training-container
    trialSpec:
      apiVersion: batch/v1
      kind: Job
      spec:
        template:
          spec:
            containers:
            - name: training-container
              image: pytorch/pytorch:latest
              command:
              - python
              - train.py
              - --learning-rate={{.HyperParameters.learning-rate}}
              - --batch-size={{.HyperParameters.batch-size}}
```

### 2. Model Serving with KFServing
```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: sklearn-iris
spec:
  predictor:
    sklearn:
      storageUri: gs://your-bucket/sklearn/iris
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 1
          memory: 2Gi
  explainer:
    alibi:
      type: AnchorTabular
      storageUri: gs://your-bucket/explainer/iris
```

### 3. A/B Testing for Models
```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: model-ab-test
spec:
  predictor:
    canaryTrafficPercent: 20
    sklearn:
      storageUri: gs://your-bucket/model-v2
  canary:
    sklearn:
      storageUri: gs://your-bucket/model-v1
```

### 4. Batch Inference Jobs
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-inference
spec:
  template:
    spec:
      containers:
      - name: inference
        image: tensorflow/serving:2.8.0
        command:
        - python
        - batch_inference.py
        - --model-path=/models/saved_model
        - --input-data=/data/batch_input.csv
        - --output-data=/data/batch_output.csv
        volumeMounts:
        - name: model-storage
          mountPath: /models
        - name: data-storage
          mountPath: /data
      restartPolicy: Never
```

## Advanced Features

### 1. MLflow Integration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mlflow-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mlflow-server
  template:
    metadata:
      labels:
        app: mlflow-server
    spec:
      containers:
      - name: mlflow
        image: python:3.8
        command:
        - sh
        - -c
        - |
          pip install mlflow psycopg2-binary boto3
          mlflow server \
            --backend-store-uri postgresql://user:pass@postgres:5432/mlflow \
            --default-artifact-root s3://mlflow-artifacts/ \
            --host 0.0.0.0 \
            --port 5000
        ports:
        - containerPort: 5000
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: s3-credentials
              key: access-key
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: s3-credentials
              key: secret-key
```

### 2. Feature Store with Feast
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: feast-serving
spec:
  replicas: 1
  selector:
    matchLabels:
      app: feast-serving
  template:
    metadata:
      labels:
        app: feast-serving
    spec:
      containers:
      - name: feast
        image: feastdev/feast-serving:0.10.0
        ports:
        - containerPort: 6566
        env:
        - name: FEAST_CORE_URL
          value: "feast-core:6565"
        - name: FEAST_STORE_CONFIG_PATH
          value: "/feast/store.yaml"
        volumeMounts:
        - name: feast-config
          mountPath: /feast
      volumes:
      - name: feast-config
        configMap:
          name: feast-config
```

### 3. Model Monitoring and Drift Detection
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: model-monitor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: model-monitor
  template:
    metadata:
      labels:
        app: model-monitor
    spec:
      containers:
      - name: monitor
        image: python:3.9
        command:
        - python
        - monitor.py
        env:
        - name: MODEL_ENDPOINT
          value: "http://sklearn-iris-predictor:8080"
        - name: DRIFT_THRESHOLD
          value: "0.1"
        - name: CHECK_INTERVAL
          value: "300"
        volumeMounts:
        - name: monitoring-data
          mountPath: /data
```

## Troubleshooting

### Common Issues

1. **GPU allocation failures**
   ```bash
   # Check GPU availability
   kubectl describe nodes | grep -A 10 Capacity
   
   # Check GPU device plugin
   kubectl get daemonset nvidia-device-plugin-daemonset -n kube-system
   
   # Verify GPU drivers
   kubectl exec -it <gpu-pod> -- nvidia-smi
   ```

2. **Pipeline execution failures**
   ```bash
   # Check pipeline status
   kubectl get workflows
   kubectl describe workflow <workflow-name>
   
   # Check logs
   kubectl logs <pod-name> -c <container-name>
   ```

3. **Model serving issues**
   ```bash
   # Check inference service status
   kubectl get inferenceservice
   kubectl describe inferenceservice <service-name>
   
   # Test model endpoint
   curl -X POST http://<service-url>/v1/models/<model-name>:predict -d '{"instances": [...]}'
   ```

### Performance Optimization

1. **GPU Utilization**
   ```bash
   # Monitor GPU usage
   kubectl exec -it <gpu-pod> -- watch nvidia-smi
   
   # Use fractional GPUs for smaller workloads
   resources:
     limits:
       nvidia.com/gpu: 0.5
   ```

2. **Data Pipeline Optimization**
   ```bash
   # Use parallel data loading
   volumeMounts:
   - name: data-cache
     mountPath: /cache
   
   # Implement data caching
   initContainers:
   - name: data-prefetch
     image: busybox
     command: ['sh', '-c', 'cp /data/* /cache/']
   ```

## Security Considerations

### 1. Model Security
```yaml
# Secure model storage
apiVersion: v1
kind: Secret
metadata:
  name: model-credentials
type: Opaque
data:
  access-key: <base64-encoded-key>
  secret-key: <base64-encoded-secret>
```

### 2. Network Policies for ML Workloads
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ml-pipeline-network-policy
spec:
  podSelector:
    matchLabels:
      app: ml-pipeline
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ml-client
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: data-storage
```

### 3. RBAC for ML Operations
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ml-operator
rules:
- apiGroups: ["kubeflow.org"]
  resources: ["pytorchjobs", "tfjobs", "experiments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

## Best Practices

### 1. Resource Management
- Set appropriate resource requests and limits
- Use node affinity for GPU workloads
- Implement resource quotas for different teams
- Monitor resource utilization

### 2. Data Management
- Implement data versioning
- Use efficient data formats (Parquet, TFRecord)
- Implement data validation pipelines
- Cache frequently accessed data

### 3. Model Lifecycle
- Version control for models and code
- Automated testing for model quality
- Gradual rollout strategies
- Model performance monitoring

### 4. Monitoring and Observability
- Track model performance metrics
- Monitor data drift and model drift
- Implement alerting for model degradation
- Log prediction requests and responses

## Next Steps
- Implement advanced AutoML pipelines
- Set up multi-cloud ML deployments
- Integrate with streaming data sources
- Implement federated learning

## Cleanup
```bash
# Remove Kubeflow
kubectl delete -k manifests/example

# Remove GPU resources
kubectl delete -f gpu/

# Remove ML pipelines
kubectl delete -f pipelines/

# Remove models
kubectl delete -f models/
```

## Additional Resources
- [Kubeflow Documentation](https://www.kubeflow.org/docs/)
- [KFServing Documentation](https://kserve.github.io/website/)
- [MLflow on Kubernetes](https://mlflow.org/docs/latest/deployment.html#deploy-mlflow-on-kubernetes)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html)
