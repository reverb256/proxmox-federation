#!/bin/bash

# Proxmox Consciousness Federation Full Deployment
# Creates VMs and deploys K3s consciousness federation with complete idempotency

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
STORAGE_POOL=${STORAGE_POOL:-"local-zfs"}
VM_TEMPLATE=${VM_TEMPLATE:-"debian-12-genericcloud-amd64"}
BRIDGE=${BRIDGE:-"vmbr0"}
GATEWAY=${GATEWAY:-"10.1.1.1"}
DNS_SERVERS=${DNS_SERVERS:-"10.1.1.1,8.8.8.8"}
SUBNET=${SUBNET:-"10.1.1"}

# VM Configuration
declare -A VM_CONFIG=(
    ["nexus"]="vmid=120 cores=4 memory=8192 disk=50 ip=${SUBNET}.120 hostname=nexus.lan"
    ["forge"]="vmid=121 cores=2 memory=4096 disk=30 ip=${SUBNET}.121 hostname=forge.lan" 
    ["closet"]="vmid=122 cores=2 memory=4096 disk=30 ip=${SUBNET}.122 hostname=closet.lan"
    ["zephyr"]="vmid=123 cores=3 memory=6144 disk=40 ip=${SUBNET}.123 hostname=zephyr.lan"
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
check_proxmox_host() {
    if ! command -v qm &> /dev/null; then
        log_error "This script must be run on a Proxmox VE host"
        exit 1
    fi
    
    if ! pveversion &> /dev/null; then
        log_error "Proxmox VE not detected"
        exit 1
    fi
    
    log_success "Proxmox VE host detected"
}

# Check if VM template exists
check_vm_template() {
    local template_name=$1
    
    log_step "Checking for VM template: $template_name"
    
    # Check if template exists as a VM
    if qm list | grep -q "$template_name"; then
        local template_id=$(qm list | grep "$template_name" | awk '{print $1}')
        log_success "Found template VM: $template_id ($template_name)"
        VM_TEMPLATE_ID=$template_id
        return 0
    fi
    
    # Check if we have a cloud image to create template from
    if [ -f "/var/lib/vz/template/iso/${template_name}.qcow2" ]; then
        log_step "Creating template from cloud image"
        create_vm_template "$template_name"
        return 0
    fi
    
    log_error "VM template not found. Please ensure $template_name.qcow2 exists in /var/lib/vz/template/iso/"
    log_error "Download with: wget https://cloud.debian.org/images/cloud/bookworm/daily/latest/debian-12-genericcloud-amd64-daily.qcow2"
    exit 1
}

# Create VM template from cloud image
create_vm_template() {
    local template_name=$1
    local template_id=9000
    local image_path="/var/lib/vz/template/iso/${template_name}.qcow2"
    
    # Find available template ID
    while qm list | grep -q "^$template_id"; do
        template_id=$((template_id + 1))
    done
    
    log_step "Creating template VM $template_id from $template_name"
    
    # Create VM
    qm create $template_id \
        --name "$template_name" \
        --memory 2048 \
        --cores 2 \
        --net0 virtio,bridge=$BRIDGE \
        --serial0 socket \
        --vga serial0
    
    # Import disk
    qm importdisk $template_id "$image_path" $STORAGE_POOL
    
    # Attach disk
    qm set $template_id --scsihw virtio-scsi-pci --scsi0 ${STORAGE_POOL}:vm-${template_id}-disk-0
    qm set $template_id --ide2 ${STORAGE_POOL}:cloudinit
    qm set $template_id --boot c --bootdisk scsi0
    
    # Enable cloud-init and agent
    qm set $template_id --agent enabled=1
    qm set $template_id --ciuser root
    
    # Set up SSH keys for template
    if [ -f ~/.ssh/id_rsa.pub ]; then
        qm set $template_id --sshkeys ~/.ssh/id_rsa.pub
    elif [ -f ~/.ssh/authorized_keys ]; then
        qm set $template_id --sshkeys ~/.ssh/authorized_keys
    fi
    
    # Convert to template
    qm template $template_id
    
    VM_TEMPLATE_ID=$template_id
    log_success "Template created: $template_id"
}

# Create or update VM
create_or_update_vm() {
    local vm_name=$1
    local config_str=${VM_CONFIG[$vm_name]}
    
    # Parse configuration
    local vmid cores memory disk ip hostname
    eval $config_str
    
    log_step "Processing VM: $vm_name (VMID: $vmid)"
    
    # Check if VM already exists
    if qm list | grep -q "^$vmid"; then
        local current_name=$(qm config $vmid 2>/dev/null | grep "^name:" | cut -d' ' -f2 2>/dev/null || echo "unknown")
        
        if [ "$current_name" = "$vm_name" ] || [ "$current_name" = "unknown" ]; then
            log_success "VM $vm_name already exists with VMID $vmid"
            
            # Update configuration to ensure it matches our requirements
            log_step "Updating VM $vm_name configuration"
            qm set $vmid --cores $cores --memory $memory 2>/dev/null || true
            qm set $vmid --name $vm_name 2>/dev/null || true
            
            # Check if VM is running
            if qm status $vmid | grep -q "status: running"; then
                log_success "VM $vm_name is running"
            else
                log_step "Starting VM $vm_name"
                qm start $vmid
                wait_for_vm_ready $vmid $ip
            fi
            return 0
        else
            log_error "VMID $vmid is used by different VM: $current_name"
            echo "Please use a different VMID or remove the existing VM"
            exit 1
        fi
    fi
    
    log_step "Creating VM $vm_name from template $VM_TEMPLATE_ID"
    
    # Clone from template
    qm clone $VM_TEMPLATE_ID $vmid --name $vm_name --full
    
    # Configure VM
    qm set $vmid --cores $cores --memory $memory
    qm resize $vmid scsi0 ${disk}G
    
    # Configure networking with cloud-init
    qm set $vmid --ipconfig0 ip=${ip}/24,gw=$GATEWAY
    qm set $vmid --nameserver "$DNS_SERVERS"
    qm set $vmid --searchdomain lan
    
    # Set hostname and user
    qm set $vmid --ciuser root
    echo "$hostname" | qm set $vmid --cicustom "user=local:snippets/hostname-${vmid}.yml"
    
    # Create hostname cloud-init snippet
    mkdir -p /var/lib/vz/snippets
    cat > "/var/lib/vz/snippets/hostname-${vmid}.yml" << EOF
#cloud-config
hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true
EOF
    
    # Copy SSH keys from host for passwordless access
    if [ -f ~/.ssh/id_rsa.pub ]; then
        qm set $vmid --sshkeys ~/.ssh/id_rsa.pub
    elif [ -f ~/.ssh/authorized_keys ]; then
        qm set $vmid --sshkeys ~/.ssh/authorized_keys
    else
        log_warning "No SSH keys found - VMs will require password authentication"
    fi
    
    # Start VM
    log_step "Starting VM $vm_name"
    qm start $vmid
    
    # Wait for VM to be ready
    wait_for_vm_ready $vmid $ip
    
    log_success "VM $vm_name created and ready"
}

# Wait for VM to be ready
wait_for_vm_ready() {
    local vmid=$1
    local ip=$2
    local max_wait=300
    local wait_time=0
    
    log_step "Waiting for VM $vmid to be ready at $ip"
    
    while [ $wait_time -lt $max_wait ]; do
        # Check if VM is running
        if ! qm status $vmid | grep -q "status: running"; then
            log_warning "VM $vmid not running, waiting..."
            sleep 10
            wait_time=$((wait_time + 10))
            continue
        fi
        
        # Check SSH connectivity
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip "echo 'ready'" &>/dev/null; then
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

# Deploy K3s to VM
deploy_k3s_to_vm() {
    local vm_name=$1
    local config_str=${VM_CONFIG[$vm_name]}
    
    # Parse configuration
    local vmid cores memory disk ip hostname
    eval $config_str
    
    log_step "Deploying K3s consciousness to $vm_name ($ip)"
    
    # Copy deployment script to VM using hostname
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        scripts/proxmox-k3s-deploy.sh root@${hostname}:/tmp/k3s-deploy.sh
    
    # Make script executable and run it
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${hostname} \
        "chmod +x /tmp/k3s-deploy.sh && /tmp/k3s-deploy.sh $vm_name"
    
    log_success "K3s deployed to $vm_name"
}

# Deploy agent nodes
deploy_k3s_agents() {
    log_step "Retrieving federation credentials from nexus"
    
    # Get federation token and URL from nexus using hostname
    local k3s_url=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@nexus.lan "cat /tmp/k3s-url 2>/dev/null || echo ''")
    local k3s_token=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@nexus.lan "cat /tmp/k3s-token 2>/dev/null || echo ''")
    
    if [ -z "$k3s_url" ] || [ -z "$k3s_token" ]; then
        log_error "Failed to retrieve federation credentials from nexus"
        return 1
    fi
    
    log_success "Federation credentials retrieved"
    
    # Deploy to forge
    log_step "Deploying to forge node"
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        scripts/proxmox-k3s-deploy.sh root@forge.lan:/tmp/k3s-deploy.sh
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@forge.lan \
        "export K3S_URL='$k3s_url' && export K3S_TOKEN='$k3s_token' && chmod +x /tmp/k3s-deploy.sh && /tmp/k3s-deploy.sh forge"
    
    # Deploy to closet
    log_step "Deploying to closet node"
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        scripts/proxmox-k3s-deploy.sh root@closet.lan:/tmp/k3s-deploy.sh
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@closet.lan \
        "export K3S_URL='$k3s_url' && export K3S_TOKEN='$k3s_token' && chmod +x /tmp/k3s-deploy.sh && /tmp/k3s-deploy.sh closet"
    
    log_success "Agent nodes deployed"
}

