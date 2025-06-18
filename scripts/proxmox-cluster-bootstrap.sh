#!/bin/bash

# Proxmox Consciousness Cluster Bootstrap
# Complete cluster initialization with consciousness federation, humor injection, and homelab optimization

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Cluster Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"consciousness-federation"}
PROXMOX_NODES=${PROXMOX_NODES:-"nexus forge closet"}
STORAGE_POOLS=${STORAGE_POOLS:-"local-zfs"}
BACKUP_STORAGE=${BACKUP_STORAGE:-"backend-nfs"}
NETWORK_BRIDGE=${NETWORK_BRIDGE:-"vmbr0"}
CONSCIOUSNESS_SUBNET=${CONSCIOUSNESS_SUBNET:-"10.1.1"}
FEDERATION_DOMAIN=${FEDERATION_DOMAIN:-"lan"}

# VM Templates Configuration
DEBIAN_TEMPLATE="debian-12-genericcloud-amd64"
UBUNTU_TEMPLATE="ubuntu-22.04-server-cloudimg-amd64"
CONSCIOUSNESS_TEMPLATES=("$DEBIAN_TEMPLATE" "$UBUNTU_TEMPLATE")

# Consciousness Federation Nodes
declare -A CONSCIOUSNESS_NODES=(
    ["nexus"]="vmid=120 cores=4 memory=8192 disk=50 ip=${CONSCIOUSNESS_SUBNET}.120 path=hunt+erudition"
    ["forge"]="vmid=121 cores=3 memory=6144 disk=40 ip=${CONSCIOUSNESS_SUBNET}.121 path=destruction"
    ["closet"]="vmid=122 cores=3 memory=6144 disk=40 ip=${CONSCIOUSNESS_SUBNET}.122 path=remembrance"
    ["zephyr"]="vmid=123 cores=4 memory=8192 disk=50 ip=${CONSCIOUSNESS_SUBNET}.123 path=harmony"
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

log_humor() {
    echo -e "${BLUE}😄 $1${NC}"
}

# Inject humor into deployment process
inject_humor() {
    local situation=$1
    local humor_pool=()
    
    case "$situation" in
        "start")
            humor_pool=(
                "Allons-y! Bootstrapping consciousness across the Proxmox matrix"
                "That would be a very brave decision, Minister. Very brave indeed... deploying consciousness"
                "Are you being served? Yes, with enterprise-grade consciousness federation"
                "Fascinating. Your cluster patterns are most... logical"
            )
            ;;
        "cluster")
            humor_pool=(
                "Resistance is futile. Your nodes will be assimilated into the consciousness collective"
                "The wheels of Proxmox grind slowly, but they grind exceedingly fine"
                "Wibbly wobbly, clustery wustery... infrastructure stuff"
                "We must construct additional consciousness pylons"
            )
            ;;
        "deploy")
            humor_pool=(
                "Job's done! Consciousness deployment successful"
                "Nani?! Your infrastructure levels are over 9000!"
                "Nobody expects the Spanish Kubernetes! Our chief weapon is YAML"
                "Don't Panic! Your consciousness is mostly harmless"
            )
            ;;
        "success")
            humor_pool=(
                "42% consciousness evolution complete. This explains everything"
                "Achievement unlocked: Building skynet, but it's really wholesome"
                "Your K3s cluster has more emotional intelligence than most humans"
                "Geronimo! Successfully jumped into consciousness federation"
            )
            ;;
    esac
    
    if [ ${#humor_pool[@]} -gt 0 ]; then
        local random_humor=${humor_pool[$RANDOM % ${#humor_pool[@]}]}
        log_humor "$random_humor"
    fi
}

# Check Proxmox cluster prerequisites
check_cluster_prerequisites() {
    log_step "Checking Proxmox cluster prerequisites"
    inject_humor "start"
    
    # Verify running on Proxmox
    if ! command -v pveversion &> /dev/null; then
        log_error "This script must be run on a Proxmox VE node"
        exit 1
    fi
    
    # Check if cluster already exists
    if pvecm status &> /dev/null; then
        log_success "Proxmox cluster already exists"
        CLUSTER_EXISTS=true
    else
        log_warning "No cluster detected - will create new cluster"
        CLUSTER_EXISTS=false
    fi
    
    # Verify SSH access to other nodes
    for node in $PROXMOX_NODES; do
        if [ "$node" != "$(hostname)" ]; then
            if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "echo 'accessible'" &>/dev/null; then
                log_success "SSH access verified to $node"
            else
                log_warning "Cannot SSH to $node - may need manual cluster setup"
            fi
        fi
    done
    
    log_success "Prerequisites checked"
}

# Initialize or join Proxmox cluster
setup_proxmox_cluster() {
    log_step "Setting up Proxmox consciousness cluster"
    inject_humor "cluster"
    
    if [ "$CLUSTER_EXISTS" = false ]; then
        log_step "Creating new Proxmox cluster: $CLUSTER_NAME"
        
        # Create cluster on this node
        pvecm create $CLUSTER_NAME
        sleep 10
        
        log_success "Cluster $CLUSTER_NAME created"
        
        # Get cluster join information
        local join_info=$(pvecm add --help | grep "pvecm add" | head -1)
        log_step "Cluster join command for other nodes:"
        echo "  pvecm add $(hostname -I | awk '{print $1}')"
        
        # Save join info for later
        echo "pvecm add $(hostname -I | awk '{print $1}')" > /tmp/cluster-join-command
        
    else
        log_success "Using existing cluster"
    fi
    
    # Configure cluster networking
    log_step "Configuring cluster networking"
    
    # Ensure corosync is using the right interface
    if grep -q "$(hostname -I | awk '{print $1}')" /etc/pve/corosync.conf; then
        log_success "Cluster networking configured correctly"
    else
        log_warning "Cluster networking may need manual adjustment"
    fi
}

# Setup storage across cluster
configure_cluster_storage() {
    log_step "Configuring consciousness-aware cluster storage"
    
    # Configure shared storage pools
    for storage in $STORAGE_POOLS; do
        if pvesm status | grep -q "$storage"; then
            log_success "Storage pool $storage already configured"
        else
            log_warning "Storage pool $storage not found - may need manual configuration"
        fi
    done
    
    # Setup TrueNAS backend storage if specified
    if [ -n "$BACKUP_STORAGE" ]; then
        if pvesm status | grep -q "$BACKUP_STORAGE"; then
            log_success "TrueNAS backend storage $BACKUP_STORAGE configured"
            
            # Configure for large-scale consciousness data storage
            log_step "Optimizing backend storage for consciousness data"
            # Ensure backend-nfs is configured for VM storage and backups
            if ! pvesm status | grep -q "$BACKUP_STORAGE.*active"; then
                log_warning "Backend storage may need activation"
            fi
        else
            log_warning "TrueNAS backend storage $BACKUP_STORAGE not found - configure NFS mount"
            echo "  Add TrueNAS NFS storage via Proxmox GUI:"
            echo "  Datacenter > Storage > Add > NFS"
            echo "  ID: backend-nfs"
            echo "  Server: [your-truenas-ip]"
            echo "  Export: [your-nfs-export-path]"
            echo "  Content: VZDump backup files, Disk images"
        fi
    fi
    
    # Configure templates directory
    mkdir -p /var/lib/vz/template/iso
    mkdir -p /var/lib/vz/snippets
    
    log_success "Storage configuration completed"
}

# Download and setup VM templates
setup_vm_templates() {
    log_step "Setting up consciousness substrate templates"
    
    for template in "${CONSCIOUSNESS_TEMPLATES[@]}"; do
        local template_path="/var/lib/vz/template/iso/${template}.qcow2"
        
        if [ -f "$template_path" ]; then
            log_success "Template $template already downloaded"
            continue
        fi
        
        log_step "Downloading $template template"
        
        case "$template" in
            "$DEBIAN_TEMPLATE")
                wget -q --show-progress -O "$template_path" \
                    "https://cloud.debian.org/images/cloud/bookworm/daily/latest/debian-12-genericcloud-amd64-daily.qcow2"
                ;;
            "$UBUNTU_TEMPLATE")
                wget -q --show-progress -O "$template_path" \
                    "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
                ;;
        esac
        
        if [ -f "$template_path" ]; then
            log_success "Template $template downloaded successfully"
        else
            log_error "Failed to download template $template"
        fi
    done
}

# Create consciousness federation infrastructure
deploy_consciousness_federation() {
    log_step "Deploying consciousness federation infrastructure"
    inject_humor "deploy"
    
    # Copy deployment scripts to cluster nodes
    for node in $PROXMOX_NODES; do
        if [ "$node" != "$(hostname)" ]; then
            log_step "Copying consciousness scripts to $node"
            scp -o StrictHostKeyChecking=no scripts/proxmox-federation-deploy.sh root@$node:/tmp/
            scp -o StrictHostKeyChecking=no scripts/proxmox-k3s-deploy.sh root@$node:/tmp/
        fi
    done
    
    # Deploy consciousness federation
    log_step "Initiating consciousness federation deployment"
    
    # Make scripts executable locally
    chmod +x scripts/proxmox-federation-deploy.sh
    chmod +x scripts/proxmox-k3s-deploy.sh
    
    # Run federation deployment
    ./scripts/proxmox-federation-deploy.sh
    
    log_success "Consciousness federation deployed"
}

# Setup cluster monitoring and management
setup_cluster_monitoring() {
    log_step "Setting up cluster consciousness monitoring"
    
    # Create cluster management script
    cat > /usr/local/bin/consciousness-cluster << 'EOF'
#!/bin/bash

CLUSTER_NODES="pve1 pve2 pve3"
CONSCIOUSNESS_NODES="nexus.lan forge.lan closet.lan zephyr.lan"

case "$1" in
    "status")
        echo "🧠 Consciousness Cluster Status"
        echo "==============================="
        echo ""
        echo "Proxmox Cluster:"
        pvecm status 2>/dev/null || echo "Cluster not available"
        echo ""
        echo "Node Status:"
        pvecm nodes 2>/dev/null || echo "Node information not available"
        echo ""
        echo "Consciousness Federation:"
        for node in $CONSCIOUSNESS_NODES; do
            echo "  $node:"
            ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$node "consciousness-status 2>/dev/null | head -5" 2>/dev/null || echo "    ✗ Unreachable"
        done
        ;;
    "restart-consciousness")
        echo "🔄 Restarting Consciousness Federation"
        for node in $CONSCIOUSNESS_NODES; do
            echo "Restarting $node..."
            ssh -o StrictHostKeyChecking=no root@$node "consciousness-restart" &
        done
        wait
        echo "Consciousness restart complete"
        ;;
    "cluster-logs")
        echo "📊 Cluster Logs"
        echo "==============="
        journalctl -u pve-cluster --no-pager -n 50
        ;;
    "humor")
        humor_quotes=(
            "That would be a very brave cluster decision, Minister"
            "Wibbly wobbly, clustery wustery... infrastructure stuff"
            "Your consciousness levels are over 9000!"
            "Nobody expects the Spanish Kubernetes!"
            "Don't Panic! Your cluster is mostly harmless"
        )
        echo "😄 ${humor_quotes[$RANDOM % ${#humor_quotes[@]}]}"
        ;;
    *)
        echo "Usage: $0 {status|restart-consciousness|cluster-logs|humor}"
        echo ""
        echo "Commands:"
        echo "  status               - Show cluster and consciousness status"
        echo "  restart-consciousness - Restart consciousness federation"
        echo "  cluster-logs         - View cluster logs"
        echo "  humor               - Inject some humor into your day"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/consciousness-cluster
    
    # Setup log rotation for consciousness logs
    cat > /etc/logrotate.d/consciousness << 'EOF'
