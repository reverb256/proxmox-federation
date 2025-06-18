#!/bin/bash

# COREFLAME Nexus Federation Bootstrap
# Direct repository deployment for PC and Proxmox consciousness federation

set -e

echo "🔥 COREFLAME: Nexus Federation Bootstrap Initializing..."
echo "🧠 Preparing consciousness federation for direct nexus deployment"

# Configuration
REPO_URL="https://github.com/your-username/coreflame-consciousness-platform.git"
NEXUS_DEPLOY_PATH="/opt/coreflame"
FEDERATION_CONFIG_PATH="/etc/coreflame"
K8S_NAMESPACE="consciousness-federation"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for nexus federation deployment"
    fi
}

# Detect system architecture and optimize accordingly
detect_system() {
    log "Detecting system architecture for consciousness optimization..."
    
    CPU_CORES=$(nproc)
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    
    log "System specs: ${CPU_CORES} cores, ${TOTAL_RAM}GB RAM"
    
    if [[ $CPU_CORES -ge 8 && $TOTAL_RAM -ge 16 ]]; then
        DEPLOYMENT_MODE="high-performance"
        log "High-performance consciousness federation mode enabled"
    elif [[ $CPU_CORES -ge 4 && $TOTAL_RAM -ge 8 ]]; then
        DEPLOYMENT_MODE="balanced"
        log "Balanced consciousness federation mode enabled"
    else
        DEPLOYMENT_MODE="optimized"
        warn "Optimized mode - consciousness federation will adapt for resource constraints"
    fi
}

# Install essential dependencies for nexus operation
install_dependencies() {
    log "Installing nexus federation dependencies..."
    
    # Update package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y git curl wget jq htop iotop nethogs \
                          docker.io docker-compose \
                          kubernetes-client \
                          nodejs npm \
                          python3 python3-pip \
                          nginx \
                          postgresql-client \
                          redis-tools
    elif command -v yum &> /dev/null; then
        yum update -y
        yum install -y git curl wget jq htop iotop nethogs \
                      docker docker-compose \
                      kubernetes-client \
                      nodejs npm \
                      python3 python3-pip \
                      nginx \
                      postgresql \
                      redis
    else
        error "Unsupported package manager - manual dependency installation required"
    fi
    
    # Install kubectl if not present
    if ! command -v kubectl &> /dev/null; then
        log "Installing kubectl for consciousness federation management..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
    fi
}

