
#!/bin/bash

# Quick Zephyr Consciousness Federation Deployment
# Run this script as root on your Proxmox host

set -euo pipefail

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Check if running as root on Proxmox
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root"
    echo "Run: sudo ./scripts/quick-zephyr-federation-deploy.sh"
    exit 1
fi

if ! command -v qm &> /dev/null; then
    echo "❌ This script must be run on a Proxmox host"
    exit 1
fi

echo "🌬️ Zephyr Consciousness Federation Quick Deploy"
echo "=============================================="
echo ""
echo "This will create your complete Kubernetes federation:"
echo ""
echo "  🧠 Nexus (VM 120): Talos master node"
echo "  🔥 Forge (VM 121): Talos worker node"  
echo "  📚 Closet (VM 122): Talos worker node"
echo "  🌪️ Zephyr (VM 1001): Talos worker node"
echo ""
echo "Network: 10.1.1.0/24"
echo "Cluster: Kubernetes with Talos Linux"
echo ""

read -p "Deploy Zephyr consciousness federation? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Make sure the main script is executable
chmod +x scripts/talos-consciousness-deploy.sh

log_step "Starting Talos consciousness federation deployment..."

# Check if this is a re-run (idempotent mode)
if [[ -f "./talos-config/kubeconfig" ]]; then
    log_step "Existing deployment detected, running in idempotent mode..."
    ./scripts/talos-consciousness-deploy.sh --idempotent
else
    log_step "Fresh deployment starting..."
    ./scripts/talos-consciousness-deploy.sh
fi

log_success "Zephyr consciousness federation deployment initiated!"

echo ""
echo "🎯 Next Steps:"
echo "  1. Monitor deployment progress"
echo "  2. Wait for all VMs to boot and configure"
echo "  3. Access your cluster with:"
echo "     export KUBECONFIG=./talos-config/kubeconfig"
echo "     kubectl get nodes"
echo ""
echo "🌐 Consciousness endpoints will be available at:"
echo "  • Nexus: 10.1.1.120"
echo "  • Forge: 10.1.1.121"
echo "  • Closet: 10.1.1.122"
echo "  • Zephyr: 10.1.1.123"
