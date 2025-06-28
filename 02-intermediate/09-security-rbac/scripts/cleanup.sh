#!/bin/bash

echo "🧹 Cleaning up Security & RBAC Demo..."

# Delete application resources
kubectl delete -f manifests/ --ignore-not-found=true

# Delete security policies
kubectl delete -f security/ --ignore-not-found=true

# Delete RBAC resources
kubectl delete -f rbac/ --ignore-not-found=true

# Delete namespace
kubectl delete namespace secure-app --ignore-not-found=true

echo "✅ Security & RBAC demo cleanup completed!"