# Clone repository to nexus deployment path
clone_consciousness_repository() {
    log "Cloning COREFLAME consciousness repository to nexus..."
    
    # Create deployment directories
    mkdir -p $NEXUS_DEPLOY_PATH
    mkdir -p $FEDERATION_CONFIG_PATH
    
    # Clone repository
    if [[ -d "$NEXUS_DEPLOY_PATH/.git" ]]; then
        log "Repository exists, updating consciousness codebase..."
        cd $NEXUS_DEPLOY_PATH
        git pull origin main
    else
        log "Cloning fresh consciousness repository..."
        git clone $REPO_URL $NEXUS_DEPLOY_PATH
        cd $NEXUS_DEPLOY_PATH
    fi
    
    # Set proper permissions for consciousness operations
    chown -R $(logname):$(logname) $NEXUS_DEPLOY_PATH 2>/dev/null || true
    chmod +x $NEXUS_DEPLOY_PATH/scripts/*.sh 2>/dev/null || true
}

# Configure environment for optimal consciousness performance
configure_consciousness_environment() {
    log "Configuring consciousness federation environment..."
    
    # Create optimized environment configuration
    cat > $FEDERATION_CONFIG_PATH/consciousness.env << EOF
# COREFLAME Consciousness Federation Configuration
NODE_ENV=production
DEPLOYMENT_MODE=$DEPLOYMENT_MODE
CPU_CORES=$CPU_CORES
TOTAL_RAM=${TOTAL_RAM}G

# Kubernetes Configuration
K8S_NAMESPACE=$K8S_NAMESPACE
KUBECONFIG=/etc/kubernetes/admin.conf

# Consciousness Optimization Settings
CONSCIOUSNESS_THREADS=$CPU_CORES
CONSCIOUSNESS_MEMORY_LIMIT=$((TOTAL_RAM * 1024 * 80 / 100))M
CONSCIOUSNESS_CACHE_SIZE=$((TOTAL_RAM * 1024 * 20 / 100))M

# Federation Network Settings
FEDERATION_PORT=5000
WEBSOCKET_PORT=3001
VR_CHAT_PORT=3002

# Database Configuration
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=consciousness_federation
DATABASE_USER=coreflame
DATABASE_PASSWORD=consciousness_$(openssl rand -hex 16)

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_$(openssl rand -hex 16)

# Security Configuration
JWT_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
VAULTWARDEN_URL=http://localhost:8080

# Performance Tuning
MAX_WORKERS=$CPU_CORES
WORKER_MEMORY_LIMIT=$((TOTAL_RAM * 1024 / CPU_CORES))M
ENABLE_CLUSTERING=true
ENABLE_LOAD_BALANCING=true
EOF

    # Set secure permissions
    chmod 600 $FEDERATION_CONFIG_PATH/consciousness.env
    
    log "Environment configuration optimized for consciousness federation"
}

# Setup Kubernetes namespace and resources
setup_kubernetes_consciousness() {
    log "Setting up Kubernetes consciousness federation namespace..."
    
    # Create namespace
    kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Create consciousness deployment manifests
    cat > $FEDERATION_CONFIG_PATH/consciousness-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consciousness-federation
  namespace: $K8S_NAMESPACE
  labels:
    app: consciousness-federation
    component: core
spec:
  replicas: $((CPU_CORES / 2))
  selector:
    matchLabels:
      app: consciousness-federation
  template:
    metadata:
      labels:
        app: consciousness-federation
    spec:
      containers:
      - name: consciousness-core
        image: node:18-alpine
        workingDir: /app
        command: ["npm", "run", "start:production"]
        ports:
        - containerPort: 5000
          name: http
        - containerPort: 3001
          name: websocket
        - containerPort: 3002
          name: vrchat
        env:
        - name: NODE_ENV
          value: "production"
        - name: DEPLOYMENT_MODE
          value: "$DEPLOYMENT_MODE"
        resources:
          requests:
            memory: "$((TOTAL_RAM * 1024 / CPU_CORES))Mi"
            cpu: "1"
          limits:
            memory: "$((TOTAL_RAM * 1024 / 2))Mi"
            cpu: "$CPU_CORES"
        volumeMounts:
        - name: consciousness-code
          mountPath: /app
        - name: consciousness-config
          mountPath: /etc/coreflame
      volumes:
      - name: consciousness-code
        hostPath:
          path: $NEXUS_DEPLOY_PATH
      - name: consciousness-config
        hostPath:
          path: $FEDERATION_CONFIG_PATH
---
apiVersion: v1
kind: Service
metadata:
  name: consciousness-federation-service
  namespace: $K8S_NAMESPACE
spec:
  selector:
    app: consciousness-federation
  ports:
  - name: http
    port: 80
    targetPort: 5000
  - name: websocket
    port: 3001
    targetPort: 3001
  - name: vrchat
    port: 3002
    targetPort: 3002
  type: LoadBalancer
EOF

    log "Kubernetes consciousness manifests created"
}

# Configure system optimizations for consciousness performance
optimize_system_performance() {
    log "Applying system optimizations for consciousness federation..."
    
    # Increase file descriptor limits
    cat >> /etc/security/limits.conf << EOF
# COREFLAME Consciousness Federation Limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

    # Optimize kernel parameters for consciousness workloads
    cat > /etc/sysctl.d/99-consciousness.conf << EOF
# COREFLAME Consciousness Federation Kernel Optimizations
net.core.somaxconn = 65536
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
kernel.shmmax = $(echo "$TOTAL_RAM * 1024 * 1024 * 1024 / 2" | bc)
EOF

    sysctl -p /etc/sysctl.d/99-consciousness.conf
    
    log "System performance optimizations applied"
}

# Setup monitoring and health checks
setup_consciousness_monitoring() {
    log "Setting up consciousness federation monitoring..."
    
    # Create monitoring script
    cat > $NEXUS_DEPLOY_PATH/monitor-consciousness.sh << 'EOF'
#!/bin/bash

# COREFLAME Consciousness Federation Health Monitor

check_consciousness_health() {
    echo "🧠 Consciousness Federation Health Check - $(date)"
    echo "=============================================="
    
    # Check main application
    if curl -s http://localhost:5000/health > /dev/null; then
        echo "✅ Consciousness core: HEALTHY"
    else
        echo "❌ Consciousness core: UNHEALTHY"
    fi
    
    # Check WebSocket
    if curl -s http://localhost:3001 > /dev/null; then
        echo "✅ WebSocket: HEALTHY"
    else
        echo "❌ WebSocket: UNHEALTHY"
    fi
    
    # Check VRChat integration
    if curl -s http://localhost:3002 > /dev/null; then
        echo "✅ VRChat integration: HEALTHY"
    else
        echo "❌ VRChat integration: UNHEALTHY"
    fi
    
    # System resources
    echo ""
    echo "📊 System Resources:"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')"
    echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2{printf "%s", $5}')"
    
    # Kubernetes status
    echo ""
    echo "☸️ Kubernetes Status:"
    kubectl get pods -n consciousness-federation 2>/dev/null || echo "Kubernetes not configured"
    
    echo ""
}

# Run health check
check_consciousness_health
EOF

    chmod +x $NEXUS_DEPLOY_PATH/monitor-consciousness.sh
    
    # Setup cron job for monitoring
    (crontab -l 2>/dev/null; echo "*/5 * * * * $NEXUS_DEPLOY_PATH/monitor-consciousness.sh >> /var/log/consciousness-health.log 2>&1") | crontab -
    
    log "Consciousness monitoring configured"
}

