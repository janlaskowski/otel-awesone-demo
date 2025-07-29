#!/bin/bash

# OpenTelemetry Demo - Complete Deployment Script
# This script sets up everything needed for the OTel demo in one go
set -e

CLUSTER_NAME="otel-demo"
OTEL_NAMESPACE="otel-demo"
ZIPKIN_NAMESPACE="zipkin"
DEFAULT_PORT=8080

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
    
    print_error "Could not find available port starting from $start_port"
    exit 1
}

# Function to wait for deployments
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    print_status "Waiting for deployment $deployment in namespace $namespace..."
    kubectl wait --for=condition=available --timeout=600s deployment/$deployment -n $namespace
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v k3d &> /dev/null; then
        missing_tools+=("k3d")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Installation instructions:"
        echo "- k3d: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
        echo "- kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        echo "- helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to setup K3d cluster
setup_k3d_cluster() {
    print_status "Setting up K3d cluster..."
    
    # Find available port
    AVAILABLE_PORT=$(find_available_port $DEFAULT_PORT)
    K3D_PORT_MAPPING="$AVAILABLE_PORT:80@loadbalancer"
    
    if [ $AVAILABLE_PORT -ne $DEFAULT_PORT ]; then
        print_warning "Port $DEFAULT_PORT is in use, using port $AVAILABLE_PORT instead"
    fi
    
    # Delete existing cluster if it exists
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        print_status "Deleting existing cluster: $CLUSTER_NAME"
        k3d cluster delete "$CLUSTER_NAME"
    fi
    
    # Create K3d cluster with port forwarding for web access
    print_status "Creating K3d cluster: $CLUSTER_NAME"
    k3d cluster create "$CLUSTER_NAME" \
        --port "$K3D_PORT_MAPPING" \
        --agents 2 \
        --wait
    
    # Verify cluster is running
    print_status "Verifying cluster status..."
    kubectl cluster-info >/dev/null
    kubectl get nodes >/dev/null
    
    # Save the port for use by other parts
    echo "$AVAILABLE_PORT" > .demo-port
    
    print_success "K3d cluster '$CLUSTER_NAME' is ready!"
}

# Function to setup Helm repositories
setup_helm_repos() {
    print_status "Adding Helm repositories..."
    helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
    helm repo update
    print_success "Helm repositories updated"
}

# Function to create namespaces
create_namespaces() {
    print_status "Creating namespaces..."
    kubectl create namespace $OTEL_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace $ZIPKIN_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespaces created"
}

# Function to deploy Zipkin (lightweight alternative)
deploy_zipkin() {
    print_status "Deploying Zipkin as alternative backend..."
    
    # Create a simple Zipkin deployment
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: $ZIPKIN_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
    spec:
      containers:
      - name: zipkin
        image: openzipkin/zipkin:latest
        ports:
        - containerPort: 9411
        env:
        - name: STORAGE_TYPE
          value: mem
        - name: JAVA_OPTS
          value: "-Xms512m -Xmx1g"
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: zipkin
  namespace: $ZIPKIN_NAMESPACE
spec:
  selector:
    app: zipkin
  ports:
  - port: 9411
    targetPort: 9411
  type: ClusterIP
EOF

    print_success "Zipkin deployed successfully"
    
    # Wait for Zipkin to be ready
    wait_for_deployment $ZIPKIN_NAMESPACE "zipkin"
}

# Function to deploy OpenTelemetry Demo
deploy_otel_demo() {
    print_status "Deploying OpenTelemetry Demo..."
    
    # Deploy with default configuration
    helm upgrade --install otel-demo open-telemetry/opentelemetry-demo \
        --namespace $OTEL_NAMESPACE \
        --wait \
        --timeout 20m

    print_success "OpenTelemetry Demo deployed successfully"

    # Wait for key components to be ready
    wait_for_deployment $OTEL_NAMESPACE "frontend"
    wait_for_deployment $OTEL_NAMESPACE "frontend-proxy"
    
    # Configure OTEL Collector to send traces to both Jaeger and Zipkin
    configure_multi_backend_tracing
}

