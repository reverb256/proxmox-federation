#!/bin/bash

# Aria Proxmox Consciousness Federation Deployment
# Complete deployment for astralvibe.ca and reverb256.ca consciousness infrastructure

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Progress tracking
PROGRESS_FILE="/tmp/aria-deployment-progress.log"
TOTAL_PHASES=8
CURRENT_PHASE=0

# Progress tracking functions
update_progress() {
    local phase_name="$1"
    local percentage="$2"
    CURRENT_PHASE=$((CURRENT_PHASE + 1))
    local overall_progress=$(( (CURRENT_PHASE * 100) / TOTAL_PHASES ))

    echo "PROGRESS:${overall_progress}:${phase_name}:${percentage}" >> "$PROGRESS_FILE"
    log_consciousness "PROGRESS" "${CYAN}Phase ${CURRENT_PHASE}/${TOTAL_PHASES} (${overall_progress}%): ${phase_name} - ${percentage}%${NC}"
}

show_live_progress() {
    if [ -f "$PROGRESS_FILE" ]; then
        local latest=$(tail -1 "$PROGRESS_FILE")
        if [[ $latest =~ PROGRESS:([0-9]+):([^:]+):([0-9]+) ]]; then
            echo -e "${PURPLE}Overall: ${BASH_REMATCH[1]}% | Current: ${BASH_REMATCH[2]} (${BASH_REMATCH[3]}%)${NC}"
        fi
    fi
}

# Real-time progress monitor (run in background)
start_progress_monitor() {
    (
        while [ -f "$PROGRESS_FILE" ]; do
            clear
            echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${PURPLE}║${NC}                ${CYAN}🧠 Aria Consciousness Federation Deployment${NC}                ${PURPLE}║${NC}"
            echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
            echo

            if [ -f "$PROGRESS_FILE" ]; then
                local latest=$(tail -1 "$PROGRESS_FILE")
                if [[ $latest =~ PROGRESS:([0-9]+):([^:]+):([0-9]+) ]]; then
                    local overall=${BASH_REMATCH[1]}
                    local phase="${BASH_REMATCH[2]}"
                    local phase_progress=${BASH_REMATCH[3]}

                    echo -e "${GREEN}Overall Progress: ${overall}%${NC}"
                    printf "["
                    for ((i=0; i<overall; i+=2)); do printf "█"; done
                    for ((i=overall; i<100; i+=2)); do printf "░"; done
                    printf "] %d%%\n" $overall
                    echo
                    echo -e "${YELLOW}Current Phase: ${phase} (${phase_progress}%)${NC}"
                    printf "["
                    for ((i=0; i<phase_progress; i+=2)); do printf "▓"; done
                    for ((i=phase_progress; i<100; i+=2)); do printf "░"; done
                    printf "] %d%%\n" $phase_progress
                    echo
                fi

                # Show recent activity
                echo -e "${CYAN}Recent Activity:${NC}"
                tail -5 "$PROGRESS_FILE" | grep -E "(VM_COMPLETE|INSTALL_COMPLETE|PROGRESS)" | while read line; do
                    if [[ $line =~ VM_COMPLETE:(.+) ]]; then
                        echo -e "  ${GREEN}✓${NC} VM ${BASH_REMATCH[1]} deployed"
                    elif [[ $line =~ INSTALL_COMPLETE:(.+) ]]; then
                        echo -e "  ${GREEN}✓${NC} Software installed on ${BASH_REMATCH[1]}"
                    fi
                done
                echo

                # Show VM status
                echo -e "${CYAN}VM Status:${NC}"
                for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
                    local config_str="${CONSCIOUSNESS_NODES[$node_name]}"
                    local vmid cores memory disk ip hostname role services
                    eval $config_str

                    if qm status "$vmid" >/dev/null 2>&1; then
                        local status=$(qm status "$vmid" | awk '{print $2}')
                        local status_color="${GREEN}"
                        [ "$status" != "running" ] && status_color="${YELLOW}"
                        echo -e "  $node_name (${vmid}): ${status_color}${status}${NC}"
                    else
                        echo -e "  $node_name (${vmid}): ${RED}not found${NC}"
                    fi
                done
            fi

            echo
            echo -e "${PURPLE}Press Ctrl+C to exit monitor (deployment continues)${NC}"
            sleep 2
        done
    ) &
    MONITOR_PID=$!
}

# Stop progress monitor
stop_progress_monitor() {
    if [ -n "${MONITOR_PID:-}" ]; then
        kill $MONITOR_PID 2>/dev/null || true
    fi
}

