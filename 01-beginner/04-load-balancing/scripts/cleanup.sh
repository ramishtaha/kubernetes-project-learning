#!/bin/bash

echo "🧹 Cleaning up Load Balancing Demo..."

# Delete all resources
kubectl delete namespace load-balancing

echo "✅ Cleanup complete!"
