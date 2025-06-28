#!/bin/bash

echo "🆘 Simulating disaster and recovery scenarios..."

NAMESPACE="disaster-recovery"

echo "📋 Available disaster scenarios:"
echo "1. Pod failure (delete pods)"
echo "2. Data corruption (delete PVC data)"
echo "3. Configuration loss (delete ConfigMap)"
echo "4. Complete application failure (delete deployment)"
echo ""

read -p "Select scenario (1-4): " scenario

case $scenario in
    1)
        echo "💥 Simulating pod failure..."
        kubectl delete pods -l app=critical-app -n $NAMESPACE
        echo "⏳ Waiting for automatic recovery..."
        kubectl wait --for=condition=ready pod -l app=critical-app -n $NAMESPACE --timeout=120s
        echo "✅ Pods recovered automatically!"
        ;;
    2)
        echo "💥 Simulating data corruption..."
        echo "⚠️  In real scenario, you would restore from Velero backup"
        echo "kubectl get backup -n velero"
        echo "velero restore create --from-backup <backup-name>"
        ;;
    3)
        echo "💥 Simulating configuration loss..."
        kubectl delete configmap app-config -n $NAMESPACE
        echo "🔄 Restoring configuration..."
        kubectl apply -f manifests/03-app-config.yaml
        echo "✅ Configuration restored!"
        ;;
    4)
        echo "💥 Simulating complete application failure..."
        kubectl delete deployment critical-app -n $NAMESPACE
        echo "🔄 Restoring application..."
        kubectl apply -f manifests/02-critical-app.yaml
        kubectl wait --for=condition=available --timeout=120s deployment/critical-app -n $NAMESPACE
        echo "✅ Application restored!"
        ;;
    *)
        echo "❌ Invalid scenario selected"
        exit 1
        ;;
esac

echo ""
echo "🔍 Check recovery status:"
echo "kubectl get all -n $NAMESPACE"
