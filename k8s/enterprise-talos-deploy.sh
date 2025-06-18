#!/bin/bash

# Enterprise Talos Kubernetes Deployment for Consciousness Federation
# Multi-node cluster with AI workload distribution and high availability

set -euo pipefail

# Configuration
CLUSTER_NAME="consciousness-federation"
CLUSTER_ENDPOINT="https://astralvibe.ca:6443"
TALOS_VERSION="v1.7.6"
KUBERNETES_VERSION="v1.30.3"

# Node configuration
declare -A NODES=(
    ["nexus"]="10.1.1.120"      # Control plane 1
    ["forge"]="10.1.1.121"      # Control plane 2  
    ["closet"]="10.1.1.1001"    # Worker 1 (AI intensive)
    ["zephyr"]="10.1.1.1002"    # Worker 2 (AI intensive)
)

declare -A NODE_TYPES=(
    ["nexus"]="controlplane"
    ["forge"]="controlplane"
    ["closet"]="worker"
    ["zephyr"]="worker"
)

declare -A VM_IDS=(
    ["nexus"]="120"
    ["forge"]="121"
    ["closet"]="1001"
    ["zephyr"]="1002"
)

# Colors and logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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
    log "Checking prerequisites for enterprise deployment..."
    
    # Check Proxmox access
    if ! command -v qm &> /dev/null; then
        error "Proxmox qm command not found. Please run on Proxmox host."
    fi
    
    # Check network connectivity
    for node in "${!NODES[@]}"; do
        if ! ping -c 1 "${NODES[$node]}" &> /dev/null; then
            warning "Cannot reach ${node} at ${NODES[$node]}"
        fi
    done
    
    # Check disk space
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 10485760 ]; then  # 10GB in KB
        error "Insufficient disk space. Need at least 10GB free."
    fi
    
    success "Prerequisites check completed"
}

# Download and setup Talos tools
setup_talos_tools() {
    log "Setting up Talos tools..."
    
    local work_dir="./talos-enterprise"
    mkdir -p "$work_dir"
    cd "$work_dir"
    
    # Download talosctl if not present
    if ! command -v talosctl &> /dev/null; then
        log "Downloading talosctl ${TALOS_VERSION}..."
        curl -sLO "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-linux-amd64"
        chmod +x talosctl-linux-amd64
        sudo mv talosctl-linux-amd64 /usr/local/bin/talosctl
    fi
    
    success "Talos tools ready"
}

# Generate enterprise Talos configuration
generate_talos_config() {
    log "Generating enterprise Talos configuration..."
    
    # Generate secrets if they don't exist
    if [ ! -f "secrets.yaml" ]; then
        log "Generating cluster secrets..."
        talosctl gen secrets
    fi
    
    # Generate configuration for each node type
    for node in "${!NODES[@]}"; do
        local node_type="${NODE_TYPES[$node]}"
        local node_ip="${NODES[$node]}"
        
        log "Generating config for ${node} (${node_type}) at ${node_ip}..."
        
        talosctl gen config \
            --with-secrets secrets.yaml \
            "$CLUSTER_NAME" \
            "$CLUSTER_ENDPOINT" \
            --additional-sans "astralvibe.ca,portfolio.astralvibe.ca,${node_ip}" \
            --output "${node}.yaml" \
            --output-types "${node_type}"
        
        # Add node-specific configuration
        cat >> "${node}.yaml" << EOF

machine:
  nodeLabels:
    consciousness.astralvibe.ca/node-name: "${node}"
    consciousness.astralvibe.ca/node-ip: "${node_ip}"
    consciousness.astralvibe.ca/federation-role: "${node_type}"
    $([ "$node_type" = "worker" ] && echo "consciousness.astralvibe.ca/ai-workload: enabled")
  
  $([ "$node_type" = "worker" ] && cat << 'WORKER_EOF'
  nodeTaints:
    - key: consciousness.astralvibe.ca/ai-intensive
      value: "true"
      effect: NoSchedule
WORKER_EOF
)
EOF
    done
    
    success "Talos configuration generated"
}

