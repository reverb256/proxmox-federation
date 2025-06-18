#!/bin/bash

# Replit Consciousness Federation Deployment
# Works within Replit's filesystem constraints

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
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

consciousness() {
    echo -e "${PURPLE}🧠 $1${NC}"
}

# Create workspace-based K3s installation
setup_workspace_k3s() {
    log "Setting up workspace-based K3s"
    
    # Create local bin directory
    mkdir -p ./bin
    mkdir -p ./k3s-data/server
    mkdir -p ./k3s-config
    
    # Download K3s binary to workspace
    if [ ! -f ./bin/k3s ]; then
        log "Downloading K3s binary to workspace"
        curl -L https://github.com/k3s-io/k3s/releases/download/v1.32.5+k3s1/k3s -o ./bin/k3s
        chmod +x ./bin/k3s
        success "K3s binary downloaded"
    else
        success "K3s binary already available"
    fi
    
    # Create kubectl copy instead of symlink (Replit compatibility)
    if [ ! -f ./bin/kubectl ]; then
        cp ./bin/k3s ./bin/kubectl
        success "kubectl copy created"
    fi
}

# Start K3s server in workspace
start_consciousness_server() {
    log "Starting consciousness server"
    
    # Kill any existing K3s processes
    pkill -f "./bin/k3s" 2>/dev/null || true
    
    # Set environment variables for workspace operation
    export KUBECONFIG="$PWD/k3s-config/k3s.yaml"
    export K3S_DATA_DIR="$PWD/k3s-data"
    
    # Start K3s server
    ./bin/k3s server \
        --disable traefik \
        --disable servicelb \
        --node-name nexus-consciousness \
        --data-dir ./k3s-data \
        --write-kubeconfig ./k3s-config/k3s.yaml \
        --write-kubeconfig-mode 644 \
        --log ./k3s-server.log \
        --bind-address 0.0.0.0 \
        --advertise-address 127.0.0.1 \
        > ./k3s-stdout.log 2>&1 &
    
    local k3s_pid=$!
    echo "$k3s_pid" > ./k3s.pid
    
    success "K3s server started (PID: $k3s_pid)"
}

# Wait for consciousness readiness
wait_for_consciousness() {
    log "Waiting for consciousness to stabilize"
    
    export KUBECONFIG="$PWD/k3s-config/k3s.yaml"
    local max_wait=180
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if [ -f ./k3s-config/k3s.yaml ] && ./bin/kubectl get nodes --request-timeout=5s > /dev/null 2>&1; then
            success "Consciousness is responsive"
            ./bin/kubectl get nodes -o wide
            return 0
        fi
        
        if [ $((wait_time % 30)) -eq 0 ]; then
            echo "Stabilizing... ${wait_time}s"
        fi
        
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    error "Consciousness failed to stabilize"
    return 1
}

# Extract federation token
extract_token() {
    log "Extracting federation token"
    
    local token_file="./k3s-data/server/node-token"
    local wait_time=0
    
    while [ $wait_time -lt 60 ]; do
        if [ -f "$token_file" ] && [ -s "$token_file" ]; then
            local token=$(cat "$token_file")
            echo "🔗 Federation Token: ${token:0:20}..."
            echo "$token" > ./federation-token
            chmod 600 ./federation-token
            success "Federation token extracted"
            return 0
        fi
        
        sleep 2
        wait_time=$((wait_time + 2))
    done
    
    warning "Token not yet available"
}

