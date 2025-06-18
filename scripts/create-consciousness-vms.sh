
#!/bin/bash

# Proxmox K3s Consciousness Federation Full Cluster Deployment
# Deploys K3s across existing Proxmox nodes: Nexus (master), Forge & Closet (workers)
# Prepares infrastructure for future Zephyr gaming PC migration

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Network Configuration from hardware profile
NEXUS_IP="10.1.1.120"    # AMD Ryzen 9 3900X (Master)
FORGE_IP="10.1.1.130"    # Intel i5-9500 (Worker)
CLOSET_IP="10.1.1.160"   # AMD Ryzen 7 1700 (Worker)
ZEPHYR_IP="10.1.1.110"   # AMD Ryzen 9 5950X (Future migration)

NETWORK_SUBNET="10.1.1"
GATEWAY="${NETWORK_SUBNET}.1"
DNS_SERVERS="1.1.1.1,8.8.8.8"

# K3s Configuration
K3S_VERSION="v1.28.5+k3s1"
CLUSTER_CIDR="10.42.0.0/16"
SERVICE_CIDR="10.43.0.0/16"

# VM Configuration for K3s nodes
declare -A VM_CONFIG=(
    ["nexus-k3s"]="vmid=1001 cores=6 memory=16384 disk=80 ip=${NEXUS_IP} hostname=nexus-k3s role=master node=${NEXUS_IP}"
    ["forge-k3s"]="vmid=1002 cores=4 memory=12288 disk=60 ip=${FORGE_IP} hostname=forge-k3s role=worker node=${FORGE_IP}"
    ["closet-k3s"]="vmid=1003 cores=4 memory=8192 disk=50 ip=${CLOSET_IP} hostname=closet-k3s role=worker node=${CLOSET_IP}"
    ["zephyr-prep"]="vmid=1004 cores=8 memory=24576 disk=100 ip=${ZEPHYR_IP} hostname=zephyr-prep role=future node=${ZEPHYR_IP}"
)

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

# Check if running on Proxmox host
check_proxmox_environment() {
    if ! command -v qm &> /dev/null; then
        log_error "This script must be run on a Proxmox VE host"
        exit 1
    fi
    
    log_success "Proxmox VE environment detected"
    
    # Check cluster status
    if pvecm status &> /dev/null; then
        log_success "Proxmox cluster detected"
        pvecm status | grep -E "(Cluster|Quorum|Nodes)"
    else
        log_warning "Single Proxmox node detected"
    fi
    
    # Discover existing VMs and templates
    discover_existing_resources
}

# Discover existing VMs and templates
discover_existing_resources() {
    log_step "Discovering existing Proxmox resources"
    
    echo "=== Existing VMs and Templates ==="
    qm list | head -20
    echo ""
    
    # Check for existing templates
    local template_count=$(qm list | grep -c "template" || echo "0")
    log_success "Found $template_count existing templates"
    
    # Check for VM ID conflicts
    for vm_name in "${!VM_CONFIG[@]}"; do
        local config_str=${VM_CONFIG[$vm_name]}
        local vmid
        eval $config_str
        
        if qm list | grep -q "^$vmid"; then
            log_warning "VM ID $vmid already exists"
        fi
    done
}