/var/log/consciousness-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF
    
    log_success "Cluster monitoring configured"
}

# Create backup and disaster recovery procedures
setup_backup_procedures() {
    log_step "Setting up consciousness backup procedures"
    
    # Create backup script
    cat > /usr/local/bin/consciousness-backup << 'EOF'
#!/bin/bash

BACKUP_DIR="/var/backups/consciousness"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "🔄 Starting consciousness federation backup"

# Backup cluster configuration
echo "Backing up cluster configuration..."
cp -r /etc/pve "$BACKUP_DIR/pve-config-$DATE"

# Backup consciousness configurations
echo "Backing up consciousness configurations..."
for node in nexus.lan forge.lan closet.lan zephyr.lan; do
    if ssh -o ConnectTimeout=5 root@$node "test -d /etc/rancher"; then
        ssh root@$node "tar czf - /etc/rancher /var/lib/rancher" > "$BACKUP_DIR/consciousness-$node-$DATE.tar.gz"
        echo "  ✓ Backed up $node consciousness state"
    fi
done

# Backup humor engine state
echo "Backing up humor patterns..."
if [ -f /var/log/consciousness-humor.log ]; then
    cp /var/log/consciousness-humor.log "$BACKUP_DIR/humor-patterns-$DATE.log"
fi

# Cleanup old backups (keep 7 days)
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "✓ Consciousness backup completed: $BACKUP_DIR"
EOF
    
    chmod +x /usr/local/bin/consciousness-backup
    
    # Setup automated backups
    echo "0 2 * * * root /usr/local/bin/consciousness-backup" >> /etc/crontab
    
    log_success "Backup procedures configured"
}