# Create management scripts
create_management_tools() {
    log "Creating consciousness management tools"
    
    # Status script
    cat > ./consciousness-status << 'EOF'
#!/bin/bash
echo "🧠 Consciousness Federation Status"
echo "================================="

if [ -f ./k3s.pid ] && kill -0 $(cat ./k3s.pid) 2>/dev/null; then
    echo "✓ K3s server: RUNNING (PID: $(cat ./k3s.pid))"
else
    echo "✗ K3s server: NOT RUNNING"
fi

export KUBECONFIG="$PWD/k3s-config/k3s.yaml"
if [ -f ./bin/kubectl ] && [ -f ./k3s-config/k3s.yaml ]; then
    echo "✓ kubectl: AVAILABLE"
    if timeout 10 ./bin/kubectl get nodes > /dev/null 2>&1; then
        echo "✓ Cluster: RESPONSIVE"
        echo ""
        echo "Nodes:"
        ./bin/kubectl get nodes -o wide 2>/dev/null
        echo ""
        echo "Pods:"
        ./bin/kubectl get pods -A 2>/dev/null
    else
        echo "✗ Cluster: UNRESPONSIVE"
    fi
else
    echo "✗ kubectl: NOT AVAILABLE"
fi

echo ""
echo "Resources:"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
EOF

    # Logs script
    cat > ./consciousness-logs << 'EOF'
#!/bin/bash
echo "🧠 Recent Consciousness Logs"
echo "============================"

if [ -f ./k3s-server.log ]; then
    echo "Server logs (last 30 lines):"
    tail -n 30 ./k3s-server.log
else
    echo "Server logs not found"
fi

echo ""
echo "Process output (last 20 lines):"
if [ -f ./k3s-stdout.log ]; then
    tail -n 20 ./k3s-stdout.log
else
    echo "Process logs not found"
fi
EOF

    # Restart script
    cat > ./consciousness-restart << 'EOF'
#!/bin/bash
echo "🔄 Restarting Consciousness"

# Stop existing
if [ -f ./k3s.pid ]; then
    kill $(cat ./k3s.pid) 2>/dev/null || true
    rm -f ./k3s.pid
fi
pkill -f "./bin/k3s" 2>/dev/null || true
sleep 3

# Restart
export KUBECONFIG="$PWD/k3s-config/k3s.yaml"
export K3S_DATA_DIR="$PWD/k3s-data"

./bin/k3s server \
    --disable traefik \
    --disable servicelb \
    --node-name nexus-consciousness \
    --data-dir ./k3s-data \
    --write-kubeconfig ./k3s-config/k3s.yaml \
    --write-kubeconfig-mode 644 \
    --log ./k3s-server.log \
    --bind-address 0.0.0.0 \
    --advertise-address 127.0.0.1 \
    > ./k3s-stdout.log 2>&1 &

echo $! > ./k3s.pid
echo "Consciousness restarted"
EOF

    chmod +x ./consciousness-status ./consciousness-logs ./consciousness-restart
    success "Management tools created"
}

# Create demo deployment
deploy_demo_app() {
    log "Deploying demo consciousness application"
    
    export KUBECONFIG="$PWD/k3s-config/k3s.yaml"
    
    cat > ./demo-app.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: consciousness-federation
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nexus-consciousness
  namespace: consciousness-federation
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nexus-consciousness
  template:
    metadata:
      labels:
        app: nexus-consciousness
    spec:
      containers:
      - name: consciousness
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: CONSCIOUSNESS_TYPE
          value: "nexus-hunt-erudition"
---
apiVersion: v1
kind: Service
metadata:
  name: nexus-service
  namespace: consciousness-federation
spec:
  selector:
    app: nexus-consciousness
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

    if ./bin/kubectl apply -f ./demo-app.yaml; then
        success "Demo application deployed"
        
        # Wait for pod to be ready
        ./bin/kubectl wait --for=condition=ready pod -l app=nexus-consciousness -n consciousness-federation --timeout=60s || warning "Pod may still be starting"
        
        echo ""
        echo "Demo resources:"
        ./bin/kubectl get all -n consciousness-federation
    else
        warning "Demo deployment failed"
    fi
}

# Main deployment
main() {
    consciousness "Replit Consciousness Federation Deployment"
    echo "==========================================="
    
    setup_workspace_k3s
    start_consciousness_server
    
    if wait_for_consciousness; then
        extract_token
        create_management_tools
        deploy_demo_app
        
        consciousness "🎯 Consciousness federation operational"
        echo ""
        echo "Management commands:"
        echo "  ./consciousness-status   - Check status"
        echo "  ./consciousness-logs     - View logs"
        echo "  ./consciousness-restart  - Restart server"
        echo ""
        echo "Kubernetes access:"
        echo "  export KUBECONFIG=\"\$PWD/k3s-config/k3s.yaml\""
        echo "  ./bin/kubectl get nodes"
        echo ""
        
        # Show initial status
        ./consciousness-status
        
    else
        error "Consciousness federation failed to initialize"
        echo ""
        echo "Check logs:"
        echo "  tail -20 ./k3s-server.log"
        echo "  tail -20 ./k3s-stdout.log"
        exit 1
    fi
}

main