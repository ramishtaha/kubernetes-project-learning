#!/bin/bash
# K3s installation script for edge nodes

echo "🚀 Installing K3s for Edge Computing..."

# Set K3s version
K3S_VERSION=${K3S_VERSION:-"v1.28.2+k3s1"}

# Installation options
INSTALL_OPTIONS=""

# Check if this is a server or agent node
if [ "$K3S_ROLE" = "server" ]; then
    echo "📡 Setting up K3s server node..."
    INSTALL_OPTIONS="--write-kubeconfig-mode 644 --disable traefik --disable servicelb"
    
    if [ -n "$K3S_CLUSTER_SECRET" ]; then
        INSTALL_OPTIONS="$INSTALL_OPTIONS --token $K3S_CLUSTER_SECRET"
    fi
    
    # Edge-specific configurations
    INSTALL_OPTIONS="$INSTALL_OPTIONS --node-label edge-role=server"
    INSTALL_OPTIONS="$INSTALL_OPTIONS --node-label hardware-type=${HARDWARE_TYPE:-unknown}"
    
elif [ "$K3S_ROLE" = "agent" ]; then
    echo "🔌 Setting up K3s agent node..."
    
    if [ -z "$K3S_SERVER_URL" ] || [ -z "$K3S_TOKEN" ]; then
        echo "❌ K3S_SERVER_URL and K3S_TOKEN must be set for agent nodes"
        exit 1
    fi
    
    INSTALL_OPTIONS="--server $K3S_SERVER_URL --token $K3S_TOKEN"
    INSTALL_OPTIONS="$INSTALL_OPTIONS --node-label edge-role=agent"
    INSTALL_OPTIONS="$INSTALL_OPTIONS --node-label hardware-type=${HARDWARE_TYPE:-unknown}"
    INSTALL_OPTIONS="$INSTALL_OPTIONS --node-label location=${EDGE_LOCATION:-unknown}"
else
    echo "❌ K3S_ROLE must be set to 'server' or 'agent'"
    exit 1
fi

# Download and install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh -s - $INSTALL_OPTIONS

# Wait for K3s to be ready
echo "⏳ Waiting for K3s to be ready..."
sleep 30

if [ "$K3S_ROLE" = "server" ]; then
    # Configure kubectl for the user
    mkdir -p $HOME/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    echo "✅ K3s server node ready!"
    echo "🔑 Node token: $(sudo cat /var/lib/rancher/k3s/server/node-token)"
    echo "📡 Server URL: https://$(hostname -I | awk '{print $1}'):6443"
    
    # Install edge-specific components
    echo "🔧 Installing edge components..."
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
    
else
    echo "✅ K3s agent node ready!"
fi

echo "📊 Node status:"
kubectl get nodes -o wide

echo "🎯 Installation complete!"
