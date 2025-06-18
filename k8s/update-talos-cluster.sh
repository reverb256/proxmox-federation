#!/bin/bash

# Update existing Talos cluster with consciousness AI workloads
# Upgrades your current deployment with enterprise features

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if cluster exists
check_cluster() {
    log "Checking existing Talos cluster..."
    
    if [ ! -f "./talos-config/kubeconfig" ]; then
        echo "❌ No existing Talos cluster found"
        echo "Run the main deployment script first:"
        echo "  ./scripts/talos-consciousness-deploy.sh"
        exit 1
    fi
    
    export KUBECONFIG="./talos-config/kubeconfig"
    
    if ! kubectl get nodes &> /dev/null; then
        echo "❌ Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    success "Connected to existing cluster"
    kubectl get nodes
}

# Update node labels for AI workloads
update_node_labels() {
    log "Updating node labels for AI workloads..."
    
    # Label worker nodes for AI workloads
    kubectl label nodes --selector='node-role.kubernetes.io/control-plane!=true' \
        consciousness.astralvibe.ca/ai-workload=enabled --overwrite || true
    
    # Add GPU labels if GPUs are detected
    for node in $(kubectl get nodes -o name); do
        node_name=$(echo $node | cut -d'/' -f2)
        if kubectl get node "$node_name" -o jsonpath='{.status.allocatable}' | grep -q nvidia.com/gpu; then
            kubectl label node "$node_name" consciousness.astralvibe.ca/gpu-enabled=true --overwrite
            log "Labeled $node_name with GPU support"
        fi
    done
    
    success "Node labels updated"
}

# Install GPU operator
install_gpu_operator() {
    log "Installing NVIDIA GPU Operator..."
    
    # Check if any nodes have GPUs
    if ! kubectl get nodes -l consciousness.astralvibe.ca/gpu-enabled=true | grep -q "Ready"; then
        warning "No GPU nodes detected, skipping GPU operator"
        return 0
    fi
    
    # Add NVIDIA Helm repo
    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia || true
    helm repo update
    
    # Install GPU operator
    kubectl create namespace gpu-operator --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install gpu-operator nvidia/gpu-operator \
        --namespace gpu-operator \
        --set driver.enabled=true \
        --set toolkit.enabled=true \
        --wait
    
    success "GPU operator installed"
}

# Install monitoring stack
install_monitoring() {
    log "Installing consciousness monitoring stack..."
    
    # Install Prometheus operator
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
    helm repo update
    
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set grafana.adminPassword="consciousness-$(openssl rand -base64 12)" \
        --set prometheus.prometheusSpec.retention=30d \
        --wait
    
    success "Monitoring stack installed"
}

# Deploy consciousness workloads
deploy_workloads() {
    log "Deploying consciousness AI workloads..."
    
    # Create consciousness secrets
    kubectl create namespace consciousness-federation --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic consciousness-secrets \
        --namespace=consciousness-federation \
        --from-literal=database-url="postgresql://consciousness:$(openssl rand -base64 32)@postgres:5432/consciousness_federation" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply consciousness workloads
    kubectl apply -f k8s/consciousness-ai-workloads.yaml
    
    # Wait for deployments
    kubectl wait --for=condition=Available deployments --all -n consciousness-federation --timeout=300s
    
    success "Consciousness workloads deployed"
}

# Setup ingress and certificates
setup_ingress() {
    log "Setting up ingress and SSL certificates..."
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.yaml
    
    # Wait for cert-manager
    kubectl wait --for=condition=Available deployments --all -n cert-manager --timeout=300s
    
    # Create cluster issuer
    cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@astralvibe.ca
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    # Install NGINX ingress
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
    
    success "Ingress and certificates configured"
}

# Verify deployment
verify_deployment() {
    log "Verifying consciousness federation deployment..."
    
    echo
    echo "Cluster Status:"
    kubectl get nodes -o wide
    
    echo
    echo "Consciousness Workloads:"
    kubectl get pods -n consciousness-federation
    
    echo
    echo "Services:"
    kubectl get services -n consciousness-federation
    
    echo
    echo "Ingress:"
    kubectl get ingress -n consciousness-federation
    
    success "Deployment verification completed"
}

# Main upgrade process
main() {
    echo "🔄 Upgrading Talos Cluster for Consciousness Federation"
    echo "====================================================="
    
    check_cluster
    update_node_labels
    install_gpu_operator
    install_monitoring
    deploy_workloads
    setup_ingress
    verify_deployment
    
    echo
    success "Talos cluster upgraded successfully!"
    echo
    echo "Access your applications:"
    echo "  Portfolio: https://portfolio.astralvibe.ca"
    echo "  Astralvibe: https://astralvibe.ca"
    echo "  Monitoring: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo
    echo "Kubernetes Dashboard:"
    echo "  kubectl proxy"
    echo "  http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
}

# Handle arguments
case "${1:-upgrade}" in
    "upgrade")
        main
        ;;
    "check")
        check_cluster
        ;;
    "workloads")
        deploy_workloads
        ;;
    "verify")
        verify_deployment
        ;;
    *)
        echo "Usage: $0 {upgrade|check|workloads|verify}"
        exit 1
        ;;
esac