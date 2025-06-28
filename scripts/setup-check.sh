#!/bin/bash

echo "🚀 Kubernetes Project-Based Learning Setup"
echo "=========================================="

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    echo "   Installation guide: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo "✅ kubectl is installed"

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ No Kubernetes cluster found. Please set up a cluster first."
    echo ""
    echo "📖 Quick setup options:"
    echo "   - Local: docs/setup/minikube.md"
    echo "   - AWS: docs/setup/eks.md"
    echo "   - Google Cloud: docs/setup/gke.md"
    echo "   - Azure: docs/setup/aks.md"
    exit 1
fi

echo "✅ Kubernetes cluster is accessible"

# Display cluster info
echo ""
echo "🔍 Cluster Information:"
kubectl cluster-info

echo ""
echo "📊 Cluster Nodes:"
kubectl get nodes

echo ""
echo "🎯 Ready to start learning!"
echo ""
echo "📚 Recommended learning path:"
echo "   1. Start with: 01-beginner/01-hello-kubernetes/"
echo "   2. Follow the projects in order"
echo "   3. Read each project's README.md for detailed instructions"
echo ""
echo "🛠️ Useful commands:"
echo "   - Deploy a project: cd <project-dir> && ./scripts/deploy.sh"
echo "   - Clean up: cd <project-dir> && ./scripts/cleanup.sh"
echo "   - Check completeness: ./scripts/check-completeness.sh"
echo ""
echo "💡 Need help? Check docs/FAQ.md for common questions"
echo ""
echo "Happy learning! 🎉"
