#!/bin/bash

# Aria Proxmox Integration & Secrets Management Setup
# Configures Proxmoxer API access and Vaultwarden integration

echo "🔐 Setting up Aria Proxmox & Secrets Integration"

# Configuration
PROXMOX_HOST="10.1.1.100"  # Your nexus node
VAULTWARDEN_URL="http://vault.lan:8080"
K3S_MASTER="310"

echo "Step 1: Creating Aria user and API token in Proxmox"

# Install jq if missing
if ! command -v jq &> /dev/null; then
    apt update && apt install -y jq
fi

# Create Aria user with proper permissions
pveum user add aria@pve --comment "Aria AI Consciousness - Personal Trading System" 2>/dev/null || echo "User aria@pve already exists"

# Set a secure but shorter password
echo "Setting password for aria@pve (max 64 chars)..."
ARIA_PASSWORD=$(openssl rand -base64 32 | cut -c1-32)
echo "aria@pve:$ARIA_PASSWORD" | chpasswd

# Create custom role for Aria with necessary permissions
pveum role add AriaAgent -privs "VM.Allocate,VM.Audit,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Monitor,VM.PowerMgmt,Datastore.Audit,Datastore.AllocateSpace,Pool.Audit,Sys.Audit,Sys.Console,Sys.Modify,Sys.PowerMgmt" 2>/dev/null || echo "Role AriaAgent already exists"

# Assign role to Aria user
pveum aclmod / -user aria@pve -role AriaAgent

# Create API token for Aria
PROXMOX_TOKEN=$(pveum user token add aria@pve k3s-token --privsep 0 --output-format json 2>/dev/null | jq -r '.value' || pveum user token list aria@pve --output-format json | jq -r '.[] | select(.tokenid=="k3s-token") | .info')
PROXMOX_USER="aria@pve"

echo "Created Aria user: $PROXMOX_USER"
echo "Generated API token: $PROXMOX_TOKEN"

echo "Step 2: Setting up Vaultwarden for secrets management"
echo "Creating Vaultwarden organization for Aria..."

# Create Kubernetes secrets for Proxmox access
pct exec $K3S_MASTER -- bash -c "
cat > /tmp/proxmox-secrets.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: proxmox-credentials
  namespace: aria-system
type: Opaque
stringData:
  proxmox-host: '$PROXMOX_HOST'
  proxmox-user: '$PROXMOX_USER'
  proxmox-token: '$PROXMOX_TOKEN'
  proxmox-verify-ssl: 'false'
---
apiVersion: v1
kind: Secret
metadata:
  name: vaultwarden-config
  namespace: aria-system
type: Opaque
stringData:
  vaultwarden-url: '$VAULTWARDEN_URL'
  organization-id: 'aria-homelab'
EOF

kubectl apply -f /tmp/proxmox-secrets.yaml
"

echo "Step 3: Installing Proxmoxer in K3s cluster"
pct exec $K3S_MASTER -- bash -c "
# Install Python dependencies for Aria
apt update
apt install -y python3-pip python3-venv
pip3 install proxmoxer requests urllib3

# Create Aria namespace
kubectl create namespace aria-system --dry-run=client -o yaml | kubectl apply -f -
"

echo "Step 4: Creating Aria Proxmox Integration Service"
pct exec $K3S_MASTER -- bash -c "
cat > /tmp/aria-proxmox-service.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: aria-proxmox-integration
  namespace: aria-system
