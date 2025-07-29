# OpenTelemetry Multi-Backend Demo

**Showcase OpenTelemetry's vendor-neutral approach with multiple observability backends receiving the same telemetry data simultaneously.**

## 🎯 Demo Purpose

This demo proves that OpenTelemetry eliminates vendor lock-in by sending **identical telemetry data** to multiple observability platforms:
- Same traces appear in both **Jaeger** and **Zipkin**
- Same metrics flow to **Prometheus + Grafana** 
- **Zero code changes** needed to switch or add backends
- **12+ microservices** in different languages, all auto-instrumented

## 🚀 Quick Start

Deploy everything with a single command:

```bash
./deploy.sh
```

Clean up everything:

```bash
./cleanup.sh
```

## 📊 What Gets Deployed

- **K3d Kubernetes cluster** - Lightweight local Kubernetes
- **OpenTelemetry Demo** - Multi-language e-commerce microservices
- **Jaeger** - Distributed tracing backend #1
- **Zipkin** - Distributed tracing backend #2  
- **Prometheus + Grafana** - Metrics collection and visualization
- **OTEL Collector** - Configured to send data to multiple backends

## 🔗 Access Points

After deployment, compare the same data across different vendors:

| Service | URL | Purpose |
|---------|-----|---------|
| 🛒 **Demo Store** | http://localhost:8080 | Generate real traffic |
| 🔍 **Jaeger** | http://localhost:8080/jaeger/ui/ | View traces (Backend #1) |
| 🔍 **Zipkin** | http://localhost:9411 | View **same traces** (Backend #2) |
| 📈 **Grafana** | http://localhost:8080/grafana/ | View metrics dashboards |
| ⚡ **Load Generator** | http://localhost:8080/loadgen/ | Control traffic patterns |

## 🎪 Demo Flow for Presentations

1. **Start with the store** - Show working e-commerce app
2. **Generate traffic** - Use load generator or browse the store
3. **Show Jaeger traces** - Pick a complex multi-service trace
4. **Show same trace in Zipkin** - Prove identical data, different UI
5. **Highlight the magic** - Same OpenTelemetry data, zero vendor lock-in!

### Key Talking Points

> *"Watch this - I'm making a purchase in the store. Now I'll show you the exact same trace data in two different observability platforms. Notice how both Jaeger and Zipkin show identical spans, timings, and service relationships. This is OpenTelemetry's power - one instrumentation, any backend!"*

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐
│  Applications   │───▶│ OTEL Collector   │───▶│   Jaeger    │
│  (Go, Java,     │    │                  │    │             │
│   .NET, Python, │    │  Multi-Backend   │───▶│   Zipkin    │
│   JavaScript,   │    │  Configuration   │    │             │
│   Rust, etc.)   │    │                  │───▶│ Prometheus  │
└─────────────────┘    └──────────────────┘    └─────────────┘
```

## 💻 Prerequisites

- **k3d** - Local Kubernetes cluster
- **kubectl** - Kubernetes CLI  
- **helm** - Package manager
- **8GB+ RAM** - For all services
- **4+ CPU cores** - Recommended

*The deployment script will check for missing tools and provide installation instructions.*

## 🛠️ Project Structure

```
├── deploy.sh              # Complete deployment (5-10 minutes)
├── cleanup.sh             # Lightning-fast cleanup (5 seconds)
├── README.md              # This documentation
└── LICENSE                # License file
```

## 🎯 Perfect for Demonstrating

- ✅ **Vendor neutrality** - Same data, multiple backends
- ✅ **Zero code changes** - Auto-instrumentation across languages
- ✅ **Real-world complexity** - 12+ microservices, realistic traffic
- ✅ **Live demo ready** - Fast deployment, reliable cleanup
- ✅ **Multi-language support** - Go, Java, .NET, Python, JavaScript, Rust

## 🚨 Troubleshooting

- **Port conflicts**: Script automatically finds available ports
- **Resource issues**: Ensure 8GB+ RAM available
- **Zipkin not loading**: Wait 30s after deployment for memory allocation
- **Missing traces**: Generate traffic first, then check both UIs
- **Complete reset**: Run `./cleanup.sh` then `./deploy.sh`

---

**Ready to prove OpenTelemetry eliminates vendor lock-in? Run `./deploy.sh` and show the world! 🌟**