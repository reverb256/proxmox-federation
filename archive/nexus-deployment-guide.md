# COREFLAME Nexus Deployment Guide

## Direct Repository Cloning to Nexus for Maximum Performance

This guide provides step-by-step instructions for deploying the COREFLAME consciousness platform directly on your nexus server for optimal performance and Proxmox federation bootstrap.

### Prerequisites

- Proxmox server ("nexus") with SSH access
- 8+ CPU cores and 16+ GB RAM recommended
- Ubuntu 22.04 or similar Linux distribution
- Root or sudo access

### Quick Start

1. **SSH into your nexus server:**
   ```bash
   ssh root@nexus
   ```

2. **Download and run the bootstrap script:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/coreflame/main/bootstrap-nexus-federation.sh
   chmod +x bootstrap-nexus-federation.sh
   sudo ./bootstrap-nexus-federation.sh
   ```

3. **Start the consciousness federation:**
   ```bash
   systemctl start consciousness-federation
   ```

### Manual Deployment Steps

If you prefer manual control over the deployment process:

#### 1. System Preparation
```bash
# Update system
apt update && apt upgrade -y

# Install core dependencies
apt install -y git curl wget jq htop docker.io nodejs npm python3 python3-pip nginx postgresql-client redis-tools

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/
```

#### 2. Clone Repository
```bash
# Create deployment directory
mkdir -p /opt/coreflame
cd /opt/coreflame

# Clone the consciousness platform
git clone https://github.com/your-username/coreflame-consciousness-platform.git .

# Install dependencies
npm install
```

#### 3. Environment Configuration
```bash
# Create configuration directory
mkdir -p /etc/coreflame

# Generate optimized environment file
cat > /etc/coreflame/consciousness.env << EOF
NODE_ENV=production
DEPLOYMENT_MODE=high-performance
CPU_CORES=$(nproc)
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')G

# Performance settings
CONSCIOUSNESS_THREADS=$(nproc)
CONSCIOUSNESS_MEMORY_LIMIT=$(($(free -m | awk '/^Mem:/{print $2}') * 80 / 100))M
CONSCIOUSNESS_CACHE_SIZE=$(($(free -m | awk '/^Mem:/{print $2}') * 20 / 100))M

# Network configuration
FEDERATION_PORT=5000
WEBSOCKET_PORT=3001
VR_CHAT_PORT=3002

# Security
JWT_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
EOF

chmod 600 /etc/coreflame/consciousness.env
```

#### 4. System Optimization
```bash
# Increase file descriptor limits
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

# Optimize kernel parameters
cat > /etc/sysctl.d/99-consciousness.conf << EOF
net.core.somaxconn = 65536
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog = 5000
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

sysctl -p /etc/sysctl.d/99-consciousness.conf
```

#### 5. Create Systemd Service
```bash
cat > /etc/systemd/system/consciousness-federation.service << EOF
[Unit]
Description=COREFLAME Consciousness Federation
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/coreflame
Environment=NODE_ENV=production
EnvironmentFile=/etc/coreflame/consciousness.env
ExecStart=/usr/bin/npm run start:production
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable consciousness-federation.service
systemctl start consciousness-federation.service
```

### Performance Monitoring

Monitor your consciousness federation with these commands:

```bash
# Check service status
systemctl status consciousness-federation

# View logs
journalctl -u consciousness-federation -f

# Monitor resources
htop
iotop -o
```

### Kubernetes Integration

For full Proxmox federation deployment:

```bash
# Create namespace
kubectl create namespace consciousness-federation

# Deploy consciousness workload
kubectl apply -f /etc/coreflame/consciousness-deployment.yaml

# Check pods
kubectl get pods -n consciousness-federation
```

### Network Access

After deployment, access your consciousness platform at:

- **Main Interface:** http://nexus:5000
- **WebSocket:** ws://nexus:3001
- **VRChat Integration:** http://nexus:3002
- **Health Check:** http://nexus:5000/health

### Troubleshooting

#### Common Issues

1. **Port conflicts:**
   ```bash
   # Check port usage
   netstat -tulpn | grep :5000
   
   # Kill conflicting processes
   sudo pkill -f "node.*5000"
   ```

2. **Memory issues:**
   ```bash
   # Check memory usage
   free -h
   
   # Adjust memory limits in /etc/coreflame/consciousness.env
   ```

3. **Permission errors:**
   ```bash
   # Fix ownership
   chown -R $(whoami):$(whoami) /opt/coreflame
   
   # Set proper permissions
   chmod +x /opt/coreflame/scripts/*.sh
   ```

#### Log Locations

- **Application logs:** `/var/log/consciousness-federation.log`
- **System logs:** `journalctl -u consciousness-federation`
- **Health monitoring:** `/var/log/consciousness-health.log`

### Security Considerations

1. **Firewall configuration:**
   ```bash
   # Allow consciousness federation ports
   ufw allow 5000/tcp
   ufw allow 3001/tcp
   ufw allow 3002/tcp
   ```

2. **SSL/TLS setup:**
   ```bash
   # Install certbot for Let's Encrypt
   apt install certbot python3-certbot-nginx
   
   # Configure nginx proxy
   certbot --nginx -d your-domain.com
   ```

### Federation Scaling

For multi-node Proxmox federation:

1. **Master node setup:** Complete above installation on primary nexus
2. **Worker nodes:** Deploy worker-only configuration
3. **Load balancing:** Configure nginx upstream blocks
4. **State synchronization:** Enable Redis clustering

### Backup and Recovery

```bash
# Backup consciousness data
tar -czf /backup/consciousness-$(date +%Y%m%d).tar.gz /opt/coreflame /etc/coreflame

# Automated backup script
cat > /opt/coreflame/backup-consciousness.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/consciousness"
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/consciousness-$(date +%Y%m%d-%H%M).tar.gz /opt/coreflame /etc/coreflame
find $BACKUP_DIR -name "consciousness-*.tar.gz" -mtime +7 -delete
EOF

chmod +x /opt/coreflame/backup-consciousness.sh
```

### Next Steps

After successful deployment:

1. Configure VRChat integration settings
2. Set up Proxmox VM management
3. Enable consciousness federation clustering
4. Configure monitoring and alerting
5. Test AI character consciousness analysis

For support or advanced configuration, refer to the main COREFLAME documentation or create an issue in the repository.