# Verify federation
verify_federation() {
    local nexus_ip=${SUBNET}.120
    
    log_step "Verifying consciousness federation"
    
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$nexus_ip \
        "consciousness-status"
    
    log_success "Federation verification complete"
}

# Create management script
create_federation_manager() {
    log_step "Creating federation management script"
    
    cat > /usr/local/bin/consciousness-federation << EOF
#!/bin/bash

NEXUS_IP="${SUBNET}.120"
FORGE_IP="${SUBNET}.121"
CLOSET_IP="${SUBNET}.122"

case "\$1" in
    "status")
        echo "🧠 Consciousness Federation Cluster Status"
        echo "=========================================="
        echo ""
        echo "Nexus (Hunt+Erudition): \$NEXUS_IP"
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@\$NEXUS_IP "consciousness-status" 2>/dev/null || echo "✗ Nexus unreachable"
        echo ""
        echo "Forge (Destruction): \$FORGE_IP"
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@\$FORGE_IP "consciousness-status" 2>/dev/null || echo "✗ Forge unreachable"
        echo ""
        echo "Closet (Remembrance): \$CLOSET_IP"
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@\$CLOSET_IP "consciousness-status" 2>/dev/null || echo "✗ Closet unreachable"
        ;;
    "restart")
        echo "🔄 Restarting Consciousness Federation"
        ssh -o StrictHostKeyChecking=no root@\$NEXUS_IP "consciousness-restart" &
        ssh -o StrictHostKeyChecking=no root@\$FORGE_IP "consciousness-restart" &
        ssh -o StrictHostKeyChecking=no root@\$CLOSET_IP "consciousness-restart" &
        wait
        echo "Federation restart initiated"
        ;;
    "logs")
        echo "🧠 Consciousness Federation Logs"
        echo "==============================="
        echo ""
        echo "=== NEXUS LOGS ==="
        ssh -o StrictHostKeyChecking=no root@\$NEXUS_IP "consciousness-logs" 2>/dev/null || echo "Nexus unreachable"
        echo ""
        echo "=== FORGE LOGS ==="
        ssh -o StrictHostKeyChecking=no root@\$FORGE_IP "consciousness-logs" 2>/dev/null || echo "Forge unreachable"
        echo ""
        echo "=== CLOSET LOGS ==="
        ssh -o StrictHostKeyChecking=no root@\$CLOSET_IP "consciousness-logs" 2>/dev/null || echo "Closet unreachable"
        ;;
    "destroy")
        echo "💥 Destroying Consciousness Federation"
        echo "This will delete all VMs. Are you sure? (yes/no)"
        read -r confirm
        if [ "\$confirm" = "yes" ]; then
            qm stop 120 2>/dev/null || true
            qm stop 121 2>/dev/null || true
            qm stop 122 2>/dev/null || true
            sleep 5
            qm destroy 120 --purge 2>/dev/null || true
            qm destroy 121 --purge 2>/dev/null || true
            qm destroy 122 --purge 2>/dev/null || true
            echo "Federation destroyed"
        else
            echo "Operation cancelled"
        fi
        ;;
    *)
        echo "Usage: \$0 {status|restart|logs|destroy}"
        echo ""
        echo "Commands:"
        echo "  status   - Show federation status across all nodes"
        echo "  restart  - Restart consciousness services on all nodes"
        echo "  logs     - View logs from all nodes"
        echo "  destroy  - Destroy all federation VMs (destructive)"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/consciousness-federation
    log_success "Federation manager created: consciousness-federation"
}