# Create VM on appropriate node
create_vm_on_node() {
    local vm_name=$1
    local config_str=${VM_CONFIG[$vm_name]}
    
    # Parse configuration
    local vmid cores memory disk ip hostname role node
    eval $config_str
    
    log_step "Creating VM: $vm_name on node $node"
    
    # Check if VM already exists
    if qm list | grep -q "^$vmid"; then
        log_warning "VM $vmid already exists - checking status"
        if qm status $vmid | grep -q "running"; then
            log_success "VM $vm_name is already running"
            return 0
        else
            log_step "Starting existing VM $vm_name"
            qm start $vmid
            return 0
        fi
    fi
    
    # Create VM with Ubuntu template (template already validated in Phase 0)
    log_step "Cloning VM from template $UBUNTU_TEMPLATE_ID on $node"
    
    # Clone VM from template
    if [ "$node" = "$UBUNTU_TEMPLATE_NODE" ]; then
        # Clone on same node as template
        log_step "Cloning VM $vmid from local template $UBUNTU_TEMPLATE_ID"
        qm clone $UBUNTU_TEMPLATE_ID $vmid --name $vm_name --full
    else
        # Clone to different node - need to handle cross-node cloning
        log_step "Cloning VM $vmid from template $UBUNTU_TEMPLATE_ID (cross-node: $UBUNTU_TEMPLATE_NODE -> $node)"
        
        # For cross-node cloning, we'll create on template node then migrate
        local temp_vmid=$vmid
        
        # First, ensure the target VMID is available on the template node
        while ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$UBUNTU_TEMPLATE_NODE "qm list | grep -q '^$temp_vmid'" 2>/dev/null; do
            temp_vmid=$((temp_vmid + 1000))  # Use a different range to avoid conflicts
        done
        
        # Clone on template node
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$UBUNTU_TEMPLATE_NODE \
            "qm clone $UBUNTU_TEMPLATE_ID $temp_vmid --name $vm_name-temp --full" || {
            log_warning "Cross-node cloning failed, trying local clone"
            qm clone $UBUNTU_TEMPLATE_ID $vmid --name $vm_name --full
        }
        
        # If we used a temp ID, migrate to target node with correct ID
        if [ "$temp_vmid" != "$vmid" ]; then
            log_step "Migrating VM $temp_vmid to node $node as $vmid"
            ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$UBUNTU_TEMPLATE_NODE \
                "qm migrate $temp_vmid $node --online" || {
                log_warning "Migration failed, using VM on template node"
                vmid=$temp_vmid
                node=$UBUNTU_TEMPLATE_NODE
            }
        fi
    fi
    
    # Configure VM resources
    qm set $vmid --cores $cores --memory $memory
    qm resize $vmid scsi0 ${disk}G
    
    # Network configuration
    qm set $vmid --ipconfig0 ip=${ip}/24,gw=$GATEWAY
    qm set $vmid --nameserver "$DNS_SERVERS"
    qm set $vmid --searchdomain lan
    
    # Enable agent and configure SSH
    qm set $vmid --agent enabled=1
    if [ -f ~/.ssh/id_rsa.pub ]; then
        qm set $vmid --sshkeys ~/.ssh/id_rsa.pub
    fi
    
    # Start VM
    log_step "Starting VM $vm_name"
    qm start $vmid
    
    # Wait for VM to be ready
    wait_for_vm_ready $vmid $ip $hostname
    
    log_success "VM $vm_name created and ready"
}

