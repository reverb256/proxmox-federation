#!/bin/bash

# Idempotent Talos Linux Consciousness Federation Deployment
# Can be run multiple times safely, handles all state checks

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

# Node Configuration
declare -A TALOS_NODES=(
    ["nexus"]="vmid=1003 cores=8 memory=16384 disk=100 ip=${SUBNET}.120 role=controlplane"
    ["forge"]="vmid=1004 cores=6 memory=12288 disk=80 ip=${SUBNET}.121 role=controlplane"  
    ["closet"]="vmid=1005 cores=4 memory=8192 disk=60 ip=${SUBNET}.122 role=worker"
    ["zephyr"]="vmid=1006 cores=6 memory=12288 disk=80 ip=${SUBNET}.123 role=worker"
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
    [[ "$(qm status $vmid | grep -o 'status: [^,]*' | cut -d' ' -f2)" == "running" ]]
}

# Check if Talos is responding
talos_responding() {
    local ip=$1
    timeout 5 talosctl version --nodes $ip >/dev/null 2>&1
}

# Check if Kubernetes is ready
k8s_ready() {
    timeout 10 kubectl --kubeconfig ${WORK_DIR}/kubeconfig get nodes >/dev/null 2>&1
}

# Setup working directory
setup_work_dir() {
    log_step "Setting up working directory..."
    mkdir -p ${WORK_DIR}
    cd ${WORK_DIR}
    log_success "Working directory ready: ${WORK_DIR}"
}

