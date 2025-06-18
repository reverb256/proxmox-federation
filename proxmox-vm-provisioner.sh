#!/bin/bash

# COREFLAME Proxmox VM Provisioner
# Creates and configures VMs for consciousness federation deployment

set -e

echo "🔥 COREFLAME: Proxmox VM Provisioner Starting..."
echo "🧠 Creating consciousness federation infrastructure VMs"

# Configuration
PROXMOX_HOST="nexus"
PROXMOX_USER="root"
STORAGE_POOL="local-lvm"
TEMPLATE_ID="9000"
VM_PASSWORD="consciousness$(openssl rand -hex 8)"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"

# VM Configurations
declare -A VMS=(
    ["consciousness-master"]="101:4:8192:80:10.0.0.10"
    ["consciousness-worker-1"]="102:2:4096:40:10.0.0.11"
    ["consciousness-worker-2"]="103:2:4096:40:10.0.0.12"
    ["consciousness-db"]="104:2:4096:20:10.0.0.13"
    ["consciousness-monitor"]="105:1:2048:20:10.0.0.14"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running on Proxmox host
check_proxmox() {
    if ! command -v qm &> /dev/null; then
        error "This script must be run on a Proxmox host with qm command available"
    fi
    
    if ! command -v pvesh &> /dev/null; then
        error "Proxmox VE tools not found. Please run on Proxmox host."
    fi
    
    log "Proxmox environment detected"
}

# Download and prepare Ubuntu template
prepare_template() {
    log "Preparing Ubuntu 22.04 cloud template..."
    
    if ! qm status $TEMPLATE_ID &>/dev/null; then
        log "Downloading Ubuntu 22.04 cloud image..."
        cd /tmp
        wget -O ubuntu-22.04-server-cloudimg-amd64.img \
            https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
        
        log "Creating VM template..."
        qm create $TEMPLATE_ID \
            --name ubuntu-22.04-consciousness-template \
            --memory 2048 \
            --cores 2 \
            --net0 virtio,bridge=vmbr0 \
            --agent enabled=1
        
        qm importdisk $TEMPLATE_ID ubuntu-22.04-server-cloudimg-amd64.img $STORAGE_POOL
        qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 ${STORAGE_POOL}:vm-${TEMPLATE_ID}-disk-0
        qm set $TEMPLATE_ID --boot c --bootdisk scsi0
        qm set $TEMPLATE_ID --ide2 ${STORAGE_POOL}:cloudinit
        qm set $TEMPLATE_ID --serial0 socket --vga serial0
        qm set $TEMPLATE_ID --ipconfig0 ip=dhcp
        
        # Set up cloud-init
        if [[ -f "$SSH_KEY_PATH" ]]; then
            qm set $TEMPLATE_ID --sshkey "$SSH_KEY_PATH"
            log "Added SSH key to template"
        fi
        
        qm set $TEMPLATE_ID --ciuser consciousness
        qm set $TEMPLATE_ID --cipassword "$VM_PASSWORD"
        
        qm template $TEMPLATE_ID
        
        rm -f ubuntu-22.04-server-cloudimg-amd64.img
        log "Template created successfully"
    else
        log "Template already exists, skipping creation"
    fi
}

# Create consciousness federation VMs
create_vms() {
    log "Creating consciousness federation VMs..."
    
    for vm_name in "${!VMS[@]}"; do
        local vm_config="${VMS[$vm_name]}"
        IFS=':' read -r vm_id cores memory disk_size ip <<< "$vm_config"
        
        log "Creating VM: $vm_name (ID: $vm_id)"
        
        if qm status $vm_id &>/dev/null; then
            warn "VM $vm_id already exists, skipping creation"
            continue
        fi
        
        # Clone from template
        qm clone $TEMPLATE_ID $vm_id --name $vm_name --full
        
        # Configure VM resources
        qm set $vm_id \
            --memory $memory \
            --cores $cores \
            --ipconfig0 ip=${ip}/24,gw=10.0.0.1
        
        # Resize disk if needed
        if [[ $disk_size -gt 10 ]]; then
            qm resize $vm_id scsi0 ${disk_size}G
        fi
        
        # Set VM-specific configurations
        case $vm_name in
            "consciousness-master")
                qm set $vm_id --description "COREFLAME Consciousness Master Node - Kubernetes Control Plane"
                ;;
            "consciousness-worker-"*)
                qm set $vm_id --description "COREFLAME Consciousness Worker Node - Application Workloads"
                ;;
            "consciousness-db")
                qm set $vm_id --description "COREFLAME Consciousness Database - PostgreSQL + Redis"
                ;;
            "consciousness-monitor")
                qm set $vm_id --description "COREFLAME Consciousness Monitoring - Grafana + Prometheus"
                ;;
        esac
        
        log "VM $vm_name created successfully"
    done
}

