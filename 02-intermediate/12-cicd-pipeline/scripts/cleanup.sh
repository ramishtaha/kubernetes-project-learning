#!/bin/bash

echo "🧹 Cleaning up CI/CD Pipeline..."

# Delete all resources
kubectl delete namespace cicd

echo "✅ Cleanup complete!"
