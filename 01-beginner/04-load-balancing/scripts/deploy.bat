@echo off
echo 🚀 Deploying Load Balancing Demo...

echo Creating namespace...
kubectl apply -f manifests/01-namespace.yaml

echo Creating ConfigMap...
kubectl apply -f manifests/03-configmap.yaml

echo Creating deployment...
kubectl apply -f manifests/02-deployment.yaml

echo Creating services...
kubectl apply -f manifests/04-services.yaml

echo Creating ingress...
kubectl apply -f manifests/05-ingress.yaml

echo Waiting for deployment to be ready...
kubectl wait --for=condition=available --timeout=300s deployment/web-app -n load-balancing

echo ✅ Deployment complete!
echo.
echo 📋 Access methods:
echo 1. ClusterIP: kubectl port-forward -n load-balancing svc/web-service 8080:80
echo 2. NodePort: http://localhost:30080 (minikube: minikube service web-nodeport -n load-balancing)
echo 3. LoadBalancer: kubectl get svc web-loadbalancer -n load-balancing
echo 4. Ingress: Add '127.0.0.1 web-app.local' to hosts file, then visit http://web-app.local
echo.
echo 🔍 Check status:
echo kubectl get all -n load-balancing