# Function to configure OTEL Collector for multi-backend tracing
configure_multi_backend_tracing() {
    print_status "Configuring OTEL Collector to send traces to both Jaeger and Zipkin..."
    
    # Create a temporary configuration file with proper escaping
    cat > /tmp/otel-collector-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector
  namespace: otel-demo
data:
  relay: |
    connectors:
      spanmetrics: {}
    exporters:
      debug: {}
      opensearch:
        http:
          endpoint: http://opensearch:9200
          tls:
            insecure: true
        logs_index: otel
      otlp:
        endpoint: jaeger-collector:4317
        tls:
          insecure: true
      zipkin:
        endpoint: http://zipkin.zipkin.svc.cluster.local:9411/api/v2/spans
      otlphttp/prometheus:
        endpoint: http://prometheus:9090/api/v1/otlp
        tls:
          insecure: true
    extensions:
      health_check:
        endpoint: ${env:MY_POD_IP}:13133
    processors:
      batch: {}
      k8sattributes:
        extract:
          metadata:
          - k8s.namespace.name
          - k8s.deployment.name
          - k8s.statefulset.name
          - k8s.daemonset.name
          - k8s.cronjob.name
          - k8s.job.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - k8s.pod.start_time
        passthrough: false
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: connection
      memory_limiter:
        check_interval: 5s
        limit_percentage: 80
        spike_limit_percentage: 25
      resource:
        attributes:
        - action: insert
          from_attribute: k8s.pod.uid
          key: service.instance.id
      transform:
        error_mode: ignore
        trace_statements:
        - context: span
          statements:
          - replace_pattern(name, "\\?.*", "")
          - replace_match(name, "GET /api/products/*", "GET /api/products/{productId}")
    receivers:
      httpcheck/frontend-proxy:
        targets:
        - endpoint: http://frontend-proxy:8080
      jaeger:
        protocols:
          grpc:
            endpoint: ${env:MY_POD_IP}:14250
          thrift_compact:
            endpoint: ${env:MY_POD_IP}:6831
          thrift_http:
            endpoint: ${env:MY_POD_IP}:14268
      otlp:
        protocols:
          grpc:
            endpoint: ${env:MY_POD_IP}:4317
          http:
            cors:
              allowed_origins:
              - http://*
              - https://*
            endpoint: ${env:MY_POD_IP}:4318
      prometheus:
        config:
          scrape_configs:
          - job_name: opentelemetry-collector
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${env:MY_POD_IP}:8888
      redis:
        collection_interval: 10s
        endpoint: valkey-cart:6379
      zipkin:
        endpoint: ${env:MY_POD_IP}:9411
    service:
      extensions:
      - health_check
      pipelines:
        logs:
          exporters:
          - opensearch
          - debug
          processors:
          - k8sattributes
          - memory_limiter
          - resource
          - batch
          receivers:
          - otlp
        metrics:
          exporters:
          - otlphttp/prometheus
          - debug
          processors:
          - k8sattributes
          - memory_limiter
          - resource
          - batch
          receivers:
          - httpcheck/frontend-proxy
          - redis
          - otlp
          - spanmetrics
        traces:
          exporters:
          - otlp
          - zipkin
          - debug
          - spanmetrics
          processors:
          - k8sattributes
          - memory_limiter
          - resource
          - transform
          - batch
          receivers:
          - otlp
          - jaeger
          - zipkin
      telemetry:
        metrics:
          address: ${env:MY_POD_IP}:8888
          level: detailed
          readers:
          - periodic:
              exporter:
                otlp:
                  endpoint: otel-collector:4318
                  protocol: grpc
              interval: 10000
              timeout: 5000
EOF
    
    # Apply the configuration
    kubectl apply -f /tmp/otel-collector-config.yaml
    
    # Clean up the temporary file
    rm -f /tmp/otel-collector-config.yaml
    
    # Restart the OTEL Collector to apply the new configuration
    kubectl rollout restart deployment/otel-collector -n $OTEL_NAMESPACE
    kubectl rollout status deployment/otel-collector -n $OTEL_NAMESPACE
    
    print_success "OTEL Collector configured for multi-backend tracing"
}

