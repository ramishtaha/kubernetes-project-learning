#!/bin/bash

echo "🚀 Deploying ML Pipeline..."

# Create namespace
kubectl apply -f manifests/01-namespace.yaml

# Deploy ML scripts
kubectl apply -f manifests/04-ml-scripts.yaml

# Deploy Jupyter notebook
kubectl apply -f jupyter/jupyter-deployment.yaml

echo "Waiting for Jupyter to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/jupyter-notebook -n ml-pipeline

# Run data preprocessing job
echo "🔄 Starting data preprocessing..."
kubectl apply -f manifests/02-ml-jobs.yaml

# Wait for preprocessing to complete
echo "Waiting for data preprocessing to complete..."
kubectl wait --for=condition=complete --timeout=600s job/data-preprocessing -n ml-pipeline

# Run model training job
echo "🏋️ Starting model training..."
kubectl patch job model-training -n ml-pipeline -p '{"metadata":{"name":"model-training-'$(date +%s)'"}}'
kubectl apply -f manifests/02-ml-jobs.yaml

echo "Waiting for model training to complete..."
kubectl wait --for=condition=complete --timeout=1200s job/model-training -n ml-pipeline

# Deploy model serving
echo "🚀 Deploying model serving..."
kubectl apply -f manifests/03-model-serving.yaml

echo "Waiting for model serving to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/model-serving -n ml-pipeline

echo "✅ ML Pipeline deployment complete!"
echo ""
echo "📋 Access services:"
echo "# Jupyter Notebook"
echo "kubectl port-forward -n ml-pipeline svc/jupyter-service 8888:8888"
echo "Token: kubernetes-ml-demo"
echo ""
echo "# Model Serving API"
echo "kubectl port-forward -n ml-pipeline svc/model-serving-service 8501:8501"
echo ""
echo "🔍 Monitor ML jobs:"
echo "kubectl get jobs -n ml-pipeline"
echo "kubectl logs job/data-preprocessing -n ml-pipeline"
echo "kubectl logs job/model-training -n ml-pipeline"
echo ""
echo "📊 Check model serving:"
echo "kubectl get pods -n ml-pipeline"
echo "kubectl get hpa -n ml-pipeline"
echo ""
echo "🧪 Test model prediction:"
echo 'curl -X POST http://localhost:8501/v1/models/my_model:predict \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"instances": [[1.0, 2.0, 0.5, -1.0]]}'"'"