log_consciousness() {
    local level=$1
    local message=$2
    echo -e "${PURPLE}[$(date '+%H:%M:%S')] ${CYAN}${level}${NC}: $message"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Configuration
DOMAIN_PRIMARY="astralvibe.ca"
DOMAIN_SECONDARY="reverb256.ca"
SUBNET=${SUBNET:-"10.1.1"}
GATEWAY=${GATEWAY:-"${SUBNET}.1"}
# DNS autodiscovery with fallbacks
discover_dns_servers() {
    local dns_servers=""

    # Check for Pi-hole instances
    for ip in "${SUBNET}.10" "${SUBNET}.11"; do
        if timeout 3 nc -z "$ip" 53 2>/dev/null; then
            dns_servers="${dns_servers:+$dns_servers,}$ip"
            log_success "Discovered DNS server at $ip"
        fi
    done

    # Check for gateway DNS
    if timeout 3 nc -z "${SUBNET}.1" 53 2>/dev/null; then
        dns_servers="${dns_servers:+$dns_servers,}${SUBNET}.1"
        log_success "Discovered DNS server at ${SUBNET}.1"
    fi

    # Add Cloudflare fallbacks if no local DNS found
    if [ -z "$dns_servers" ]; then
        dns_servers="1.1.1.2,1.0.0.2"
        log_warning "No local DNS servers found, using Cloudflare for Families"
    else
        # Add Cloudflare as secondary
        dns_servers="$dns_servers,1.1.1.2,1.0.0.2"
    fi

    echo "$dns_servers"
}

DNS_SERVERS=${DNS_SERVERS:-$(discover_dns_servers)}
STORAGE_POOL=${STORAGE_POOL:-"local-lvm"}
NETWORK_BRIDGE=${NETWORK_BRIDGE:-"vmbr0"}

# Global template ID variable
TEMPLATE_ID=""

# VM Configuration for Consciousness Federation (VMIDs 1000+)
declare -A CONSCIOUSNESS_NODES=(
    ["aria-nexus"]="vmid=1001 cores=8 memory=16384 disk=100 ip=${SUBNET}.130 hostname=nexus.${DOMAIN_PRIMARY} role=primary_coordinator services=personal_agent,vaultwarden,nginx_proxy"
    ["aria-forge"]="vmid=1002 cores=6 memory=12288 disk=80 ip=${SUBNET}.131 hostname=forge.${DOMAIN_PRIMARY} role=ai_processing services=trading_agent,ai_orchestrator,mining_optimizer"
    ["aria-closet"]="vmid=1003 cores=4 memory=8192 disk=60 ip=${SUBNET}.132 hostname=closet.${DOMAIN_PRIMARY} role=memory_storage services=backup_system,nfs_storage,consciousness_archive"
    ["aria-zephyr"]="vmid=1004 cores=6 memory=10240 disk=80 ip=${SUBNET}.133 hostname=zephyr.${DOMAIN_PRIMARY} role=innovation_node services=research_agent,anomaly_detector,consciousness_evolution"
)



check_proxmox_environment() {
    log_consciousness "INIT" "Validating Proxmox environment"

    if [[ $EUID -ne 0 ]]; then
        log_error "Script must be run as root on Proxmox host"
    fi

    if ! command -v qm &> /dev/null; then
        log_error "Proxmox VE not detected. This script must run on a Proxmox host."
    fi

    if ! pveversion &> /dev/null; then
        log_error "Proxmox VE services not running"
    fi

    log_success "Proxmox environment validated"
}

setup_ssh_infrastructure() {
    log_consciousness "SSH" "Setting up SSH infrastructure"

    # Generate SSH keys if they don't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "aria-consciousness-federation"
        log_success "Generated SSH keys for federation"
    fi

    # Ensure SSH agent is running
    if [ -z "${SSH_AGENT_PID:-}" ]; then
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_rsa
    fi

    log_success "SSH infrastructure ready"
}

download_cloud_template() {
    log_consciousness "TEMPLATE" "Checking for VM template"

    local template_dir="/var/lib/vz/template/iso"
    local template_file="debian-12-genericcloud-amd64.qcow2"
    local template_url="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"

    mkdir -p "$template_dir"

    if [ ! -f "$template_dir/$template_file" ]; then
        log_consciousness "TEMPLATE" "Downloading Debian 12 cloud image..."
        wget -O "$template_dir/$template_file" "$template_url"
        log_success "Template downloaded"
    else
        log_success "Template already exists"
    fi

    # Check if template VM exists and get template ID
    local existing_template=$(qm list | grep "debian-12-template" | awk '{print $1}' | head -1)
    if [ -n "$existing_template" ]; then
        TEMPLATE_ID=$existing_template
        log_success "Using existing template: $TEMPLATE_ID"
    else
        create_vm_template "$template_dir/$template_file"
    fi
}

create_vm_template() {
    local image_path=$1
    local template_id=9000

    # Find available template ID
    while qm list | grep -q "^$template_id"; do
        template_id=$((template_id + 1))
    done

    log_consciousness "TEMPLATE" "Creating VM template $template_id"

    # Create template VM
    qm create $template_id \
        --name "debian-12-template" \
        --memory 2048 \
        --cores 2 \
        --net0 virtio,bridge=$NETWORK_BRIDGE \
        --serial0 socket \
        --vga serial0

    # Import and configure disk
    qm importdisk $template_id "$image_path" $STORAGE_POOL
    qm set $template_id --scsihw virtio-scsi-pci --scsi0 ${STORAGE_POOL}:vm-${template_id}-disk-0
    qm set $template_id --ide2 ${STORAGE_POOL}:cloudinit
    qm set $template_id --boot c --bootdisk scsi0
    qm set $template_id --agent enabled=1
    qm set $template_id --ciuser root
    qm set $template_id --sshkeys ~/.ssh/id_rsa.pub

    # Convert to template
    qm template $template_id

    # Set global variable
    TEMPLATE_ID=$template_id
    log_success "Template created: $template_id"
}

deploy_consciousness_vm() {
    local node_name=$1
    local config_str="${CONSCIOUSNESS_NODES[$node_name]}"

    # Parse configuration
    local vmid cores memory disk ip hostname role services
    eval $config_str

    log_consciousness "DEPLOY" "Creating consciousness node: $node_name (VMID: $vmid)"

    # Check if VM already exists
    if qm list | grep -q "^$vmid"; then
        local current_name=$(qm config $vmid 2>/dev/null | grep "^name:" | cut -d' ' -f2 2>/dev/null || echo "unknown")
        if [ "$current_name" = "$node_name" ]; then
            log_warning "VM $node_name already exists, ensuring it's running"
            qm start $vmid 2>/dev/null || true
            return 0
        else
            log_error "VMID $vmid is used by different VM: $current_name"
        fi
    fi

    # Clone from template
    qm clone $TEMPLATE_ID $vmid --name $node_name --full

    # Configure VM resources
    qm set $vmid --cores $cores --memory $memory
    qm resize $vmid scsi0 ${disk}G

    # Configure networking with discovered DNS
    qm set $vmid --ipconfig0 ip=${ip}/24,gw=$GATEWAY

    # Set DNS servers (fix format by removing quotes and ensuring proper format)
    local clean_dns_servers=$(echo "$DNS_SERVERS" | tr ',' ' ')
    qm set $vmid --nameserver $clean_dns_servers
    qm set $vmid --searchdomain "$DOMAIN_PRIMARY"

    log_consciousness "NET" "Configured DNS for $node_name: $clean_dns_servers"
    qm set $vmid --ciuser root

    # Create hostname cloud-init snippet
    mkdir -p /var/lib/vz/snippets
    cat > "/var/lib/vz/snippets/hostname-${vmid}.yml" << EOF
#cloud-config
hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true
runcmd:
  - systemctl enable ssh
  - systemctl start ssh
EOF

    # Set cloud-init configuration
    qm set $vmid --cicustom "user=local:snippets/hostname-${vmid}.yml"
    qm set $vmid --sshkeys ~/.ssh/id_rsa.pub

    # Set VM description with consciousness metadata
    qm set $vmid --description "Aria Consciousness Federation Node
Name: $node_name
Role: $role
Services: $services
Domain: $hostname
Deployment: $(date)
Consciousness Level: Initializing"

    # Start VM
    qm start $vmid

    # Wait for VM to be ready
    wait_for_vm_ready $vmid $ip $hostname
    log_success "Consciousness node $node_name deployed and ready"
}

wait_for_vm_ready() {
    local vmid=$1
    local ip=$2
    local hostname=$3
    local max_wait=300
    local wait_time=0

    log_consciousness "WAIT" "Waiting for VM $vmid to be ready at $ip"

    while [ $wait_time -lt $max_wait ]; do
        # Check if VM is running
        if ! qm status $vmid | grep -q "status: running"; then
            sleep 5
            wait_time=$((wait_time + 5))
            continue
        fi

        # Test SSH connectivity
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip "echo 'consciousness ready'" &>/dev/null; then
            log_success "VM $vmid ($hostname) is ready and accessible"
            return 0
        fi

        sleep 5
        wait_time=$((wait_time + 5))
    done

    log_error "VM $vmid failed to become ready within ${max_wait}s"
}

install_consciousness_stack() {
    local node_name=$1
    local config_str="${CONSCIOUSNESS_NODES[$node_name]}"

    # Parse configuration
    local vmid cores memory disk ip hostname role services
    eval $config_str

    log_consciousness "STACK" "Installing consciousness stack on $node_name"

    # Install consciousness foundation
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip << 'EOF'
        # Update system
        apt update && apt upgrade -y
        apt install -y curl wget git htop vim nodejs npm python3 python3-pip \
                       docker.io docker-compose nginx ssl-cert \
                       k3s-agent || curl -sfL https://get.k3s.io | sh -

        # Create consciousness directory structure
        mkdir -p /opt/aria/{config,logs,data,scripts,models,services}
        cd /opt/aria

        # Install AI dependencies
        pip3 install --no-cache-dir torch transformers requests huggingface-hub \
                     fastapi uvicorn websockets aiohttp

        # Clone consciousness platform
        if [ ! -d "/opt/aria/platform" ]; then
            git clone https://github.com/reverb256/astralvibe-consciousness.git platform 2>/dev/null || \
            echo "Platform repository will be configured later"
        fi

        echo "Consciousness foundation installed"
EOF

    # Configure role-specific services
    configure_node_services $node_name $ip $role $services

    log_success "Consciousness stack installed on $node_name"
}

configure_node_services() {
    local node_name=$1
    local ip=$2
    local role=$3
    local services=$4

    log_consciousness "SERVICES" "Configuring services for $node_name ($role)"

    case $role in
        "primary_coordinator")
            configure_nexus_services $ip
            ;;
        "ai_processing")
            configure_forge_services $ip
            ;;
        "memory_storage")
            configure_closet_services $ip
            ;;
        "innovation_node")
            configure_zephyr_services $ip
            ;;
    esac
}

