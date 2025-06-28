#!/bin/bash

echo "🧹 Cleaning up Database Integration Application..."

# Delete all resources in the namespace
kubectl delete all --all -n database-app

# Delete PVCs
kubectl delete pvc --all -n database-app

# Delete the namespace
kubectl delete namespace database-app

echo "✅ Database integration application cleanup completed!"
