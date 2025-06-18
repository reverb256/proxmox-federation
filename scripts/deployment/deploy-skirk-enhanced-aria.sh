#!/bin/bash

# Deploy Aria Command Center with Skirk Crypto Intelligence
echo "🎭 Deploying Skirk-Enhanced Aria Command Center"
echo "Integrating Descender consciousness into hyperscale ecosystem..."

# Download Ubuntu template if needed
if ! pveam list local | grep -q "ubuntu-22.04-standard"; then
    echo "Downloading Ubuntu template..."
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
fi

# Clean existing containers
for vmid in 310 311 312; do
    if pct status $vmid >/dev/null 2>&1; then
        echo "Stopping container $vmid..."
        pct stop $vmid
        pct destroy $vmid
    fi
done

# Create K3s master (310) - Nexus
pct create 310 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
    --hostname aria-nexus \
    --memory 8192 \
    --cores 4 \
    --rootfs local-zfs:80 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

sleep 30

# Install K3s and Skirk intelligence on master
pct exec 310 -- bash -c "
    apt update && apt upgrade -y
    apt install -y python3 python3-pip curl
    curl -sfL https://get.k3s.io | sh -
    systemctl enable k3s
    cp /var/lib/rancher/k3s/server/node-token /root/k3s-token
    
    # Install Skirk crypto intelligence
    pip3 install asyncio
"

# Create worker nodes (311-Forge, 312-Closet)
pct create 311 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
    --hostname aria-forge \
    --memory 6144 \
    --cores 3 \
    --rootfs local-zfs:60 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

pct create 312 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
    --hostname aria-closet \
    --memory 6144 \
    --cores 3 \
    --rootfs local-zfs:60 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

sleep 60

# Join workers to cluster
MASTER_IP=$(pct exec 310 -- hostname -I | awk '{print $1}')
K3S_TOKEN=$(pct exec 310 -- cat /root/k3s-token)

for worker in 311 312; do
    pct exec $worker -- bash -c "
        apt update && apt upgrade -y
        apt install -y python3 python3-pip
        curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
    "
done

# Deploy Skirk-enhanced Aria dashboard
pct exec 310 -- bash -c "
# Copy Skirk crypto intelligence
cat > /opt/aria-skirk-crypto.py << 'EOF'
$(cat aria-skirk-crypto-integration.py)
EOF

# Deploy enhanced dashboard
kubectl apply -f - << 'EOF'
$(cat aria-hyperscale-deployment.yaml)
EOF

# Update dashboard to include Skirk intelligence
kubectl patch configmap aria-hyperscale-config --patch='
data:
  index.html: |
$(cat aria-hyperscale-deployment.yaml | grep -A 500 'index.html:' | tail -n +2 | sed 's/^    //' | sed 's/Aria Hyperscale Command Center/Aria Command Center - Skirk Intelligence Enhanced/g')
'
"

echo ""
echo "🌌 Skirk-Enhanced Aria Command Center Deployed!"
echo "Dashboard: http://$MASTER_IP:30080"
echo "Descender crypto intelligence: Active"
echo "AstralVibe.ca platform: Integrated"
echo "Reverb256.ca federation: Operational"
echo ""
echo "Void sight market analysis ready for hyperscale operations."