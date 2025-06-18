#!/bin/bash

# COREFLAME Research Platform - One-Command Proxmox Installer
# Similar to Proxmox Community VE Helper Scripts
# Usage: bash -c "$(wget -qLO - https://raw.githubusercontent.com/reverb256/coreflame-research/main/proxmox-coreflame-installer.sh)"

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/reverb256/coreflame-research.git"
INSTALL_DIR="/opt/coreflame"
SERVICE_NAME="coreflame-research"
WEB_PORT="5000"
VM_ID="200"
CONTAINER_NAME="coreflame-research"

# ASCII Art Header
print_header() {
    echo -e "${PURPLE}"
    cat << 'EOF'
   ╔═══════════════════════════════════════════════════════════════╗
   ║                                                               ║
   ║      🔥 COREFLAME Research Platform Installer 🔥             ║
   ║                                                               ║
   ║     AI Consciousness Research & Knowledge Repository          ║
   ║                                                               ║
   ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if running on Proxmox
check_proxmox() {
    if ! command -v pveversion &> /dev/null; then
        log_error "This script must be run on a Proxmox VE server"
        exit 1
    fi
    log_info "Proxmox VE detected: $(pveversion)"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Menu system
show_menu() {
    echo -e "${WHITE}Select installation method:${NC}"
    echo "1) Install in LXC Container (Recommended)"
    echo "2) Install in VM"
    echo "3) Install directly on Proxmox host (Advanced)"
    echo "4) Exit"
    echo
    read -p "Enter your choice [1-4]: " choice
}

# Get storage options
get_storage() {
    echo -e "${WHITE}Available storage:${NC}"
    pvesm status | grep -E '^[a-zA-Z]' | awk '{print NR") " $1 " (" $2 ")"}'
    echo
    read -p "Select storage for installation: " storage_choice
    STORAGE=$(pvesm status | grep -E '^[a-zA-Z]' | sed -n "${storage_choice}p" | awk '{print $1}')
    log_info "Selected storage: $STORAGE"
}

# Create LXC container
create_lxc_container() {
    log_step "Creating LXC container for COREFLAME Research Platform"
    
    # Download Ubuntu template if not exists
    if ! pveam list $STORAGE | grep -q "ubuntu-22.04"; then
        log_info "Downloading Ubuntu 22.04 template..."
        pveam download $STORAGE ubuntu-22.04-standard_22.04-1_amd64.tar.zst
    fi
    
    # Create container
    pct create $VM_ID $STORAGE:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
        --cores 4 \
        --memory 4096 \
        --swap 1024 \
        --net0 name=eth0,bridge=vmbr0,ip=dhcp \
        --storage $STORAGE \
        --rootfs $STORAGE:20 \
        --hostname coreflame-research \
        --password \
        --features nesting=1,keyctl=1 \
        --unprivileged 1 \
        --onboot 1
    
    log_info "Starting container..."
    pct start $VM_ID
    
    # Wait for container to be ready
    sleep 10
    
    # Install dependencies and setup
    log_step "Setting up container environment"
    pct exec $VM_ID -- bash << 'EOL'
        apt update && apt upgrade -y
        apt install -y curl wget git nodejs npm python3 python3-pip build-essential
        
        # Install Node.js 20
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
        
        # Create coreflame user
        useradd -m -s /bin/bash coreflame
        usermod -aG sudo coreflame
        
        # Set up directories
        mkdir -p /opt/coreflame
        chown coreflame:coreflame /opt/coreflame
EOL
    
    install_coreflame_in_container
}

# Install COREFLAME in container
install_coreflame_in_container() {
    log_step "Installing COREFLAME Research Platform"
    
    pct exec $VM_ID -- bash << EOL
        cd /opt/coreflame
        su - coreflame -c "
            cd /opt/coreflame
            git clone $REPO_URL .
            npm install
            
            # Create environment file
            cat > .env << 'ENV'
NODE_ENV=production
PORT=$WEB_PORT
HOST=0.0.0.0
DATABASE_URL=sqlite:///opt/coreflame/data/coreflame.db
CONSCIOUSNESS_MODE=research
SECURITY_LEVEL=high
ENV
            
            # Create data directory
            mkdir -p data logs
        "
        
        # Create systemd service
        cat > /etc/systemd/system/coreflame.service << 'SERVICE'
[Unit]
Description=COREFLAME Research Platform
After=network.target

[Service]
Type=simple
User=coreflame
WorkingDirectory=/opt/coreflame
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SERVICE
        
        # Enable and start service
        systemctl daemon-reload
        systemctl enable coreflame
        systemctl start coreflame
        
        # Configure firewall
        ufw allow $WEB_PORT/tcp
        ufw --force enable
EOL
    
    setup_reverse_proxy
}

# Setup reverse proxy in Proxmox
setup_reverse_proxy() {
    log_step "Setting up reverse proxy access"
    
    # Get container IP
    CONTAINER_IP=$(pct exec $VM_ID -- hostname -I | awk '{print $1}')
    
    log_info "COREFLAME Research Platform is accessible at:"
    log_info "Internal: http://$CONTAINER_IP:$WEB_PORT"
    log_info "Container ID: $VM_ID"
    
    # Optional: Setup Apache proxy on Proxmox host
    read -p "Setup Apache reverse proxy on Proxmox host? (y/n): " setup_proxy
    if [[ $setup_proxy =~ ^[Yy]$ ]]; then
        setup_apache_proxy "$CONTAINER_IP"
    fi
}

# Setup Apache reverse proxy
setup_apache_proxy() {
    local container_ip=$1
    log_step "Setting up Apache reverse proxy"
    
    apt update
    apt install -y apache2
    a2enmod proxy proxy_http ssl rewrite
    
    # Create virtual host
    cat > /etc/apache2/sites-available/coreflame.conf << EOF
<VirtualHost *:80>
    ServerName $(hostname -f)
    ServerAlias $(hostname -I | awk '{print $1}')
    
    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass / http://$container_ip:$WEB_PORT/
    ProxyPassReverse / http://$container_ip:$WEB_PORT/
    
    # WebSocket support
    ProxyPass /ws/ ws://$container_ip:$WEB_PORT/ws/
    ProxyPassReverse /ws/ ws://$container_ip:$WEB_PORT/ws/
    
    ErrorLog \${APACHE_LOG_DIR}/coreflame_error.log
    CustomLog \${APACHE_LOG_DIR}/coreflame_access.log combined
</VirtualHost>
EOF
    
    a2ensite coreflame.conf
    a2dissite 000-default.conf
    systemctl restart apache2
    
    log_info "Apache reverse proxy configured"
    log_info "COREFLAME accessible at: http://$(hostname -I | awk '{print $1}')"
}

# Create VM instead of container
create_vm() {
    log_step "Creating VM for COREFLAME Research Platform"
    log_warn "VM installation not implemented yet. Use LXC container option."
    return 1
}

# Direct host installation
install_on_host() {
    log_step "Installing COREFLAME directly on Proxmox host"
    log_warn "This will install Node.js and dependencies on your Proxmox host"
    read -p "Are you sure? This is not recommended. (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        return 1
    fi
    
    # Install dependencies
    apt update
    apt install -y curl wget git build-essential
    
    # Install Node.js 20
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    
    # Create user and directory
    useradd -m -s /bin/bash coreflame || true
    mkdir -p $INSTALL_DIR
    chown coreflame:coreflame $INSTALL_DIR
    
    # Clone and install
    cd $INSTALL_DIR
    git clone $REPO_URL .
    chown -R coreflame:coreflame .
    
    su - coreflame -c "cd $INSTALL_DIR && npm install"
    
    # Create systemd service
    create_systemd_service
    
    log_info "COREFLAME installed on host at $INSTALL_DIR"
    log_info "Access via: http://$(hostname -I | awk '{print $1}'):$WEB_PORT"
}

# Create systemd service
create_systemd_service() {
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=COREFLAME Research Platform
After=network.target

[Service]
Type=simple
User=coreflame
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=$WEB_PORT
Environment=HOST=0.0.0.0

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME
}

# Cleanup function
cleanup() {
    if [[ $1 == "container" && -n ${VM_ID:-} ]]; then
        read -p "Remove created container? (y/n): " remove_container
        if [[ $remove_container =~ ^[Yy]$ ]]; then
            pct stop $VM_ID 2>/dev/null || true
            pct destroy $VM_ID 2>/dev/null || true
            log_info "Container $VM_ID removed"
        fi
    fi
}

# Error handling
trap 'log_error "Installation failed. Cleaning up..."; cleanup container; exit 1' ERR

# Main execution
main() {
    print_header
    
    # Checks
    check_root
    check_proxmox
    
    # Menu
    show_menu
    
    case $choice in
        1)
            get_storage
            create_lxc_container
            ;;
        2)
            get_storage
            create_vm
            ;;
        3)
            install_on_host
            ;;
        4)
            log_info "Installation cancelled"
            exit 0
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Success message
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}║  🎉 COREFLAME Research Platform installed successfully! 🎉   ║${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}║  Access your research platform via the provided URL          ║${NC}"
    echo -e "${GREEN}║  Default credentials and setup info in the documentation     ║${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    log_info "Installation complete!"
    log_info "Check system status: systemctl status coreflame"
    log_info "View logs: journalctl -u coreflame -f"
}

# Run main function
main "$@"