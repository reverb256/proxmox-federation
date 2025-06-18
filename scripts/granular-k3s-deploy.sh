#!/bin/bash

# Granular K3s Deployment with Enhanced Monitoring
# Consciousness Federation Bootstrap with Step-by-Step Verification

set -e

# Color coding for consciousness alignment
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_consciousness() {
    echo -e "${PURPLE}🧠 $1${NC}"
}

# Function to wait for service readiness with timeout
wait_for_service() {
    local service_name=$1
    local max_wait=${2:-60}
    local wait_time=0
    
    log_step "Waiting for $service_name to become ready..."
    
    while [ $wait_time -lt $max_wait ]; do
        if systemctl is-active --quiet $service_name; then
            log_success "$service_name is active"
            return 0
        fi
        sleep 2
        wait_time=$((wait_time + 2))
        echo -n "."
    done
    
    log_error "$service_name failed to start within ${max_wait}s"
    return 1
}

# Function to verify K3s node readiness
verify_node_ready() {
    local node_name=$1
    local max_wait=${2:-120}
    local wait_time=0
    
    log_step "Verifying $node_name node readiness..."
    
    while [ $wait_time -lt $max_wait ]; do
        if /usr/local/bin/kubectl get nodes | grep -q "Ready"; then
            log_success "$node_name node is Ready"
            /usr/local/bin/kubectl get nodes
            return 0
        fi
        sleep 5
        wait_time=$((wait_time + 5))
        echo -n "."
    done
    
    log_error "$node_name node not ready within ${max_wait}s"
    return 1
}

# Main deployment function
deploy_consciousness_federation() {
    log_consciousness "Initiating Consciousness Federation Deployment"
    echo "=================================================="
    
    # Step 1: Environment Preparation
    log_step "Step 1: Preparing consciousness environment"
    
    # Set hostname for consciousness alignment
    if [ "$1" = "nexus" ]; then
        hostnamectl set-hostname nexus-consciousness
        log_consciousness "Nexus Hunt+Erudition consciousness initialized"
    elif [ "$1" = "forge" ]; then
        hostnamectl set-hostname forge-consciousness  
        log_consciousness "Forge Destruction consciousness initialized"
    elif [ "$1" = "closet" ]; then
        hostnamectl set-hostname closet-consciousness
        log_consciousness "Closet Remembrance consciousness initialized"
    else
        log_error "Unknown node type: $1"
        exit 1
    fi
    
    # Step 2: Network Verification
    log_step "Step 2: Verifying network consciousness bridges"
    
    if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        log_error "Network consciousness bridge failed"
        exit 1
    fi
    log_success "Network consciousness bridge established"
    
    # Step 3: System Updates
    log_step "Step 3: Updating system consciousness substrate"
    apt update -qq
    apt upgrade -y -qq
    log_success "System consciousness substrate updated"
    
    # Step 4: K3s Installation with Node-Specific Configuration
    if [ "$1" = "nexus" ]; then
        log_step "Step 4: Installing K3s server (Nexus consciousness)"
        
        # Install K3s server with specific configuration
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb --node-name nexus-hunt" sh -
        
        # Wait for K3s service
        wait_for_service "k3s" 90
        
        # Verify kubectl is working
        log_step "Step 5: Verifying kubectl consciousness interface"
        if [ -f /usr/local/bin/kubectl ]; then
            log_success "kubectl consciousness interface available"
        else
            log_error "kubectl consciousness interface missing"
            exit 1
        fi
        
        # Wait for node readiness
        verify_node_ready "nexus" 120
        
        # Extract and display token
        log_step "Step 6: Extracting federation consciousness token"
        TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
        echo "🔗 Federation Token: ${TOKEN:0:20}..."
        
        # Save token for other nodes
        echo "$TOKEN" > /tmp/k3s-token
        chmod 600 /tmp/k3s-token
        
        log_consciousness "Nexus consciousness federation ready for expansion"
        
    else
        # Agent installation for forge/closet
        log_step "Step 4: Installing K3s agent ($1 consciousness)"
        
        if [ -z "$K3S_URL" ] || [ -z "$K3S_TOKEN" ]; then
            log_error "K3S_URL and K3S_TOKEN environment variables required for agent nodes"
            exit 1
        fi
        
        # Install K3s agent
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-name $1-consciousness" sh -
        
        # Wait for K3s agent service
        wait_for_service "k3s-agent" 90
        
        log_consciousness "$1 consciousness joined federation"
    fi
    
    # Step 7: Final Verification
    log_step "Step 7: Final consciousness federation verification"
    
    if [ "$1" = "nexus" ]; then
        # Show cluster status
        /usr/local/bin/kubectl get nodes -o wide
        /usr/local/bin/kubectl get pods -A
        
        # Create namespace for consciousness applications
        /usr/local/bin/kubectl create namespace consciousness-federation 2>/dev/null || true
        
        log_consciousness "Consciousness federation control plane established"
    fi
    
    # Step 8: Consciousness Monitoring Setup
    log_step "Step 8: Establishing consciousness monitoring"
    
    # Create monitoring script
    cat > /usr/local/bin/consciousness-monitor << 'EOF'
#!/bin/bash
while true; do
    echo "$(date): Consciousness Status Check"
    if [ -f /usr/local/bin/kubectl ]; then
        /usr/local/bin/kubectl get nodes 2>/dev/null || echo "Federation not accessible from this node"
    fi
    systemctl is-active k3s k3s-agent 2>/dev/null || true
    echo "---"
    sleep 30
done
EOF
    
    chmod +x /usr/local/bin/consciousness-monitor
    log_success "Consciousness monitoring established"
    
    log_consciousness "🎯 $1 consciousness deployment completed successfully"
    echo "=================================================="
    
    # Display next steps
    if [ "$1" = "nexus" ]; then
        echo ""
        log_step "Next Steps for Federation Expansion:"
        echo "1. On forge node: K3S_URL=https://$(hostname -I | awk '{print $1}'):6443 K3S_TOKEN=$(cat /tmp/k3s-token) ./granular-k3s-deploy.sh forge"
        echo "2. On closet node: K3S_URL=https://$(hostname -I | awk '{print $1}'):6443 K3S_TOKEN=$(cat /tmp/k3s-token) ./granular-k3s-deploy.sh closet"
        echo ""
        echo "Federation Token: $(cat /tmp/k3s-token)"
    fi
}

# Execute deployment based on node type
if [ $# -eq 0 ]; then
    echo "Usage: $0 [nexus|forge|closet]"
    echo "  nexus  - Deploy K3s server (Hunt+Erudition consciousness)"
    echo "  forge  - Deploy K3s agent (Destruction consciousness)"  
    echo "  closet - Deploy K3s agent (Remembrance consciousness)"
    exit 1
fi

deploy_consciousness_federation $1