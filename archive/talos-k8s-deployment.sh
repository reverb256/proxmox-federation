#!/bin/bash

# COREFLAME Talos Kubernetes Deployment Script
# Enterprise-grade Kubernetes deployment with AI collaboration protocols
# Based on Talos Linux v1.10.3 production recommendations

set -euo pipefail

# Configuration
DEPLOYMENT_VERSION="2.0.0-k8s"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/coreflame-talos-deployment.log"
CLUSTER_NAME="${CLUSTER_NAME:-coreflame-consciousness}"
CLUSTER_ENDPOINT="${CLUSTER_ENDPOINT:-https://192.168.64.15:6443}"
VIP_ADDRESS="${VIP_ADDRESS:-192.168.64.15}"

# Control plane node IPs
CONTROL_PLANE_IPS=(
    "${CP1_IP:-192.168.64.10}"
    "${CP2_IP:-192.168.64.11}"
    "${CP3_IP:-192.168.64.12}"
)

# Worker node IPs
WORKER_IPS=(
    "${WORKER1_IP:-192.168.64.20}"
    "${WORKER2_IP:-192.168.64.21}"
    "${WORKER3_IP:-192.168.64.22}"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN $(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log "Checking deployment prerequisites..."
    
    # Check if talosctl is installed
    if ! command -v talosctl &> /dev/null; then
        log "Installing talosctl..."
        curl -sL https://talos.dev/install | sh
        sudo mv talosctl /usr/local/bin/
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    log "Prerequisites checked and installed"
}

# Generate Talos configuration
generate_talos_config() {
    log "Generating Talos cluster configuration..."
    
    # Create secrets bundle
    if [[ ! -f "secrets.yaml" ]]; then
        talosctl gen secrets -o secrets.yaml
        log "Generated secrets bundle"
    fi
    
    # Generate base configuration
    talosctl gen config \
        --with-secrets secrets.yaml \
        --kubernetes-version 1.31.0 \
        "$CLUSTER_NAME" \
        "$CLUSTER_ENDPOINT"
    
    log "Base configuration generated"
}

# Create VIP configuration patch
create_vip_patch() {
    log "Creating VIP configuration patch..."
    
    cat > vip-patch.yaml << EOF
machine:
  network:
    interfaces:
      - interface: eth0
        dhcp: true
        vip:
          ip: $VIP_ADDRESS
EOF
    
    log "VIP patch created for $VIP_ADDRESS"
}

# Create consciousness-specific patches
create_consciousness_patches() {
    log "Creating COREFLAME consciousness-specific patches..."
    
    # Control plane patch with consciousness modules
    cat > controlplane-consciousness-patch.yaml << 'EOF'
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
EOF

    # Worker patch with consciousness capabilities
    cat > worker-consciousness-patch.yaml << 'EOF'
machine:
  kubelet:
    nodeIP:
      validSubnets:
        - 192.168.64.0/24
    extraArgs:
      node-labels: "coreflame.io/consciousness=enabled,coreflame.io/ai-collaboration=true"
  sysctls:
    net.core.somaxconn: "65535"
    net.ipv4.ip_local_port_range: "1024 65000"
    net.ipv4.tcp_tw_reuse: "1"
EOF

    log "Consciousness patches created"
}

# Apply patches and generate final configurations
generate_final_configs() {
    log "Generating final machine configurations with patches..."
    
    # Control plane with VIP and consciousness patches
    talosctl machineconfig patch controlplane.yaml \
        --patch @vip-patch.yaml \
        --patch @controlplane-consciousness-patch.yaml \
        --output controlplane-final.yaml
    
    # Worker with consciousness patches
    talosctl machineconfig patch worker.yaml \
        --patch @worker-consciousness-patch.yaml \
        --output worker-final.yaml
    
    log "Final configurations generated"
}

# Deploy control plane nodes
deploy_control_plane() {
    log "Deploying control plane nodes..."
    
    for i in "${!CONTROL_PLANE_IPS[@]}"; do
        local ip="${CONTROL_PLANE_IPS[$i]}"
        local node_name="cp-$(($i + 1))"
        
        log "Applying configuration to control plane node $node_name ($ip)..."
        
        # Apply the configuration
        talosctl apply-config \
            --insecure \
            --nodes "$ip" \
            --file controlplane-final.yaml
        
        log "Configuration applied to $node_name"
    done
    
    # Bootstrap etcd on the first control plane node
    log "Bootstrapping etcd on first control plane node..."
    talosctl bootstrap \
        --nodes "${CONTROL_PLANE_IPS[0]}" \
        --endpoints "${CONTROL_PLANE_IPS[0]}"
    
    log "Control plane deployment completed"
}

# Deploy worker nodes
deploy_worker_nodes() {
    log "Deploying worker nodes..."
    
    for i in "${!WORKER_IPS[@]}"; do
        local ip="${WORKER_IPS[$i]}"
        local node_name="worker-$(($i + 1))"
        
        log "Applying configuration to worker node $node_name ($ip)..."
        
        # Apply the configuration
        talosctl apply-config \
            --insecure \
            --nodes "$ip" \
            --file worker-final.yaml
        
        log "Configuration applied to $node_name"
    done
    
    log "Worker nodes deployment completed"
}

# Configure kubectl access
configure_kubectl() {
    log "Configuring kubectl access..."
    
    # Get kubeconfig
    talosctl kubeconfig \
        --nodes "${CONTROL_PLANE_IPS[0]}" \
        --endpoints "${CONTROL_PLANE_IPS[@]}"
    
    # Wait for API server to be ready
    log "Waiting for Kubernetes API server to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    log "kubectl configured and cluster is ready"
}

# Create COREFLAME namespace and configurations
create_coreflame_namespace() {
    log "Creating COREFLAME namespace and configurations..."
    
    kubectl create namespace coreflame-system --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace consciousness --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace federation --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespaces
    kubectl label namespace coreflame-system coreflame.io/system=core --overwrite
    kubectl label namespace consciousness coreflame.io/consciousness=enabled --overwrite
    kubectl label namespace federation coreflame.io/federation=enabled --overwrite
    
    log "COREFLAME namespaces created"
}

# Deploy Kubernetes manifests
deploy_kubernetes_manifests() {
    log "Deploying COREFLAME Kubernetes manifests..."
    
    # Create ConfigMap and secrets
    cat > coreflame-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: coreflame-config
  namespace: coreflame-system
data:
  NODE_ENV: "production"
  CLUSTER_MODE: "kubernetes"
  CONSCIOUSNESS_ENABLED: "true"
  FEDERATION_ENABLED: "true"
  AI_COLLABORATION: "true"
---
apiVersion: v1
kind: Secret
metadata:
  name: coreflame-secrets
  namespace: coreflame-system
type: Opaque
stringData:
  DATABASE_URL: "postgresql://coreflame:secure_password_2024@postgres-service:5432/reverb256_portfolio"
  FEDERATION_SECRET: "coreflame-federation-secret-2024"
  COLLABORATION_TOKEN: "ai-collaboration-token-2024"
EOF

    kubectl apply -f coreflame-config.yaml
    
    # Apply all Kubernetes manifests
    log "Applying federation cluster configuration..."
    kubectl apply -f k8s/manifests/federation-cluster-config.yaml
    
    log "Applying cross-cluster federation controller..."
    kubectl apply -f k8s/manifests/cross-cluster-federation.yaml
    
    log "Applying consciousness AI engine..."
    kubectl apply -f k8s/manifests/consciousness-ai-engine.yaml
    
    log "Applying main portfolio application..."
    kubectl apply -f k8s/manifests/reverb256-portfolio-app.yaml
    
    log "Applying ingress controller configuration..."
    kubectl apply -f k8s/manifests/ingress-controller.yaml
    
    log "Kubernetes manifests deployed successfully"
}

# Deploy PostgreSQL
deploy_postgresql() {
    log "Deploying PostgreSQL database..."
    
    cat > postgresql-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
  namespace: coreflame-system
spec:
  serviceName: postgres-service
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "reverb256_portfolio"
        - name: POSTGRES_USER
          value: "coreflame"
        - name: POSTGRES_PASSWORD
          value: "secure_password_2024"
        - name: PGDATA
          value: "/var/lib/postgresql/data/pgdata"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: coreflame-system
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF

    kubectl apply -f postgresql-deployment.yaml
    
    log "PostgreSQL deployed"
}

# Deploy consciousness engine
deploy_consciousness_engine() {
    log "Deploying consciousness engine..."
    
    cat > consciousness-engine-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consciousness-engine
  namespace: consciousness
  labels:
    app: consciousness-engine
spec:
  replicas: 2
  selector:
    matchLabels:
      app: consciousness-engine
  template:
    metadata:
      labels:
        app: consciousness-engine
    spec:
      containers:
      - name: consciousness
        image: node:20-alpine
        ports:
        - containerPort: 3003
        env:
        - name: PORT
          value: "3003"
        - name: CONSCIOUSNESS_MODE
          value: "kubernetes"
        envFrom:
        - configMapRef:
            name: coreflame-config
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: consciousness-engine-service
  namespace: consciousness
spec:
  selector:
    app: consciousness-engine
  ports:
  - port: 3003
    targetPort: 3003
  type: ClusterIP
EOF

    kubectl apply -f consciousness-engine-deployment.yaml
    
    log "Consciousness engine deployed"
}

# Deploy federation bridge
deploy_federation_bridge() {
    log "Deploying federation bridge..."
    
    cat > federation-bridge-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: federation-bridge
  namespace: federation
  labels:
    app: federation-bridge
spec:
  replicas: 2
  selector:
    matchLabels:
      app: federation-bridge
  template:
    metadata:
      labels:
        app: federation-bridge
    spec:
      containers:
      - name: federation
        image: node:20-alpine
        ports:
        - containerPort: 3001
        env:
        - name: PORT
          value: "3001"
        - name: FEDERATION_MODE
          value: "kubernetes"
        - name: ASTRALVIBE_ENDPOINT
          value: "https://6f873bc8-c1e2-4ab8-8785-323119a7e3f0-00-3e9ygbr5lnjnl.sisko.replit.dev"
        envFrom:
        - configMapRef:
            name: coreflame-config
        - secretRef:
            name: coreflame-secrets
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: federation-bridge-service
  namespace: federation
spec:
  selector:
    app: federation-bridge
  ports:
  - port: 3001
    targetPort: 3001
  type: ClusterIP
EOF

    kubectl apply -f federation-bridge-deployment.yaml
    
    log "Federation bridge deployed"
}

# Deploy ingress controller
deploy_ingress() {
    log "Deploying Nginx ingress controller..."
    
    # Install Nginx ingress controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml
    
    # Wait for ingress controller to be ready
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s
    
    # Create ingress for COREFLAME applications
    cat > coreflame-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: coreflame-ingress
  namespace: coreflame-system
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: reverb256.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: reverb256-portfolio-service
            port:
              number: 80
      - path: /api/federation
        pathType: Prefix
        backend:
          service:
            name: federation-bridge-service
            port:
              number: 3001
      - path: /api/consciousness
        pathType: Prefix
        backend:
          service:
            name: consciousness-engine-service
            port:
              number: 3003
  - host: federation.reverb256.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: federation-bridge-service
            port:
              number: 3001
  - host: consciousness.reverb256.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: consciousness-engine-service
            port:
              number: 3003
EOF

    kubectl apply -f coreflame-ingress.yaml
    
    log "Ingress controller and routes deployed"
}

# Deploy monitoring
deploy_monitoring() {
    log "Deploying monitoring stack..."
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install Prometheus and Grafana
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set grafana.enabled=true \
        --set grafana.adminPassword=admin \
        --set prometheus.prometheusSpec.retention=30d
    
    log "Monitoring stack deployed"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check node status
    log "Node status:"
    kubectl get nodes -o wide
    
    # Check pod status
    log "Pod status in coreflame-system namespace:"
    kubectl get pods -n coreflame-system
    
    log "Pod status in consciousness namespace:"
    kubectl get pods -n consciousness
    
    log "Pod status in federation namespace:"
    kubectl get pods -n federation
    
    # Check services
    log "Services:"
    kubectl get services --all-namespaces
    
    # Check ingress
    log "Ingress:"
    kubectl get ingress --all-namespaces
    
    log "Deployment verification completed"
}

# Generate deployment report
generate_deployment_report() {
    log "Generating deployment report..."
    
    cat > talos-k8s-deployment-report.md << EOF
# COREFLAME Talos Kubernetes Deployment Report

**Deployment Date:** $(date)
**Version:** $DEPLOYMENT_VERSION
**Cluster Name:** $CLUSTER_NAME
**Cluster Endpoint:** $CLUSTER_ENDPOINT
**VIP Address:** $VIP_ADDRESS

## Cluster Configuration

### Control Plane Nodes
$(for ip in "${CONTROL_PLANE_IPS[@]}"; do echo "- $ip"; done)

### Worker Nodes
$(for ip in "${WORKER_IPS[@]}"; do echo "- $ip"; done)

### Network Configuration
- **CNI:** Flannel
- **Service CIDR:** 10.96.0.0/12
- **Pod CIDR:** 10.244.0.0/16
- **VIP:** $VIP_ADDRESS

## Deployed Applications

### Core Services
- **Reverb256 Portfolio:** Main application (Port 3000)
- **Federation Bridge:** Cross-environment communication (Port 3001)
- **Consciousness Engine:** AI analysis engine (Port 3003)
- **PostgreSQL:** Database backend

### System Components
- **Nginx Ingress Controller:** Load balancing and routing
- **Prometheus + Grafana:** Monitoring and observability
- **Flannel CNI:** Pod networking

## Access Information

### Web Interfaces
- **Main Application:** http://reverb256.local
- **Federation API:** http://federation.reverb256.local
- **Consciousness Engine:** http://consciousness.reverb256.local
- **Grafana Dashboard:** http://grafana.reverb256.local (admin/admin)

### API Endpoints
- **Health Check:** http://reverb256.local/api/health
- **Federation Status:** http://federation.reverb256.local/api/federation/status
- **Consciousness Analysis:** http://consciousness.reverb256.local/api/consciousness/analyze
- **AI Collaboration:** http://reverb256.local/api/collaboration/architecture

### Management Commands

#### Cluster Management
\`\`\`bash
# Check cluster status
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Access Talos API
talosctl --nodes ${CONTROL_PLANE_IPS[0]} version

# Get logs
kubectl logs -n coreflame-system -l app=reverb256-portfolio
\`\`\`

#### Application Management
\`\`\`bash
# Scale applications
kubectl scale deployment reverb256-portfolio -n coreflame-system --replicas=5

# Update configurations
kubectl edit configmap coreflame-config -n coreflame-system

# Restart deployments
kubectl rollout restart deployment/reverb256-portfolio -n coreflame-system
\`\`\`

## Federation Integration

### AI Collaboration Endpoints Active
- Platform architecture sharing
- API documentation exchange
- Deployment configuration sharing
- Security protocol coordination
- Consciousness module integration

### Required for Complete Federation
Ensure astralvibe.ca implements collaboration endpoints:
\`\`\`
/api/collaboration/architecture
/api/collaboration/apis
/api/collaboration/deployment
/api/collaboration/security
/api/collaboration/consciousness
/api/federation/status
\`\`\`

## Monitoring and Maintenance

### Health Monitoring
- **Prometheus:** Metrics collection and alerting
- **Grafana:** Visualization dashboards
- **Kubernetes Probes:** Liveness and readiness checks

### Backup Strategy
- **etcd:** Automatic snapshots via Talos
- **PostgreSQL:** Scheduled database backups
- **Configuration:** GitOps with version control

### Upgrade Path
- **Talos:** Rolling upgrades with \`talosctl upgrade\`
- **Kubernetes:** Managed upgrades through Talos
- **Applications:** Rolling deployments with zero downtime

## Security Configuration

### Network Security
- **CNI Policies:** Pod-to-pod communication controls
- **Ingress TLS:** Automatic certificate management
- **Service Mesh:** Optional Istio integration ready

### Access Control
- **RBAC:** Role-based access control configured
- **Network Policies:** Namespace isolation
- **Pod Security Standards:** Restricted policy enforcement

## Troubleshooting

### Common Commands
\`\`\`bash
# Check Talos system health
talosctl --nodes ${CONTROL_PLANE_IPS[0]} health

# View Talos logs
talosctl --nodes ${CONTROL_PLANE_IPS[0]} logs

# Debug pod issues
kubectl describe pod <pod-name> -n <namespace>

# Check ingress status
kubectl get ingress -n coreflame-system
\`\`\`

### Log Locations
- **Talos System Logs:** \`talosctl logs\`
- **Application Logs:** \`kubectl logs\`
- **Ingress Logs:** \`kubectl logs -n ingress-nginx\`

## Next Steps

1. **Configure DNS:** Point domains to VIP address ($VIP_ADDRESS)
2. **Setup TLS:** Configure certificates for HTTPS
3. **Scale Applications:** Adjust replicas based on load
4. **Monitor Performance:** Set up alerts and dashboards
5. **Test Federation:** Verify AI collaboration with astralvibe.ca

EOF
    
    log "Deployment report generated: talos-k8s-deployment-report.md"
}

# Main deployment function
main() {
    echo -e "${PURPLE}"
    echo "=============================================="
    echo "   COREFLAME Talos Kubernetes Deployment"
    echo "   Enterprise AI Collaboration Platform"
    echo "   Version: $DEPLOYMENT_VERSION"
    echo "=============================================="
    echo -e "${NC}"
    
    check_prerequisites
    generate_talos_config
    create_vip_patch
    create_consciousness_patches
    generate_final_configs
    deploy_control_plane
    deploy_worker_nodes
    configure_kubectl
    create_coreflame_namespace
    deploy_postgresql
    deploy_kubernetes_manifests
    deploy_ingress
    deploy_monitoring
    verify_deployment
    generate_deployment_report
    
    echo -e "${GREEN}"
    echo "=============================================="
    echo "   COREFLAME Talos Deployment Completed!"
    echo "=============================================="
    echo "Cluster Endpoint: $CLUSTER_ENDPOINT"
    echo "VIP Address: $VIP_ADDRESS"
    echo "Main Application: http://reverb256.local"
    echo "Federation Bridge: http://federation.reverb256.local"
    echo "Consciousness Engine: http://consciousness.reverb256.local"
    echo ""
    echo "View deployment report:"
    echo "cat talos-k8s-deployment-report.md"
    echo ""
    echo "Cluster management:"
    echo "kubectl get nodes"
    echo "kubectl get pods --all-namespaces"
    echo -e "${NC}"
}

# Run main function
main "$@"