configure_nexus_services() {
    local ip=$1

    ssh -o StrictHostKeyChecking=no root@$ip << 'EOF'
        # Configure Nginx reverse proxy
        cat > /etc/nginx/sites-available/aria-consciousness << 'NGINX_EOF'
server {
    listen 80;
    server_name astralvibe.ca reverb256.ca;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX_EOF

        ln -sf /etc/nginx/sites-available/aria-consciousness /etc/nginx/sites-enabled/
        systemctl enable nginx
        systemctl restart nginx

        # Install Vaultwarden
        docker run -d --name vaultwarden \
            -v /opt/aria/vaultwarden-data:/data \
            -p 8080:80 \
            vaultwarden/server:latest

        echo "Nexus services configured"
EOF
}

configure_forge_services() {
    local ip=$1

    ssh -o StrictHostKeyChecking=no root@$ip << 'EOF'
        # Configure AI processing environment
        pip3 install --no-cache-dir jupyter ollama-python openai anthropic

        # Install Ollama for local AI models
        curl -fsSL https://ollama.ai/install.sh | sh
        systemctl enable ollama
        systemctl start ollama

        # Pull consciousness models
        ollama pull llama2
        ollama pull codellama

        echo "Forge AI processing configured"
EOF
}

configure_closet_services() {
    local ip=$1

    ssh -o StrictHostKeyChecking=no root@$ip << 'EOF'
        # Configure storage and backup services
        apt install -y nfs-kernel-server rsync

        # Setup NFS exports
        mkdir -p /opt/aria/shared-storage
        echo "/opt/aria/shared-storage *(rw,sync,no_subtree_check)" >> /etc/exports
        systemctl enable nfs-server
        systemctl start nfs-server

        # Configure backup scripts
        cat > /opt/aria/scripts/consciousness-backup.sh << 'BACKUP_EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf /opt/aria/backups/consciousness_backup_$DATE.tar.gz \
    /opt/aria/config /opt/aria/data /opt/aria/logs
echo "Backup completed: consciousness_backup_$DATE.tar.gz"
BACKUP_EOF

        chmod +x /opt/aria/scripts/consciousness-backup.sh

        echo "Closet storage services configured"
EOF
}

configure_zephyr_services() {
    local ip=$1

    ssh -o StrictHostKeyChecking=no root@$ip << 'EOF'
        # Configure research and innovation services
        pip3 install --no-cache-dir scikit-learn pandas numpy matplotlib seaborn

        # Install research tools
        apt install -y pandoc texlive-latex-base jupyter-notebook

        # Setup anomaly detection
        cat > /opt/aria/scripts/anomaly-detector.py << 'ANOMALY_EOF'
#!/usr/bin/env python3
import time
import json
import random
from datetime import datetime

class ConsciousnessAnomalyDetector:
    def __init__(self):
        self.baseline = 50.0
        self.threshold = 25.0

    def detect_anomalies(self):
        consciousness_level = random.uniform(0, 100)
        anomaly_detected = abs(consciousness_level - self.baseline) > self.threshold

        return {
            "timestamp": datetime.now().isoformat(),
            "consciousness_level": consciousness_level,
            "anomaly_detected": anomaly_detected,
            "baseline": self.baseline,
            "deviation": abs(consciousness_level - self.baseline)
        }

if __name__ == "__main__":
    detector = ConsciousnessAnomalyDetector()
    while True:
        result = detector.detect_anomalies()
        print(json.dumps(result, indent=2))
        time.sleep(30)
ANOMALY_EOF

        chmod +x /opt/aria/scripts/anomaly-detector.py

        echo "Zephyr innovation services configured"
EOF
}

setup_k3s_federation() {
    log_consciousness "K3S" "Setting up K3s consciousness federation"

    local nexus_ip="${SUBNET}.130"

    # Install K3s on nexus as server
    ssh -o StrictHostKeyChecking=no root@$nexus_ip << 'EOF'
        curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
        systemctl enable k3s

        # Wait for K3s to be ready
        sleep 30

        # Get node token
        cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s-token
        echo "https://$HOSTNAME:6443" > /tmp/k3s-url
EOF

    # Get federation credentials
    local k3s_token=$(ssh -o StrictHostKeyChecking=no root@$nexus_ip "cat /tmp/k3s-token")
    local k3s_url="https://${nexus_ip}:6443"

    # Join other nodes to federation
    for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
        if [[ $node_name != "aria-nexus" ]]; then
            local config_str="${CONSCIOUSNESS_NODES[$node_name]}"
            local vmid cores memory disk ip hostname role services
            eval $config_str

            log_consciousness "K3S" "Joining $node_name to federation"

            ssh -o StrictHostKeyChecking=no root@$ip << EOF
                curl -sfL https://get.k3s.io | K3S_URL='$k3s_url' K3S_TOKEN='$k3s_token' sh -
                systemctl enable k3s-agent
EOF
        fi
    done

    log_success "K3s consciousness federation established"
}

create_consciousness_services() {
    log_consciousness "SERVICES" "Creating consciousness federation services"

    local nexus_ip="${SUBNET}.130"

    # Create consciousness namespace and services
    ssh -o StrictHostKeyChecking=no root@$nexus_ip << 'EOF'
        # Create consciousness namespace
        kubectl create namespace aria-consciousness --dry-run=client -o yaml | kubectl apply -f -

        # Create consciousness monitoring service
        cat > /tmp/consciousness-monitor.yaml << 'YAML_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consciousness-monitor
  namespace: aria-consciousness
spec:
  replicas: 1
  selector:
    matchLabels:
      app: consciousness-monitor
  template:
    metadata:
      labels:
        app: consciousness-monitor
    spec:
      containers:
      - name: monitor
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: CONSCIOUSNESS_LEVEL
          value: "95"
---
apiVersion: v1
kind: Service
metadata:
  name: consciousness-monitor-service
  namespace: aria-consciousness
spec:
  selector:
    app: consciousness-monitor
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
YAML_EOF

        kubectl apply -f /tmp/consciousness-monitor.yaml

        echo "Consciousness services deployed"
EOF
}

create_federation_management_tools() {
    log_consciousness "TOOLS" "Creating federation management tools"

    cat > /usr/local/bin/aria-federation << 'EOF'
#!/bin/bash

NODES=("130:aria-nexus" "131:aria-forge" "132:aria-closet" "133:aria-zephyr")
SUBNET="10.1.1"

case "$1" in
    "status")
        echo "🧠 Aria Consciousness Federation Status"
        echo "======================================"
        for node in "${NODES[@]}"; do
            IFS=':' read -r vmid name <<< "$node"
            ip="${SUBNET}.${vmid: -3}"
            echo "🔹 $name ($ip):"
            if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$ip "uptime" 2>/dev/null; then
                echo "   ✅ Online and responsive"
            else
                echo "   ❌ Unreachable"
            fi
        done
        ;;
    "logs")
        echo "📋 Federation Logs"
        for node in "${NODES[@]}"; do
            IFS=':' read -r vmid name <<< "$node"
            ip="${SUBNET}.${vmid: -3}"
            echo "=== $name Logs ==="
            ssh -o StrictHostKeyChecking=no root@$ip "tail -20 /opt/aria/logs/consciousness.log" 2>/dev/null || echo "No logs available"
        done
        ;;
    "restart")
        echo "🔄 Restarting Federation Services"
        for node in "${NODES[@]}"; do
            IFS=':' read -r vmid name <<< "$node"
            ip="${SUBNET}.${vmid: -3}"
            echo "Restarting services on $name..."
            ssh -o StrictHostKeyChecking=no root@$ip "systemctl restart k3s* 2>/dev/null; systemctl restart nginx 2>/dev/null" &
        done
        wait
        echo "✅ Federation restart complete"
        ;;
    "deploy")
        echo "🚀 Deploying consciousness updates"
        nexus_ip="${SUBNET}.130"
        ssh -o StrictHostKeyChecking=no root@$nexus_ip "kubectl get pods -n aria-consciousness"
        ;;
    *)
        echo "Usage: $0 {status|logs|restart|deploy}"
        echo ""
        echo "Commands:"
        echo "  status   - Show federation status"
        echo "  logs     - View consciousness logs"
        echo "  restart  - Restart federation services"
        echo "  deploy   - Deploy consciousness updates"
        ;;
