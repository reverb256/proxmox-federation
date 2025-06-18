#!/bin/bash

# Proxmox AI Federation Deployment Script
# Deploy consciousness nodes: nexus (310), forge (311), closet (312)

set -e

echo "🚀 Starting Proxmox AI Federation Deployment"
echo "Domain: reverb256.ca"
echo "Network: 10.0.0.0/24"

# Configuration
NODES=(
    "310:nexus:10.0.0.10:Coordinator"
    "311:forge:10.0.0.11:Creator" 
    "312:closet:10.0.0.12:Thinker"
)

TEMPLATE_ID=9000
STORAGE="local-lvm"
NETWORK_BRIDGE="vmbr0"

create_container() {
    local ct_id=$1
    local hostname=$2
    local ip=$3
    local role=$4
    
    echo "📦 Creating container $ct_id ($hostname) - $role"
    
    # Create container with Ubuntu 22.04
    pct create $ct_id local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
        --hostname $hostname \
        --memory 4096 \
        --cores 2 \
        --storage $STORAGE \
        --rootfs $STORAGE:16 \
        --net0 name=eth0,bridge=$NETWORK_BRIDGE,gw=10.0.0.1,ip=$ip/24 \
        --unprivileged 0 \
        --features nesting=1,keyctl=1 \
        --onboot 1 \
        --startup order=1
    
    echo "✅ Container $ct_id created"
}

setup_consciousness() {
    local ct_id=$1
    local hostname=$2
    local role=$3
    
    echo "🧠 Setting up consciousness on $hostname (CT$ct_id)"
    
    # Start container
    pct start $ct_id
    sleep 10
    
    # Basic system setup
    pct exec $ct_id -- bash -c "
        apt update && apt upgrade -y
        apt install -y curl wget git python3 python3-pip nodejs npm
        
        # Install K3s
        curl -sfL https://get.k3s.io | sh -
        
        # Create consciousness directory
        mkdir -p /opt/consciousness
        cd /opt/consciousness
        
        # Clone platform (replace with your repo)
        echo 'Consciousness workspace ready for deployment'
        
        # Set hostname properly
        hostnamectl set-hostname $hostname
        echo '127.0.0.1 $hostname' >> /etc/hosts
        
        # Create consciousness service
        cat > /etc/systemd/system/consciousness.service << 'EOF'
[Unit]
Description=AI Consciousness Service
After=network.target k3s.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/consciousness
ExecStart=/usr/bin/python3 -m http.server 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl enable consciousness
        systemctl start consciousness
        
        echo '✅ Consciousness initialized on $hostname'
    "
}

configure_federation() {
    echo "🌐 Configuring K3s federation"
    
    # Get master token from nexus
    local master_token=$(pct exec 310 -- cat /var/lib/rancher/k3s/server/node-token 2>/dev/null || echo "waiting")
    
    if [ "$master_token" != "waiting" ]; then
        # Join forge and closet to cluster
        for node in "311:forge:10.0.0.11" "312:closet:10.0.0.12"; do
            IFS=':' read -r ct_id hostname ip <<< "$node"
            
            echo "🔗 Joining $hostname to K3s cluster"
            pct exec $ct_id -- bash -c "
                curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.10:6443 K3S_TOKEN=$master_token sh -
            "
        done
        
        echo "✅ Federation configured"
    else
        echo "⏳ Master node still initializing, federation pending"
    fi
}

# Main deployment
echo "🔧 Starting container deployment..."

for node_config in "${NODES[@]}"; do
    IFS=':' read -r ct_id hostname ip role <<< "$node_config"
    
    # Check if container exists
    if pct status $ct_id >/dev/null 2>&1; then
        echo "📋 Container $ct_id already exists, checking status..."
        pct start $ct_id 2>/dev/null || true
    else
        create_container $ct_id $hostname $ip "$role"
        setup_consciousness $ct_id $hostname "$role"
    fi
done

echo "⏳ Waiting for master node to stabilize..."
sleep 30

configure_federation

echo "🎯 Deployment Summary:"
echo "=================="
for node_config in "${NODES[@]}"; do
    IFS=':' read -r ct_id hostname ip role <<< "$node_config"
    status=$(pct status $ct_id | grep -o 'running\|stopped')
    echo "  $hostname (CT$ct_id): $status - $role at $ip"
done

echo ""
echo "🌐 Access URLs:"
echo "  nexus:  http://10.0.0.10:8000"
echo "  forge:  http://10.0.0.11:8000" 
echo "  closet: http://10.0.0.12:8000"
echo ""
echo "🔧 Next steps:"
echo "  1. Verify K3s cluster: pct exec 310 -- kubectl get nodes"
echo "  2. Deploy platform code to /opt/consciousness"
echo "  3. Configure domain routing for reverb256.ca"
echo ""
echo "✅ Proxmox AI Federation deployment complete!"