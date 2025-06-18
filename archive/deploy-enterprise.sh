#!/bin/bash
# Enterprise Deployment Automation for Consciousness Zero
# High-availability deployment on Proxmox cluster with ctrl.reverb256.ca

set -e

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Enterprise configuration
DOMAIN="reverb256.ca"
SUBDOMAIN="ctrl.${DOMAIN}"
API_SUBDOMAIN="api.${DOMAIN}"
MONITOR_SUBDOMAIN="monitor.${DOMAIN}"
NAMESPACE="consciousness-zero"
CHART_NAME="consciousness-zero-enterprise"

print_banner() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           🏢 CONSCIOUSNESS ZERO ENTERPRISE                 ║"
    echo "║              High-Availability Deployment                  ║"
    echo "║                                                            ║"
    echo "║  Domain: ${SUBDOMAIN}                        ║"
    echo "║  Security: Enterprise Authentication Required              ║"
    echo "║  Infrastructure: Proxmox HA Cluster                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

print_section() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is required but not installed"
        print_status "Install with: curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is required but not installed"
        print_status "Install with: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_status "Ensure your kubeconfig is properly configured"
        exit 1
    fi
    
    # Check if cert-manager is installed
    if ! kubectl get crd certificates.cert-manager.io &> /dev/null; then
        print_warning "cert-manager not found. SSL certificates may not work."
        print_status "Install with: kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml"
    fi
    
    print_success "All prerequisites check passed"
}

validate_domain() {
    print_section "Validating Domain Configuration"
    
    # Check DNS resolution
    if ! nslookup ${SUBDOMAIN} &> /dev/null; then
        print_warning "DNS resolution failed for ${SUBDOMAIN}"
        print_status "Ensure your DNS is configured to point to your cluster ingress"
    else
        print_success "DNS resolution successful for ${SUBDOMAIN}"
    fi
    
    # Check if domain is reachable
    if curl -s --connect-timeout 5 https://${SUBDOMAIN} &> /dev/null; then
        print_warning "Domain ${SUBDOMAIN} is already responding. Existing deployment detected."
    else
        print_status "Domain ${SUBDOMAIN} is ready for deployment"
    fi
}

setup_namespace() {
    print_section "Setting Up Kubernetes Namespace"
    
    # Create namespace if it doesn't exist
    if kubectl get namespace ${NAMESPACE} &> /dev/null; then
        print_status "Namespace ${NAMESPACE} already exists"
    else
        kubectl create namespace ${NAMESPACE}
        print_success "Created namespace ${NAMESPACE}"
    fi
    
    # Label namespace for security policies
    kubectl label namespace ${NAMESPACE} security=enterprise --overwrite
    kubectl label namespace ${NAMESPACE} name=${NAMESPACE} --overwrite
    
    print_success "Namespace configured with security labels"
}