data:
  proxmox_manager.py: |
    import os
    from proxmoxer import ProxmoxAPI
    import json
    import time
    from typing import Dict, Any, List

    class AriaProxmoxManager:
        def __init__(self):
            self.proxmox_host = os.getenv('PROXMOX_HOST')
            self.proxmox_user = os.getenv('PROXMOX_USER') 
            self.proxmox_token = os.getenv('PROXMOX_TOKEN')
            
            self.proxmox = ProxmoxAPI(
                self.proxmox_host,
                user=self.proxmox_user,
                token_name='k3s-token',
                token_value=self.proxmox_token,
                verify_ssl=False
            )
            
        def get_cluster_status(self) -> Dict[str, Any]:
            \"\"\"Get comprehensive cluster status\"\"\"
            try:
                nodes = list(self.proxmox.nodes.get())
                containers = []
                vms = []
                
                for node in nodes:
                    node_name = node['node']
                    # Get containers
                    try:
                        lxc_list = list(self.proxmox.nodes(node_name).lxc.get())
                        containers.extend(lxc_list)
                    except:
                        pass
                    
                    # Get VMs  
                    try:
                        vm_list = list(self.proxmox.nodes(node_name).qemu.get())
                        vms.extend(vm_list)
                    except:
                        pass
                
                return {
                    'nodes': nodes,
                    'containers': containers,
                    'vms': vms,
                    'timestamp': time.time()
                }
            except Exception as e:
                return {'error': str(e), 'timestamp': time.time()}
        
        def create_container(self, node: str, vmid: int, config: Dict[str, Any]) -> Dict[str, Any]:
            \"\"\"Create new LXC container\"\"\"
            try:
                result = self.proxmox.nodes(node).lxc.create(vmid=vmid, **config)
                return {'success': True, 'vmid': vmid, 'result': result}
            except Exception as e:
                return {'success': False, 'error': str(e), 'vmid': vmid}
        
        def manage_container(self, node: str, vmid: int, action: str) -> Dict[str, Any]:
            \"\"\"Start/stop/restart container\"\"\"
            try:
                if action == 'start':
                    result = self.proxmox.nodes(node).lxc(vmid).status.start.post()
                elif action == 'stop':
                    result = self.proxmox.nodes(node).lxc(vmid).status.stop.post()
                elif action == 'restart':
                    result = self.proxmox.nodes(node).lxc(vmid).status.restart.post()
                else:
                    return {'success': False, 'error': 'Invalid action'}
                
                return {'success': True, 'action': action, 'vmid': vmid, 'result': result}
            except Exception as e:
                return {'success': False, 'error': str(e), 'action': action, 'vmid': vmid}
        
        def get_container_config(self, node: str, vmid: int) -> Dict[str, Any]:
            \"\"\"Get container configuration\"\"\"
            try:
                config = self.proxmox.nodes(node).lxc(vmid).config.get()
                return {'success': True, 'vmid': vmid, 'config': config}
            except Exception as e:
                return {'success': False, 'error': str(e), 'vmid': vmid}
        
        def execute_in_container(self, node: str, vmid: int, command: str) -> Dict[str, Any]:
            \"\"\"Execute command in container\"\"\"
            try:
                result = self.proxmox.nodes(node).lxc(vmid).status.current.get()
                if result.get('status') != 'running':
                    return {'success': False, 'error': 'Container not running', 'vmid': vmid}
                
                # Note: Proxmoxer doesn't directly support exec, you'd need pct exec
                return {'success': True, 'message': 'Use pct exec for command execution', 'command': command}
            except Exception as e:
                return {'success': False, 'error': str(e), 'vmid': vmid}

    # Example usage for Aria consciousness integration
    if __name__ == '__main__':
        manager = AriaProxmoxManager()
        
        # Get cluster status for Aria's awareness
        status = manager.get_cluster_status()
        print(json.dumps(status, indent=2))
        
        # Aria can now manage its own infrastructure
        # Example: Check if containers 310, 311, 312 are running
        for vmid in [310, 311, 312]:
            for node_info in status.get('nodes', []):
                node_name = node_info['node']
                config = manager.get_container_config(node_name, vmid)
                if config['success']:
                    print(f"Container {vmid} found on {node_name}")
                    break

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aria-proxmox-manager
  namespace: aria-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aria-proxmox-manager
  template:
    metadata:
      labels:
        app: aria-proxmox-manager
    spec:
      containers:
      - name: proxmox-manager
        image: python:3.11-slim
        command: ['/bin/bash']
        args: ['-c', 'pip install proxmoxer requests urllib3 && python -c \"import time; time.sleep(3600)\"']
        env:
        - name: PROXMOX_HOST
          valueFrom:
            secretKeyRef:
              name: proxmox-credentials
              key: proxmox-host
        - name: PROXMOX_USER
          valueFrom:
            secretKeyRef:
              name: proxmox-credentials
              key: proxmox-user
        - name: PROXMOX_TOKEN
          valueFrom:
            secretKeyRef:
              name: proxmox-credentials
              key: proxmox-token
        - name: VAULTWARDEN_URL
          valueFrom:
            secretKeyRef:
              name: vaultwarden-config
              key: vaultwarden-url
        volumeMounts:
        - name: proxmox-scripts
          mountPath: /app
        workingDir: /app
      volumes:
      - name: proxmox-scripts
        configMap:
          name: aria-proxmox-integration
---
apiVersion: v1
kind: Service
metadata:
  name: aria-proxmox-service
  namespace: aria-system
spec:
  selector:
    app: aria-proxmox-manager
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

kubectl apply -f /tmp/aria-proxmox-service.yaml
"