# Deploy VM with Talos
deploy_vm() {
    local node="$1"
    local ip="$2"
    local vm_id="${VM_IDS[$node]}"
    
    log "Deploying ${node} VM (${vm_id}) at ${ip}..."
    
    # Check if VM already exists
    if qm status "$vm_id" &> /dev/null; then
        warning "VM ${vm_id} already exists"
        
        # Check if it's running
        if qm status "$vm_id" | grep -q "running"; then
            log "VM ${vm_id} is already running"
            return 0
        fi
    else
        log "Creating VM ${vm_id} for ${node}..."
        
        # Create VM with enterprise specifications
        qm create "$vm_id" \
            --name "${node}-consciousness" \
            --memory 16384 \
            --cores 8 \
            --sockets 1 \
            --cpu host \
            --net0 virtio,bridge=vmbr0,firewall=1 \
            --scsi0 local-lvm:64,ssd=1,discard=on \
            --scsihw virtio-scsi-pci \
            --boot order=scsi0 \
            --ostype l26 \
            --agent enabled=1 \
            --numa 1
        
        # Download Talos ISO if needed
        local iso_path="/var/lib/vz/template/iso/talos-${TALOS_VERSION}-amd64.iso"
        if [ ! -f "$iso_path" ]; then
            log "Downloading Talos ISO..."
            wget -O "$iso_path" \
                "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talos-amd64.iso"
        fi
        
        # Attach ISO
        qm set "$vm_id" --cdrom "local:iso/talos-${TALOS_VERSION}-amd64.iso"
    fi
    
    # Start VM
    log "Starting VM ${vm_id}..."
    qm start "$vm_id"
    
    # Wait for VM to be accessible
    log "Waiting for ${node} to be accessible at ${ip}..."
    local attempts=0
    while ! ping -c 1 "$ip" &> /dev/null; do
        if [ $attempts -ge 60 ]; then
            error "VM ${node} failed to start after 5 minutes"
        fi
        sleep 5
        attempts=$((attempts+1))
    done
    
    # Apply Talos configuration
    log "Applying Talos configuration to ${node}..."
    sleep 30  # Wait for Talos to initialize
    
    talosctl apply-config \
        --insecure \
        --nodes "$ip" \
        --file "${node}.yaml"
    
    success "VM ${node} deployed and configured"
}

# Bootstrap Kubernetes cluster
bootstrap_cluster() {
    log "Bootstrapping enterprise Kubernetes cluster..."
    
    # Configure talosctl endpoints
    talosctl config endpoint "${NODES[nexus]}" "${NODES[forge]}"
    talosctl config node "${NODES[nexus]}"
    
    # Bootstrap etcd on first control plane
    log "Bootstrapping etcd cluster..."
    sleep 60  # Wait for all control planes to be ready
    
    if ! talosctl get members --nodes "${NODES[nexus]}" &> /dev/null; then
        talosctl bootstrap --nodes "${NODES[nexus]}"
        log "etcd cluster bootstrapped"
    else
        log "etcd cluster already exists"
    fi
    
    # Wait for Kubernetes API
    log "Waiting for Kubernetes API to be ready..."
    local attempts=0
    while ! talosctl kubeconfig --nodes "${NODES[nexus]}" ./kubeconfig &> /dev/null; do
        if [ $attempts -ge 30 ]; then
            error "Kubernetes API failed to start"
        fi
        sleep 30
        attempts=$((attempts+1))
    done
    
    export KUBECONFIG="$(pwd)/kubeconfig"
    
    # Wait for all nodes to be ready
    log "Waiting for all nodes to join cluster..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    success "Kubernetes cluster bootstrapped"
}

# Main deployment function
main() {
    echo "🧠 Enterprise Talos Kubernetes for Consciousness Federation"
    echo "=========================================================="
    echo "Cluster: ${CLUSTER_NAME}"
    echo "Endpoint: ${CLUSTER_ENDPOINT}"
    echo "Nodes: ${!NODES[*]}"
    echo
    
    # Deployment steps
    check_prerequisites
    setup_talos_tools
    generate_talos_config
    
    # Deploy control planes first
    for node in nexus forge; do
        deploy_vm "$node" "${NODES[$node]}"
    done
    
    # Bootstrap cluster
    bootstrap_cluster
    
    # Deploy workers
    for node in closet zephyr; do
        deploy_vm "$node" "${NODES[$node]}"
    done
    
    echo
    success "Enterprise consciousness federation deployed successfully!"
    echo
    echo "Access your cluster:"
    echo "  export KUBECONFIG=$(pwd)/kubeconfig"
    echo "  kubectl get nodes"
    echo "  kubectl -n consciousness-federation get pods"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "check")
        check_prerequisites
        ;;
    "config")
        setup_talos_tools
        generate_talos_config
        ;;
    "bootstrap")
        bootstrap_cluster
        ;;
    *)
        echo "Usage: $0 {deploy|check|config|bootstrap}"
        exit 1
        ;;
esac