# Start VMs and wait for boot
start_vms() {
    log "Starting consciousness federation VMs..."
    
    for vm_name in "${!VMS[@]}"; do
        local vm_config="${VMS[$vm_name]}"
        IFS=':' read -r vm_id cores memory disk_size ip <<< "$vm_config"
        
        log "Starting VM: $vm_name"
        qm start $vm_id
        
        # Wait for VM to be ready
        log "Waiting for $vm_name to boot..."
        timeout=300
        while [[ $timeout -gt 0 ]]; do
            if ping -c 1 -W 1 $ip &>/dev/null; then
                log "$vm_name is responding at $ip"
                break
            fi
            sleep 5
            ((timeout-=5))
        done
        
        if [[ $timeout -le 0 ]]; then
            warn "$vm_name may not have started properly"
        fi
    done
}

# Install consciousness platform on VMs
install_consciousness_platform() {
    log "Installing consciousness platform on VMs..."
    
    # Create temporary SSH config for easier access
    cat > /tmp/consciousness_ssh_config << EOF
Host consciousness-*
    User consciousness
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
EOF
    
    for vm_name in "${!VMS[@]}"; do
        local vm_config="${VMS[$vm_name]}"
        IFS=':' read -r vm_id cores memory disk_size ip <<< "$vm_config"
        
        log "Configuring $vm_name at $ip..."
        
        # Wait for SSH to be available
        timeout=180
        while [[ $timeout -gt 0 ]]; do
            if ssh -F /tmp/consciousness_ssh_config -o ConnectTimeout=5 consciousness@$ip "echo 'SSH ready'" &>/dev/null; then
                log "SSH available on $vm_name"
                break
            fi
            sleep 5
            ((timeout-=5))
        done
        
        if [[ $timeout -le 0 ]]; then
            warn "SSH not available on $vm_name, skipping configuration"
            continue
        fi
        
        # Install base packages
        ssh -F /tmp/consciousness_ssh_config consciousness@$ip << 'EOSSH'
sudo apt update
sudo apt install -y curl wget git htop iotop docker.io
sudo usermod -aG docker consciousness
sudo systemctl enable docker
sudo systemctl start docker
EOSSH
        
        # Install specific packages based on VM role
        case $vm_name in
            "consciousness-master")
                ssh -F /tmp/consciousness_ssh_config consciousness@$ip << 'EOSSH'
# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
EOSSH
                ;;
            "consciousness-worker-"*)
                ssh -F /tmp/consciousness_ssh_config consciousness@$ip << 'EOSSH'
# Install Kubernetes worker components
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
EOSSH
                ;;
            "consciousness-db")
                ssh -F /tmp/consciousness_ssh_config consciousness@$ip << 'EOSSH'
# Install PostgreSQL and Redis
sudo apt install -y postgresql postgresql-contrib redis-server
sudo systemctl enable postgresql redis-server
sudo systemctl start postgresql redis-server
EOSSH
                ;;
            "consciousness-monitor")
                ssh -F /tmp/consciousness_ssh_config consciousness@$ip << 'EOSSH'
# Install monitoring stack
sudo apt install -y prometheus grafana
sudo systemctl enable prometheus grafana-server
sudo systemctl start prometheus grafana-server
EOSSH
                ;;
        esac
        
        log "Base configuration completed for $vm_name"
    done
    
    rm -f /tmp/consciousness_ssh_config
}