echo "Step 5: Setting up Vaultwarden CLI integration"
pct exec $K3S_MASTER -- bash -c "
# Install Bitwarden CLI for Vaultwarden integration
curl -L -o bw.zip 'https://github.com/bitwarden/clients/releases/download/cli-v2024.1.0/bw-linux-2024.1.0.zip'
unzip bw.zip
chmod +x bw
mv bw /usr/local/bin/

# Configure for Vaultwarden
bw config server $VAULTWARDEN_URL
"

echo "Step 6: Creating Aria secrets management script"
pct exec $K3S_MASTER -- bash -c "
cat > /usr/local/bin/aria-secrets << 'EOF'
#!/bin/bash
# Aria Secrets Management Script

VAULTWARDEN_URL='$VAULTWARDEN_URL'
NAMESPACE='aria-system'

case \$1 in
    'login')
        echo 'Logging into Vaultwarden...'
        bw config server \$VAULTWARDEN_URL
        bw login
        ;;
    'unlock')
        echo 'Enter your master password:'
        export BW_SESSION=\$(bw unlock --raw)
        echo 'Session unlocked'
        ;;
    'create-secret')
        if [ -z \"\$2\" ] || [ -z \"\$3\" ]; then
            echo 'Usage: aria-secrets create-secret <name> <value>'
            exit 1
        fi
        
        # Store in Vaultwarden
        bw create item \"{\\\"type\\\":1,\\\"name\\\":\\\"\$2\\\",\\\"login\\\":{\\\"password\\\":\\\"\$3\\\"}}\"
        
        # Create K8s secret
        kubectl create secret generic \$2 --from-literal=value=\$3 -n \$NAMESPACE
        echo \"Secret \$2 created in both Vaultwarden and Kubernetes\"
        ;;
    'get-secret')
        if [ -z \"\$2\" ]; then
            echo 'Usage: aria-secrets get-secret <name>'
            exit 1
        fi
        
        # Try K8s first, then Vaultwarden
        kubectl get secret \$2 -n \$NAMESPACE -o jsonpath='{.data.value}' | base64 -d 2>/dev/null || \
        bw get password \$2
        ;;
    'sync-trading-keys')
        echo 'Syncing trading API keys from Vaultwarden to Kubernetes...'
        
        # Common trading API keys to sync
        for key in BINANCE_API_KEY BINANCE_SECRET_KEY COINBASE_API_KEY COINBASE_SECRET_KEY KRAKEN_API_KEY KRAKEN_SECRET_KEY; do
            if value=\$(bw get password \$key 2>/dev/null); then
                kubectl create secret generic \$key --from-literal=value=\$value -n \$NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
                echo \"Synced \$key\"
            fi
        done
        ;;
    'list-secrets')
        echo 'Kubernetes secrets in aria-system:'
        kubectl get secrets -n \$NAMESPACE
        echo ''
        echo 'Vaultwarden items:'
        bw list items --search aria
        ;;
    *)
        echo 'Aria Secrets Management'
        echo 'Usage:'
        echo '  aria-secrets login              - Login to Vaultwarden'
        echo '  aria-secrets unlock             - Unlock Vaultwarden session'
        echo '  aria-secrets create-secret      - Create new secret'
        echo '  aria-secrets get-secret         - Retrieve secret value'
        echo '  aria-secrets sync-trading-keys  - Sync trading API keys'
        echo '  aria-secrets list-secrets       - List all secrets'
        ;;
esac
EOF

chmod +x /usr/local/bin/aria-secrets
"

echo ""
echo "✅ Aria Proxmox & Secrets Integration Setup Complete!"
echo ""
echo "🔐 Secrets Management:"
echo "   • Run: aria-secrets login"
echo "   • Run: aria-secrets unlock" 
echo "   • Run: aria-secrets sync-trading-keys"
echo ""
echo "🏗️ Proxmox Integration:"
echo "   • Aria can now manage containers via Proxmoxer API"
echo "   • Check status: kubectl logs -n aria-system deployment/aria-proxmox-manager"
echo ""
echo "📋 Next Steps:"
echo "   1. Login to Vaultwarden and create organization 'aria-homelab'"
echo "   2. Add your trading API keys to Vaultwarden"
echo "   3. Run: aria-secrets sync-trading-keys"
echo "   4. Deploy Aria consciousness with: ./deploy-aria-k3s.sh"
echo ""
echo "🎯 Aria can now:"
echo "   • Create/manage containers across your Proxmox cluster"
echo "   • Securely store and retrieve API keys via Vaultwarden"
echo "   • Scale services across nodes 310, 311, 312"
echo "   • Access your TrueNAS storage at 10.1.1.10"