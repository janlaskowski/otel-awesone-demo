<<<<<<< HEAD
# otel-awesone-demo
This repo has setup for OTel telemetry showing how amazing OTel capabilites are.
=======
# OpenTelemetry Demo with Multi-Backend Setup

This demo showcases how different services written in various programming languages and frameworks can work together and send telemetry data to multiple observability backends using OpenTelemetry.

## 🎯 Demo Highlights

- **Multi-language microservices**: Go, Java, .NET, Python, JavaScript, Rust
- **Distributed tracing** across all services
- **Metrics collection** and visualization
- **Log aggregation** and analysis
- **Multiple observability backends**:
  - 🔍 **Jaeger** for distributed tracing
  - 📊 **Prometheus + Grafana** for metrics and dashboards
  - 🎯 **SigNoz** for unified observability platform

## 🛠️ Prerequisites

Make sure you have the following tools installed:

- [Docker](https://docs.docker.com/get-docker/)
- [k3d](https://k3d.io/v5.4.6/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) (version >= 3.8)

### Quick Installation Commands

```bash
# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 🚀 Quick Start

### Deploy the Demo

Run the deployment script to set up everything with a single command:

```bash
./deploy-otel-demo.sh
```

This script will:
1. Create a K3d Kubernetes cluster
2. Deploy SigNoz observability platform
3. Deploy OpenTelemetry Demo with multi-backend configuration
4. Set up port forwarding for easy access
5. Display all access URLs

### Access the Demo

Once deployed, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| 🛒 **Demo Store** | http://localhost:8080 | Main e-commerce application |
| 📈 **Grafana** | http://localhost:8080/grafana | Metrics dashboards |
| 🔍 **Jaeger** | http://localhost:8080/jaeger/ui | Distributed tracing |
| 🚩 **Feature Flags** | http://localhost:8080/feature | Feature flag management |
| ⚡ **Load Generator** | http://localhost:8080/loadgen | Traffic generation |
| 📊 **SigNoz** | http://localhost:3301 | Unified observability |

### Generate Traffic

The demo includes an automatic load generator, but you can also:
1. Browse the demo store at http://localhost:8080
2. Add items to cart and complete purchases
3. Adjust load generation at http://localhost:8080/loadgen

## 📁 File Structure

```
.
├── README.md                           # This file
├── setup-k3d-cluster.sh              # K3d cluster setup script
├── deploy-otel-demo.sh               # Main deployment script
├── cleanup-demo.sh                   # Cleanup script
├── otel-demo-values.yaml             # OTel demo basic configuration
├── otel-demo-with-signoz-values.yaml # OTel demo with SigNoz integration
└── signoz-values.yaml                # SigNoz configuration
```

## 🔧 Configuration Details

### Multi-Backend Telemetry Flow

The demo is configured to send telemetry data to multiple backends simultaneously:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐
│   Application   │───▶│ OTel Collector   │───▶│   Jaeger    │
│   Services      │    │                  │    │  (Traces)   │
│                 │    │                  │───▶│ Prometheus  │
│ • Frontend      │    │  Multi-pipeline  │    │ (Metrics)   │
│ • Cart Service  │    │  Configuration   │    │             │
│ • Payment Svc   │    │                  │───▶│   SigNoz    │
│ • etc...        │    │                  │    │(Unified O11y)│
└─────────────────┘    └──────────────────┘    └─────────────┘
```

### OpenTelemetry Collector Configuration

The collector is configured with multiple exporters:

- **Jaeger exporter**: For distributed tracing
- **Prometheus exporter**: For metrics scraping
- **OTLP/SigNoz exporter**: For unified observability

### Resource Requirements

**Minimum Requirements:**
- 8 GB RAM
- 4 CPU cores
- 30 GB storage

**Recommended:**
- 16 GB RAM
- 8 CPU cores
- 80 GB storage

## 🧹 Cleanup

To completely remove the demo environment:

```bash
./cleanup-demo.sh
```

This will:
- Stop all port forwarding
- Uninstall all Helm releases
- Delete Kubernetes namespaces
- Destroy the K3d cluster

## 🎪 Presentation Tips

### Demo Flow Suggestions

1. **Start with the Store**: Show the working e-commerce application
2. **Generate Load**: Use the load generator to create realistic traffic
3. **Explore Jaeger**: Show distributed traces across microservices
4. **View Grafana**: Display metrics dashboards and service maps  
5. **Compare with SigNoz**: Show how the same data appears in SigNoz
6. **Highlight Multi-language**: Point out different services are in different languages

### Key Demo Points

- **Language Diversity**: Services written in Go, Java, .NET, Python, JavaScript, Rust
- **Automatic Instrumentation**: No code changes needed for basic telemetry
- **Backend Flexibility**: Same telemetry data sent to multiple systems
- **Real-world Scenarios**: E-commerce application with realistic microservice interactions

## 🛠️ Troubleshooting

### Common Issues

**Port Already in Use:**
```bash
# Kill existing port forwards
pkill -f "kubectl port-forward"
```

**Insufficient Resources:**
```bash
# Check cluster resources
kubectl top nodes
kubectl top pods --all-namespaces
```

**SigNoz Not Accessible:**
```bash
# Check SigNoz pods
kubectl get pods -n signoz
kubectl logs -n signoz deployment/signoz-frontend
```

**Demo Services Not Starting:**
```bash
# Check demo pods
kubectl get pods -n otel-demo
kubectl describe pods -n otel-demo
```

### Manual Port Forwarding

If automatic port forwarding fails:

```bash
# Demo access
kubectl port-forward svc/otel-demo-frontendproxy 8080:8080 -n otel-demo

# SigNoz access  
kubectl port-forward svc/signoz-frontend 3301:3301 -n signoz
```

## 📚 Additional Resources

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [OpenTelemetry Demo Documentation](https://opentelemetry.io/docs/demo/)
- [SigNoz Documentation](https://signoz.io/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## 🤝 Contributing

Feel free to modify the configurations to suit your presentation needs:

- Adjust resource limits in `*-values.yaml` files
- Modify service selection in the demo configuration  
- Add additional observability backends
- Customize Grafana dashboards

---

**Happy presenting! 🎉**
>>>>>>> d29dbd7 (inital commit of files)
