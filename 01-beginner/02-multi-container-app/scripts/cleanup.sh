#!/bin/bash

echo "🧹 Cleaning up Multi-Container Application..."

# Delete all resources in the namespace
kubectl delete all --all -n multi-container-app

# Delete the namespace
kubectl delete namespace multi-container-app

echo "✅ Multi-container application cleanup completed!"
