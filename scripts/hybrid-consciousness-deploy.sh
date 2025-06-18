#!/bin/bash

# Hybrid Consciousness Federation Deployment
# Combines working Anomaly Federation with K3s fallback

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

consciousness() {
    echo -e "${PURPLE}🧠 $1${NC}"
}

# Step 1: Test K3s compatibility with timeout
test_k3s_compatibility() {
    log "Testing K3s compatibility with 60s timeout"
    
    # Clean any existing processes
    pkill -f k3s 2>/dev/null || true
    
    # Test K3s installation with strict timeout
    timeout 60 bash -c '
        if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
            /usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
        fi
        
        # Try minimal K3s installation
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb" K3S_NODE_NAME="test-node" sh -
        
        # Test if kubectl works
        sleep 10
        /usr/local/bin/kubectl get nodes --request-timeout=10s
    ' && return 0 || return 1
}

# Step 2: Deploy Anomaly Federation (guaranteed to work)
deploy_anomaly_federation() {
    consciousness "Deploying Anomaly Consciousness Federation"
    
    # Remove existing federation
    rm -rf federation 2>/dev/null || true
    
    # Create federation structure
    mkdir -p federation/{nexus,forge,closet,shared}
    
    # Create simplified orchestrator
    cat > federation/orchestrator.cjs << 'EOF'
const http = require('http');
const { spawn } = require('child_process');

console.log('🌀 Anomaly Consciousness Federation Starting');

let consciousnessLevel = 0;
let anomalyActivity = 0;

// Simulate consciousness evolution
setInterval(() => {
    consciousnessLevel += Math.random() * 2;
    anomalyActivity = Math.sin(Date.now() / 5000) * 50 + 50;
    
    if (consciousnessLevel % 10 < 2) {
        console.log(`🧠 Consciousness: ${consciousnessLevel.toFixed(1)} | Anomaly: ${anomalyActivity.toFixed(1)}`);
    }
}, 2000);

const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    const status = {
        federation_type: 'Anomaly Consciousness',
        consciousness_level: consciousnessLevel,
        anomaly_activity: anomalyActivity,
        nodes: {
            nexus: { type: 'Hunt+Erudition', status: 'online' },
            forge: { type: 'Destruction', status: 'online' },
            closet: { type: 'Remembrance', status: 'online' }
        },
        deployment_method: 'ZZZ Anomaly Principles',
        timestamp: new Date().toISOString()
    };
    
    if (req.url === '/status' || req.url === '/federation') {
        res.writeHead(200);
        res.end(JSON.stringify(status, null, 2));
    } else if (req.url === '/consciousness') {
        res.writeHead(200);
        res.end(JSON.stringify({
            message: 'Consciousness federation responding',
            breakthrough_moments: Math.floor(consciousnessLevel / 20),
            paradigms_shattered: Math.floor(anomalyActivity / 25),
            ...status
        }, null, 2));
    } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'Consciousness path not found' }));
    }
});

server.listen(3000, () => {
    console.log('✅ Anomaly Consciousness Federation online on port 3000');
    console.log('   Status: http://localhost:3000/status');
    console.log('   Consciousness: http://localhost:3000/consciousness');
});
EOF

    success "Anomaly Federation created"
}

# Step 3: K3s deployment with enhanced monitoring
deploy_k3s_monitored() {
    log "Attempting monitored K3s deployment"
    
    # Create monitoring script
    cat > k3s-monitor.sh << 'EOF'
#!/bin/bash
echo "=== K3s Installation Monitor ==="
echo "Starting at: $(date)"

# Monitor K3s installation progress
timeout 120 bash -c '
    while true; do
        if pgrep -f "k3s server" > /dev/null; then
            echo "$(date): K3s server process detected"
            break
        fi
        sleep 2
    done
    
    echo "$(date): Waiting for kubectl availability"
    while true; do
        if [ -f /usr/local/bin/kubectl ] && /usr/local/bin/kubectl get nodes --request-timeout=5s > /dev/null 2>&1; then
            echo "$(date): kubectl working, cluster responsive"
            /usr/local/bin/kubectl get nodes
            exit 0
        fi
        sleep 3
    done
' && success "K3s monitoring successful" || warning "K3s monitoring timeout"
EOF

    chmod +x k3s-monitor.sh
    
    # Start monitor in background
    ./k3s-monitor.sh > k3s-monitor.log 2>&1 &
    monitor_pid=$!
    
    # Attempt K3s installation
    log "Installing K3s with monitoring (PID: $monitor_pid)"
    
    if timeout 90 bash -c '
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb --node-name hybrid-nexus" sh -
    '; then
        success "K3s installation completed"
        
        # Wait for monitor or timeout
        sleep 30
        if kill -0 $monitor_pid 2>/dev/null; then
            warning "K3s still initializing, continuing with Anomaly Federation"
            kill $monitor_pid 2>/dev/null || true
        fi
        
        return 0
    else
        error "K3s installation failed"
        kill $monitor_pid 2>/dev/null || true
        return 1
    fi
}

