#!/bin/bash

echo "🧹 Cleaning up Configuration Management Demo..."

# Delete all resources
kubectl delete namespace config-management

echo "✅ Cleanup complete!"