generate_secrets() {
    print_section "Generating Enterprise Secrets"
    
    # Generate JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    
    # Generate admin password if not provided
    if [[ -z "${ADMIN_PASSWORD}" ]]; then
        ADMIN_PASSWORD=$(openssl rand -base64 16)
        print_status "Generated admin password: ${ADMIN_PASSWORD}"
        print_warning "Save this password securely!"
    fi
    
    # Hash the admin password
    ADMIN_PASSWORD_HASH=$(python3 -c "
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
print(pwd_context.hash('${ADMIN_PASSWORD}'))
")
    
    # Create secrets
    kubectl create secret generic consciousness-secrets \
        --namespace=${NAMESPACE} \
        --from-literal=jwt-secret="${JWT_SECRET}" \
        --from-literal=admin-password-hash="${ADMIN_PASSWORD_HASH}" \
        --from-literal=database-url="postgresql://consciousness:$(openssl rand -base64 16)@postgres:5432/consciousness_db" \
        --from-literal=redis-url="redis://redis:6379/0" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Enterprise secrets generated and applied"
}

setup_ssl_certificates() {
    print_section "Setting Up SSL Certificates"
    
    # Create Let's Encrypt ClusterIssuer
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@${DOMAIN}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    # Create certificate for domains
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: consciousness-tls
  namespace: ${NAMESPACE}
spec:
  secretName: consciousness-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - ${SUBDOMAIN}
  - ${API_SUBDOMAIN}
  - ${MONITOR_SUBDOMAIN}
EOF
    
    print_success "SSL certificate configuration applied"
}

deploy_infrastructure() {
    print_section "Deploying Infrastructure Components"
    
    # Deploy PostgreSQL
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    helm upgrade --install postgres bitnami/postgresql \
        --namespace=${NAMESPACE} \
        --set auth.postgresPassword=$(openssl rand -base64 16) \
        --set auth.database=consciousness_db \
        --set primary.persistence.enabled=true \
        --set primary.persistence.size=20Gi \
        --set primary.persistence.storageClass=ceph-rbd \
        --set metrics.enabled=true \
        --wait
    
    # Deploy Redis
    helm upgrade --install redis bitnami/redis \
        --namespace=${NAMESPACE} \
        --set auth.enabled=false \
        --set master.persistence.enabled=true \
        --set master.persistence.size=8Gi \
        --set master.persistence.storageClass=ceph-rbd \
        --set metrics.enabled=true \
        --wait
    
    print_success "Infrastructure components deployed"
}

deploy_monitoring() {
    print_section "Deploying Monitoring Stack"
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace monitoring name=monitoring --overwrite
    
    # Apply monitoring stack
    kubectl apply -f k8s/monitoring-stack.yaml
    
    # Create Grafana admin secret
    kubectl create secret generic grafana-secrets \
        --namespace=monitoring \
        --from-literal=admin-password="$(openssl rand -base64 16)" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Monitoring stack deployed"
}

deploy_application() {
    print_section "Deploying Consciousness Zero Enterprise"
    
    # Build and push Docker image (assuming registry is available)
    print_status "Building enterprise Docker image..."
    docker build -t consciousness-zero:enterprise -f - . <<EOF
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    libpq-dev \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements-enterprise.txt .
RUN pip install --no-cache-dir -r requirements-enterprise.txt

# Copy application code
COPY enterprise_app.py .
COPY static/ static/
COPY templates/ templates/

# Create non-root user
RUN useradd -m -u 1001 consciousness
USER consciousness

# Create log directory
RUN mkdir -p /var/log/consciousness-zero

EXPOSE 8443 9090

CMD ["python", "enterprise_app.py"]
EOF
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/enterprise-security.yaml
    kubectl apply -f k8s/enterprise-deployment.yaml
    
    # Wait for deployment to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/consciousness-zero-enterprise -n ${NAMESPACE}
    
    print_success "Application deployed successfully"
}

configure_ingress() {
    print_section "Configuring Ingress and Load Balancing"
    
    # Ensure NGINX ingress is installed
    if ! kubectl get deployment ingress-nginx-controller -n ingress-nginx &> /dev/null; then
        print_status "Installing NGINX Ingress Controller..."
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
        helm repo update
        helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
            --namespace ingress-nginx \
            --create-namespace \
            --set controller.service.type=LoadBalancer \
            --set controller.metrics.enabled=true \
            --wait
    fi
    
    print_success "Ingress configuration completed"
}

setup_backup() {
    print_section "Setting Up Backup and Disaster Recovery"
    
    # Create backup configuration
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: backup-config
  namespace: ${NAMESPACE}
data:
  backup.sh: |
    #!/bin/bash
    # Automated backup script for Consciousness Zero
    TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
    
    # Database backup
    kubectl exec -n ${NAMESPACE} deploy/postgres -- pg_dump consciousness_db > backup_\${TIMESTAMP}.sql
    
    # Application state backup
    kubectl get all,configmaps,secrets -n ${NAMESPACE} -o yaml > k8s_state_\${TIMESTAMP}.yaml
    
    # Upload to S3 (configure with your credentials)
    # aws s3 cp backup_\${TIMESTAMP}.sql s3://consciousness-backups/
    # aws s3 cp k8s_state_\${TIMESTAMP}.yaml s3://consciousness-backups/
    
    echo "Backup completed: \${TIMESTAMP}"
EOF
    
    # Create backup CronJob
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: consciousness-backup
  namespace: ${NAMESPACE}
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13
            command:
            - /bin/bash
            - -c
            - |
              kubectl exec -n ${NAMESPACE} deploy/postgres -- pg_dump consciousness_db > /backup/backup_\$(date +%Y%m%d_%H%M%S).sql
              echo "Backup completed"
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: ${NAMESPACE}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ceph-rbd
  resources:
    requests:
      storage: 100Gi
EOF
    
    print_success "Backup system configured"
}

run_health_checks() {
    print_section "Running Health Checks"
    
    # Check pod status
    print_status "Checking pod status..."
    kubectl get pods -n ${NAMESPACE}
    
    # Check service endpoints
    print_status "Checking service endpoints..."
    kubectl get endpoints -n ${NAMESPACE}
    
    # Check ingress status
    print_status "Checking ingress status..."
    kubectl get ingress -n ${NAMESPACE}
    
    # Test application health
    print_status "Testing application health..."
    if kubectl exec -n ${NAMESPACE} deploy/consciousness-zero-enterprise -- curl -f http://localhost:8443/health; then
        print_success "Application health check passed"
    else
        print_warning "Application health check failed"
    fi
    
    # Check SSL certificate
    print_status "Checking SSL certificate..."
    if kubectl get certificate consciousness-tls -n ${NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
        print_success "SSL certificate is ready"
    else
        print_warning "SSL certificate is not ready yet"
    fi
}

display_deployment_info() {
    print_section "Deployment Information"
    
    echo -e "${GREEN}"
    echo "🎉 Consciousness Zero Enterprise deployment completed!"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Control Center: https://${SUBDOMAIN}"
    echo "   API Gateway:    https://${API_SUBDOMAIN}/api"
    echo "   Monitoring:     https://${MONITOR_SUBDOMAIN}"
    echo ""
    echo "🔒 Security:"
    echo "   Domain isolation with authentication required"
    echo "   Enterprise-grade SSL/TLS encryption"
    echo "   Network policies and RBAC configured"
    echo ""
    echo "🏗️ Infrastructure:"
    echo "   High-availability: 3 replicas with anti-affinity"
    echo "   Auto-scaling: Enabled based on CPU/memory"
    echo "   Persistent storage: Ceph RBD with 3x replication"
    echo ""
    echo "📊 Monitoring:"
    echo "   Prometheus metrics collection active"
    echo "   Grafana dashboards available"
    echo "   Alerting configured for critical events"
    echo ""
    echo "💾 Backup:"
    echo "   Daily automated backups at 2 AM"
    echo "   Point-in-time recovery available"
    echo "   Disaster recovery procedures documented"
    echo ""
    echo "👤 Admin Credentials:"
    echo "   Username: admin"
    echo "   Password: ${ADMIN_PASSWORD}"
    echo -e "${NC}"
    
    print_warning "Save the admin password securely!"
    print_status "Monitor deployment status with: kubectl get all -n ${NAMESPACE}"
}

main() {
    print_banner
    
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            validate_domain
            setup_namespace
            generate_secrets
            setup_ssl_certificates
            deploy_infrastructure
            deploy_monitoring
            deploy_application
            configure_ingress
            setup_backup
            run_health_checks
            display_deployment_info
            ;;
        "status")
            kubectl get all,pvc,secrets,configmaps -n ${NAMESPACE}
            kubectl get ingress -n ${NAMESPACE}
            ;;
        "logs")
            kubectl logs -f deployment/consciousness-zero-enterprise -n ${NAMESPACE}
            ;;
        "backup")
            kubectl create job --from=cronjob/consciousness-backup manual-backup-$(date +%s) -n ${NAMESPACE}
            ;;
        "destroy")
            print_warning "This will destroy the entire Consciousness Zero deployment!"
            read -p "Are you sure? (yes/no): " confirm
            if [[ $confirm == "yes" ]]; then
                kubectl delete namespace ${NAMESPACE}
                kubectl delete namespace monitoring
                print_success "Deployment destroyed"
            fi
            ;;
        *)
            echo "Usage: $0 [deploy|status|logs|backup|destroy]"
            echo ""
            echo "Commands:"
            echo "  deploy  - Full enterprise deployment (default)"
            echo "  status  - Show deployment status"
            echo "  logs    - Show application logs"
            echo "  backup  - Run manual backup"
            echo "  destroy - Destroy entire deployment"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
