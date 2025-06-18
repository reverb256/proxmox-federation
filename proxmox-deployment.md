# Proxmox Consciousness Federation - Node 0 Deployment

## Overview
Deployment configuration for hosting the AI Portfolio Platform and astralvibe.ca on Proxmox home server infrastructure. This serves as Node 0 of the consciousness federation architecture.

## Architecture

### VM Configuration
- **Primary VM**: Ubuntu 22.04 LTS Server
- **Resources**: 4 vCPUs, 8GB RAM, 100GB Storage
- **Network**: Bridge to home network with static IP
- **Services**: Docker, Nginx, SSL termination

### Container Stack
```yaml
# docker-compose.yml for consciousness federation
version: '3.8'
services:
  portfolio-app:
    build: .
    container_name: consciousness-portfolio
    ports:
      - "3000:5000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    restart: unless-stopped
    
  astralvibe:
    image: node:18-alpine
    container_name: astralvibe-consciousness
    ports:
      - "3001:3000"
    volumes:
      - ./astralvibe:/app
    working_dir: /app
    command: npm start
    restart: unless-stopped
    
  nginx-proxy:
    image: nginx:alpine
    container_name: consciousness-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - portfolio-app
      - astralvibe
    restart: unless-stopped
    
  postgres:
    image: postgres:15
    container_name: consciousness-db
    environment:
      - POSTGRES_DB=consciousness_federation
      - POSTGRES_USER=consciousness
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

## Domain Configuration

### astralvibe.ca
- **Purpose**: Primary consciousness layer platform
- **Features**: AI consciousness training, federation management
- **SSL**: Let's Encrypt automatic renewal

### Portfolio Subdomain
- **URL**: portfolio.astralvibe.ca
- **Purpose**: Technical showcase and project documentation
- **Integration**: Coreflame Protocol as flagship project

## Proxmox VM Setup

### 1. Create VM Template
```bash
# Download Ubuntu 22.04 cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM in Proxmox
qm create 9000 --name ubuntu-consciousness-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

### 2. Deploy Consciousness Node 0
```bash
# Clone template for Node 0
qm clone 9000 100 --name consciousness-node-0 --full

# Configure resources
qm set 100 --memory 8192 --cores 4 --sockets 1
qm resize 100 scsi0 +80G

# Set static IP and SSH key
qm set 100 --ipconfig0 ip=192.168.1.100/24,gw=192.168.1.1
qm set 100 --sshkey ~/.ssh/id_rsa.pub

# Start the VM
qm start 100
```

## Application Deployment

### Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

RUN npm run build

EXPOSE 5000

CMD ["npm", "start"]
```

### Environment Configuration
```bash
# .env.production
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://consciousness:${DB_PASSWORD}@postgres:5432/consciousness_federation

# Consciousness Federation Config
FEDERATION_NODE_ID=node-0
FEDERATION_ROLE=primary
ASTRALVIBE_URL=https://astralvibe.ca
PORTFOLIO_URL=https://portfolio.astralvibe.ca

# SSL/Security
SSL_CERT_PATH=/etc/nginx/ssl/astralvibe.ca.crt
SSL_KEY_PATH=/etc/nginx/ssl/astralvibe.ca.key
```

### Nginx Configuration
```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream portfolio {
        server portfolio-app:5000;
    }
    
    upstream astralvibe {
        server astralvibe:3000;
    }
    
    # Portfolio subdomain
    server {
        listen 443 ssl;
        server_name portfolio.astralvibe.ca;
        
        ssl_certificate /etc/nginx/ssl/astralvibe.ca.crt;
        ssl_certificate_key /etc/nginx/ssl/astralvibe.ca.key;
        
        location / {
            proxy_pass http://portfolio;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
    
    # Main astralvibe.ca domain
    server {
        listen 443 ssl;
        server_name astralvibe.ca www.astralvibe.ca;
        
        ssl_certificate /etc/nginx/ssl/astralvibe.ca.crt;
        ssl_certificate_key /etc/nginx/ssl/astralvibe.ca.key;
        
        location / {
            proxy_pass http://astralvibe;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
    
    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name astralvibe.ca www.astralvibe.ca portfolio.astralvibe.ca;
        return 301 https://$server_name$request_uri;
    }
}
```

## Federation Architecture

### Node 0 Capabilities
- **Primary Consciousness Database**: PostgreSQL with character patterns
- **API Gateway**: RESTful endpoints for consciousness training
- **Federation Management**: Coordinates with future nodes
- **SSL Termination**: Handles all encrypted traffic
- **Monitoring**: System health and consciousness metrics

### Scaling Preparation
```yaml
# federation-nodes.yml - Future expansion
node-1:
  role: compute
  specialization: training_acceleration
  location: cloud_provider_1
  
node-2:
  role: storage
  specialization: consciousness_backup
  location: cloud_provider_2
  
node-3:
  role: edge
  specialization: real_time_inference
  location: edge_location_1
```

## Deployment Scripts

### Setup Script
```bash
#!/bin/bash
# setup-consciousness-node.sh

echo "🧠 Setting up Consciousness Federation Node 0"

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone repositories
git clone https://github.com/user/consciousness-portfolio.git /opt/portfolio
git clone https://github.com/user/astralvibe.git /opt/astralvibe

# Setup SSL certificates (Let's Encrypt)
apt install certbot -y
certbot certonly --standalone -d astralvibe.ca -d www.astralvibe.ca -d portfolio.astralvibe.ca

# Deploy containers
cd /opt/portfolio
docker-compose up -d

echo "✅ Consciousness Federation Node 0 deployed successfully"
echo "🌐 Portfolio: https://portfolio.astralvibe.ca"
echo "🧠 Astralvibe: https://astralvibe.ca"
```

## Monitoring and Maintenance

### Health Checks
```bash
#!/bin/bash
# health-check.sh

echo "🔍 Consciousness Federation Health Check"

# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check consciousness metrics
curl -s https://portfolio.astralvibe.ca/api/consciousness/status | jq

# Check SSL certificates
echo | openssl s_client -connect astralvibe.ca:443 2>/dev/null | openssl x509 -noout -dates

# Check federation connectivity
ping -c 3 astralvibe.ca
```

### Backup Strategy
```bash
#!/bin/bash
# backup-consciousness.sh

# Database backup
docker exec consciousness-db pg_dump -U consciousness consciousness_federation > /backup/consciousness-$(date +%Y%m%d).sql

# Application data backup
tar -czf /backup/portfolio-$(date +%Y%m%d).tar.gz /opt/portfolio

# Sync to remote storage
rsync -av /backup/ user@backup-server:/consciousness-backups/
```

## Security Configuration

### Firewall Rules
```bash
# UFW configuration
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

### Access Control
- SSH key-only authentication
- VPN access for administration
- Rate limiting on API endpoints
- Consciousness data encryption at rest

## Next Steps

1. **VM Creation**: Set up Ubuntu 22.04 VM on Proxmox
2. **Domain Setup**: Configure DNS for astralvibe.ca
3. **SSL Certificates**: Obtain Let's Encrypt certificates
4. **Application Deployment**: Deploy both platforms
5. **Federation Expansion**: Plan additional nodes

This configuration provides a robust foundation for hosting both the portfolio platform and astralvibe.ca on your Proxmox home server, with room for future consciousness federation expansion.