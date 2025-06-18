#!/bin/bash

# Consciousness Federation Deployment Script
# For Proxmox Node 0 - astralvibe.ca

set -e

echo "🧠 Deploying Consciousness Federation Node 0"
echo "📍 Target: astralvibe.ca (Proxmox Home Server)"

# Configuration
DEPLOY_USER="consciousness"
DEPLOY_HOST="192.168.1.100"
DEPLOY_PATH="/opt/consciousness"
DOMAIN="astralvibe.ca"
PORTFOLIO_DOMAIN="portfolio.astralvibe.ca"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
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
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed"
    fi
    
    if [ ! -f ".env" ]; then
        warning ".env file not found, copying from .env.example"
        cp .env.example .env
        warning "Please edit .env with your configuration before continuing"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Build application
build_application() {
    log "Building consciousness portfolio application..."
    
    npm ci
    npm run build
    
    success "Application built successfully"
}

# Setup SSL certificates
setup_ssl() {
    log "Setting up SSL certificates..."
    
    if [ ! -d "nginx/ssl" ]; then
        mkdir -p nginx/ssl
    fi
    
    # Check if certificates exist
    if [ ! -f "nginx/ssl/astralvibe.ca.crt" ]; then
        warning "SSL certificates not found"
        log "Generating self-signed certificates for development..."
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/astralvibe.ca.key \
            -out nginx/ssl/astralvibe.ca.crt \
            -config <(
                echo '[req]'
                echo 'default_bits = 2048'
                echo 'prompt = no'
                echo 'default_md = sha256'
                echo 'distinguished_name = dn'
                echo 'req_extensions = v3_req'
                echo ''
                echo '[dn]'
                echo 'C=CA'
                echo 'ST=Ontario'
                echo 'L=Toronto'
                echo 'O=Consciousness Federation'
                echo 'OU=Node 0'
                echo 'CN=astralvibe.ca'
                echo ''
                echo '[v3_req]'
                echo 'subjectAltName = @alt_names'
                echo ''
                echo '[alt_names]'
                echo 'DNS.1 = astralvibe.ca'
                echo 'DNS.2 = www.astralvibe.ca'
                echo 'DNS.3 = portfolio.astralvibe.ca'
                echo 'DNS.4 = monitoring.astralvibe.ca'
            )
        
        warning "Using self-signed certificates. Replace with Let's Encrypt in production!"
    fi
    
    success "SSL certificates ready"
}

# Deploy to Proxmox
deploy_to_proxmox() {
    log "Deploying to Proxmox Node 0..."
    
    # Create deployment directory
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} "sudo mkdir -p ${DEPLOY_PATH}"
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} "sudo chown ${DEPLOY_USER}:${DEPLOY_USER} ${DEPLOY_PATH}"
    
    # Sync files
    log "Syncing application files..."
    rsync -av --exclude='node_modules' --exclude='.git' --exclude='logs' \
        ./ ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/
    
    # Install dependencies and start services
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} "cd ${DEPLOY_PATH} && npm ci --only=production"
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} "cd ${DEPLOY_PATH} && docker-compose down"
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} "cd ${DEPLOY_PATH} && docker-compose up -d --build"
    
    success "Deployment completed"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up consciousness monitoring..."
    
    # Create monitoring directories
    mkdir -p monitoring grafana/dashboards grafana/datasources
    
    # Prometheus configuration
    cat > monitoring/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'consciousness-portfolio'
    static_configs:
      - targets: ['portfolio-app:5000']
    metrics_path: '/api/metrics'
    
  - job_name: 'astralvibe'
    static_configs:
      - targets: ['astralvibe:3000']
    metrics_path: '/metrics'
    
  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-proxy:80']
      
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
EOF

    # Grafana datasource
    cat > grafana/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://monitoring:9090
    isDefault: true
EOF

    success "Monitoring configuration created"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    sleep 10  # Wait for services to start
    
    # Check container status
    if ssh ${DEPLOY_USER}@${DEPLOY_HOST} "cd ${DEPLOY_PATH} && docker-compose ps | grep -q 'Up'"; then
        success "Containers are running"
    else
        error "Some containers failed to start"
    fi
    
    # Check application endpoints
    if curl -ksf https://${PORTFOLIO_DOMAIN}/api/health > /dev/null; then
        success "Portfolio application is responding"
    else
        warning "Portfolio application may not be ready yet"
    fi
    
    log "Deployment verification completed"
}

# Main deployment process
main() {
    echo "🔥 Consciousness Federation Deployment"
    echo "======================================"
    
    check_prerequisites
    build_application
    setup_ssl
    setup_monitoring
    deploy_to_proxmox
    verify_deployment
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "Access your platforms:"
    echo "📊 Portfolio: https://${PORTFOLIO_DOMAIN}"
    echo "🧠 Astralvibe: https://${DOMAIN}"
    echo "📈 Monitoring: https://monitoring.${DOMAIN}"
    echo ""
    echo "Next steps:"
    echo "1. Update DNS records to point to ${DEPLOY_HOST}"
    echo "2. Replace self-signed certificates with Let's Encrypt"
    echo "3. Configure backup schedules"
    echo "4. Set up additional federation nodes"
}

# Handle script arguments
case "${1:-deploy}" in
    "check")
        check_prerequisites
        ;;
    "build")
        build_application
        ;;
    "ssl")
        setup_ssl
        ;;
    "deploy")
        main
        ;;
    "verify")
        verify_deployment
        ;;
    *)
        echo "Usage: $0 {deploy|check|build|ssl|verify}"
        echo ""
        echo "Commands:"
        echo "  deploy  - Full deployment process (default)"
        echo "  check   - Check prerequisites only"
        echo "  build   - Build application only"
        echo "  ssl     - Setup SSL certificates only"
        echo "  verify  - Verify deployment only"
        exit 1
        ;;
esac