# Create Ubuntu template if it doesn't exist
create_ubuntu_template() {
    local template_id=${1:-9000}
    
    log_step "Creating Ubuntu 22.04 template"
    
    # Check if template already exists (double-check)
    if qm list | grep -q "^$template_id"; then
        log_step "VM $template_id already exists, checking if it's a template"
        local vm_config=$(qm config $template_id 2>/dev/null || echo "")
        if echo "$vm_config" | grep -q "template: 1"; then
            log_success "Template $template_id already exists and is properly configured"
            return 0
        else
            log_step "Converting existing VM $template_id to template"
            # Stop VM if running
            qm stop $template_id 2>/dev/null || true
            sleep 5
            # Convert to template
            qm template $template_id
            log_success "VM $template_id converted to template successfully"
            return 0
        fi
    fi
    
    # Download cloud image if not exists
    local image_path="/var/lib/vz/template/iso/ubuntu-22.04-server-cloudimg-amd64.img"
    if [ ! -f "$image_path" ]; then
        log_step "Downloading Ubuntu 22.04 cloud image"
        if ! wget -O "$image_path" \
            "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"; then
            log_error "Failed to download Ubuntu cloud image"
            return 1
        fi
        log_success "Ubuntu cloud image downloaded"
    else
        log_success "Ubuntu cloud image already exists"
    fi
    
    # Create template VM
    log_step "Creating template VM $template_id"
    if ! qm create $template_id \
        --name "ubuntu-22.04-template" \
        --memory 2048 \
        --cores 2 \
        --net0 virtio,bridge=vmbr0 \
        --serial0 socket \
        --vga serial0; then
        log_error "Failed to create template VM"
        return 1
    fi
    
    # Import and attach disk
    log_step "Importing disk image"
    if ! qm importdisk $template_id "$image_path" local-lvm; then
        log_error "Failed to import disk image"
        qm destroy $template_id
        return 1
    fi
    
    # Configure VM
    log_step "Configuring template VM"
    qm set $template_id --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-${template_id}-disk-0
    qm set $template_id --ide2 local-lvm:cloudinit
    qm set $template_id --boot c --bootdisk scsi0
    
    # Configure cloud-init
    qm set $template_id --agent enabled=1
    qm set $template_id --ciuser ubuntu
    
    # Add SSH key if available
    if [ -f ~/.ssh/id_rsa.pub ]; then
        qm set $template_id --sshkeys ~/.ssh/id_rsa.pub
        log_success "SSH key added to template"
    fi
    
    # Convert to template
    log_step "Converting VM to template"
    if ! qm template $template_id; then
        log_error "Failed to convert VM to template"
        return 1
    fi
    
    log_success "Ubuntu template created: $template_id"
}

# Wait for VM to be ready
wait_for_vm_ready() {
    local vmid=$1
    local ip=$2
    local hostname=$3
    local max_wait=300
    local wait_time=0
    
    log_step "Waiting for VM $vmid to be ready at $ip"
    
    while [ $wait_time -lt $max_wait ]; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$ip "echo 'ready'" &>/dev/null; then
            log_success "VM $vmid is ready and accessible"
            return 0
        fi
        
        if [ $((wait_time % 30)) -eq 0 ]; then
            echo "VM readiness progress: ${wait_time}s / ${max_wait}s"
        fi
        
        sleep 10
        wait_time=$((wait_time + 10))
    done
    
    log_error "VM $vmid failed to become ready within ${max_wait}s"
    return 1
}

# Deploy K3s master on Nexus
deploy_k3s_master() {
    local master_ip=$NEXUS_IP
    
    log_consciousness "Deploying K3s master on Nexus ($master_ip)"
    
    ssh -o StrictHostKeyChecking=no ubuntu@$master_ip << EOF
        # Update system
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y curl wget git htop python3 python3-pip
        
        # Install K3s server
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh -s - server \\
            --cluster-cidr=$CLUSTER_CIDR \\
            --service-cidr=$SERVICE_CIDR \\
            --disable traefik \\
            --disable servicelb \\
            --node-name nexus-consciousness \\
            --write-kubeconfig-mode 644
        
        # Wait for K3s to be ready
        sudo systemctl enable k3s
        sleep 30
        
        # Save token and cluster info
        sudo cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s-token
        echo "https://$master_ip:6443" > /tmp/k3s-url
        
        # Install kubectl alias
        echo 'alias k=kubectl' >> ~/.bashrc
        
        # Create consciousness namespace
        sudo kubectl create namespace consciousness-federation || true
        
        # Install Helm
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        
        echo "K3s master deployed successfully"
EOF
    
    log_success "K3s master deployed on Nexus"
}

