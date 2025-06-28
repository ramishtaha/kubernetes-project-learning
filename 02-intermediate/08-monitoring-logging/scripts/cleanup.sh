#!/bin/bash

echo "🧹 Cleaning up Monitoring & Logging Stack..."

# Delete all resources in the monitoring namespace
kubectl delete all --all -n monitoring

# Delete PVCs
kubectl delete pvc --all -n monitoring

# Delete config maps and secrets
kubectl delete configmap --all -n monitoring
kubectl delete secret --all -n monitoring

# Delete the namespace
kubectl delete namespace monitoring

echo "✅ Monitoring & Logging stack cleanup completed!"
