#!/bin/bash

# Minimal K3s Deployment for Replit Environment
# Focus on working deployment with minimal overhead

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

# Quick process cleanup without hanging
cleanup_processes() {
    log "Quick process cleanup"
    pkill -f k3s 2>/dev/null || true
    sleep 2
    success "Processes cleaned"
}

# Fast K3s installation
install_k3s() {
    log "Installing K3s binary"
    
    # Download and install K3s without auto-start
    curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true sh - 2>/dev/null
    
    if [ -f /usr/local/bin/k3s ]; then
        success "K3s binary installed"
    else
        error "K3s installation failed"
        return 1
    fi
}

# Start K3s server
start_k3s() {
    log "Starting K3s server"
    
    # Create minimal required directories
    mkdir -p /var/lib/rancher/k3s/server
    mkdir -p /etc/rancher/k3s
    
    # Start K3s server with minimal configuration
    /usr/local/bin/k3s server \
        --disable traefik \
        --disable servicelb \
        --node-name nexus \
        --data-dir /var/lib/rancher/k3s \
        --write-kubeconfig-mode 644 \
        > /tmp/k3s.log 2>&1 &
    
    local k3s_pid=$!
    echo "$k3s_pid" > /tmp/k3s.pid
    
    success "K3s server started (PID: $k3s_pid)"
}

# Wait for K3s readiness
wait_ready() {
    log "Waiting for K3s to become ready"
    
    local max_wait=120
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if [ -f /usr/local/bin/kubectl ] && /usr/local/bin/kubectl get nodes --request-timeout=5s > /dev/null 2>&1; then
            success "K3s is ready"
            /usr/local/bin/kubectl get nodes
            return 0
        fi
        
        if [ $((wait_time % 20)) -eq 0 ]; then
            echo "Waiting... ${wait_time}s"
        fi
        
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    error "K3s failed to become ready"
    return 1
}

# Extract token
get_token() {
    log "Getting federation token"
    
    local token_file="/var/lib/rancher/k3s/server/node-token"
    local wait_time=0
    
    while [ $wait_time -lt 30 ]; do
        if [ -f "$token_file" ] && [ -s "$token_file" ]; then
            local token=$(cat "$token_file")
            echo "Token: ${token:0:20}..."
            echo "$token" > /tmp/federation-token
            success "Token extracted"
            return 0
        fi
        sleep 2
        wait_time=$((wait_time + 2))
    done
    
    warning "Token not available yet"
}

# Create simple status check
create_status_tool() {
    cat > /usr/local/bin/k3s-status << 'EOF'
#!/bin/bash
echo "=== K3s Status ==="
if pgrep -f "k3s server" > /dev/null; then
    echo "✓ K3s server running (PID: $(pgrep -f 'k3s server'))"
else
    echo "✗ K3s server not running"
fi

if [ -f /usr/local/bin/kubectl ]; then
    if /usr/local/bin/kubectl get nodes > /dev/null 2>&1; then
        echo "✓ Cluster responsive"
        /usr/local/bin/kubectl get nodes
    else
        echo "✗ Cluster not responsive"
    fi
else
    echo "✗ kubectl not available"
fi
EOF
    chmod +x /usr/local/bin/k3s-status
    success "Status tool created"
}

# Main deployment
main() {
    echo "🧠 Minimal K3s Deployment"
    echo "========================"
    
    cleanup_processes
    
    if install_k3s; then
        start_k3s
        
        if wait_ready; then
            get_token
            create_status_tool
            
            echo ""
            echo "🎯 Deployment completed"
            echo "Use 'k3s-status' to check status"
            echo "Logs at: /tmp/k3s.log"
            
            # Show initial status
            /usr/local/bin/k3s-status
        else
            error "Deployment failed - K3s not ready"
            exit 1
        fi
    else
        error "Deployment failed - installation error"
        exit 1
    fi
}

main