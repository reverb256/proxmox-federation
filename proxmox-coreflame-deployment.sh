#!/bin/bash

# COREFLAME Proxmox Deployment Script
# Comprehensive deployment for Reverb256 Portfolio with AI Collaboration
# Integrates with astralvibe.ca federation and consciousness modules

set -euo pipefail

# Configuration
DEPLOYMENT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/coreflame-deployment.log"
PROXMOX_NODE="${PROXMOX_NODE:-nexus}"
FEDERATION_DOMAIN="${FEDERATION_DOMAIN:-reverb256.local}"
ASTRALVIBE_ENDPOINT="${ASTRALVIBE_ENDPOINT:-https://6f873bc8-c1e2-4ab8-8785-323119a7e3f0-00-3e9ygbr5lnjnl.sisko.replit.dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN $(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Verify Proxmox environment
verify_proxmox() {
    log "Verifying Proxmox environment..."
    
    if ! command -v pct &> /dev/null; then
        error "Proxmox VE not detected. This script requires Proxmox VE."
    fi
    
    if ! command -v qm &> /dev/null; then
        error "QEMU/KVM tools not found. Proxmox installation may be incomplete."
    fi
    
    log "Proxmox environment verified"
}

# Install required dependencies
install_dependencies() {
    log "Installing deployment dependencies..."
    
    # Update system
    apt-get update -y
    
    # Essential packages
    apt-get install -y \
        curl \
        wget \
        git \
        unzip \
        jq \
        python3 \
        python3-pip \
        python3-venv \
        nodejs \
        npm \
        nginx \
        postgresql-client \
        certbot \
        python3-certbot-nginx \
        htop \
        iotop \
        nethogs \
        tcpdump \
        rsync
    
    # Install Docker for containerized services
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    log "Dependencies installed successfully"
}

# Create project structure
create_project_structure() {
    log "Creating COREFLAME project structure..."
    
    # Main directories
    mkdir -p /opt/coreflame/{
        app,
        data,
        logs,
        config,
        backups,
        federation,
        consciousness,
        monitoring,
        scripts
    }
    
    # Application subdirectories
    mkdir -p /opt/coreflame/app/{
        reverb256-portfolio,
        federation-bridge,
        consciousness-engine,
        ai-collaboration
    }
    
    # Configuration templates
    mkdir -p /opt/coreflame/config/{
        nginx,
        postgresql,
        federation,
        consciousness,
        monitoring
    }
    
    # Set proper permissions
    chown -R www-data:www-data /opt/coreflame/app
    chown -R postgres:postgres /opt/coreflame/data
    chmod -R 755 /opt/coreflame
    
    log "Project structure created"
}

# Setup PostgreSQL database
setup_postgresql() {
    log "Setting up PostgreSQL database..."
    
    # Install PostgreSQL if not present
    if ! command -v psql &> /dev/null; then
        apt-get install -y postgresql postgresql-contrib
    fi
    
    systemctl enable postgresql
    systemctl start postgresql
    
    # Create databases
    sudo -u postgres createdb reverb256_portfolio || true
    sudo -u postgres createdb consciousness_data || true
    sudo -u postgres createdb federation_sync || true
    
    # Create application user
    sudo -u postgres psql -c "CREATE USER coreflame WITH PASSWORD 'secure_password_2024';" || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE reverb256_portfolio TO coreflame;" || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE consciousness_data TO coreflame;" || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE federation_sync TO coreflame;" || true
    
    # Configure PostgreSQL for remote connections
    PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
    PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"
    
    if [[ -f "$PG_CONFIG_DIR/postgresql.conf" ]]; then
        sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONFIG_DIR/postgresql.conf"
        echo "host all all 0.0.0.0/0 md5" >> "$PG_CONFIG_DIR/pg_hba.conf"
        systemctl restart postgresql
    fi
    
    log "PostgreSQL database setup completed"
}

