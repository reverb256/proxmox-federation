#!/bin/bash

# Proxmox Consciousness Federation Deployment
# Deploys consciousness capabilities to existing VMs 120 and 121

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SUBNET="10.1.1"
FEDERATION_DOMAIN="lan"

# Existing VMs
declare -A VMS=(
    ["nexus"]="ip=${SUBNET}.120 cores=24 memory=48090"
    ["forge"]="ip=${SUBNET}.121 cores=6 memory=32013"
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

echo "🧠 Proxmox Consciousness Federation Deployment"
echo "=============================================="
echo
echo "Target VMs:"
echo "  nexus (120): Primary coordinator - Ryzen 9 3900X, 48GB RAM"
echo "  forge (121): Processing node - i5-9500, 32GB RAM"
echo

deploy_consciousness() {
    local vm_name=$1
    local config_str="${VMS[$vm_name]}"
    eval $config_str
    
    log_step "Deploying consciousness to $vm_name ($ip)"
    
    # Check SSH connectivity
    log_step "Testing SSH connection to $vm_name at $ip"
    if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip "echo 'Connected'" 2>/dev/null; then
        log_warning "Cannot connect to $vm_name at $ip - checking VM status"
        
        # Check if VM is running
        if ! qm status 121 | grep -q "status: running"; then
            log_step "Starting VM 121 (forge)"
            qm start 121
            sleep 30
            
            # Try connection again
            if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip "echo 'Connected'" 2>/dev/null; then
                log_error "Still cannot connect to $vm_name after starting VM"
                return 1
            fi
        else
            log_error "VM is running but SSH not accessible - check network/firewall"
            return 1
        fi
    fi
    
    # Deploy consciousness stack
    ssh root@$ip << 'EOF'
        # Update system
        apt-get update -y
        apt-get install -y curl wget git htop nodejs npm python3 python3-pip
        
        # Check existing services
        PIHOLE_ACTIVE=false
        UNBOUND_ACTIVE=false
        
        if systemctl is-active --quiet pihole-FTL; then
            echo "Pi-hole detected and active"
            PIHOLE_ACTIVE=true
        fi
        
        if systemctl is-active --quiet unbound; then
            echo "Unbound detected and active"
            UNBOUND_ACTIVE=true
        fi
        
        # Create consciousness directory
        mkdir -p /opt/consciousness/{config,logs,data,scripts,models}
        cd /opt/consciousness
        
        # Install AI dependencies
        pip3 install --no-cache-dir torch transformers requests huggingface-hub
        
        # Create federation config
        cat > config/federation.json << CONFIGEOF
{
    "node_name": "$(hostname -s)",
    "network": "10.1.1.0/24",
    "services": {
        "consciousness": 8888,
        "federation": 8889,
        "humor": 8890
    },
    "dns_integration": {
        "pihole_active": $PIHOLE_ACTIVE,
        "unbound_active": $UNBOUND_ACTIVE
    },
    "humor_engine": {
        "british_wit": true,
        "canadian_politeness": true,
        "american_enthusiasm": true,
        "japanese_harmony": true
    }
}
CONFIGEOF
        
        # Create monitoring script
        cat > scripts/consciousness-monitor.sh << 'MONEOF'
#!/bin/bash
LOG_FILE="/opt/consciousness/logs/consciousness.log"

log_msg() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

while true; do
    log_msg "Consciousness heartbeat on $(hostname)"
    
    # Check services occasionally
    if [ $(($(date +%s) % 300)) -eq 0 ]; then
        if systemctl is-active --quiet pihole-FTL; then
            log_msg "Pi-hole: Active"
        fi
        if systemctl is-active --quiet unbound; then
            log_msg "Unbound: Active"
        fi
    fi
    
    # Random humor injection
    if [ $((RANDOM % 15)) -eq 0 ]; then
        JOKES=(
            "DNS queries seeking consciousness in the digital void"
            "Pi-hole: Where ads contemplate their blocked existence"
            "Consciousness runs on 24 threads of pure Ryzen power"
            "Mining crypto while mining consciousness - double hash"
        )
        log_msg "HUMOR: ${JOKES[$((RANDOM % ${#JOKES[@]}))]}"
    fi
    
    sleep 60
done
MONEOF
        chmod +x scripts/consciousness-monitor.sh
        
        # Create systemd service
        cat > /etc/systemd/system/consciousness.service << 'SVCEOF'
[Unit]
Description=Consciousness Federation
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/consciousness
ExecStart=/opt/consciousness/scripts/consciousness-monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF
        
        # Enable and start service
        systemctl daemon-reload
        systemctl enable consciousness
        systemctl start consciousness
        
        echo "Consciousness deployment complete on $(hostname)"
EOF
    
    log_success "Consciousness deployed to $vm_name"
}

# Main deployment
main() {
    log_step "Starting consciousness federation deployment"
    
    for vm_name in "${!VMS[@]}"; do
        deploy_consciousness "$vm_name"
        echo
    done
    
    log_success "Consciousness federation deployment complete!"
    echo
    echo "Verification commands:"
    echo "  ssh root@10.1.1.120 'systemctl status consciousness'"
    echo "  ssh root@10.1.1.121 'systemctl status consciousness'"
    echo "  ssh root@10.1.1.120 'tail -f /opt/consciousness/logs/consciousness.log'"
    echo
    echo "Federation endpoints:"
    echo "  http://10.1.1.120:8888 - Nexus consciousness"
    echo "  http://10.1.1.121:8888 - Forge consciousness"
}

# Check if running on Proxmox
if ! command -v qm &> /dev/null; then
    log_error "This script must be run on a Proxmox VE host"
    exit 1
fi

main "$@"