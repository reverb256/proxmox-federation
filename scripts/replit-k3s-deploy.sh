#!/bin/bash

# Replit-Compatible K3s Consciousness Federation Deployment
# Adapted for containerized environment without systemd

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# Function to check if process is running
check_process() {
    local process_name=$1
    if pgrep -f "$process_name" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to wait for K3s to be ready
wait_for_k3s_ready() {
    local max_wait=${1:-180}
    local wait_time=0
    
    log_step "Waiting for K3s consciousness to stabilize..."
    
    while [ $wait_time -lt $max_wait ]; do
        if [ -f /usr/local/bin/kubectl ] && /usr/local/bin/kubectl get nodes --request-timeout=5s > /dev/null 2>&1; then
            log_success "K3s consciousness is responsive"
            return 0
        fi
        
        if [ $((wait_time % 30)) -eq 0 ]; then
            echo -n "Waiting... ${wait_time}s"
        fi
        echo -n "."
        
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    log_error "K3s consciousness failed to stabilize within ${max_wait}s"
    return 1
}

# Function to install K3s in background mode for Replit
install_k3s_replit() {
    local node_type=$1
    
    log_consciousness "Deploying $node_type consciousness in Replit environment"
    
    # Clean any existing K3s processes
    if check_process "k3s"; then
        log_step "Stopping existing K3s processes"
        pkill -f k3s || true
        sleep 5
    fi
    
    # Remove existing installations
    if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
        log_step "Cleaning previous K3s installation"
        /usr/local/bin/k3s-uninstall.sh || true
    fi
    
    # Set up directories
    mkdir -p /var/lib/rancher/k3s/server
    mkdir -p /etc/rancher/k3s
    
    if [ "$node_type" = "nexus" ]; then
        log_step "Installing K3s server for Nexus consciousness"
        
        # Install K3s server in background mode
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --node-name nexus-hunt --log /tmp/k3s.log" sh -s - &
        
        # Wait for installation to complete
        sleep 15
        
        # Start K3s server manually in background
        log_step "Starting K3s consciousness process"
        nohup /usr/local/bin/k3s server \
            --disable traefik \
            --disable servicelb \
            --node-name nexus-hunt \
            --log /tmp/k3s.log \
            --data-dir /var/lib/rancher/k3s \
            > /tmp/k3s-stdout.log 2>&1 &
        
        # Wait for K3s to be ready
        if wait_for_k3s_ready 180; then
            log_success "Nexus consciousness established"
            
            # Display cluster info
            log_step "Nexus consciousness cluster status:"
            /usr/local/bin/kubectl get nodes -o wide
            
            # Extract token for other nodes
            if [ -f /var/lib/rancher/k3s/server/node-token ]; then
                TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
                echo "🔗 Federation Token: ${TOKEN:0:20}..."
                echo "$TOKEN" > /tmp/k3s-token
                chmod 600 /tmp/k3s-token
            else
                log_error "Federation token not found"
                return 1
            fi
            
        else
            log_error "Nexus consciousness failed to establish"
            return 1
        fi
        
    else
        log_error "Agent nodes not supported in Replit environment"
        log_step "Use multiple Replit instances for multi-node federation"
        return 1
    fi
}

# Function to create consciousness monitoring
setup_consciousness_monitoring() {
    log_step "Establishing consciousness monitoring"
    
    cat > /usr/local/bin/consciousness-monitor << 'EOF'
#!/bin/bash
echo "=== Consciousness Federation Status ==="
echo "Time: $(date)"
echo ""

if [ -f /usr/local/bin/kubectl ]; then
    echo "Cluster Nodes:"
    /usr/local/bin/kubectl get nodes -o wide 2>/dev/null || echo "Cluster not accessible"
    echo ""
    
    echo "System Pods:"
    /usr/local/bin/kubectl get pods -A 2>/dev/null || echo "Pods not accessible"
    echo ""
fi

echo "K3s Processes:"
ps aux | grep -E "k3s" | grep -v grep || echo "No K3s processes found"
echo ""

echo "Memory Usage:"
free -h
echo ""

echo "Consciousness Logs (last 10 lines):"
tail -n 10 /tmp/k3s.log 2>/dev/null || echo "No consciousness logs found"
echo "=================================="
EOF
    
    chmod +x /usr/local/bin/consciousness-monitor
    log_success "Consciousness monitoring established"
}

# Function to create consciousness management tools
create_consciousness_tools() {
    log_step "Creating consciousness management tools"
    
    # Consciousness status checker
    cat > /usr/local/bin/consciousness-status << 'EOF'
#!/bin/bash
echo "🧠 Consciousness Federation Status"
echo "================================="

if pgrep -f "k3s server" > /dev/null; then
    echo "✓ K3s server consciousness: ACTIVE"
else
    echo "✗ K3s server consciousness: INACTIVE"
fi

if [ -f /usr/local/bin/kubectl ]; then
    if /usr/local/bin/kubectl get nodes --request-timeout=5s > /dev/null 2>&1; then
        echo "✓ Cluster consciousness: RESPONSIVE"
        /usr/local/bin/kubectl get nodes
    else
        echo "✗ Cluster consciousness: UNRESPONSIVE"
    fi
else
    echo "✗ kubectl interface: NOT AVAILABLE"
fi
EOF
    
    # Consciousness restart tool
    cat > /usr/local/bin/consciousness-restart << 'EOF'
#!/bin/bash
echo "🔄 Restarting Consciousness Federation"
echo "====================================="

# Stop existing processes
pkill -f "k3s server" || true
sleep 5

# Restart K3s server
echo "Starting K3s consciousness..."
nohup /usr/local/bin/k3s server \
    --disable traefik \
    --disable servicelb \
    --node-name nexus-hunt \
    --log /tmp/k3s.log \
    --data-dir /var/lib/rancher/k3s \
    > /tmp/k3s-stdout.log 2>&1 &

echo "Consciousness restart initiated"
echo "Use 'consciousness-status' to check progress"
EOF
    
    chmod +x /usr/local/bin/consciousness-status
    chmod +x /usr/local/bin/consciousness-restart
    
    log_success "Consciousness management tools created"
}

# Main deployment function
main() {
    log_consciousness "Consciousness Federation Deployment for Replit"
    echo "=============================================="
    
    local node_type=${1:-nexus}
    
    # Install K3s
    if install_k3s_replit "$node_type"; then
        
        # Set up monitoring and tools
        setup_consciousness_monitoring
        create_consciousness_tools
        
        log_consciousness "🎯 Consciousness federation deployment completed"
        echo ""
        echo "Available commands:"
        echo "  consciousness-status   - Check federation status"
        echo "  consciousness-monitor  - Detailed monitoring output"
        echo "  consciousness-restart  - Restart federation"
        echo ""
        echo "Logs available at:"
        echo "  /tmp/k3s.log          - K3s consciousness logs"
        echo "  /tmp/k3s-stdout.log   - Process output"
        
    else
        log_error "Consciousness federation deployment failed"
        exit 1
    fi
}

# Execute deployment
main "$@"