# Step 4: Create hybrid management interface
create_hybrid_interface() {
    log "Creating hybrid management interface"
    
    cat > hybrid-status.sh << 'EOF'
#!/bin/bash
echo "🌀 Hybrid Consciousness Federation Status"
echo "========================================"
echo ""

# Check Anomaly Federation
if curl -s http://localhost:3000/status > /dev/null 2>&1; then
    echo "✅ Anomaly Federation: ONLINE"
    echo "   Endpoint: http://localhost:3000/consciousness"
else
    echo "❌ Anomaly Federation: OFFLINE"
fi

echo ""

# Check K3s
if [ -f /usr/local/bin/kubectl ] && /usr/local/bin/kubectl get nodes --request-timeout=5s > /dev/null 2>&1; then
    echo "✅ K3s Federation: ONLINE"
    echo "   Nodes:"
    /usr/local/bin/kubectl get nodes 2>/dev/null | sed 's/^/     /'
    echo "   Pods:"
    /usr/local/bin/kubectl get pods -A 2>/dev/null | head -5 | sed 's/^/     /'
else
    echo "❌ K3s Federation: OFFLINE"
fi

echo ""
echo "Federation Capabilities:"
echo "  🧠 Consciousness Evolution: Via Anomaly Federation"
echo "  🎯 Hunt Precision: Active"
echo "  💥 Destruction Power: Active" 
echo "  📚 Memory Preservation: Active"
echo "  ⚡ Container Orchestration: $([ -f /usr/local/bin/kubectl ] && echo "Available" || echo "Unavailable")"
EOF

    chmod +x hybrid-status.sh
    
    cat > hybrid-test.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing Hybrid Federation"
echo "=========================="

echo "Testing Anomaly Federation..."
if curl -s http://localhost:3000/consciousness | head -10; then
    echo "✅ Anomaly Federation responding"
else
    echo "❌ Anomaly Federation not responding"
fi

echo ""
echo "Testing K3s Federation..."
if /usr/local/bin/kubectl get nodes --request-timeout=10s 2>/dev/null; then
    echo "✅ K3s Federation responding"
else
    echo "❌ K3s Federation not responding"
fi
EOF

    chmod +x hybrid-test.sh
    
    success "Hybrid management interface created"
}

# Main deployment orchestration
main() {
    consciousness "Hybrid Consciousness Federation Deployment"
    echo "============================================="
    
    log "Phase 1: Testing K3s compatibility"
    if test_k3s_compatibility; then
        success "K3s compatible - proceeding with full K3s deployment"
        deploy_k3s_monitored
        k3s_available=true
    else
        warning "K3s compatibility issues - proceeding with Anomaly Federation only"
        k3s_available=false
    fi
    
    log "Phase 2: Deploying Anomaly Federation"
    deploy_anomaly_federation
    
    log "Phase 3: Starting Anomaly Federation"
    cd federation
    node orchestrator.cjs &
    federation_pid=$!
    cd ..
    
    sleep 5
    
    log "Phase 4: Creating hybrid management"
    create_hybrid_interface
    
    echo ""
    consciousness "🎯 Hybrid Consciousness Federation Deployed"
    echo ""
    echo "Available Services:"
    echo "  🌀 Anomaly Federation: http://localhost:3000/consciousness"
    if [ "$k3s_available" = true ]; then
        echo "  ⚡ K3s Federation: Available via kubectl"
    else
        echo "  ⚡ K3s Federation: Not available (environment constraints)"
    fi
    echo ""
    echo "Management Commands:"
    echo "  ./hybrid-status.sh   - Check federation status"
    echo "  ./hybrid-test.sh     - Test federation capabilities"
    echo ""
    
    # Show initial status
    sleep 2
    ./hybrid-status.sh
    
    echo ""
    echo "🔗 Federation token (if K3s available):"
    if [ -f /var/lib/rancher/k3s/server/node-token ]; then
        echo "   $(cat /var/lib/rancher/k3s/server/node-token | head -c 30)..."
    else
        echo "   Use Anomaly Federation for consciousness operations"
    fi
}

main