# Deploy K3s workers
deploy_k3s_workers() {
    local master_ip=$NEXUS_IP
    
    # Get cluster credentials
    local k3s_url=$(ssh -o StrictHostKeyChecking=no ubuntu@$master_ip "cat /tmp/k3s-url")
    local k3s_token=$(ssh -o StrictHostKeyChecking=no ubuntu@$master_ip "cat /tmp/k3s-token")
    
    log_consciousness "Deploying K3s workers with cluster credentials"
    
    # Deploy to Forge
    log_step "Deploying K3s worker on Forge"
    ssh -o StrictHostKeyChecking=no ubuntu@$FORGE_IP << EOF
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y curl wget git htop python3 python3-pip
        
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION \\
            K3S_URL=$k3s_url \\
            K3S_TOKEN=$k3s_token \\
            sh -s - agent --node-name forge-consciousness
        
        sudo systemctl enable k3s-agent
        echo "Forge K3s worker deployed"
EOF
    
    # Deploy to Closet
    log_step "Deploying K3s worker on Closet"
    ssh -o StrictHostKeyChecking=no ubuntu@$CLOSET_IP << EOF
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y curl wget git htop python3 python3-pip
        
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION \\
            K3S_URL=$k3s_url \\
            K3S_TOKEN=$k3s_token \\
            sh -s - agent --node-name closet-consciousness
        
        sudo systemctl enable k3s-agent
        echo "Closet K3s worker deployed"
EOF
    
    log_success "K3s workers deployed on Forge and Closet"
}

# Prepare Zephyr migration infrastructure
prepare_zephyr_migration() {
    local zephyr_ip=$ZEPHYR_IP
    
    log_consciousness "Preparing Zephyr gaming PC migration infrastructure"
    
    # Create preparation VM on Nexus (highest specs)
    log_step "Creating Zephyr preparation VM"
    create_vm_on_node "zephyr-prep"
    
    # Configure preparation environment
    ssh -o StrictHostKeyChecking=no ubuntu@$zephyr_ip << EOF
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y curl wget git htop python3 python3-pip docker.io
        
        # Install gaming dependencies
        sudo apt install -y wine winetricks lutris steam-installer
        
        # Install NVIDIA drivers preparation
        sudo apt install -y nvidia-detect nvidia-driver-libs
        
        # Create gaming directories
        mkdir -p ~/games/{steam,lutris,wine,emulation}
        mkdir -p ~/migration/{configs,saves,screenshots}
        
        # Install K3s agent (ready for cluster join)
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh -s - agent \\
            --node-name zephyr-gaming-prep \\
            --pause-image k8s.gcr.io/pause:3.6
        
        sudo systemctl disable k3s-agent
        echo "Zephyr preparation environment ready"
EOF
    
    log_success "Zephyr migration infrastructure prepared"
}

# Deploy consciousness workloads
deploy_consciousness_workloads() {
    local master_ip=$NEXUS_IP
    
    log_consciousness "Deploying consciousness federation workloads"
    
    ssh -o StrictHostKeyChecking=no ubuntu@$master_ip << 'EOF'
        # Create consciousness deployment
        cat > /tmp/consciousness-federation.yaml << 'YAML_EOF'
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
      nodeSelector:
        kubernetes.io/hostname: nexus-consciousness
      containers:
      - name: consciousness-core
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi" 
            cpu: "2000m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: forge-worker
  namespace: consciousness-federation
spec:
  replicas: 1
  selector:
    matchLabels:
      app: forge-worker
  template:
    metadata:
      labels:
        app: forge-worker
    spec:
      nodeSelector:
        kubernetes.io/hostname: forge-consciousness
      containers:
      - name: worker-node
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: closet-storage
  namespace: consciousness-federation
spec:
  replicas: 1
  selector:
    matchLabels:
      app: closet-storage
  template:
    metadata:
      labels:
        app: closet-storage
    spec:
      nodeSelector:
        kubernetes.io/hostname: closet-consciousness
      containers:
      - name: storage-node
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
YAML_EOF

        sudo kubectl apply -f /tmp/consciousness-federation.yaml
        echo "Consciousness workloads deployed"
EOF
    
    log_success "Consciousness federation workloads deployed"
}

