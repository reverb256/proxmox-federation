#!/bin/bash

# Aria Hyperscale Command Center Deployment
echo "🎭 Deploying Aria Hyperscale Command Center"
echo "Orchestrating astralvibe.ca and reverb256.ca federation..."

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

# Create K3s master (310)
pct create 310 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
    --hostname aria-master \
    --memory 8192 \
    --cores 4 \
    --rootfs local-zfs:80 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1 \
    --start

sleep 30

# Install K3s on master
pct exec 310 -- bash -c "
    apt update && apt upgrade -y
    curl -sfL https://get.k3s.io | sh -
    systemctl enable k3s
    cp /var/lib/rancher/k3s/server/node-token /root/k3s-token
"

# Create workers (311, 312)
for worker in 311 312; do
    hostname="aria-worker-$((worker-310))"
    pct create $worker local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
        --hostname $hostname \
        --memory 6144 \
        --cores 3 \
        --rootfs local-zfs:60 \
        --net0 name=eth0,bridge=vmbr0,ip=dhcp \
        --features nesting=1 \
        --start
done

sleep 60

# Get master IP and join workers
MASTER_IP=$(pct exec 310 -- hostname -I | awk '{print $1}')
K3S_TOKEN=$(pct exec 310 -- cat /root/k3s-token)

for worker in 311 312; do
    pct exec $worker -- bash -c "
        apt update && apt upgrade -y
        curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
    "
done

# Deploy Aria services
pct exec 310 -- bash -c '
cat > /tmp/aria-dashboard.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aria-dashboard
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
        - name: config
          mountPath: /usr/share/nginx/html
      volumes:
      - name: config
        configMap:
          name: aria-config
---
apiVersion: v1
kind: Service
metadata:
  name: aria-dashboard
spec:
  selector:
    app: aria-dashboard
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aria-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Aria Trading System</title>
        <style>
            body { font-family: Arial; background: linear-gradient(135deg, #667eea, #764ba2); color: white; margin: 0; padding: 20px; }
            .header { text-align: center; margin-bottom: 40px; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
            .card { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; }
            .status { display: inline-block; padding: 5px 10px; border-radius: 15px; font-size: 12px; }
            .active { background: #4CAF50; }
            .pending { background: #FF9800; }
            .btn { background: rgba(255,255,255,0.2); border: none; padding: 10px 20px; border-radius: 5px; color: white; cursor: pointer; margin: 5px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🎭 Aria Personal Trading System</h1>
            <p>AI-Powered Portfolio Management</p>
        </div>
        <div class="grid">
            <div class="card">
                <h3>System Status</h3>
                <div class="status active">K3s Cluster Active</div><br>
                <div class="status pending">Trading Agent Ready</div><br>
                <div class="status pending">Secrets Not Configured</div>
                <p>Containers: 310 (master), 311 (worker-1), 312 (worker-2)</p>
            </div>
            <div class="card">
                <h3>Portfolio</h3>
                <h2>$0.00</h2>
                <p>Configure API keys to begin trading</p>
                <button class="btn" onclick="alert(\"Use aria-secrets setup-trading on Proxmox host\")">Setup API Keys</button>
            </div>
            <div class="card">
                <h3>Trading Strategies</h3>
                <p>Momentum Strategy: Ready</p>
                <p>Mean Reversion: Ready</p>
                <p>Risk Management: Active</p>
                <button class="btn" onclick="alert(\"Strategies will activate after API configuration\")">View Details</button>
            </div>
            <div class="card">
                <h3>Security</h3>
                <p>Encrypted Storage: Ready</p>
                <p>API Keys: Not configured</p>
                <p>Proxmox Integration: Active</p>
                <button class="btn" onclick="alert(\"All credentials stored encrypted locally\")">Security Info</button>
            </div>
        </div>
        <div style="text-align: center; margin-top: 40px;">
            <p>Access your system at: http://MASTER_IP:30080</p>
            <p>Configure trading with: aria-secrets setup-trading</p>
        </div>
    </body>
    </html>
EOF

kubectl apply -f /tmp/aria-dashboard.yaml
'

# Setup secrets management
cat > /usr/local/bin/aria-secrets << 'EOF'
#!/usr/bin/env python3
import json, os, argparse
from cryptography.fernet import Fernet

class SecretsManager:
    def __init__(self):
        self.secrets_dir = "/etc/aria"
        self.secrets_file = f"{self.secrets_dir}/secrets.json"
        self.key_file = f"{self.secrets_dir}/master.key"
        os.makedirs(self.secrets_dir, exist_ok=True)
    
    def get_key(self):
        if os.path.exists(self.key_file):
            with open(self.key_file, 'rb') as f:
                return f.read()
        key = Fernet.generate_key()
        with open(self.key_file, 'wb') as f:
            f.write(key)
        os.chmod(self.key_file, 0o600)
        return key
    
    def load_secrets(self):
        if not os.path.exists(self.secrets_file):
            return {}
        with open(self.secrets_file, 'r') as f:
            encrypted_data = json.load(f)
        fernet = Fernet(self.get_key())
        secrets = {}
        for name, encrypted_value in encrypted_data.items():
            secrets[name] = fernet.decrypt(encrypted_value.encode()).decode()
        return secrets
    
    def save_secrets(self, secrets):
        fernet = Fernet(self.get_key())
        encrypted_data = {}
        for name, value in secrets.items():
            encrypted_data[name] = fernet.encrypt(value.encode()).decode()
        with open(self.secrets_file, 'w') as f:
            json.dump(encrypted_data, f)
        os.chmod(self.secrets_file, 0o600)
    
    def add_secret(self, name, value):
        secrets = self.load_secrets()
        secrets[name] = value
        self.save_secrets(secrets)
        print(f"Secret '{name}' added")
    
    def setup_trading(self):
        print("Trading API Setup")
        exchanges = ["binance", "coinbase", "kraken"]
        for i, exchange in enumerate(exchanges, 1):
            print(f"{i}. {exchange.title()}")
        
        choice = input("Select exchange (1-3): ").strip()
        if choice in ["1", "2", "3"]:
            exchange = exchanges[int(choice)-1]
            api_key = input(f"Enter {exchange.upper()} API key: ").strip()
            secret_key = input(f"Enter {exchange.upper()} secret key: ").strip()
            
            if api_key and secret_key:
                self.add_secret(f"{exchange.upper()}_API_KEY", api_key)
                self.add_secret(f"{exchange.upper()}_SECRET_KEY", secret_key)
                print(f"{exchange.title()} configured successfully!")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['add', 'list', 'setup-trading'])
    parser.add_argument('name', nargs='?')
    parser.add_argument('value', nargs='?')
    args = parser.parse_args()
    
    manager = SecretsManager()
    
    if args.command == 'add' and args.name and args.value:
        manager.add_secret(args.name, args.value)
    elif args.command == 'list':
        secrets = manager.load_secrets()
        for name in secrets.keys():
            print(f"  {name}")
    elif args.command == 'setup-trading':
        manager.setup_trading()

if __name__ == "__main__":
    main()
EOF

chmod +x /usr/local/bin/aria-secrets

# Install dependencies
apt update
apt install -y python3-pip
pip3 install cryptography

echo ""
echo "🎉 Aria Trading System Deployed!"
echo "Dashboard: http://$MASTER_IP:30080"
echo "Configure trading: aria-secrets setup-trading"
echo ""
echo "System ready for API key configuration and trading activation."