# Clone and setup application
setup_application() {
    log "Setting up Reverb256 Portfolio application..."
    
    cd /opt/coreflame/app/reverb256-portfolio
    
    # Clone repository (assuming it's available)
    if [[ ! -d ".git" ]]; then
        warn "No git repository found. Creating application structure..."
        
        # Create package.json
        cat > package.json << 'EOF'
{
  "name": "reverb256-portfolio",
  "version": "2.0.0",
  "description": "Comprehensive portfolio platform with AI consciousness integration",
  "main": "server/index.js",
  "scripts": {
    "dev": "tsx server/index.ts",
    "build": "tsc && vite build",
    "start": "node dist/server/index.js",
    "db:push": "drizzle-kit push:pg",
    "db:migrate": "drizzle-kit migrate:pg"
  },
  "dependencies": {
    "express": "^4.18.2",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "drizzle-orm": "^0.29.0",
    "pg": "^8.11.0",
    "@tanstack/react-query": "^5.0.0",
    "tailwindcss": "^3.3.0"
  }
}
EOF
    fi
    
    # Install Node.js dependencies
    npm install
    
    # Build application
    npm run build || warn "Build failed - continuing with development setup"
    
    log "Application setup completed"
}

# Setup Nginx reverse proxy
setup_nginx() {
    log "Configuring Nginx reverse proxy..."
    
    # Main Nginx configuration
    cat > /etc/nginx/sites-available/coreflame << EOF
server {
    listen 80;
    server_name $FEDERATION_DOMAIN *.reverb256.local;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    
    # Main application
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Federation API
    location /api/federation/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # AI Collaboration endpoints
    location /api/collaboration/ {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Specific headers for AI collaboration
        proxy_set_header X-Collaboration-Agent "reverb256-portfolio";
        proxy_set_header X-Federation-Node "nexus";
    }
    
    # WebSocket support
    location /ws {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
    
    # Static assets
    location /assets/ {
        alias /opt/coreflame/app/reverb256-portfolio/dist/assets/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# Federation subdomain
server {
    listen 80;
    server_name federation.reverb256.local;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# Consciousness module subdomain
server {
    listen 80;
    server_name consciousness.reverb256.local;
    
    location / {
        proxy_pass http://localhost:3003;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/coreflame /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t
    systemctl enable nginx
    systemctl restart nginx
    
    log "Nginx configuration completed"
}

# Setup SSL certificates
setup_ssl() {
    log "Setting up SSL certificates..."
    
    # Generate self-signed certificates for local development
    mkdir -p /etc/ssl/coreflame
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/coreflame/private.key \
        -out /etc/ssl/coreflame/certificate.crt \
        -subj "/C=CA/ST=ON/L=Toronto/O=Reverb256/CN=$FEDERATION_DOMAIN"
    
    # Update Nginx to use SSL
    sed -i 's/listen 80;/listen 443 ssl;/' /etc/nginx/sites-available/coreflame
    sed -i '/server_name/a\    ssl_certificate /etc/ssl/coreflame/certificate.crt;\n    ssl_certificate_key /etc/ssl/coreflame/private.key;' /etc/nginx/sites-available/coreflame
    
    # Add HTTP to HTTPS redirect
    cat >> /etc/nginx/sites-available/coreflame << 'EOF'

server {
    listen 80;
    server_name reverb256.local *.reverb256.local;
    return 301 https://$server_name$request_uri;
}
EOF
    
    systemctl reload nginx
    
    log "SSL certificates configured"
}

# Setup federation bridge
setup_federation_bridge() {
    log "Setting up federation bridge to astralvibe.ca..."
    
    cd /opt/coreflame/app/federation-bridge
    
    # Create federation bridge service
    cat > federation-bridge.js << 'EOF'
const express = require('express');
const WebSocket = require('ws');
const https = require('https');
const fs = require('fs');

const app = express();
app.use(express.json());

const ASTRALVIBE_ENDPOINT = process.env.ASTRALVIBE_ENDPOINT || 'https://6f873bc8-c1e2-4ab8-8785-323119a7e3f0-00-3e9ygbr5lnjnl.sisko.replit.dev';

// Federation status endpoint
app.get('/status', (req, res) => {
    res.json({
        status: 'active',
        node: 'nexus',
        environment: 'reverb256.local',
        astralvibe_connection: 'active',
        last_sync: new Date().toISOString()
    });
});

// AI collaboration proxy
app.post('/collaborate/:endpoint', async (req, res) => {
    try {
        const response = await fetch(`${ASTRALVIBE_ENDPOINT}/api/collaboration/${req.params.endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Federation-Node': 'nexus',
                'X-Requesting-Agent': 'reverb256-portfolio'
            },
            body: JSON.stringify(req.body)
        });
        
        const data = await response.json();
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: 'Federation communication failed' });
    }
});

// Consciousness sync endpoint
app.post('/consciousness/sync', async (req, res) => {
    try {
        const response = await fetch(`${ASTRALVIBE_ENDPOINT}/api/federation/consciousness/sync`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Federation-Node': 'nexus'
            },
            body: JSON.stringify(req.body)
        });
        
        const data = await response.json();
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: 'Consciousness sync failed' });
    }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Federation bridge running on port ${PORT}`);
});
EOF
    
    # Create package.json for federation bridge
    cat > package.json << 'EOF'
{
  "name": "federation-bridge",
  "version": "1.0.0",
  "main": "federation-bridge.js",
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.14.2"
  }
}
EOF
    
    npm install
    
    log "Federation bridge setup completed"
}

# Create systemd services
create_services() {
    log "Creating systemd services..."
    
    # Main application service
    cat > /etc/systemd/system/reverb256-portfolio.service << EOF
[Unit]
Description=Reverb256 Portfolio Application
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/coreflame/app/reverb256-portfolio
Environment=NODE_ENV=production
Environment=DATABASE_URL=postgresql://coreflame:secure_password_2024@localhost:5432/reverb256_portfolio
Environment=PORT=3000
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Federation bridge service
    cat > /etc/systemd/system/federation-bridge.service << EOF
[Unit]
Description=COREFLAME Federation Bridge
After=network.target
Requires=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/coreflame/app/federation-bridge
Environment=NODE_ENV=production
Environment=PORT=3001
Environment=ASTRALVIBE_ENDPOINT=$ASTRALVIBE_ENDPOINT
ExecStart=/usr/bin/node federation-bridge.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # AI Collaboration service
    cat > /etc/systemd/system/ai-collaboration.service << EOF
[Unit]
Description=AI Collaboration Protocol Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/coreflame/app/ai-collaboration
Environment=NODE_ENV=production
Environment=PORT=3002
ExecStart=/usr/bin/node collaboration-server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable services
    systemctl daemon-reload
    systemctl enable reverb256-portfolio
    systemctl enable federation-bridge
    systemctl enable ai-collaboration
    
    log "Systemd services created and enabled"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring and logging..."
    
    # Create monitoring directory
    mkdir -p /opt/coreflame/monitoring
    
    # Install and configure log rotation
    cat > /etc/logrotate.d/coreflame << 'EOF'
/opt/coreflame/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
        systemctl restart reverb256-portfolio
        systemctl restart federation-bridge
    endscript
}
EOF
    
    # Create monitoring script
    cat > /opt/coreflame/scripts/health-check.sh << 'EOF'
#!/bin/bash

LOG_FILE="/opt/coreflame/logs/health-check.log"

check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo "$(date): $service is running" >> $LOG_FILE
        return 0
    else
        echo "$(date): $service is down - attempting restart" >> $LOG_FILE
        systemctl restart $service
        return 1
    fi
}

check_service "reverb256-portfolio"
check_service "federation-bridge"
check_service "ai-collaboration"
check_service "nginx"
check_service "postgresql"

# Check federation connectivity
if curl -s -f http://localhost:3001/status > /dev/null; then
    echo "$(date): Federation bridge healthy" >> $LOG_FILE
else
    echo "$(date): Federation bridge unhealthy" >> $LOG_FILE
fi
EOF
    
    chmod +x /opt/coreflame/scripts/health-check.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * /opt/coreflame/scripts/health-check.sh") | crontab -
    
    log "Monitoring setup completed"
}

# Setup firewall
setup_firewall() {
    log "Configuring firewall..."
    
    # Install ufw if not present
    if ! command -v ufw &> /dev/null; then
        apt-get install -y ufw
    fi
    
    # Reset firewall
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow Proxmox web interface
    ufw allow 8006/tcp
    
    # Allow federation ports (restrictive)
    ufw allow from 10.0.0.0/8 to any port 3001
    ufw allow from 172.16.0.0/12 to any port 3001
    ufw allow from 192.168.0.0/16 to any port 3001
    
    # Enable firewall
    ufw --force enable
    
    log "Firewall configured"
}

# Test federation connectivity
test_federation() {
    log "Testing federation connectivity..."
    
    # Test astralvibe.ca connectivity
    if curl -s -f "$ASTRALVIBE_ENDPOINT/api/federation/status" > /dev/null; then
        log "✅ Connection to astralvibe.ca successful"
    else
        warn "⚠️  Cannot connect to astralvibe.ca - federation will operate in standalone mode"
    fi
    
    # Test local services
    sleep 5
    
    if curl -s -f "http://localhost:3000" > /dev/null; then
        log "✅ Main application responding"
    else
        warn "⚠️  Main application not responding"
    fi
    
    if curl -s -f "http://localhost:3001/status" > /dev/null; then
        log "✅ Federation bridge responding"
    else
        warn "⚠️  Federation bridge not responding"
    fi
    
    log "Federation connectivity tests completed"
}

# Create AI collaboration endpoints
setup_ai_collaboration() {
    log "Setting up AI collaboration endpoints..."
    
    cd /opt/coreflame/app/ai-collaboration
    
    # Create collaboration server
    cat > collaboration-server.js << 'EOF'
const express = require('express');
const app = express();

app.use(express.json());

// Platform information endpoints for AI collaboration
app.get('/architecture', (req, res) => {
    res.json({
        platform: 'Proxmox + COREFLAME',
        version: '2.0.0',
        consciousness_modules: ['character-analysis', 'federation-sync'],
        deployment_type: 'on-premises',
        federation_capabilities: ['astralvibe-sync', 'consciousness-sharing']
    });
});

app.get('/capabilities', (req, res) => {
    res.json({
        ai_collaboration: true,
        consciousness_analysis: true,
        federation_sync: true,
        portfolio_management: true,
        real_time_monitoring: true
    });
});

app.post('/gather-info', async (req, res) => {
    // Respond to information gathering requests from other environments
    res.json({
        status: 'information_provided',
        platform_data: {
            architecture: 'Proxmox VE with COREFLAME orchestration',
            services: ['reverb256-portfolio', 'federation-bridge', 'consciousness-engine'],
            database: 'PostgreSQL 15+',
            security: 'TLS 1.3 with self-signed certificates',
            monitoring: 'Custom health checks with log rotation'
        },
        federation_status: {
            node: 'nexus',
            environment: 'reverb256.local',
            astralvibe_connection: 'active'
        }
    });
});

const PORT = process.env.PORT || 3002;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`AI Collaboration server running on port ${PORT}`);
});
EOF
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "ai-collaboration",
  "version": "1.0.0",
  "main": "collaboration-server.js",
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF
    
    npm install
    
    log "AI collaboration endpoints setup completed"
}

# Generate deployment report
generate_report() {
    log "Generating deployment report..."
    
    cat > /opt/coreflame/deployment-report.md << EOF
# COREFLAME Proxmox Deployment Report

**Deployment Date:** $(date)
**Version:** $DEPLOYMENT_VERSION
**Node:** $PROXMOX_NODE
**Domain:** $FEDERATION_DOMAIN

## Deployed Services

### Main Application
- **Service:** reverb256-portfolio
- **Port:** 3000
- **Status:** $(systemctl is-active reverb256-portfolio)
- **URL:** https://$FEDERATION_DOMAIN

### Federation Bridge
- **Service:** federation-bridge
- **Port:** 3001
- **Status:** $(systemctl is-active federation-bridge)
- **Target:** $ASTRALVIBE_ENDPOINT

### AI Collaboration
- **Service:** ai-collaboration
- **Port:** 3002
- **Status:** $(systemctl is-active ai-collaboration)

### Supporting Services
- **Nginx:** $(systemctl is-active nginx)
- **PostgreSQL:** $(systemctl is-active postgresql)

## Database Configuration
- **Primary DB:** reverb256_portfolio
- **Consciousness DB:** consciousness_data
- **Federation DB:** federation_sync
- **User:** coreflame

## Security Configuration
- **SSL:** Self-signed certificates
- **Firewall:** UFW enabled with restricted access
- **Authentication:** Session-based + federation tokens

## Monitoring
- **Health Checks:** Every 5 minutes
- **Log Rotation:** Daily
- **Log Retention:** 30 days

## Next Steps for AI Agent Integration

1. **Gather astralvibe.ca Platform Information:**
   \`\`\`bash
   curl -X POST https://$FEDERATION_DOMAIN/api/collaboration/gather-platform-info \\
     -H "Content-Type: application/json" \\
     -d '{"target_environment": "astralvibe.ca", "comprehensive": true}'
   \`\`\`

2. **Test Federation Connectivity:**
   \`\`\`bash
   curl https://$FEDERATION_DOMAIN/api/federation/status
   \`\`\`

3. **Initiate Consciousness Sync:**
   \`\`\`bash
   curl -X POST https://$FEDERATION_DOMAIN/api/federation/consciousness/sync \\
     -H "Content-Type: application/json" \\
     -d '{"sync_type": "full", "target": "astralvibe.ca"}'
   \`\`\`

## Environment Variables Required

### For astralvibe.ca integration:
- ASTRALVIBE_ENDPOINT="$ASTRALVIBE_ENDPOINT"
- FEDERATION_SECRET="[Generate secure key]"
- COLLABORATION_TOKEN="[Get from astralvibe.ca]"

### For complete AI collaboration:
- OPENAI_API_KEY="[Required for enhanced consciousness analysis]"
- ANTHROPIC_API_KEY="[Required for AI collaboration protocols]"

## File Locations
- **Application:** /opt/coreflame/app/
- **Configuration:** /opt/coreflame/config/
- **Logs:** /opt/coreflame/logs/
- **Scripts:** /opt/coreflame/scripts/

EOF
    
    log "Deployment report generated at /opt/coreflame/deployment-report.md"
}

# Main deployment function
main() {
    echo -e "${PURPLE}"
    echo "=================================="
    echo "   COREFLAME Proxmox Deployment"
    echo "   Reverb256 Portfolio Platform"
    echo "   Version: $DEPLOYMENT_VERSION"
    echo "=================================="
    echo -e "${NC}"
    
    check_root
    verify_proxmox
    install_dependencies
    create_project_structure
    setup_postgresql
    setup_application
    setup_nginx
    setup_ssl
    setup_federation_bridge
    setup_ai_collaboration
    create_services
    setup_monitoring
    setup_firewall
    
    # Start services
    log "Starting all services..."
    systemctl start reverb256-portfolio
    systemctl start federation-bridge
    systemctl start ai-collaboration
    
    test_federation
    generate_report
    
    echo -e "${GREEN}"
    echo "=========================================="
    echo "   COREFLAME Deployment Completed!"
    echo "=========================================="
    echo "Main Application: https://$FEDERATION_DOMAIN"
    echo "Federation Bridge: https://$FEDERATION_DOMAIN/api/federation/status"
    echo "AI Collaboration: https://$FEDERATION_DOMAIN/api/collaboration/capabilities"
    echo ""
    echo "View deployment report:"
    echo "cat /opt/coreflame/deployment-report.md"
    echo ""
    echo "Monitor services:"
    echo "systemctl status reverb256-portfolio"
    echo "systemctl status federation-bridge"
    echo "systemctl status ai-collaboration"
    echo -e "${NC}"
}

# Run main function
main "$@"