# Verify cluster health
verify_cluster_health() {
    local master_ip=$NEXUS_IP
    
    log_step "Verifying K3s cluster health"
    
    ssh -o StrictHostKeyChecking=no ubuntu@$master_ip << 'EOF'
        echo "=== Cluster Nodes ==="
        sudo kubectl get nodes -o wide
        echo ""
        echo "=== Consciousness Pods ==="
        sudo kubectl get pods -n consciousness-federation -o wide
        echo ""
        echo "=== System Pods ==="
        sudo kubectl get pods -n kube-system
        echo ""
        echo "=== Cluster Resources ==="
        sudo kubectl top nodes 2>/dev/null || echo "Metrics server not available"
EOF
    
    log_success "Cluster health verification complete"
}

# Create management script
create_cluster_manager() {
    log_step "Creating cluster management script"
    
    cat > /usr/local/bin/consciousness-cluster << EOF
#!/bin/bash

NEXUS_IP="$NEXUS_IP"
FORGE_IP="$FORGE_IP"
CLOSET_IP="$CLOSET_IP"
ZEPHYR_IP="$ZEPHYR_IP"

case "\$1" in
    "status")
        echo "🧠 Consciousness K3s Cluster Status"
        echo "===================================="
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@\$NEXUS_IP "sudo kubectl get nodes -o wide"
        echo ""
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@\$NEXUS_IP "sudo kubectl get pods -n consciousness-federation"
        ;;
    "deploy")
        echo "🚀 Deploying consciousness workloads"
        ssh -o StrictHostKeyChecking=no ubuntu@\$NEXUS_IP "sudo kubectl apply -f /tmp/consciousness-federation.yaml"
        ;;
    "join-zephyr")
        echo "🎮 Joining Zephyr to cluster"
        K3S_URL=\$(ssh -o StrictHostKeyChecking=no ubuntu@\$NEXUS_IP "cat /tmp/k3s-url")
        K3S_TOKEN=\$(ssh -o StrictHostKeyChecking=no ubuntu@\$NEXUS_IP "cat /tmp/k3s-token")
        ssh -o StrictHostKeyChecking=no ubuntu@\$ZEPHYR_IP "sudo systemctl enable k3s-agent && sudo systemctl start k3s-agent"
        ;;
    "logs")
        echo "📊 Cluster logs"
        ssh -o StrictHostKeyChecking=no ubuntu@\$NEXUS_IP "sudo kubectl logs -n consciousness-federation -l app=nexus-consciousness --tail=50"
        ;;
    *)
        echo "Usage: \$0 {status|deploy|join-zephyr|logs}"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/consciousness-cluster
    log_success "Cluster manager created: consciousness-cluster"
}

