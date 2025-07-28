#!/bin/bash

# OpenTelemetry Demo Cleanup Script
set -e

CLUSTER_NAME="otel-demo"
OTEL_NAMESPACE="otel-demo"
SIGNOZ_NAMESPACE="signoz"

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

echo "🧹 Starting OpenTelemetry Demo cleanup..."

# Step 1: Stop port forwarding processes
print_status "Stopping port forwarding processes..."
if [ -f .demo-pf.pid ]; then
    DEMO_PID=$(cat .demo-pf.pid)
    kill $DEMO_PID 2>/dev/null || true
    rm .demo-pf.pid
fi

if [ -f .signoz-pf.pid ]; then
    SIGNOZ_PID=$(cat .signoz-pf.pid)
    kill $SIGNOZ_PID 2>/dev/null || true
    rm .signoz-pf.pid
fi

# Kill any remaining port forward processes
pkill -f "kubectl port-forward" 2>/dev/null || true
print_success "Port forwarding stopped"

# Step 2: Uninstall Helm releases
print_status "Uninstalling Helm releases..."

# Uninstall OpenTelemetry Demo
if helm list -n $OTEL_NAMESPACE | grep -q otel-demo; then
    print_status "Uninstalling OpenTelemetry Demo..."
    helm uninstall otel-demo -n $OTEL_NAMESPACE
    print_success "OpenTelemetry Demo uninstalled"
else
    print_warning "OpenTelemetry Demo not found"
fi

# Uninstall SigNoz
if helm list -n $SIGNOZ_NAMESPACE | grep -q signoz; then
    print_status "Uninstalling SigNoz..."
    helm uninstall signoz -n $SIGNOZ_NAMESPACE
    print_success "SigNoz uninstalled"
else
    print_warning "SigNoz not found"
fi

# Step 3: Delete namespaces
print_status "Deleting namespaces..."
kubectl delete namespace $OTEL_NAMESPACE --ignore-not-found=true
kubectl delete namespace $SIGNOZ_NAMESPACE --ignore-not-found=true
print_success "Namespaces deleted"

# Step 4: Delete K3d cluster
print_status "Deleting K3d cluster..."
if k3d cluster list | grep -q $CLUSTER_NAME; then
    k3d cluster delete $CLUSTER_NAME
    print_success "K3d cluster deleted"
else
    print_warning "K3d cluster not found"
fi

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "📝 What was cleaned up:"
echo "========================"
echo "✅ Port forwarding processes stopped"
echo "✅ Helm releases uninstalled"
echo "✅ Kubernetes namespaces deleted"
echo "✅ K3d cluster destroyed"
echo ""
echo "💡 Your system is now clean and ready for the next demo!"