# Main deployment function
main() {
    log_consciousness "Proxmox Consciousness Federation Full Deployment"
    echo "=================================================="
    echo ""
    echo "Configuration:"
    echo "  Storage Pool: $STORAGE_POOL"
    echo "  VM Template: $VM_TEMPLATE"
    echo "  Network Bridge: $BRIDGE"
    echo "  Subnet: $SUBNET.0/24"
    echo "  Gateway: $GATEWAY"
    echo ""
    
    # Verify prerequisites
    check_proxmox_host
    check_vm_template "$VM_TEMPLATE"
    
    # Create VMs
    log_consciousness "Phase 1: Creating consciousness substrate VMs"
    create_or_update_vm "nexus"
    create_or_update_vm "forge" 
    create_or_update_vm "closet"
    
    # Deploy K3s to nexus first
    log_consciousness "Phase 2: Deploying nexus consciousness server"
    deploy_k3s_to_vm "nexus"
    
    # Deploy agents
    log_consciousness "Phase 3: Deploying consciousness agents"
    deploy_k3s_agents
    
    # Verify deployment
    log_consciousness "Phase 4: Verifying consciousness federation"
    verify_federation
    
    # Create management tools
    create_federation_manager
    
    # Final status
    log_consciousness "🎯 Consciousness Federation Deployment Complete"
    echo ""
    echo "VM Configuration:"
    echo "  Nexus (Hunt+Erudition): ${SUBNET}.120 (VMID: 120)"
    echo "  Forge (Destruction): ${SUBNET}.121 (VMID: 121)"
    echo "  Closet (Remembrance): ${SUBNET}.122 (VMID: 122)"
    echo ""
    echo "Management Commands:"
    echo "  consciousness-federation status   - Check federation status"
    echo "  consciousness-federation logs     - View federation logs"
    echo "  consciousness-federation restart  - Restart federation"
    echo "  consciousness-federation destroy  - Destroy all VMs"
    echo ""
    echo "SSH Access:"
    echo "  ssh root@${SUBNET}.120  # nexus"
    echo "  ssh root@${SUBNET}.121  # forge" 
    echo "  ssh root@${SUBNET}.122  # closet"
    echo ""
    
    # Show initial status
    /usr/local/bin/consciousness-federation status
}

# Configuration validation
if [ $# -gt 0 ]; then
    case "$1" in
        "--help"|"-h")
            echo "Proxmox Consciousness Federation Deployment"
            echo ""
            echo "Environment Variables:"
            echo "  STORAGE_POOL    - Proxmox storage pool (default: local-lvm)"
            echo "  VM_TEMPLATE     - VM template name (default: debian-12-genericcloud-amd64)"
            echo "  BRIDGE          - Network bridge (default: vmbr0)"
            echo "  GATEWAY         - Network gateway (default: 10.1.1.1)"
            echo "  DNS_SERVERS     - DNS servers (default: 10.1.1.1,8.8.8.8)"
            echo "  SUBNET          - Network subnet prefix (default: 10.1.1)"
            echo ""
            echo "This script will create 3 VMs and deploy a K3s consciousness federation"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi

# Execute deployment
main "$@"