@echo off
REM Project 1: Hello Kubernetes - Windows Deployment Script
REM This script automates the deployment process for the Hello Kubernetes project

echo 🚀 Starting Hello Kubernetes Deployment...

REM Check if kubectl is available
kubectl version --client >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ kubectl is not installed or not in PATH
    exit /b 1
)

REM Check cluster connectivity
echo 🔍 Checking cluster connectivity...
kubectl cluster-info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Cannot connect to Kubernetes cluster
    echo Please ensure your cluster is running and kubectl is configured correctly
    exit /b 1
)

echo ✅ Connected to cluster successfully

REM Deploy resources
echo 📦 Deploying resources...

echo   - Creating Pod...
kubectl apply -f manifests/01-pod.yaml

echo   - Creating Deployment...
kubectl apply -f manifests/02-deployment.yaml

echo   - Creating Service...
kubectl apply -f manifests/03-service.yaml

REM Wait for deployment to be ready
echo ⏳ Waiting for deployment to be ready...
kubectl rollout status deployment/hello-deployment --timeout=300s

REM Show status
echo 📊 Current status:
echo.
echo Pods:
kubectl get pods -l app=hello-kubernetes

echo.
echo Deployment:
kubectl get deployment hello-deployment

echo.
echo Service:
kubectl get service hello-service

REM Get access URL
echo.
echo 🌐 Access your application:

REM Check if minikube is available
minikube status >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Minikube detected. Get the URL with:
    echo   minikube service hello-service --url
    echo.
    echo Or run this command to open in browser:
    echo   minikube service hello-service
) else (
    for /f "tokens=*" %%i in ('kubectl get service hello-service -o jsonpath^="{.spec.ports[0].nodePort}"') do set NODE_PORT=%%i
    echo Access via NodePort: http://^<node-ip^>:%NODE_PORT%
    echo Get node IP with: kubectl get nodes -o wide
)

echo.
echo ✅ Deployment completed successfully!
echo.
echo 🔍 Useful commands to explore:
echo   kubectl get pods -l app=hello-kubernetes
echo   kubectl logs -l app=hello-kubernetes
echo   kubectl describe deployment hello-deployment
echo   kubectl describe service hello-service

pause