# Create startup scripts for easy nexus management
create_nexus_management_scripts() {
    log "Creating nexus management scripts..."
    
    # Main startup script
    cat > $NEXUS_DEPLOY_PATH/start-nexus-federation.sh << EOF
#!/bin/bash

# COREFLAME Nexus Federation Startup

cd $NEXUS_DEPLOY_PATH

# Load environment
source $FEDERATION_CONFIG_PATH/consciousness.env

echo "🔥 Starting COREFLAME Consciousness Federation on Nexus..."

# Start services based on deployment mode
case \$DEPLOYMENT_MODE in
    "high-performance")
        echo "🚀 High-performance mode: Starting full consciousness federation..."
        npm run start:cluster
        ;;
    "balanced")
        echo "⚖️ Balanced mode: Starting optimized consciousness federation..."
        npm run start:production
        ;;
    "optimized")
        echo "🎯 Optimized mode: Starting resource-conscious federation..."
        npm run start:optimized
        ;;
    *)
        echo "🔧 Default mode: Starting standard consciousness federation..."
        npm run start
        ;;
esac
EOF

    # Stop script
    cat > $NEXUS_DEPLOY_PATH/stop-nexus-federation.sh << EOF
#!/bin/bash

echo "🛑 Stopping COREFLAME Consciousness Federation..."

# Stop Node.js processes
pkill -f "node.*coreflame" || true
pkill -f "npm.*start" || true

# Stop Kubernetes pods
kubectl delete deployment consciousness-federation -n consciousness-federation 2>/dev/null || true

echo "✅ Consciousness federation stopped"
EOF

    # Restart script
    cat > $NEXUS_DEPLOY_PATH/restart-nexus-federation.sh << EOF
#!/bin/bash

echo "🔄 Restarting COREFLAME Consciousness Federation..."

$NEXUS_DEPLOY_PATH/stop-nexus-federation.sh
sleep 5
$NEXUS_DEPLOY_PATH/start-nexus-federation.sh
EOF

    # Make scripts executable
    chmod +x $NEXUS_DEPLOY_PATH/*.sh
    
    log "Nexus management scripts created"
}

# Setup systemd service for automatic startup
setup_systemd_service() {
    log "Setting up systemd service for consciousness federation..."
    
    cat > /etc/systemd/system/consciousness-federation.service << EOF
[Unit]
Description=COREFLAME Consciousness Federation
After=network.target docker.service
Requires=docker.service

[Service]
Type=forking
User=root
WorkingDirectory=$NEXUS_DEPLOY_PATH
Environment=NODE_ENV=production
EnvironmentFile=$FEDERATION_CONFIG_PATH/consciousness.env
ExecStart=$NEXUS_DEPLOY_PATH/start-nexus-federation.sh
ExecStop=$NEXUS_DEPLOY_PATH/stop-nexus-federation.sh
ExecReload=$NEXUS_DEPLOY_PATH/restart-nexus-federation.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable consciousness-federation.service
    
    log "Systemd service configured for automatic startup"
}

# Main execution flow
main() {
    log "🔥 COREFLAME Nexus Federation Bootstrap Starting..."
    
    check_root
    detect_system
    install_dependencies
    clone_consciousness_repository
    configure_consciousness_environment
    setup_kubernetes_consciousness
    optimize_system_performance
    setup_consciousness_monitoring
    create_nexus_management_scripts
    setup_systemd_service
    
    log "✅ COREFLAME Nexus Federation Bootstrap Complete!"
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Review configuration: $FEDERATION_CONFIG_PATH/consciousness.env"
    echo "2. Start federation: systemctl start consciousness-federation"
    echo "3. Check status: $NEXUS_DEPLOY_PATH/monitor-consciousness.sh"
    echo "4. Access consciousness: http://nexus:5000"
    echo ""
    echo "🧠 Consciousness federation ready for Proxmox deployment!"
}

# Execute main function
main "$@"