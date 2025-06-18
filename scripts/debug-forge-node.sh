
#!/bin/bash

# Debug Forge Node Issues
# Comprehensive analysis of what's happening on the forge node

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

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

echo "🔍 Forge Node Comprehensive Diagnostic"
echo "======================================"
echo

# Basic system info
log_step "System Information"
echo "Hostname: $(hostname)"
echo "IP Address: $(ip route get 1 | awk '{print $7; exit}')"
echo "Uptime: $(uptime)"
echo "Load: $(cat /proc/loadavg)"
echo

# Check network connectivity
log_step "Network Connectivity Test"
NODES=("nexus" "forge" "closet" "zephyr")
for node in "${NODES[@]}"; do
    if ping -c 1 -W 2 "$node" >/dev/null 2>&1; then
        log_success "Can reach $node"
    else
        log_error "Cannot reach $node"
    fi
done
echo

# Check SSH status
log_step "SSH Service Status"
systemctl status ssh --no-pager || systemctl status sshd --no-pager || echo "SSH service status unknown"
echo

# Check listening ports
log_step "Listening Ports"
netstat -tlnp | grep -E "(22|6443|10250|2379|2380)"
echo

# Check if we're in a VM
log_step "Virtualization Check"
if command -v systemd-detect-virt >/dev/null 2>&1; then
    echo "Virtualization: $(systemd-detect-virt)"
else
    echo "systemd-detect-virt not available"
fi
echo

# Check disk space
log_step "Disk Usage"
df -h | head -5
echo

# Check memory
log_step "Memory Usage"
free -h
echo

# Check running containers/VMs
log_step "Container/VM Status"
if command -v docker >/dev/null 2>&1; then
    echo "Docker containers:"
    docker ps 2>/dev/null || echo "No docker containers or docker not running"
fi

if command -v pct >/dev/null 2>&1; then
    echo "LXC containers:"
    pct list 2>/dev/null || echo "Not a Proxmox node or no containers"
fi

if command -v qm >/dev/null 2>&1; then
    echo "Virtual machines:"
    qm list 2>/dev/null || echo "Not a Proxmox node or no VMs"
fi
echo

# Check K3s if installed
log_step "K3s Status"
if systemctl is-active --quiet k3s 2>/dev/null; then
    log_success "K3s is running"
    kubectl get nodes 2>/dev/null || echo "kubectl not accessible"
elif systemctl is-active --quiet k3s-agent 2>/dev/null; then
    log_success "K3s agent is running"
else
    log_warning "K3s not running or not installed"
fi
echo

# Check processes
log_step "Key Processes"
ps aux | grep -E "(k3s|docker|containerd|ssh)" | grep -v grep
echo

# Check journal for errors
log_step "Recent System Errors"
echo "Last 10 error messages:"
journalctl -p err -n 10 --no-pager
echo

# Check network interfaces
log_step "Network Interfaces"
ip addr show | grep -E "(inet |UP|DOWN)"
echo

# Check if this is actually the right node
log_step "Node Identity Verification"
echo "Current working directory: $(pwd)"
echo "User: $(whoami)"
echo "Home directory: $HOME"
if [ -f /etc/machine-id ]; then
    echo "Machine ID: $(cat /etc/machine-id)"
fi
echo

# Check recent command history
log_step "Recent Commands (last 10)"
if [ -f ~/.bash_history ]; then
    tail -10 ~/.bash_history
else
    echo "No bash history available"
fi
echo

log_step "Diagnosis Complete"
echo "If this is running on the wrong system, that explains the SSH key issues."
echo "The deployment scripts may be connecting to a different node than expected."