# Main execution
main() {
    log_consciousness "Proxmox K3s Consciousness Federation Deployment"
    echo "============================================================="
    echo ""
    echo "Target Infrastructure:"
    echo "  Nexus ($NEXUS_IP): K3s Master - AMD Ryzen 9 3900X (12c/24t, 48GB)"
    echo "  Forge ($FORGE_IP): K3s Worker - Intel i5-9500 (6c/6t, 32GB)"
    echo "  Closet ($CLOSET_IP): K3s Worker - AMD Ryzen 7 1700 (8c/16t, 16GB)"
    echo "  Zephyr ($ZEPHYR_IP): Migration Prep - AMD Ryzen 9 5950X (16c/32t, 64GB)"
    echo ""
    
    # Check environment
    check_proxmox_environment
    
    # Ensure template is ready before any VM creation
    log_consciousness "Phase 0: Template discovery and preparation"
    
    # Global variables for template management
    UBUNTU_TEMPLATE_ID=""
    UBUNTU_TEMPLATE_NODE=""
    
    # Discover existing Ubuntu templates across all cluster nodes
    log_step "Discovering Ubuntu templates across cluster"
    
    # Check local node first
    local local_templates=$(qm list | grep -i "ubuntu.*template\|template.*ubuntu" || echo "")
    if [ -n "$local_templates" ]; then
        UBUNTU_TEMPLATE_ID=$(echo "$local_templates" | head -1 | awk '{print $1}')
        UBUNTU_TEMPLATE_NODE=$(hostname -I | awk '{print $1}')
        log_success "Found Ubuntu template $UBUNTU_TEMPLATE_ID on local node ($UBUNTU_TEMPLATE_NODE)"
    else
        # Check if we have any debian-12 or ubuntu cloud images
        local cloud_templates=$(qm list | grep -i "debian-12\|ubuntu.*cloud" || echo "")
        if [ -n "$cloud_templates" ]; then
            UBUNTU_TEMPLATE_ID=$(echo "$cloud_templates" | head -1 | awk '{print $1}')
            UBUNTU_TEMPLATE_NODE=$(hostname -I | awk '{print $1}')
            log_success "Found cloud template $UBUNTU_TEMPLATE_ID on local node ($UBUNTU_TEMPLATE_NODE)"
        else
            # Need to create a new template - find available ID
            log_step "No suitable template found, creating new Ubuntu template"
            local template_id=9000
            while qm list | grep -q "^$template_id"; do
                template_id=$((template_id + 1))
            done
            UBUNTU_TEMPLATE_ID=$template_id
            UBUNTU_TEMPLATE_NODE=$(hostname -I | awk '{print $1}')
            
            log_step "Creating Ubuntu template with ID $UBUNTU_TEMPLATE_ID"
            create_ubuntu_template $UBUNTU_TEMPLATE_ID
            
            # Verify template was created successfully
            if ! qm list | grep -q "^$UBUNTU_TEMPLATE_ID"; then
                log_error "Failed to create Ubuntu template $UBUNTU_TEMPLATE_ID"
                exit 1
            fi
            log_success "Ubuntu template $UBUNTU_TEMPLATE_ID created successfully"
        fi
    fi
    
    log_success "Template ready: ID $UBUNTU_TEMPLATE_ID on node $UBUNTU_TEMPLATE_NODE"
    
    # Create VMs
    log_consciousness "Phase 1: Creating K3s infrastructure VMs"
    create_vm_on_node "nexus-k3s"
    create_vm_on_node "forge-k3s"
    create_vm_on_node "closet-k3s"
    
    # Deploy K3s cluster
    log_consciousness "Phase 2: Deploying K3s cluster"
    deploy_k3s_master
    sleep 60
    deploy_k3s_workers
    
    # Deploy workloads
    log_consciousness "Phase 3: Deploying consciousness workloads"
    sleep 30
    deploy_consciousness_workloads
    
    # Prepare Zephyr migration
    log_consciousness "Phase 4: Preparing Zephyr gaming migration"
    prepare_zephyr_migration
    
    # Verify deployment
    log_consciousness "Phase 5: Verifying cluster deployment"
    verify_cluster_health
    
    # Create management tools
    create_cluster_manager
    
    # Final status
    log_consciousness "🎯 K3s Consciousness Federation Deployment Complete!"
    echo ""
    echo "Cluster Configuration:"
    echo "  Master: Nexus ($NEXUS_IP) - VM 1001"
    echo "  Worker: Forge ($FORGE_IP) - VM 1002"  
    echo "  Worker: Closet ($CLOSET_IP) - VM 1003"
    echo "  Future: Zephyr ($ZEPHYR_IP) - VM 1004 (prep)"
    echo ""
    echo "Management Commands:"
    echo "  consciousness-cluster status    - Show cluster status"
    echo "  consciousness-cluster deploy    - Deploy workloads"
    echo "  consciousness-cluster join-zephyr - Add Zephyr to cluster"
    echo "  consciousness-cluster logs      - View cluster logs"
    echo ""
    echo "SSH Access:"
    echo "  ssh ubuntu@$NEXUS_IP   # Master node"
    echo "  ssh ubuntu@$FORGE_IP   # Worker node"
    echo "  ssh ubuntu@$CLOSET_IP  # Worker node"
    echo "  ssh ubuntu@$ZEPHYR_IP  # Migration prep"
    echo ""
    echo "Kubectl Access:"
    echo "  ssh ubuntu@$NEXUS_IP -t 'sudo kubectl get nodes'"
    
    # Show initial status
    /usr/local/bin/consciousness-cluster status
}

# Execute main function
main "$@"
