#!/bin/bash

# OpenTelemetry Demo K3d Cluster Setup Script
set -e

CLUSTER_NAME="otel-demo"
DEFAULT_PORT=8080

echo "🚀 Setting up K3d cluster for OpenTelemetry Demo..."

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1  # Port is in use
    else
        return 0  # Port is available
    fi
}

# Function to find available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    
    while [ $port -le $((start_port + 100)) ]; do
        if check_port $port; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo "❌ Could not find available port starting from $start_port"
    exit 1
}

# Find available port
AVAILABLE_PORT=$(find_available_port $DEFAULT_PORT)
K3D_PORT_MAPPING="$AVAILABLE_PORT:80@loadbalancer"

if [ $AVAILABLE_PORT -ne $DEFAULT_PORT ]; then
    echo "⚠️  Port $DEFAULT_PORT is in use, using port $AVAILABLE_PORT instead"
fi

# Check if k3d is installed
if ! command -v k3d &> /dev/null; then
    echo "❌ k3d is not installed. Please install k3d first:"
    echo "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed. Please install helm first."
    exit 1
fi

# Delete existing cluster if it exists
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "🗑️  Deleting existing cluster: $CLUSTER_NAME"
    k3d cluster delete "$CLUSTER_NAME"
fi

# Create K3d cluster with port forwarding for web access
echo "🛠️  Creating K3d cluster: $CLUSTER_NAME"
k3d cluster create "$CLUSTER_NAME" \
    --port "$K3D_PORT_MAPPING" \
    --agents 2 \
    --wait

# Verify cluster is running
echo "✅ Verifying cluster status..."
kubectl cluster-info
kubectl get nodes

echo "🎉 K3d cluster '$CLUSTER_NAME' is ready!"
echo "📝 Cluster will be accessible via: http://localhost:$AVAILABLE_PORT"

# Save the port for use by other scripts
echo "$AVAILABLE_PORT" > .demo-port