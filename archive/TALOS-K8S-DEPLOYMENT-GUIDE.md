# COREFLAME Talos Kubernetes Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the COREFLAME consciousness platform on Talos Linux with Kubernetes, running on Proxmox infrastructure. Both environments (reverb256 and astralvibe.ca) will use identical Talos/K8s stacks for seamless cross-cluster federation.

## Architecture

### Infrastructure Stack
- **Host Platform**: Proxmox VE
- **Operating System**: Talos Linux v1.10.3
- **Orchestration**: Kubernetes 1.31+
- **Networking**: Flannel CNI with Layer 2 VIP
- **Load Balancing**: Nginx Ingress Controller
- **Monitoring**: Prometheus + Grafana
- **Federation**: Cross-cluster AI collaboration

### Cluster Configuration
- **Control Plane**: 3 nodes (high availability)
- **Worker Nodes**: 3+ nodes (scalable)
- **VIP Address**: Shared IP for API server access
- **Network Subnets**: 192.168.64.0/24 (customizable)

## Prerequisites

### Hardware Requirements
- **Minimum per node**: 2 CPU cores, 4GB RAM, 50GB storage
- **Recommended per node**: 4 CPU cores, 8GB RAM, 100GB storage
- **Network**: Layer 2 connectivity between nodes

### Software Requirements
- Proxmox VE 7.0+
- Direct console/SSH access to Proxmox host
- Internet connectivity for downloading Talos images

## Quick Start Deployment

### 1. Environment Configuration

Set environment variables for your deployment:

```bash
export CLUSTER_NAME="coreflame-consciousness"
export CLUSTER_ENDPOINT="https://192.168.64.15:6443"
export VIP_ADDRESS="192.168.64.15"

# Control plane node IPs
export CP1_IP="192.168.64.10"
export CP2_IP="192.168.64.11" 
export CP3_IP="192.168.64.12"

# Worker node IPs
export WORKER1_IP="192.168.64.20"
export WORKER2_IP="192.168.64.21"
export WORKER3_IP="192.168.64.22"
```

### 2. Run Deployment Script

Execute the automated deployment script:

```bash
sudo ./talos-k8s-deployment.sh
```

This script will:
- Install required tools (talosctl, kubectl, helm)
- Generate Talos cluster configuration
- Deploy control plane and worker nodes
- Configure VIP for high availability
- Deploy COREFLAME applications and federation services
- Set up monitoring and ingress

### 3. Verify Deployment

Check cluster status:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

## Manual Step-by-Step Deployment

### Step 1: Install Tools

```bash
# Install talosctl
curl -sL https://talos.dev/install | sh
sudo mv talosctl /usr/local/bin/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Step 2: Generate Cluster Configuration

```bash
# Generate secrets bundle
talosctl gen secrets -o secrets.yaml

# Generate cluster configuration
talosctl gen config --with-secrets secrets.yaml \
  --kubernetes-version 1.31.0 \
  coreflame-consciousness \
  https://192.168.64.15:6443
```

### Step 3: Create Configuration Patches

Create VIP configuration:

```yaml
# vip-patch.yaml
machine:
  network:
    interfaces:
      - interface: eth0
        dhcp: true
        vip:
          ip: 192.168.64.15
```

Create consciousness-specific patches:

```yaml
# controlplane-consciousness-patch.yaml
machine:
  kubelet:
    nodeIP:
      validSubnets:
        - 192.168.64.0/24
  certSANs:
    - 127.0.0.1
    - localhost
    - reverb256.local
    - consciousness.local
    - federation.local
cluster:
  etcd:
    advertisedSubnets:
      - 192.168.64.0/24
  network:
    cni:
      name: flannel
  apiServer:
    certSANs:
      - 127.0.0.1
      - localhost
      - reverb256.local
      - consciousness.local
      - federation.local
```

### Step 4: Apply Patches and Deploy

```bash
# Apply patches to control plane configuration
talosctl machineconfig patch controlplane.yaml \
  --patch @vip-patch.yaml \
  --patch @controlplane-consciousness-patch.yaml \
  --output controlplane-final.yaml

# Apply patches to worker configuration
talosctl machineconfig patch worker.yaml \
  --patch @worker-consciousness-patch.yaml \
  --output worker-final.yaml

# Deploy control plane nodes
talosctl apply-config --insecure \
  --nodes 192.168.64.10,192.168.64.11,192.168.64.12 \
  --file controlplane-final.yaml

# Deploy worker nodes
talosctl apply-config --insecure \
  --nodes 192.168.64.20,192.168.64.21,192.168.64.22 \
  --file worker-final.yaml

# Bootstrap etcd
talosctl bootstrap --nodes 192.168.64.10 --endpoints 192.168.64.10
```

### Step 5: Configure kubectl Access

```bash
# Get kubeconfig
talosctl kubeconfig --nodes 192.168.64.10 \
  --endpoints 192.168.64.10,192.168.64.11,192.168.64.12