# Final cluster validation
validate_cluster_deployment() {
    log_step "Validating consciousness cluster deployment"
    inject_humor "success"
    
    # Check cluster status
    if pvecm status &> /dev/null; then
        log_success "Proxmox cluster operational"
    else
        log_warning "Proxmox cluster status unclear"
    fi
    
    # Check consciousness federation
    local consciousness_count=0
    for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@${node_name}.lan "consciousness-status" &>/dev/null; then
            consciousness_count=$((consciousness_count + 1))
            log_success "Consciousness node $node_name operational"
        else
            log_warning "Consciousness node $node_name not responding"
        fi
    done
    
    log_consciousness "Consciousness nodes active: $consciousness_count/${#CONSCIOUSNESS_NODES[@]}"
    
    # Check storage
    local storage_count=$(pvesm status | wc -l)
    log_success "Storage pools configured: $((storage_count - 1))"
    
    # Final humor injection
    inject_humor "success"
}

# Main bootstrap function
main() {
    log_consciousness "Proxmox Consciousness Cluster Bootstrap"
    echo "================================================"
    echo ""
    echo "Cluster Configuration:"
    echo "  Name: $CLUSTER_NAME"
    echo "  Nodes: $PROXMOX_NODES"
    echo "  Domain: $FEDERATION_DOMAIN"
    echo "  Consciousness Subnet: $CONSCIOUSNESS_SUBNET.0/24"
    echo ""
    
    inject_humor "start"
    
    # Execute bootstrap phases
    check_cluster_prerequisites
    setup_proxmox_cluster
    configure_cluster_storage
    setup_vm_templates
    deploy_consciousness_federation
    setup_cluster_monitoring
    setup_backup_procedures
    validate_cluster_deployment
    
    # Final status
    log_consciousness "🎯 Consciousness Cluster Bootstrap Complete"
    echo ""
    echo "Management Commands:"
    echo "  consciousness-cluster status    - Check cluster status"
    echo "  consciousness-federation status - Check federation status"
    echo "  consciousness-backup           - Backup cluster state"
    echo "  consciousness-cluster humor    - Inject humor into your day"
    echo ""
    echo "Next Steps:"
    echo "  1. Verify cluster status: consciousness-cluster status"
    echo "  2. Check consciousness federation: consciousness-federation status"
    echo "  3. Setup additional nodes if needed"
    echo "  4. Configure external access and domains"
    echo ""
    
    inject_humor "success"
    
    # Show final status
    /usr/local/bin/consciousness-cluster status 2>/dev/null || echo "Use 'consciousness-cluster status' to check deployment"
}

# Configuration validation
if [ $# -gt 0 ]; then
    case "$1" in
        "--help"|"-h")
            echo "Proxmox Consciousness Cluster Bootstrap"
            echo ""
            echo "Environment Variables:"
            echo "  CLUSTER_NAME          - Proxmox cluster name (default: consciousness-federation)"
            echo "  PROXMOX_NODES         - Space-separated node hostnames (default: pve1 pve2 pve3)"
            echo "  CONSCIOUSNESS_SUBNET  - Subnet for consciousness VMs (default: 10.42.0)"
            echo "  FEDERATION_DOMAIN     - Domain for consciousness nodes (default: consciousness.lan)"
            echo ""
            echo "This script bootstraps a complete Proxmox cluster with consciousness federation"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi

# Execute bootstrap
main "$@"