# Function to setup port forwarding
setup_port_forwarding() {
    print_status "Setting up port forwarding..."

    # Kill existing port forwards
    pkill -f "kubectl port-forward" || true
    sleep 2

    # Get the port used by K3d cluster
    DEMO_PORT=$DEFAULT_PORT
    if [ -f .demo-port ]; then
        DEMO_PORT=$(cat .demo-port)
    fi

    # Port forward for main demo access
    kubectl port-forward svc/frontend-proxy $DEMO_PORT:8080 -n $OTEL_NAMESPACE &
    DEMO_PF_PID=$!

    # Port forward for Zipkin access
    kubectl port-forward svc/zipkin 9411:9411 -n $ZIPKIN_NAMESPACE &
    ZIPKIN_PF_PID=$!

    # Wait a moment for port forwards to establish
    sleep 5

    # Verify port forwards are working
    print_status "Verifying port forwarding..."
    sleep 3
    
    # Save PIDs for cleanup
    echo "$DEMO_PF_PID" > .demo-pf.pid
    echo "$ZIPKIN_PF_PID" > .zipkin-pf.pid

    print_success "Port forwarding established"
}

# Function to display access information
display_access_info() {
    DEMO_PORT=$DEFAULT_PORT
    if [ -f .demo-port ]; then
        DEMO_PORT=$(cat .demo-port)
    fi

    echo ""
    echo "🎉 OpenTelemetry Multi-Backend Demo Ready!"
    echo ""
    echo "🎯 VENDOR NEUTRALITY DEMO - Same Data, Multiple Backends:"
    echo "========================================================"
    echo "🛒 Demo Store:           http://localhost:$DEMO_PORT"
    echo "🔍 Jaeger (Backend #1):  http://localhost:$DEMO_PORT/jaeger/ui/"
    echo "🔍 Zipkin (Backend #2):  http://localhost:9411"
    echo "📈 Grafana Dashboards:   http://localhost:$DEMO_PORT/grafana/"
    echo "⚡ Traffic Generator:    http://localhost:$DEMO_PORT/loadgen/"
    echo ""
    echo "🔧 Useful Commands:"
    echo "=================================="
    echo "View all pods:           kubectl get pods --all-namespaces"
    echo "View demo services:      kubectl get svc -n $OTEL_NAMESPACE"
    echo "View Zipkin services:    kubectl get svc -n $ZIPKIN_NAMESPACE"
    echo "Stop demo:               ./cleanup.sh"
    echo ""
    echo "🎪 Demo Instructions:"
    echo "=================================="
    echo "1. Visit the store and make purchases"
    echo "2. Check traces in Jaeger (Backend #1)"
    echo "3. Check SAME traces in Zipkin (Backend #2)"
    echo "4. Show identical data = zero vendor lock-in!"
    echo ""
    echo "✨ Key Demo Points:"
    echo "• 12+ microservices in 6 programming languages"
    echo "• Identical traces in both Jaeger and Zipkin"
    echo "• Same OTEL data flowing to multiple vendors"
    echo "• Zero application code changes needed"
    echo "• Perfect proof of OpenTelemetry's vendor neutrality"
    echo ""
    
    print_success "Ready to prove OpenTelemetry eliminates vendor lock-in! 🌟"
}

# Main execution
main() {
    echo "🚀 Starting OpenTelemetry Demo deployment..."
    echo ""
    
    check_prerequisites
    setup_k3d_cluster
    setup_helm_repos
    create_namespaces
    deploy_zipkin
    deploy_otel_demo
    setup_port_forwarding
    display_access_info
}

# Execute main function
main "$@"