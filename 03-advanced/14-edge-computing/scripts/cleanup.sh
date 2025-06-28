#!/bin/bash

echo "🧹 Cleaning up Edge Computing Demo..."

# Delete all resources
kubectl delete namespace edge-computing

echo "✅ Cleanup complete!"