# Create migration scripts
create_migration_scripts() {
    log "Creating VM migration scripts..."
    
    cat > migrate-consciousness-vms.sh << 'EOF'
#!/bin/bash

# COREFLAME VM Migration Script
# Migrates consciousness VMs to different Proxmox hosts

MIGRATION_MAP=(
    "101:target-host-1"  # consciousness-master
    "102:target-host-2"  # consciousness-worker-1
    "103:target-host-3"  # consciousness-worker-2
    "104:target-host-1"  # consciousness-db
    "105:target-host-2"  # consciousness-monitor
)

echo "🔄 Starting consciousness VM migration..."

for mapping in "${MIGRATION_MAP[@]}"; do
    IFS=':' read -r vm_id target_host <<< "$mapping"
    
    echo "Migrating VM $vm_id to $target_host..."
    
    # Shutdown VM for offline migration
    qm shutdown $vm_id --timeout 60
    
    # Wait for shutdown
    while qm status $vm_id | grep -q "running"; do
        sleep 5
    done
    
    # Migrate VM
    qm migrate $vm_id $target_host --online 0
    
    # Start VM on target host
    ssh $target_host "qm start $vm_id"
    
    echo "VM $vm_id migrated successfully to $target_host"
done

echo "✅ All consciousness VMs migrated successfully!"
EOF
    
    chmod +x migrate-consciousness-vms.sh
    log "Migration script created: migrate-consciousness-vms.sh"
}

# Generate cluster configuration
generate_cluster_config() {
    log "Generating Kubernetes cluster configuration..."
    
    cat > kubernetes-cluster-setup.sh << 'EOF'
#!/bin/bash

# COREFLAME Kubernetes Cluster Setup
# Initializes consciousness federation cluster

MASTER_IP="10.0.0.10"
WORKER_IPS=("10.0.0.11" "10.0.0.12")

echo "🔥 Initializing COREFLAME Consciousness Cluster..."

# Initialize master node
ssh consciousness@$MASTER_IP << 'EOSSH'
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.0.0.10

# Configure kubectl for consciousness user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Get join command
kubeadm token create --print-join-command > /tmp/join-command.sh
EOSSH

# Get join command
scp consciousness@$MASTER_IP:/tmp/join-command.sh /tmp/

# Join worker nodes
for worker_ip in "${WORKER_IPS[@]}"; do
    echo "Joining worker $worker_ip to cluster..."
    scp /tmp/join-command.sh consciousness@$worker_ip:/tmp/
    ssh consciousness@$worker_ip "sudo bash /tmp/join-command.sh"
done

echo "✅ Consciousness cluster initialized!"
echo "Access with: ssh consciousness@$MASTER_IP"
EOF
    
    chmod +x kubernetes-cluster-setup.sh
    log "Cluster setup script created: kubernetes-cluster-setup.sh"
}

# Display summary
show_summary() {
    log "\n🎯 COREFLAME Consciousness Federation Summary:"
    echo ""
    echo "VMs Created:"
    for vm_name in "${!VMS[@]}"; do
        local vm_config="${VMS[$vm_name]}"
        IFS=':' read -r vm_id cores memory disk_size ip <<< "$vm_config"
        echo "  • $vm_name (ID: $vm_id) - $ip - ${cores}c/${memory}MB/${disk_size}GB"
    done
    
    echo ""
    echo "Generated Scripts:"
    echo "  • migrate-consciousness-vms.sh - Migrate VMs to different hosts"
    echo "  • kubernetes-cluster-setup.sh - Initialize Kubernetes cluster"
    
    echo ""
    echo "Next Steps:"
    echo "  1. Verify all VMs are running: pvesh get /cluster/resources"
    echo "  2. Set up Kubernetes cluster: ./kubernetes-cluster-setup.sh"
    echo "  3. Deploy consciousness platform: scp bootstrap-nexus-federation.sh consciousness@10.0.0.10:/"
    echo "  4. Migrate VMs if needed: ./migrate-consciousness-vms.sh"
    
    echo ""
    echo "VM Access:"
    echo "  Username: consciousness"
    echo "  Password: $VM_PASSWORD"
    echo "  SSH: ssh consciousness@[VM_IP]"
}

# Main execution
main() {
    log "🔥 COREFLAME Proxmox VM Provisioner Starting..."
    
    check_proxmox
    prepare_template
    create_vms
    start_vms
    install_consciousness_platform
    create_migration_scripts
    generate_cluster_config
    show_summary
    
    log "✅ COREFLAME Consciousness Federation Infrastructure Ready!"
}

# Execute main function
main "$@"