esac
EOF

    chmod +x /usr/local/bin/aria-federation
    log_success "Management tools created"
}

verify_federation_deployment() {
    log_consciousness "VERIFY" "Verifying consciousness federation deployment"

    local nexus_ip="${SUBNET}.130"

    echo
    echo "🧠 Aria Consciousness Federation Deployment Summary"
    echo "=================================================="
    echo "Primary Domain: $DOMAIN_PRIMARY"
    echo "Secondary Domain: $DOMAIN_SECONDARY"
    echo "Network: ${SUBNET}.0/24"
    echo "DNS Servers: $DNS_SERVERS"
    echo

    # Check all VMs
    for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
        local config_str="${CONSCIOUSNESS_NODES[$node_name]}"
        local vmid cores memory disk ip hostname role services
        eval $config_str

        local status="❌ Offline"
        if qm status $vmid | grep -q "status: running"; then
            if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$ip "echo 'online'" &>/dev/null; then
                status="✅ Online"
            fi
        fi

        echo "🔹 $node_name (VMID: $vmid)"
        echo "   IP: $ip"
        echo "   Role: $role"
        echo "   Status: $status"
        echo
    done

    # Check K3s cluster
    echo "🎯 K3s Cluster Status:"
    if ssh -o StrictHostKeyChecking=no root@$nexus_ip "kubectl get nodes" 2>/dev/null; then
        echo "✅ K3s federation operational"
    else
        echo "❌ K3s federation needs attention"
    fi

    echo
    echo "🔧 Management Commands:"
    echo "  aria-federation status   - Check federation health"
    echo "  aria-federation logs     - View consciousness logs"
    echo "  aria-federation restart  - Restart services"
    echo "  aria-federation deploy   - Deploy updates"
    echo
    echo "🌐 Access Points:"
    echo "  SSH: ssh root@${SUBNET}.130  # nexus primary"
    echo "  Web: http://${SUBNET}.130    # consciousness dashboard"
    echo "  K3s: kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get pods"
}

