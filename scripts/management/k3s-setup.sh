#!/bin/bash

# K3s High Availability Setup Script for Quantum AI Trading Platform
# Deploys a production-ready k3s cluster with self-healing capabilities

set -e

echo "🚀 Setting up K3s cluster for Quantum AI Trading Platform..."

# Configuration
CLUSTER_NAME="quantum-trading"
MASTER_NODES=3
WORKER_NODES=2
DOMAIN="quantum-trading.ai"

# Install k3s on master nodes
install_k3s_master() {
    local node_id=$1
    echo "📋 Installing k3s master node $node_id..."
    
    # Install k3s with embedded etcd for HA
    curl -sfL https://get.k3s.io | sh -s - server \
        --cluster-init \
        --token=quantum-ai-cluster-token \
        --tls-san=$DOMAIN \
        --tls-san=api.$DOMAIN \
        --disable=traefik \
        --disable=servicelb \
        --write-kubeconfig-mode=644 \
        --node-name=master-$node_id
    
    # Enable and start k3s
    systemctl enable k3s
    systemctl start k3s
    
    echo "✅ Master node $node_id ready"
}

# Install k3s on worker nodes
install_k3s_worker() {
    local node_id=$1
    local master_ip=$2
    echo "📋 Installing k3s worker node $node_id..."
    
    curl -sfL https://get.k3s.io | K3S_URL=https://$master_ip:6443 \
        K3S_TOKEN=quantum-ai-cluster-token \
        sh -s - --node-name=worker-$node_id
    
    systemctl enable k3s-agent
    systemctl start k3s-agent
    
    echo "✅ Worker node $node_id ready"
}

# Setup load balancer
setup_load_balancer() {
    echo "⚖️ Setting up HAProxy load balancer..."
    
    # Install HAProxy
    apt-get update
    apt-get install -y haproxy
    
    # Configure HAProxy for k3s API server
    cat > /etc/haproxy/haproxy.cfg << EOF
global
    maxconn 4096
    log stdout local0

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend k3s_frontend
    bind *:6443
    default_backend k3s_backend

backend k3s_backend
    balance roundrobin
    server master-1 10.0.1.10:6443 check
    server master-2 10.0.1.11:6443 check
    server master-3 10.0.1.12:6443 check

frontend http_frontend
    bind *:80
    default_backend quantum_ai_backend

frontend https_frontend
    bind *:443
    default_backend quantum_ai_backend

backend quantum_ai_backend
    balance roundrobin
    server worker-1 10.0.1.20:80 check
    server worker-2 10.0.1.21:80 check
EOF

    systemctl enable haproxy
    systemctl restart haproxy
    
    echo "✅ Load balancer configured"
}

# Install cert-manager for SSL
install_cert_manager() {
    echo "🔒 Installing cert-manager..."
    
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s
    
    # Create cluster issuer
    cat > cluster-issuer.yaml << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@quantum-trading.ai
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
EOF
    
    kubectl apply -f cluster-issuer.yaml
    echo "✅ Cert-manager installed"
}

# Install Traefik ingress controller
install_traefik() {
    echo "🚪 Installing Traefik ingress controller..."
    
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo update
    
    cat > traefik-values.yaml << EOF
deployment:
  replicas: 2

service:
  type: LoadBalancer

ingressRoute:
  dashboard:
    enabled: true

providers:
  kubernetesCRD:
    enabled: true
  kubernetesIngress:
    enabled: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@quantum-trading.ai
      storage: /data/acme.json
      httpChallenge:
        entryPoint: web
EOF
    
    helm install traefik traefik/traefik -f traefik-values.yaml -n traefik-system --create-namespace
    
    echo "✅ Traefik installed"
}

# Install monitoring stack
install_monitoring() {
    echo "📊 Installing monitoring stack..."
    
    # Install Prometheus
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    cat > prometheus-values.yaml << EOF
server:
  persistentVolume:
    size: 20Gi
  
alertmanager:
  persistentVolume:
    size: 2Gi

nodeExporter:
  enabled: true

pushgateway:
  enabled: true
EOF
    
    helm install prometheus prometheus-community/prometheus -f prometheus-values.yaml -n monitoring --create-namespace
    
    # Install Grafana
    helm repo add grafana https://grafana.github.io/helm-charts
    
    cat > grafana-values.yaml << EOF
persistence:
  enabled: true
  size: 10Gi

adminPassword: quantum-ai-secure-password

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.monitoring.svc.cluster.local
      access: proxy
      isDefault: true
EOF
    
    helm install grafana grafana/grafana -f grafana-values.yaml -n monitoring
    
    echo "✅ Monitoring stack installed"
}

# Deploy the quantum AI trading application
deploy_application() {
    echo "🚀 Deploying Quantum AI Trading Platform..."
    
    # Apply the k3s deployment
    kubectl apply -f k3s-ha-deployment.yaml
    
    # Wait for deployments to be ready
    kubectl wait --for=condition=available deployment/quantum-ai-frontend -n quantum-trading-platform --timeout=300s
    kubectl wait --for=condition=available deployment/quantum-ai-backend -n quantum-trading-platform --timeout=300s
    
    echo "✅ Application deployed successfully"
}

# Setup backup system
setup_backups() {
    echo "💾 Setting up automated backups..."
    
    # Install Velero for cluster backups
    wget https://github.com/vmware-tanzu/velero/releases/latest/download/velero-linux-amd64.tar.gz
    tar -xzf velero-linux-amd64.tar.gz
    mv velero-*/velero /usr/local/bin/
    
    # Configure backup storage (example with S3)
    cat > backup-storage.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloud-credentials
  namespace: velero
type: Opaque
data:
  cloud: $(echo -n "[default]\naws_access_key_id=$AWS_ACCESS_KEY_ID\naws_secret_access_key=$AWS_SECRET_ACCESS_KEY" | base64 -w 0)
EOF
    
    # Install Velero
    velero install \
        --provider aws \
        --plugins velero/velero-plugin-for-aws:v1.7.0 \
        --bucket quantum-ai-backups \
        --secret-file backup-storage.yaml \
        --backup-location-config region=us-west-2
    
    # Schedule daily backups
    velero schedule create daily-backup --schedule="0 2 * * *"
    
    echo "✅ Backup system configured"
}

# Main installation flow
main() {
    echo "🎯 Starting K3s HA installation for Quantum AI Trading Platform"
    
    # Check prerequisites
    if ! command -v curl &> /dev/null; then
        echo "❌ curl is required but not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        echo "📦 Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # Install first master node
    install_k3s_master 1
    
    # Copy kubeconfig for kubectl access
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    
    # Install additional master nodes (if running on multiple servers)
    # install_k3s_master 2
    # install_k3s_master 3
    
    # Install worker nodes (if running on multiple servers)
    # install_k3s_worker 1 $(hostname -I | awk '{print $1}')
    # install_k3s_worker 2 $(hostname -I | awk '{print $1}')
    
    # Setup load balancer (if using multiple nodes)
    # setup_load_balancer
    
    # Install core components
    install_cert_manager
    install_traefik
    install_monitoring
    
    # Deploy the application
    deploy_application
    
    # Setup backups
    setup_backups
    
    echo "🎉 K3s cluster setup complete!"
    echo "📊 Access Grafana: https://grafana.$DOMAIN"
    echo "🔍 Access Traefik Dashboard: https://traefik.$DOMAIN/dashboard/"
    echo "🚀 Application: https://$DOMAIN"
    echo "🔧 API: https://api.$DOMAIN"
    
    # Display cluster status
    kubectl get nodes
    kubectl get pods --all-namespaces
}

# Run main function
main "$@"