#!/bin/bash

echo "🚀 Deploying CI/CD Pipeline..."

# Create namespace
kubectl apply -f manifests/01-namespace.yaml

# Deploy Jenkins RBAC
kubectl apply -f jenkins/jenkins-rbac.yaml

# Deploy Jenkins
kubectl apply -f jenkins/jenkins-deployment.yaml

echo "Waiting for Jenkins to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/jenkins -n cicd

# Get Jenkins admin password
echo "📋 Getting Jenkins admin password..."
sleep 30
JENKINS_PASSWORD=$(kubectl get secret jenkins-admin-password -n cicd -o jsonpath="{.data.password}" | base64 -d)

echo "✅ CI/CD Pipeline deployment complete!"
echo ""
echo "📋 Access Jenkins:"
echo "kubectl port-forward -n cicd svc/jenkins-service 8080:8080"
echo "Then visit: http://localhost:8080"
echo "Username: admin"
echo "Password: ${JENKINS_PASSWORD}"
echo ""
echo "🔍 Check CI/CD resources:"
echo "kubectl get all -n cicd"
echo ""
echo "📝 Next steps:"
echo "1. Configure Jenkins plugins"
echo "2. Setup Git repositories"
echo "3. Create CI/CD pipelines"
echo "4. Install ArgoCD: kubectl apply -f argocd/"
