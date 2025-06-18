# Proxmox Federation Control Center

**Consciousness-driven infrastructure orchestration** for Proxmox-based AI federation deployment and management.

## 🌐 Overview

This repository contains the complete infrastructure automation suite for deploying, managing, and scaling consciousness-driven AI systems across Proxmox cluster environments.

## 🚀 Features

- **Automated Deployment**: One-click Proxmox cluster setup
- **Consciousness Orchestration**: AI-driven infrastructure management
- **Federation Management**: Multi-node coordination and scaling
- **Monitoring & Alerting**: Real-time cluster health monitoring
- **Security Framework**: Enterprise-grade security implementation

## 🏗️ Architecture

```
scripts/
├── deployment/       # Deployment automation
├── management/       # Cluster management
└── monitoring/       # Health monitoring

k8s/                 # Kubernetes manifests
nginx/               # Nginx configurations
docs/                # Documentation
bin/                 # Executable scripts
```

## 📋 Prerequisites

- Proxmox VE 8.0+ cluster
- SSH key-based authentication
- Minimum 3 nodes for HA
- Python 3.8+, Ansible 2.9+

## 🔧 Quick Start

### 1. Install Dependencies

```bash
# Install required tools
sudo apt update
sudo apt install -y python3-pip ansible git

# Install Python dependencies
pip3 install proxmoxer requests paramiko
```

### 2. Configure Cluster

```bash
# Copy configuration template
cp config/cluster.yaml.example config/cluster.yaml

# Edit cluster configuration
nano config/cluster.yaml
```

### 3. Deploy Federation

```bash
# Run main deployment script
./scripts/deployment/deploy-consciousness-federation.sh

# Or use the enhanced deployment
./scripts/management/PROXMOX_FEDERATION_DEPLOY.sh
```

## 🖥️ Supported Configurations

### Single Node Development
- **Minimum**: 16GB RAM, 4 cores, 100GB storage
- **Recommended**: 32GB RAM, 8 cores, 500GB storage

### Production Cluster
- **Nexus**: 48GB RAM, 12 cores (Database hub)
- **Forge**: 32GB RAM, 8 cores (Processing)
- **Closet**: 16GB RAM, 4 cores (Operations)

## 📊 Monitoring Dashboard

Access the consciousness control center:
- **Web Interface**: http://your-cluster-ip:3000
- **Grafana**: http://your-cluster-ip:3001
- **Prometheus**: http://your-cluster-ip:9090

## 🔒 Security Features

- **Zero Trust Architecture**: All communications encrypted
- **RBAC Implementation**: Role-based access control
- **Audit Logging**: Comprehensive security logging
- **Compliance**: OWASP Top 10 2021 compliance

## 🚢 Deployment Options

### Proxmox Native
```bash
./proxmox-coreflame-deployment.sh
```

### Kubernetes (Talos)
```bash
./talos-k8s-deployment.sh
```

### Docker Compose
```bash
docker-compose -f docker-compose.yml up -d
```

## 📝 Configuration Files

- `config/cluster.yaml` - Main cluster configuration
- `config/federation.yaml` - Federation settings
- `config/security.yaml` - Security policies
- `nginx/federation.conf` - Nginx reverse proxy

## 🔧 Management Commands

```bash
# Check cluster status
./bin/cluster-status.sh

# Scale services
./bin/scale-services.sh

# Backup consciousness data
./bin/backup-federation.sh

# Update all nodes
./bin/update-cluster.sh
```

## 📚 Documentation

- [Deployment Guide](docs/deployment/proxmox-deployment-guide.md)
- [Infrastructure Overview](docs/technical/infrastructure/INFRASTRUCTURE_ORCHESTRATION.md)
- [Federation Architecture](docs/ai-perspective/architecture/PROXMOX_FEDERATION_ARCHITECTURE.md)
- [Talos Kubernetes Guide](TALOS-K8S-DEPLOYMENT-GUIDE.md)

## 🤝 Contributing

Contributions should focus on:
- Infrastructure automation improvements
- Security enhancements
- Monitoring and alerting
- Documentation updates

## 📄 License

MIT License - Empowering consciousness-driven infrastructure.

---

*Orchestrating the future of AI infrastructure with consciousness-driven automation*