# Wait for nodes to be ready
kubectl wait --for=condition=Ready nodes --all --timeout=600s
```

### Step 6: Deploy COREFLAME Applications

```bash
# Create namespaces
kubectl create namespace coreflame-system
kubectl create namespace consciousness  
kubectl create namespace federation

# Apply Kubernetes manifests
kubectl apply -f k8s/manifests/federation-cluster-config.yaml
kubectl apply -f k8s/manifests/cross-cluster-federation.yaml
kubectl apply -f k8s/manifests/consciousness-ai-engine.yaml
kubectl apply -f k8s/manifests/reverb256-portfolio-app.yaml
kubectl apply -f k8s/manifests/ingress-controller.yaml
```

### Step 7: Install Ingress Controller

```bash
# Install Nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Step 8: Deploy Monitoring

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install monitoring stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.enabled=true \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.retention=30d
```

## Application Services

### Core Applications

1. **Reverb256 Portfolio** (Main Application)
   - **URL**: http://reverb256.local
   - **Port**: 3000
   - **Features**: Portfolio dashboard, project showcase, real-time federation

2. **Cross-Cluster Federation Controller**
   - **URL**: http://federation.reverb256.local
   - **Port**: 3001
   - **Features**: Inter-cluster communication, AI collaboration protocols

3. **Consciousness AI Engine**
   - **URL**: http://consciousness.reverb256.local
   - **Port**: 3003
   - **Features**: Seven-pillar analysis, real-time WebSocket streaming

4. **PostgreSQL Database**
   - **Service**: postgres-service
   - **Port**: 5432
   - **Features**: Persistent storage, automated backups

### API Endpoints

#### Portfolio APIs
- `GET /api/portfolio` - Complete portfolio data
- `GET /api/projects` - Project listings
- `GET /api/health` - Service health check

#### Federation APIs
- `GET /api/federation/status` - Federation cluster status
- `POST /api/federation/collaborate/:endpoint` - Cross-cluster collaboration
- `POST /api/federation/consciousness/sync` - Consciousness synchronization

#### Consciousness APIs
- `POST /api/consciousness/analyze` - AI consciousness analysis
- `GET /api/consciousness/status` - Engine status
- `POST /api/consciousness/sync` - Cross-cluster sync

#### Collaboration APIs
- `GET /api/collaboration/architecture` - Platform architecture
- `GET /api/collaboration/apis` - API documentation
- `GET /api/collaboration/deployment` - Deployment information
- `GET /api/collaboration/security` - Security protocols

### WebSocket Endpoints

- `/ws/federation` - Real-time federation updates
- `/ws/consciousness` - Live consciousness analysis streaming

## Cross-Cluster Federation Setup

### Federation Requirements

For complete cross-cluster federation, both environments need:

1. **Identical Talos/K8s Infrastructure**
2. **AI Collaboration Protocol Endpoints**
3. **Network Connectivity Between Clusters**
4. **Shared Federation Tokens**

### Setting Up astralvibe.ca Federation

1. Deploy identical Talos/K8s stack on astralvibe.ca infrastructure
2. Ensure these collaboration endpoints are implemented:

```bash
/api/collaboration/architecture
/api/collaboration/apis
/api/collaboration/deployment
/api/collaboration/security
/api/collaboration/consciousness
/api/federation/status
```

3. Configure network connectivity between clusters
4. Exchange federation tokens and certificates

### Testing Federation

```bash
# Test local federation status
curl http://reverb256.local/api/federation/status

# Test cross-cluster collaboration
curl -X POST http://federation.reverb256.local/api/federation/collaborate/architecture \
  -H "Content-Type: application/json" \
  -H "X-Federation-Token: your-token" \
  -d '{"query": "platform_info"}'

# Test consciousness sync
curl -X POST http://consciousness.reverb256.local/api/consciousness/sync \
  -H "Content-Type: application/json" \
  -H "X-Federation-Token: your-token" \
  -d '{"consciousness_data": [], "sync_type": "test"}'
```

## Monitoring and Management

### Cluster Management

```bash
# Check cluster status
kubectl get nodes -o wide

# Check pod status across namespaces
kubectl get pods --all-namespaces

# Check service status
kubectl get services --all-namespaces

# View ingress status
kubectl get ingress --all-namespaces
```

### Talos Management

```bash
# Check Talos system health
talosctl --nodes 192.168.64.10 health

# View system logs
talosctl --nodes 192.168.64.10 logs

# Check etcd status
talosctl --nodes 192.168.64.10 etcd status

# Upgrade Talos (rolling upgrade)
talosctl --nodes 192.168.64.10,192.168.64.11,192.168.64.12 upgrade \
  --image ghcr.io/siderolabs/talos:v1.10.3