# Download and install tools idempotently
install_tools() {
    log_step "Checking/installing required tools..."
    
    # Install talosctl if not present
    if ! command_exists talosctl; then
        log_step "Installing talosctl..."
        curl -sLO "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64"
        chmod +x talosctl-*
        sudo mv talosctl-* /usr/local/bin/talosctl
        log_success "talosctl installed"
    else
        log_info "talosctl already installed"
    fi
    
    # Download Talos ISO if not present
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

# Generate configuration idempotently
generate_config() {
    log_step "Checking/generating Talos configuration..."
    
    if [[ -f "secrets.yaml" && -f "controlplane.yaml" && -f "worker.yaml" ]]; then
        log_info "Configuration files already exist"
        return 0
    fi
    
    log_step "Generating new Talos configuration..."
    
    # Generate secrets
    talosctl gen secrets
    
    # Generate machine configs with proper DNS
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
  kubelet:
    extraArgs:
      feature-gates: GracefulNodeShutdown=true
      rotate-server-certificates: true
EOF
    
    # Worker config patch
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
  kubelet:
    extraArgs:
      feature-gates: GracefulNodeShutdown=true
      rotate-server-certificates: true
EOF

    log_success "Configuration generated"
}

# Deploy VM idempotently
deploy_vm() {
    local vm_name=$1
    local config_str=$2
    
    # Parse configuration
    eval $config_str
    
    log_step "Deploying VM: $vm_name (VMID: $vmid)"
    
    # Check if VM exists and handle accordingly
    if vm_exists $vmid; then
        if vm_running $vmid; then
            log_info "VM $vm_name already running"
            if talos_responding $ip; then
                log_success "VM $vm_name already configured and responding"
                return 0
            else
                log_warning "VM $vm_name running but Talos not responding, reconfiguring..."
            fi
        else
            log_info "VM $vm_name exists but stopped, starting..."
            qm start $vmid
            sleep 30
        fi
    else
        log_step "Creating new VM $vm_name..."
        
        # Create VM
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
        qm set $vmid --searchdomain lan
        
        # Start VM
        log_step "Starting VM $vm_name..."
        qm start $vmid
        
        # Wait for boot
        log_step "Waiting for VM to boot..."
        sleep 60
    fi
    
    # Apply configuration
    log_step "Applying Talos configuration to $vm_name..."
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [[ "$role" == "controlplane" ]]; then
            if talosctl apply-config --insecure --nodes $ip --file controlplane.yaml; then
                log_success "Configuration applied to $vm_name"
                break
            fi
        else
            if talosctl apply-config --insecure --nodes $ip --file worker.yaml; then
                log_success "Configuration applied to $vm_name"
                break
            fi
        fi
        
        log_warning "Attempt $attempt failed, retrying in 30 seconds..."
        sleep 30
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "Failed to configure $vm_name after $max_attempts attempts"
        return 1
    fi
}

# Bootstrap cluster idempotently
bootstrap_cluster() {
    log_step "Checking/bootstrapping Kubernetes cluster..."
    
    # Configure talosctl
    talosctl config endpoint ${CLUSTER_ENDPOINT}
    talosctl config node 10.1.1.120
    
    # Check if cluster is already bootstrapped
    if k8s_ready; then
        log_success "Kubernetes cluster already ready"
        return 0
    fi
    
    # Bootstrap if needed
    log_step "Bootstrapping etcd..."
    if talosctl bootstrap --nodes 10.1.1.120; then
        log_success "Cluster bootstrapped"
    else
        log_warning "Bootstrap may have already been done"
    fi
    
    # Get kubeconfig
    log_step "Retrieving kubeconfig..."
    talosctl kubeconfig kubeconfig
    export KUBECONFIG=${WORK_DIR}/kubeconfig
    
    # Wait for nodes
    log_step "Waiting for all nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    log_success "Kubernetes cluster is ready"
}

# Deploy workloads idempotently
deploy_workloads() {
    log_step "Deploying consciousness federation workloads..."
    
    export KUBECONFIG=${WORK_DIR}/kubeconfig
    
    # Check if namespace exists
    if kubectl get namespace consciousness-federation >/dev/null 2>&1; then
        log_info "Consciousness federation namespace already exists"
    else
        kubectl create namespace consciousness-federation
        log_success "Consciousness federation namespace created"
    fi
    
    # Deploy workloads
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
      nodeSelector:
        node-role.kubernetes.io/control-plane: ""
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
          limits:
            memory: "2Gi"
            cpu: "1000m"
        env:
        - name: NODE_ROLE
          value: "coordinator"
        - name: FEDERATION_NETWORK
          value: "10.1.1.0/24"
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: consciousness-worker
  namespace: consciousness-federation
spec:
  selector:
    matchLabels:
      app: consciousness-worker
  template:
    metadata:
      labels:
        app: consciousness-worker
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker: ""
      containers:
      - name: worker
        image: alpine:latest
        command: ["sleep", "infinity"]
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        env:
        - name: NODE_ROLE
          value: "worker"
        - name: AI_MODELS_PATH
          value: "/data/models"
        volumeMounts:
        - name: models-storage
          mountPath: /data/models
      volumes:
      - name: models-storage
        hostPath:
          path: /var/lib/consciousness/models
          type: DirectoryOrCreate
EOF

    log_success "Consciousness workloads deployed"
}

# Status check
check_status() {
    log_step "Checking deployment status..."
    
    export KUBECONFIG=${WORK_DIR}/kubeconfig
    
    echo
    echo "🤖 Talos Linux Consciousness Federation Status"
    echo "=============================================="
    
    # Node status
    echo "Kubernetes Nodes:"
    kubectl get nodes -o wide || log_error "Failed to get nodes"
    
    echo
    echo "Consciousness Workloads:"
    kubectl get pods -n consciousness-federation -o wide || log_error "Failed to get workloads"
    
    echo
    echo "Management Commands:"
    echo "  Talos: talosctl --nodes 10.1.1.120,10.1.1.121 version"
    echo "  K8s: export KUBECONFIG=${WORK_DIR}/kubeconfig"
    echo "  Workloads: kubectl -n consciousness-federation get all"
}

# Main function
main() {
    echo "🤖 Idempotent Talos Linux Consciousness Federation"
    echo "================================================="
    echo "Working directory: ${WORK_DIR}"
    echo "Cluster endpoint: ${CLUSTER_ENDPOINT}"
    echo "DNS servers: ${DNS_SERVERS}"
    echo
    
    setup_work_dir
    install_tools
    generate_config
    
    # Deploy all nodes
    for node_name in "${!TALOS_NODES[@]}"; do
        deploy_vm "$node_name" "${TALOS_NODES[$node_name]}"
    done
    
    # Bootstrap cluster
    bootstrap_cluster
    
    # Deploy workloads
    deploy_workloads
    
    # Final status
    check_status
    
    log_success "Idempotent deployment complete!"
}

# Handle interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

main "$@"