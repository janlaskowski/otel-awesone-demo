#!/bin/bash

# OpenTelemetry Demo - Complete Cleanup Script
set -e

CLUSTER_NAME="otel-demo"
OTEL_NAMESPACE="otel-demo"
ZIPKIN_NAMESPACE="zipkin"

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

if [ -f .zipkin-pf.pid ]; then
    ZIPKIN_PID=$(cat .zipkin-pf.pid)
    kill $ZIPKIN_PID 2>/dev/null || true
    rm .zipkin-pf.pid
fi

# Kill any remaining port forward processes
pkill -f "kubectl port-forward" 2>/dev/null || true
print_success "Port forwarding stopped"

# Step 2: Delete K3d cluster (this removes everything at once - much faster!)
print_status "Deleting K3d cluster..."
if k3d cluster list 2>/dev/null | grep -q $CLUSTER_NAME; then
    k3d cluster delete $CLUSTER_NAME
    print_success "K3d cluster deleted"
else
    print_warning "K3d cluster not found"
fi

# Clean up all temporary files (including legacy ones)
rm -f .demo-port .demo-pf.pid .zipkin-pf.pid .signoz-pf.pid

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "📝 What was cleaned up:"
echo "========================"
echo "✅ Port forwarding processes stopped"
echo "✅ K3d cluster destroyed (includes all Helm releases and namespaces)"
echo "✅ Temporary files removed"
echo ""
echo "💡 Your system is now clean and ready for the next demo!"
echo "⚡ Much faster cleanup by destroying the entire cluster at once!"