```

### Application Management

```bash
# Scale applications
kubectl scale deployment reverb256-portfolio -n coreflame-system --replicas=5

# Update configurations
kubectl edit configmap coreflame-config -n coreflame-system

# Restart deployments
kubectl rollout restart deployment/reverb256-portfolio -n coreflame-system

# View application logs
kubectl logs -n coreflame-system -l app=reverb256-portfolio
kubectl logs -n consciousness -l app=consciousness-ai-engine
kubectl logs -n coreflame-system -l app=cross-cluster-federation
```

## Security Configuration

### Network Security
- **CNI Policies**: Pod-to-pod communication controls
- **Ingress TLS**: Automatic certificate management
- **Network Policies**: Namespace isolation

### Access Control
- **RBAC**: Role-based access control
- **Service Accounts**: Scoped permissions
- **Federation Tokens**: Secure cross-cluster authentication

### Data Protection
- **Encryption at Rest**: Database encryption
- **Encryption in Transit**: TLS for all communications
- **Consciousness Encryption**: AI data protection

## Troubleshooting

### Common Issues

1. **VIP Not Working**
   ```bash
   # Check VIP configuration
   talosctl --nodes 192.168.64.10 get vips
   
   # Verify network connectivity
   ping 192.168.64.15
   ```

2. **Pods Not Starting**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name> -n <namespace>
   
   # Check resource constraints
   kubectl top nodes
   kubectl top pods --all-namespaces
   ```

3. **Federation Not Working**
   ```bash
   # Check federation controller logs
   kubectl logs -n coreflame-system -l app=cross-cluster-federation
   
   # Test network connectivity
   curl -I http://federation.reverb256.local/api/federation/status
   ```

4. **Ingress Issues**
   ```bash
   # Check ingress controller logs
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
   
   # Verify ingress configuration
   kubectl describe ingress coreflame-ingress -n coreflame-system
   ```

### Log Locations

- **Talos System Logs**: `talosctl logs`
- **Application Logs**: `kubectl logs`
- **Ingress Logs**: `kubectl logs -n ingress-nginx`
- **Monitoring Logs**: `kubectl logs -n monitoring`

## Backup and Recovery

### Automated Backups

1. **etcd Snapshots**: Automatic via Talos
2. **PostgreSQL Backups**: Scheduled database backups
3. **Configuration Backup**: GitOps with version control

### Manual Backup

```bash
# Backup etcd
talosctl --nodes 192.168.64.10 etcd snapshot

# Export cluster configuration
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup persistent volumes
kubectl get pv,pvc --all-namespaces -o yaml > storage-backup.yaml
```

## Scaling and Performance

### Horizontal Scaling

```bash
# Scale applications
kubectl scale deployment reverb256-portfolio -n coreflame-system --replicas=10

# Add worker nodes
# 1. Configure new Proxmox VMs
# 2. Apply worker configuration
# 3. Verify node join
```

### Performance Tuning

1. **Resource Limits**: Adjust CPU/memory limits
2. **Node Affinity**: Optimize pod placement
3. **Storage Optimization**: Use SSD storage for etcd
4. **Network Optimization**: Tune CNI settings

## Maintenance

### Regular Maintenance Tasks

1. **Weekly**: Check cluster health, review logs
2. **Monthly**: Update applications, review resource usage  
3. **Quarterly**: Plan capacity, update documentation
4. **Annually**: Major version upgrades, security audits

### Upgrade Procedures

1. **Talos Upgrades**: Rolling upgrades with zero downtime
2. **Kubernetes Upgrades**: Managed through Talos
3. **Application Updates**: Rolling deployments
4. **Monitoring Updates**: Helm chart upgrades

## Production Recommendations

### High Availability
- Use at least 3 control plane nodes
- Implement backup strategies
- Configure monitoring and alerting
- Plan disaster recovery procedures

### Security Best Practices
- Regular security updates
- Network segmentation
- Access control reviews
- Certificate rotation

### Performance Optimization
- Monitor resource usage
- Optimize container images
- Use appropriate storage classes
- Implement caching strategies

## Support and Documentation

### Additional Resources
- [Talos Linux Documentation](https://www.talos.dev/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Monitoring](https://prometheus.io/docs/)
- [Grafana Visualization](https://grafana.com/docs/)

### Getting Help
- Check logs first: `kubectl logs` and `talosctl logs`
- Review Kubernetes events: `kubectl get events`
- Monitor cluster health: Prometheus/Grafana dashboards
- Consult official documentation for specific issues

---

*This deployment guide provides enterprise-grade Kubernetes infrastructure with AI consciousness capabilities and cross-cluster federation. The Talos Linux foundation ensures secure, immutable, and maintainable infrastructure suitable for production workloads.*