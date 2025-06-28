#!/bin/bash

echo "🚀 Setting up Disaster Recovery Demo..."

# Install Velero (requires cloud provider setup)
echo "📦 Installing Velero..."
echo "Note: This requires cloud provider configuration for object storage"
echo "For demo purposes, we'll create the resources that would work with Velero"

# Create namespace
kubectl apply -f manifests/01-namespace.yaml

# Setup storage
kubectl apply -f storage/storage-class.yaml

# Deploy the critical application
kubectl apply -f manifests/03-app-config.yaml
kubectl apply -f manifests/02-critical-app.yaml

echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/critical-app -n disaster-recovery

echo "✅ Deployment complete!"
echo ""
echo "📋 Access the application:"
echo "kubectl port-forward -n disaster-recovery svc/critical-app-service 8080:80"
echo "Then visit: http://localhost:8080"
echo ""
echo "🔍 Check backup status:"
echo "kubectl get all -n disaster-recovery"
echo "kubectl get pvc -n disaster-recovery"
echo ""
echo "📝 To setup Velero for real backups:"
echo "1. Install Velero CLI: https://velero.io/docs/v1.9/basic-install/"
echo "2. Configure cloud storage (AWS S3, Azure Blob, GCS)"
echo "3. Install Velero in cluster: velero install --provider <provider>"
echo "4. Apply backup schedule: kubectl apply -f velero/backup-schedule.yaml"
