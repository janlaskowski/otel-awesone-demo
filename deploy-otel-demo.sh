#!/bin/bash

# OpenTelemetry Demo Deployment Script with Multi-Backend Setup
set -e

CLUSTER_NAME="otel-demo"
OTEL_NAMESPACE="otel-demo"
SIGNOZ_NAMESPACE="signoz"

echo "🚀 Starting OpenTelemetry Demo deployment with multi-backend setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to wait for deployments
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    print_status "Waiting for deployment $deployment in namespace $namespace..."
    kubectl wait --for=condition=available --timeout=600s deployment/$deployment -n $namespace
}

# Function to wait for pods
wait_for_pods() {
    local namespace=$1
    print_status "Waiting for all pods to be ready in namespace $namespace..."
    kubectl wait --for=condition=ready --timeout=600s --all pods -n $namespace || true
}

# Step 1: Setup K3d cluster
print_status "Setting up K3d cluster..."
if ! ./setup-k3d-cluster.sh; then
    print_error "Failed to setup K3d cluster"
    exit 1
fi
print_success "K3d cluster is ready"

# Step 2: Add Helm repositories
print_status "Adding Helm repositories..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add signoz https://charts.signoz.io
helm repo update
print_success "Helm repositories updated"

# Step 3: Create namespaces
print_status "Creating namespaces..."
kubectl create namespace $OTEL_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $SIGNOZ_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespaces created"

# Step 4: Deploy SigNoz first (as it's needed as a backend)
print_status "Deploying SigNoz..."
helm upgrade --install signoz signoz/signoz \
    --namespace $SIGNOZ_NAMESPACE \
    --values signoz-values.yaml \
    --wait \
    --timeout 20m

print_success "SigNoz deployed successfully"

# Wait for SigNoz components to be ready
wait_for_deployment $SIGNOZ_NAMESPACE "signoz-otel-collector"
wait_for_deployment $SIGNOZ_NAMESPACE "signoz-query-service"
wait_for_deployment $SIGNOZ_NAMESPACE "signoz-frontend"

# Step 5: Deploy OpenTelemetry Demo with multi-backend configuration
print_status "Deploying OpenTelemetry Demo with multi-backend setup..."
helm upgrade --install otel-demo open-telemetry/opentelemetry-demo \
    --namespace $OTEL_NAMESPACE \
    --values otel-demo-with-signoz-values.yaml \
    --wait \
    --timeout 20m

print_success "OpenTelemetry Demo deployed successfully"

# Wait for key components
wait_for_deployment $OTEL_NAMESPACE "otel-demo-frontend"
wait_for_deployment $OTEL_NAMESPACE "otel-demo-frontendproxy"

# Step 6: Setup port forwarding for easy access
print_status "Setting up port forwarding..."

# Kill existing port forwards
pkill -f "kubectl port-forward" || true
sleep 2

# Get the port used by K3d cluster
DEMO_PORT=8080
if [ -f .demo-port ]; then
    DEMO_PORT=$(cat .demo-port)
fi

# Port forward for main demo access
kubectl port-forward svc/otel-demo-frontendproxy $DEMO_PORT:8080 -n $OTEL_NAMESPACE &
DEMO_PF_PID=$!

# Port forward for SigNoz access
kubectl port-forward svc/signoz-frontend 3301:3301 -n $SIGNOZ_NAMESPACE &
SIGNOZ_PF_PID=$!

# Wait a moment for port forwards to establish
sleep 5

# Step 7: Display access information
echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Access Points:"
echo "=================================="
echo "🛒 Demo Store:           http://localhost:$DEMO_PORT"
echo "📈 Grafana:              http://localhost:$DEMO_PORT/grafana"
echo "🔍 Jaeger UI:            http://localhost:$DEMO_PORT/jaeger/ui"
echo "🚩 Feature Flags:        http://localhost:$DEMO_PORT/feature"
echo "⚡ Load Generator:       http://localhost:$DEMO_PORT/loadgen"
echo "📊 SigNoz:               http://localhost:3301"
echo ""
echo "🔧 Useful Commands:"
echo "=================================="
echo "View all pods:           kubectl get pods --all-namespaces"
echo "View demo services:      kubectl get svc -n $OTEL_NAMESPACE"
echo "View SigNoz services:    kubectl get svc -n $SIGNOZ_NAMESPACE"
echo "Stop port forwarding:   pkill -f 'kubectl port-forward'"
echo ""
echo "🎯 Demo Features:"
echo "=================================="
echo "• Multi-language microservices (Go, Java, .NET, Python, JavaScript, Rust)"
echo "• Distributed tracing across services"
echo "• Metrics collection and visualization"
echo "• Log aggregation"
echo "• Feature flag integration"
echo "• Load generation for realistic traffic"
echo "• Multiple observability backends:"
echo "  - Jaeger for distributed tracing"
echo "  - Prometheus + Grafana for metrics"
echo "  - SigNoz for unified observability"
echo ""

# Save PIDs for cleanup
echo "$DEMO_PF_PID" > .demo-pf.pid
echo "$SIGNOZ_PF_PID" > .signoz-pf.pid

print_success "Ready for your presentation! 🎪"