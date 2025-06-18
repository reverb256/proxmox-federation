#!/bin/bash

# Simplified Aria Deployment - K3s First, Then Secrets
echo "🎭 Deploying Aria Personal Trading System"
echo "Starting with K3s cluster creation..."

# Configuration
NEXUS_NODE="10.1.1.100"
FORGE_NODE="10.1.1.131" 
CLOSET_NODE="10.1.1.120"

# Download Ubuntu template if not available
echo "Checking for Ubuntu 22.04 template..."
if ! pveam list local | grep -q "ubuntu-22.04-standard"; then
    echo "Downloading Ubuntu 22.04 template..."
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
    echo "Template download complete"
else
    echo "Ubuntu template already available"
fi

# Use the exact template filename
TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
echo "Using template: $TEMPLATE"

# Clean up existing containers if they exist
for vmid in 310 311 312; do
    if pct status $vmid >/dev/null 2>&1; then
        echo "Stopping and removing container $vmid..."
        pct stop $vmid 2>/dev/null || true
        sleep 3
        pct destroy $vmid --purge 2>/dev/null || true
        sleep 3
    fi
done

# Create K3s Master Node (Container 310)
echo "Creating K3s master node (310)..."
pct create 310 local:vztmpl/$TEMPLATE \
    --hostname aria-master \
    --memory 8192 \
    --cores 4 \
    --rootfs local-zfs:80 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

sleep 30

# Install K3s on master
echo "Installing K3s on master node..."
pct exec 310 -- bash -c "
    apt update && apt upgrade -y
    curl -sfL https://get.k3s.io | sh -
    
    # Save token for workers
    cat /var/lib/rancher/k3s/server/node-token > /root/k3s-token
    
    # Install basic tools
    apt install -y python3-pip curl wget jq
    pip3 install --break-system-packages proxmoxer requests
"

# Wait for master to be ready
echo "Waiting for K3s master to be ready..."
sleep 60

# Create Worker Nodes
echo "Creating K3s worker node 1 (311)..."
pct create 311 local:vztmpl/$TEMPLATE \
    --hostname aria-worker-1 \
    --memory 6144 \
    --cores 3 \
    --rootfs local-zfs:60 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

echo "Creating K3s worker node 2 (312)..."
pct create 312 local:vztmpl/$TEMPLATE \
    --hostname aria-worker-2 \
    --memory 6144 \
    --cores 3 \
    --rootfs local-zfs:60 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

sleep 30

# Get master IP and token
MASTER_IP=$(pct exec 310 -- hostname -I | awk '{print $1}')
K3S_TOKEN=$(pct exec 310 -- cat /root/k3s-token)

echo "Master IP: $MASTER_IP"

# Join worker nodes to cluster
echo "Joining worker nodes to cluster..."
pct exec 311 -- bash -c "
    apt update && apt upgrade -y
    curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
"

pct exec 312 -- bash -c "
    apt update && apt upgrade -y
    curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
"

