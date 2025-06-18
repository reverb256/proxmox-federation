#!/bin/bash

# Deploy complete consciousness federation stack to Talos Kubernetes
# Enterprise-grade deployment with monitoring, SSL, and AI workloads

set -euo pipefail

# Configuration
NAMESPACE="consciousness-federation"
HELM_TIMEOUT="600s"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check kubectl access
    if ! kubectl get nodes &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        log "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    success "Prerequisites check completed"
}

# Add required Helm repositories
setup_helm_repos() {
    log "Setting up Helm repositories..."
    
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add jetstack https://charts.jetstack.io
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
    
    helm repo update
    
    success "Helm repositories configured"
}

# Create namespace and basic resources
setup_namespace() {
    log "Setting up consciousness federation namespace..."
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace
    kubectl label namespace "$NAMESPACE" \
        consciousness.astralvibe.ca/federation-role=primary \
        --overwrite
    
    success "Namespace configured"
}

# Install cert-manager for SSL
install_cert_manager() {
    log "Installing cert-manager..."
    
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.14.5 \
        --set installCRDs=true \
        --wait --timeout="$HELM_TIMEOUT"
    
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
    
    success "cert-manager installed"
}

# Install NGINX Ingress Controller
install_ingress() {
    log "Installing NGINX Ingress Controller..."
    
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=LoadBalancer \
        --set controller.service.loadBalancerIP=192.168.1.100 \
        --set controller.metrics.enabled=true \
        --wait --timeout="$HELM_TIMEOUT"
    
    success "NGINX Ingress Controller installed"
}

# Install PostgreSQL database
install_database() {
    log "Installing PostgreSQL database..."
    
    helm upgrade --install consciousness-db bitnami/postgresql \
        --namespace "$NAMESPACE" \
        --set auth.postgresPassword="consciousness-$(openssl rand -base64 12)" \
        --set auth.database="consciousness_federation" \
        --set primary.persistence.enabled=true \
        --set primary.persistence.size=100Gi \
        --set primary.persistence.storageClass=fast-ssd \
        --set primary.resources.requests.cpu=1000m \
        --set primary.resources.requests.memory=2Gi \
        --set primary.resources.limits.cpu=2000m \
        --set primary.resources.limits.memory=4Gi \
        --wait --timeout="$HELM_TIMEOUT"
    
    success "PostgreSQL database installed"
}

# Install Redis cache
install_redis() {
    log "Installing Redis cache..."
    
    helm upgrade --install consciousness-cache bitnami/redis \
        --namespace "$NAMESPACE" \
        --set auth.enabled=true \
        --set auth.password="consciousness-cache-$(openssl rand -base64 12)" \
        --set master.persistence.enabled=true \
        --set master.persistence.size=20Gi \
        --set master.persistence.storageClass=fast-ssd \
        --wait --timeout="$HELM_TIMEOUT"
    
    success "Redis cache installed"
}

# Install GPU operator
install_gpu_operator() {
    log "Installing NVIDIA GPU Operator..."
    
    # Check if any nodes have GPUs
    if ! kubectl get nodes -l feature.node.kubernetes.io/pci-10de.present=true 2>/dev/null | grep -q Ready; then
        warning "No GPU nodes detected, skipping GPU operator"
        return 0
    fi
    
    helm upgrade --install gpu-operator nvidia/gpu-operator \
        --namespace gpu-operator \
        --create-namespace \
        --set driver.enabled=true \
        --set toolkit.enabled=true \
        --set dcgm.enabled=true \
        --wait --timeout="$HELM_TIMEOUT"
    
    success "GPU operator installed"
}

# Install monitoring stack
install_monitoring() {
    log "Installing monitoring stack..."
    
    # Install Prometheus
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set grafana.adminPassword="consciousness-monitor-$(openssl rand -base64 12)" \
        --set prometheus.prometheusSpec.retention=30d \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=fast-ssd \
        --set grafana.persistence.enabled=true \
        --set grafana.persistence.size=10Gi \
        --set grafana.persistence.storageClassName=fast-ssd \
        --wait --timeout="$HELM_TIMEOUT"
    
    success "Monitoring stack installed"
}