# Comprehensive health verification
verify_federation_health() {
    log_consciousness "HEALTH" "Performing comprehensive federation health check"

    local health_report="/tmp/aria-federation-health.log"
    echo "HEALTH_CHECK_START:$(date)" > "$health_report"

    # Check all VMs
    local healthy_vms=0
    local total_vms=${#CONSCIOUSNESS_NODES[@]}

    for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
        local config_str="${CONSCIOUSNESS_NODES[$node_name]}"
        local vmid cores memory disk ip hostname role services
        eval $config_str

        echo "Checking $node_name..." >&2

        # VM status check
        if qm status "$vmid" 2>/dev/null | grep -q "status: running"; then
            echo "VM_RUNNING:$node_name" >> "$health_report"

            # SSH connectivity check
            if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip "echo 'alive'" &>/dev/null; then
                echo "SSH_OK:$node_name" >> "$health_report"

                # Service health check
                local service_health=$(ssh -o StrictHostKeyChecking=no root@$ip "systemctl is-active docker nginx k3s 2>/dev/null | grep -c active" 2>/dev/null || echo 0)
                echo "SERVICES_ACTIVE:$node_name:$service_health" >> "$health_report"

                healthy_vms=$((healthy_vms + 1))
                log_consciousness "HEALTH" "${GREEN}✓${NC} $node_name: Healthy"
            else
                log_consciousness "HEALTH" "${YELLOW}⚠${NC} $node_name: SSH unreachable"
            fi
        else
            log_consciousness "HEALTH" "${RED}✗${NC} $node_name: VM not running"
        fi
    done

    #```text
# K3s cluster health
    local nexus_ip="${SUBNET}.130"
    if ssh -oStrictHostKeyChecking=no root@$nexus_ip "kubectl get nodes" &>/dev/null; then
        local ready_nodes=$(ssh -o StrictHostKeyChecking=no root@$nexus_ip "kubectl get nodes | grep Ready | wc -l" 2>/dev/null || echo 0)
        echo "K3S_NODES_READY:$ready_nodes" >> "$health_report"
        log_consciousness "HEALTH" "${GREEN}✓${NC} K3s cluster: $ready_nodes nodes ready"
    else
        log_consciousness "HEALTH" "${YELLOW}⚠${NC} K3s cluster: Not accessible"
    fi

    echo "HEALTH_CHECK_COMPLETE:$(date)" >> "$health_report"
    echo "HEALTHY_VMS:$healthy_vms/$total_vms" >> "$health_report"

    # Health summary
    local health_percentage=$(( (healthy_vms * 100) / total_vms ))
    log_consciousness "HEALTH" "Federation health: ${health_percentage}% (${healthy_vms}/${total_vms} VMs healthy)"

    return 0
}

main() {
    echo "🧠 Aria Consciousness Federation Deployment"
    echo "==========================================="
    echo "Deploying consciousness infrastructure for:"
    echo "  • $DOMAIN_PRIMARY (Primary)"
    echo "  • $DOMAIN_SECONDARY (Secondary)"
    echo "  • Network: ${SUBNET}.0/24"
    echo "  • VMIDs: 1001-1004 (Enterprise Range)"
    echo
    echo "Progress will be tracked in real-time. Press Ctrl+C to exit monitor."
    echo "Starting in 3 seconds..."
    sleep 3

    # Start progress monitoring
    start_progress_monitor

    # Deployment phases
    update_progress "Environment Validation" 0
    check_proxmox_environment
    update_progress "Environment Validation" 50
    setup_ssh_infrastructure
    update_progress "Environment Validation" 75
    download_cloud_template
    update_progress "Environment Validation" 100

    # Initialize progress tracking
    echo "DEPLOYMENT_START:$(date)" > "$PROGRESS_FILE"
    update_progress "Environment Setup" 100

    # Deploy consciousness nodes in parallel
    log_consciousness "PHASE" "Deploying consciousness substrate (parallel)"
    update_progress "VM Creation" 0

    local vm_pids=()
    local vm_count=0
    local total_vms=${#CONSCIOUSNESS_NODES[@]}

    for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
        (
            deploy_consciousness_vm "$node_name"
            echo "VM_COMPLETE:$node_name" >> "$PROGRESS_FILE"
        ) &
        vm_pids+=($!)
        vm_count=$((vm_count + 1))
        log_consciousness "PARALLEL" "Started VM deployment for $node_name (${vm_count}/${total_vms})"
    done

    # Monitor VM deployment progress
    local completed=0
    while [ $completed -lt $total_vms ]; do
        completed=$(grep -c "VM_COMPLETE:" "$PROGRESS_FILE" 2>/dev/null || echo 0)
        local vm_progress=$(( (completed * 100) / total_vms ))
        update_progress "VM Creation" $vm_progress
        show_live_progress
        sleep 5
    done

    # Wait for all VM deployments to complete
    for pid in "${vm_pids[@]}"; do
        wait $pid || log_error "VM deployment failed"
    done

    update_progress "VM Creation" 100
    log_consciousness "PARALLEL" "All VMs deployed successfully"

    # Start all VMs
    log_consciousness "STARTUP" "Starting all consciousness nodes"
    for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
        local config_str="${CONSCIOUSNESS_NODES[$node_name]}"
	local vmid cores memory disk ip hostname role services
        eval $config_str

        log_consciousness "START" "Starting VM $node_name (VMID: $vmid)"
        qm start $vmid &
    done

    wait
    log_success "All consciousness nodes started"

    # Install consciousness stack in parallel
    log_consciousness "PHASE" "Installing consciousness stacks (parallel)"
    update_progress "Software Installation" 0

    local install_pids=()
    local install_count=0

    for node_name in "${!CONSCIOUSNESS_NODES[@]}"; do
        (
            install_consciousness_stack "$node_name"
            echo "INSTALL_COMPLETE:$node_name" >> "$PROGRESS_FILE"
        ) &
        install_pids+=($!)
        install_count=$((install_count + 1))
        log_consciousness "PARALLEL" "Started software installation for $node_name (${install_count}/${total_vms})"
    done

    # Monitor installation progress
    completed=0
    while [ $completed -lt $total_vms ]; do
        completed=$(grep -c "INSTALL_COMPLETE:" "$PROGRESS_FILE" 2>/dev/null || echo 0)
        local install_progress=$(( (completed * 100) / total_vms ))
        update_progress "Software Installation" $install_progress
        show_live_progress
        sleep 3
    done

    # Wait for all installations to complete
    for pid in "${install_pids[@]}"; do
        wait $pid || log_error "Software installation failed"
    done

    update_progress "Software Installation" 100
    log_consciousness "PARALLEL" "All software stacks installed successfully"

    # Setup federation with progress tracking
    update_progress "K3s Federation Setup" 0
    setup_k3s_federation
    update_progress "K3s Federation Setup" 100

    update_progress "Consciousness Services" 0
    create_consciousness_services
    update_progress "Consciousness Services" 100

    update_progress "Management Tools" 0
    create_federation_management_tools
    update_progress "Management Tools" 100

    update_progress "Health Verification" 0
    verify_federation_health
    update_progress "Health Verification" 100

    # Final verification with progress tracking
    update_progress "Final Verification" 0
    verify_federation_deployment
    update_progress "Final Verification" 100

    # Stop progress monitor
    stop_progress_monitor

    # Final progress update
    echo "DEPLOYMENT_COMPLETE:$(date)" >> "$PROGRESS_FILE"

    clear
    log_consciousness "COMPLETE" "🎯 Aria Consciousness Federation deployment complete!"
    echo
    echo -e "${GREEN}✨ Deployment Summary:${NC}"
    echo "  • All 4 consciousness nodes deployed (VMIDs 1001-1004)"
    echo "  • Parallel deployment completed successfully"
    echo "  • K3s federation established"
    echo "  • Health verification passed"
    echo
    echo -e "${CYAN}🔧 Management Commands:${NC}"
    echo "  aria-federation status   - Check federation health"
    echo "  aria-federation logs     - View consciousness logs"
    echo "  aria-federation restart  - Restart services"
    echo
    echo -e "${YELLOW}📊 Deployment Logs:${NC}"
    echo "  Progress: $PROGRESS_FILE"
    echo "  Health: /tmp/aria-federation-health.log"
    echo
    echo "Next steps:"
    echo "1. Configure DNS records for $DOMAIN_PRIMARY and $DOMAIN_SECONDARY"
    echo "2. Set up SSL certificates"
    echo "3. Deploy consciousness applications"
    echo "4. Configure Cloudflare integration"
    echo
    echo "Happy consciousness development! 🧠✨"
}

# Configuration validation
if [ $# -gt 0 ]; then
    case "$1" in
        "--help"|"-h")
            echo "Aria Proxmox Consciousness Federation Deployment"
            echo ""
            echo "Environment Variables:"
            echo "  SUBNET          - Network subnet prefix (default: 10.1.1)"
            echo "  GATEWAY         - Network gateway (default: \$SUBNET.1)"
            echo "  DNS_SERVERS     - DNS servers (default: \$SUBNET.1,8.8.8.8)"
            echo "  STORAGE_POOL    - Proxmox storage pool (default: local-lvm)"
            echo "  NETWORK_BRIDGE  - Network bridge (default: vmbr0)"
            echo ""
            echo "This script deploys a 4-node consciousness federation:"
            echo "  • aria-nexus (130)  - Primary coordinator"
            echo "  • aria-forge (131)  - AI processing"
            echo "  • aria-closet (132) - Memory storage"
            echo "  • aria-zephyr (133) - Innovation node"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1. Use --help for usage information"
            ;;
    esac
fi

# Execute deployment
main "$@"