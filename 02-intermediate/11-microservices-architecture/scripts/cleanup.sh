#!/bin/bash

echo "🧹 Cleaning up Microservices Architecture Demo..."

# Delete all resources
kubectl delete namespace microservices

echo "✅ Cleanup complete!"
