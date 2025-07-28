#!/bin/bash

# Port Check Script for OpenTelemetry Demo
echo "🔍 Checking port usage for common demo ports..."

check_port_usage() {
    local port=$1
    local service_name=$2
    
    echo "Checking port $port ($service_name):"
    
    if lsof -Pi :$port -sTCP:LISTEN 2>/dev/null; then
        echo "❌ Port $port is in use by the above process(es)"
        echo ""
    else
        echo "✅ Port $port is available"
        echo ""
    fi
}

# Check common ports
check_port_usage 8080 "Demo Store/K3d LoadBalancer"
check_port_usage 3301 "SigNoz"
check_port_usage 4317 "OTLP gRPC"
check_port_usage 4318 "OTLP HTTP"

echo "💡 To free up port 8080, you can:"
echo "   - Find the process ID (PID) from the output above"
echo "   - Kill the process: kill <PID>"
echo "   - Or stop the service that's using it"
echo ""
echo "🚀 The setup script will automatically find an alternative port if 8080 is busy"