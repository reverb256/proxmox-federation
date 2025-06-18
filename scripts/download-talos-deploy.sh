#!/bin/bash

# Download and run idempotent Talos deployment on Proxmox
# Run this on your Proxmox host: nexus

set -euo pipefail

SCRIPT_URL="https://raw.githubusercontent.com/your-repo/aria/main/scripts/idempotent-talos-deploy.sh"
LOCAL_SCRIPT="./talos-consciousness-deploy.sh"

echo "🤖 Downloading Talos Consciousness Federation Deployment"
echo "======================================================="

# Create the deployment script locally
cat > "${LOCAL_SCRIPT}" << 'DEPLOY_SCRIPT_EOF'
#!/bin/bash

# Idempotent Talos Linux Consciousness Federation Deployment
# Designed to run on Proxmox homelab

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
TALOS_VERSION="v1.7.6"
KUBERNETES_VERSION="v1.30.3"
CLUSTER_NAME="consciousness-federation"
CLUSTER_ENDPOINT="https://10.1.1.120:6443"
BRIDGE="vmbr0"
SUBNET="10.1.1"
GATEWAY="${SUBNET}.1"
DNS_SERVERS="10.1.1.11,10.1.1.10"
WORK_DIR="/tmp/talos-deploy"

# Node Configuration for your homelab
declare -A TALOS_NODES=(
    ["nexus"]="vmid=120 cores=8 memory=16384 disk=100 ip=${SUBNET}.120 role=controlplane"
    ["forge"]="vmid=121 cores=6 memory=12288 disk=80 ip=${SUBNET}.121 role=controlplane"  
    ["closet"]="vmid=1001 cores=4 memory=8192 disk=60 ip=${SUBNET}.122 role=worker"
    ["zephyr"]="vmid=1002 cores=6 memory=12288 disk=80 ip=${SUBNET}.123 role=worker"
)

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running on Proxmox
check_proxmox() {
    if ! command -v qm >/dev/null 2>&1; then
        log_error "This script must be run on a Proxmox host with qm command available"
        exit 1
    fi
    log_info "Running on Proxmox host"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if VM exists
vm_exists() {
    local vmid=$1
    qm status $vmid >/dev/null 2>&1
}

# Check if VM is running
vm_running() {
    local vmid=$1
    [[ "$(qm status $vmid 2>/dev/null | grep -o 'status: [^,]*' | cut -d' ' -f2)" == "running" ]]
}

# Setup working directory
setup_work_dir() {
    log_step "Setting up working directory..."
    mkdir -p ${WORK_DIR}
    cd ${WORK_DIR}
    log_success "Working directory ready: ${WORK_DIR}"
}

# Download and install tools
install_tools() {
    log_step "Installing required tools..."
    
    # Install talosctl if not present
    if ! command_exists talosctl; then
        log_step "Installing talosctl..."
        curl -sLO "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64"
        chmod +x talosctl-*
        mv talosctl-* /usr/local/bin/talosctl
        log_success "talosctl installed"
    else
        log_info "talosctl already installed"
    fi
    
    # Download Talos ISO
    local iso_path="/var/lib/vz/template/iso/talos-${TALOS_VERSION}-amd64.iso"
    if [[ ! -f "$iso_path" ]]; then
        log_step "Downloading Talos ISO..."
        wget -O "$iso_path" \
            "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talos-amd64.iso"
        log_success "Talos ISO downloaded"
    else
        log_info "Talos ISO already present"
    fi
}

# Generate Talos configuration
generate_config() {
    log_step "Generating Talos configuration..."
    
    if [[ -f "secrets.yaml" && -f "controlplane.yaml" && -f "worker.yaml" ]]; then
        log_info "Configuration files already exist"
        return 0
    fi
    
    # Generate secrets
    talosctl gen secrets
    
    # Generate machine configs
    talosctl gen config ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
        --kubernetes-version=${KUBERNETES_VERSION} \
        --with-secrets secrets.yaml \
        --config-patch-control-plane @- <<EOF
cluster:
  network:
    dnsDomain: cluster.local
    podSubnets:
      - 10.244.0.0/16
    serviceSubnets:
      - 10.96.0.0/12
machine:
  network:
    nameservers:
      - 10.1.1.11
      - 10.1.1.10
  install:
    disk: /dev/sda
    image: ghcr.io/siderolabs/installer:${TALOS_VERSION}
    wipe: true
  features:
    rbac: true
    stableHostname: true
    apidCheckExtKeyUsage: true
EOF
    
    # Generate worker config
    talosctl gen config ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
        --kubernetes-version=${KUBERNETES_VERSION} \
        --with-secrets secrets.yaml \
        --config-patch-worker @- <<EOF
machine:
  network:
    nameservers:
      - 10.1.1.11
      - 10.1.1.10
  install:
    disk: /dev/sda
    image: ghcr.io/siderolabs/installer:${TALOS_VERSION}
    wipe: true
  features:
    rbac: true
    stableHostname: true
EOF

    log_success "Configuration generated"
}

# Create/update VM
deploy_vm() {
    local vm_name=$1
    local config_str=$2
    
    # Parse configuration
    eval $config_str
    
    log_step "Deploying VM: $vm_name (VMID: $vmid)"
    
    # Stop and destroy existing VM if it exists
    if vm_exists $vmid; then
        log_warning "VM $vmid exists, recreating for clean Talos deployment..."
        if vm_running $vmid; then
            qm stop $vmid || true
            sleep 5
        fi
        qm destroy $vmid || true
        sleep 2
    fi
    
    # Create new VM
    qm create $vmid \
        --name $vm_name \
        --memory $memory \
        --cores $cores \
        --net0 virtio,bridge=${BRIDGE} \
        --bootdisk scsi0 \
        --scsi0 local-zfs:${disk},format=raw \
        --ide0 local:iso/talos-${TALOS_VERSION}-amd64.iso,media=cdrom \
        --boot order=ide0 \
        --serial0 socket \
        --vga serial0 \
        --agent enabled=1
    
    # Configure network
    qm set $vmid --ipconfig0 ip=${ip}/24,gw=${GATEWAY}
    qm set $vmid --nameserver ${DNS_SERVERS}
    
    log_success "VM $vm_name created"
    
    # Start VM
    log_step "Starting VM $vm_name..."
    qm start $vmid
    
    # Wait for boot
    log_step "Waiting for VM to boot (90 seconds)..."
    sleep 90
    
    # Apply configuration
    log_step "Applying Talos configuration to $vm_name..."
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [[ "$role" == "controlplane" ]]; then
            if talosctl apply-config --insecure --nodes $ip --file controlplane.yaml 2>/dev/null; then
                log_success "Configuration applied to $vm_name"
                break
            fi
        else
            if talosctl apply-config --insecure --nodes $ip --file worker.yaml 2>/dev/null; then
                log_success "Configuration applied to $vm_name"
                break
            fi
        fi
        
        log_warning "Attempt $attempt failed, retrying in 20 seconds..."
        sleep 20
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "Failed to configure $vm_name after $max_attempts attempts"
        return 1
    fi
}

# Bootstrap cluster
bootstrap_cluster() {
    log_step "Bootstrapping Kubernetes cluster..."
    
    # Configure talosctl
    talosctl config endpoint 10.1.1.120
    talosctl config node 10.1.1.120
    
    # Bootstrap etcd
    log_step "Bootstrapping etcd on nexus..."
    sleep 30  # Give first control plane time to stabilize
    talosctl bootstrap --nodes 10.1.1.120
    
    # Wait and get kubeconfig
    log_step "Waiting for Kubernetes API..."
    sleep 60
    talosctl kubeconfig kubeconfig
    
    log_success "Cluster bootstrapped"
}

# Deploy consciousness workloads
deploy_workloads() {
    log_step "Deploying consciousness federation workloads..."
    
    export KUBECONFIG=${WORK_DIR}/kubeconfig
    
    # Wait for nodes to be ready
    log_step "Waiting for all nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Create namespace and deploy workloads
    kubectl create namespace consciousness-federation 2>/dev/null || true
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consciousness-coordinator
  namespace: consciousness-federation
spec:
  replicas: 2
  selector:
    matchLabels:
      app: consciousness-coordinator
  template:
    metadata:
      labels:
        app: consciousness-coordinator
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: coordinator
        image: alpine:latest
        command: ["sleep", "infinity"]
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
        env:
        - name: NODE_ROLE
          value: "coordinator"
        - name: FEDERATION_NETWORK
          value: "10.1.1.0/24"
EOF

    log_success "Consciousness workloads deployed"
}

# Main function
main() {
    echo "🤖 Talos Linux Consciousness Federation for Proxmox"
    echo "=================================================="
    echo "Target VMs: nexus(120), forge(121), closet(1001), zephyr(1002)"
    echo "DNS: ${DNS_SERVERS}"
    echo
    
    check_proxmox
    setup_work_dir
    install_tools
    generate_config
    
    # Deploy control planes first
    deploy_vm "nexus" "${TALOS_NODES[nexus]}"
    deploy_vm "forge" "${TALOS_NODES[forge]}"
    
    # Bootstrap cluster
    bootstrap_cluster
    
    # Deploy workers
    deploy_vm "closet" "${TALOS_NODES[closet]}"
    deploy_vm "zephyr" "${TALOS_NODES[zephyr]}"
    
    # Deploy workloads
    deploy_workloads
    
    log_success "Talos consciousness federation deployed!"
    echo
    echo "Management commands:"
    echo "  export KUBECONFIG=${WORK_DIR}/kubeconfig"
    echo "  kubectl get nodes"
    echo "  kubectl -n consciousness-federation get pods"
}

main "$@"
DEPLOY_SCRIPT_EOF

chmod +x "${LOCAL_SCRIPT}"

echo "✅ Talos deployment script created: ${LOCAL_SCRIPT}"
echo
echo "To deploy on your Proxmox homelab:"
echo "  ./${LOCAL_SCRIPT##*/}"
echo
echo "This will create a 4-node Talos Kubernetes cluster with consciousness workloads"