# Deploy consciousness applications
deploy_consciousness_apps() {
    log "Deploying consciousness applications..."
    
    # Create consciousness secrets
    kubectl create secret generic consciousness-secrets \
        --namespace="$NAMESPACE" \
        --from-literal=database-url="postgresql://postgres:$(kubectl get secret consciousness-db-postgresql -n $NAMESPACE -o jsonpath='{.data.postgres-password}' | base64 -d)@consciousness-db-postgresql:5432/consciousness_federation" \
        --from-literal=redis-url="redis://:$(kubectl get secret consciousness-cache -n $NAMESPACE -o jsonpath='{.data.redis-password}' | base64 -d)@consciousness-cache-master:6379" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply consciousness workloads
    kubectl apply -f k8s/consciousness-ai-workloads.yaml
    
    # Wait for deployments
    kubectl wait --for=condition=Available deployments --all -n "$NAMESPACE" --timeout=600s
    
    success "Consciousness applications deployed"
}

# Verify deployment
verify_deployment() {
    log "Verifying consciousness federation deployment..."
    
    echo
    echo "=== Cluster Status ==="
    kubectl get nodes -o wide
    
    echo
    echo "=== Consciousness Workloads ==="
    kubectl get pods -n "$NAMESPACE" -o wide
    
    echo
    echo "=== Services ==="
    kubectl get services -n "$NAMESPACE"
    
    echo
    echo "=== Ingress ==="
    kubectl get ingress -n "$NAMESPACE"
    
    echo
    echo "=== Persistent Volumes ==="
    kubectl get pv
    
    echo
    echo "=== GPU Resources ==="
    kubectl describe nodes | grep -A 5 "nvidia.com/gpu" || echo "No GPUs detected"
    
    success "Deployment verification completed"
}

# Get access information
show_access_info() {
    log "Gathering access information..."
    
    echo
    echo "🌐 Access URLs:"
    echo "  Portfolio: https://portfolio.astralvibe.ca"
    echo "  Astralvibe: https://astralvibe.ca"
    echo
    
    echo "📊 Monitoring:"
    echo "  Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo "  Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo
    
    echo "🗄️  Database:"
    echo "  PostgreSQL: kubectl port-forward -n $NAMESPACE svc/consciousness-db-postgresql 5432:5432"
    echo "  Redis: kubectl port-forward -n $NAMESPACE svc/consciousness-cache-master 6379:6379"
    echo
    
    echo "🔑 Secrets:"
    echo "  Database password: kubectl get secret consciousness-db-postgresql -n $NAMESPACE -o jsonpath='{.data.postgres-password}' | base64 -d"
    echo "  Redis password: kubectl get secret consciousness-cache -n $NAMESPACE -o jsonpath='{.data.redis-password}' | base64 -d"
    echo "  Grafana password: kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d"
}

# Main deployment function
main() {
    echo "🧠 Deploying Consciousness Federation Stack"
    echo "==========================================="
    echo "Target namespace: $NAMESPACE"
    echo "Kubernetes cluster: $(kubectl config current-context)"
    echo
    
    check_prerequisites
    setup_helm_repos
    setup_namespace
    install_cert_manager
    install_ingress
    install_database
    install_redis
    install_gpu_operator
    install_monitoring
    deploy_consciousness_apps
    verify_deployment
    show_access_info
    
    echo
    success "Consciousness Federation Stack deployed successfully!"
    echo
    echo "Next steps:"
    echo "1. Update DNS records to point to your cluster IP"
    echo "2. Wait for SSL certificates to be issued"
    echo "3. Access the applications via the URLs above"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "verify")
        verify_deployment
        ;;
    "info")
        show_access_info
        ;;
    "uninstall")
        log "Uninstalling consciousness federation..."
        kubectl delete namespace "$NAMESPACE" --ignore-not-found
        helm uninstall prometheus -n monitoring || true
        helm uninstall cert-manager -n cert-manager || true
        helm uninstall ingress-nginx -n ingress-nginx || true
        helm uninstall gpu-operator -n gpu-operator || true
        success "Consciousness federation uninstalled"
        ;;
    *)
        echo "Usage: $0 {deploy|verify|info|uninstall}"
        echo
        echo "Commands:"
        echo "  deploy     - Deploy complete consciousness stack (default)"
        echo "  verify     - Verify deployment status"
        echo "  info       - Show access information"
        echo "  uninstall  - Remove consciousness federation"
        exit 1
        ;;
esac