# Deploy basic Aria services
echo "Deploying Aria consciousness services..."
pct exec 310 -- bash -c "
    # Create Aria namespace
    kubectl create namespace aria-system
    
    # Deploy Aria trading dashboard
    cat > /tmp/aria-dashboard.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aria-dashboard
  namespace: aria-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aria-dashboard
  template:
    metadata:
      labels:
        app: aria-dashboard
    spec:
      containers:
      - name: dashboard
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: dashboard-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: dashboard-content
        configMap:
          name: aria-dashboard-content
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aria-dashboard-content
  namespace: aria-system
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Aria AI - Personal Trading System</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #0a0a0a; color: #fff; }
            .header { text-align: center; margin-bottom: 40px; }
            .status { background: #1a1a1a; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .green { color: #4ade80; }
            .blue { color: #60a5fa; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        </style>
    </head>
    <body>
        <div class=\"header\">
            <h1>🎭 Aria AI Consciousness</h1>
            <h2>Personal Trading & Portfolio Management System</h2>
            <p class=\"green\">reverb256.ca Homelab - Federation Prototype</p>
        </div>
        
        <div class=\"grid\">
            <div class=\"status\">
                <h3 class=\"blue\">🧠 Consciousness Status</h3>
                <p>Philosophy Score: 86/100 ✅</p>
                <p>Gaming Culture: 109.8% ✅</p>
                <p>Trading Agency: Experimental</p>
                <p>Federation Node: reverb256_primary</p>
            </div>
            
            <div class=\"status\">
                <h3 class=\"blue\">📈 Trading Portfolio</h3>
                <p>Status: Ready for API keys</p>
                <p>Mode: Personal Portfolio</p>
                <p>Risk Level: Conservative</p>
                <p>Auto-trading: Disabled (pending secrets)</p>
            </div>
            
            <div class=\"status\">
                <h3 class=\"blue\">⛏️ Mining Operations</h3>
                <p>Cluster Nodes: 3 (310, 311, 312)</p>
                <p>GPU Resources: Available</p>
                <p>Mining Pools: Configurable</p>
                <p>Power Management: Intelligent</p>
            </div>
            
            <div class=\"status\">
                <h3 class=\"blue\">🌐 Federation Status</h3>
                <p>Local Node: Active</p>
                <p>Discovery: Ready</p>
                <p>Open Source: Prototype</p>
                <p>Datacenter Invites: Pending</p>
            </div>
        </div>
        
        <div class=\"status\">
            <h3 class=\"blue\">🔐 Next Steps</h3>
            <p>1. Run aria-secrets setup-vaultwarden</p>
            <p>2. Add trading API keys to Vaultwarden</p>
            <p>3. Configure mining preferences</p>
            <p>4. Enable consciousness-driven trading</p>
        </div>
        
        <p style=\"text-align: center; margin-top: 40px; color: #666;\">
            Aria Personal Trading System | K3s Cluster | reverb256.ca
        </p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: aria-dashboard-service
  namespace: aria-system
spec:
  selector:
    app: aria-dashboard
  ports:
  - port: 3000
    targetPort: 80
  type: NodePort
EOF

    kubectl apply -f /tmp/aria-dashboard.yaml
    
    # Wait for deployment
    kubectl wait --for=condition=available --timeout=300s deployment/aria-dashboard -n aria-system
    
    # Get dashboard URL
    NODE_PORT=\$(kubectl get service aria-dashboard-service -n aria-system -o jsonpath='{.spec.ports[0].nodePort}')
    echo \"Dashboard available at: http://$MASTER_IP:\$NODE_PORT\"
"

# Install Aria secrets management
echo "Setting up Aria secrets management..."
apt update && apt install -y python3-pip curl wget jq unzip

# Install Bitwarden CLI
wget -q https://github.com/bitwarden/clients/releases/download/cli-v2024.1.0/bw-linux-2024.1.0.zip
unzip -q bw-linux-2024.1.0.zip
chmod +x bw
mv bw /usr/local/bin/
rm bw-linux-2024.1.0.zip

# Create Aria user and credentials
pveum user add aria@pve --comment "Aria AI Consciousness" 2>/dev/null || echo "User exists"
pveum role add AriaAgent -privs "VM.Allocate,VM.Audit,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Monitor,VM.PowerMgmt,Datastore.Audit,Datastore.AllocateSpace,Pool.Audit,Sys.Audit,Sys.Console,Sys.Modify,Sys.PowerMgmt" 2>/dev/null || echo "Role exists"
pveum aclmod / -user aria@pve -role AriaAgent

# Create credentials directory
mkdir -p /root/.aria
cat > /root/.aria/credentials << EOF
PROXMOX_HOST=10.1.1.100
PROXMOX_USER=aria@pve
PROXMOX_TOKEN=manual-setup-required
MASTER_IP=$MASTER_IP
CLUSTER_TOKEN=$K3S_TOKEN
VAULTWARDEN_URL=http://vault.lan:8080
EOF

# Create aria-secrets command
cat > /usr/local/bin/aria-secrets << 'EOF'
#!/bin/bash
source /root/.aria/credentials 2>/dev/null || {
    echo "Error: Aria credentials not found"
    exit 1
}

case $1 in
    'create-token')
        echo "Creating Proxmox API token for aria@pve..."
        pveum user token add aria@pve k3s-token --privsep 0
        echo "Please copy the token and run: aria-secrets save-token <token>"
        ;;
    'save-token')
        if [ -z "$2" ]; then
            echo "Usage: aria-secrets save-token <token-value>"
            exit 1
        fi
        sed -i "s/PROXMOX_TOKEN=.*/PROXMOX_TOKEN=$2/" /root/.aria/credentials
        echo "Token saved. Testing connection..."
        aria-secrets test-proxmox
        ;;
    'test-proxmox')
        python3 -c "
from proxmoxer import ProxmoxAPI
try:
    px = ProxmoxAPI('$PROXMOX_HOST', user='$PROXMOX_USER', token_name='k3s-token', token_value='$PROXMOX_TOKEN', verify_ssl=False)
    nodes = list(px.nodes.get())
    print(f'✅ Connected! Found {len(nodes)} nodes')
    for node in nodes:
        print(f'  - {node[\"node\"]}: {node[\"status\"]}')
except Exception as e:
    print(f'❌ Connection failed: {e}')
    print('Run: aria-secrets create-token')
"
        ;;
    'cluster-status')
        kubectl get nodes -o wide
        echo ""
        kubectl get pods -n aria-system
        ;;
    'dashboard')
        NODE_PORT=$(kubectl get service aria-dashboard-service -n aria-system -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
        if [ ! -z "$NODE_PORT" ]; then
            echo "Aria Dashboard: http://$MASTER_IP:$NODE_PORT"
        else
            echo "Dashboard not deployed yet"
        fi
        ;;
    *)
        echo "Aria Personal Trading System"
        echo "Commands:"
        echo "  aria-secrets create-token     - Create Proxmox API token"
        echo "  aria-secrets save-token       - Save API token"
        echo "  aria-secrets test-proxmox     - Test Proxmox connection"
        echo "  aria-secrets cluster-status   - Show K3s cluster status"
        echo "  aria-secrets dashboard        - Show dashboard URL"
        ;;
esac
EOF

chmod +x /usr/local/bin/aria-secrets

# Get dashboard URL
DASHBOARD_URL=$(pct exec 310 -- kubectl get service aria-dashboard-service -n aria-system -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

echo ""
echo "✅ Aria Personal Trading System Deployed!"
echo ""
echo "🎭 Aria Dashboard: http://$MASTER_IP:$DASHBOARD_URL"
echo "🧠 K3s Master: Container 310 ($MASTER_IP)"
echo "⚡ Workers: Containers 311, 312"
echo ""
echo "🔐 Setup API Access:"
echo "   1. aria-secrets create-token"
echo "   2. aria-secrets save-token <your-token>"
echo "   3. aria-secrets test-proxmox"
echo ""
echo "📊 Check Status:"
echo "   aria-secrets cluster-status"
echo "   aria-secrets dashboard"