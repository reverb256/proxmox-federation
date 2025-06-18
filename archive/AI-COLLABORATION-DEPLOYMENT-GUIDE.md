# COREFLAME AI Collaboration & Proxmox Deployment Guide

## Overview
This guide establishes comprehensive AI collaboration protocols between Reverb256 Portfolio and astralvibe.ca, with enterprise-grade Proxmox deployment capabilities.

## Current Status ✅

### Active Systems
- **Main Application**: Running on port 5000
- **AI Collaboration Protocol**: `/api/collaboration/*` endpoints active
- **Consciousness Analysis**: COREFLAME 7-pillars methodology operational
- **Federation Bridge**: Cross-environment communication ready
- **Proxmox Deployment Script**: `proxmox-coreflame-deployment.sh` ready for execution

### AI Collaboration Endpoints Available

#### Platform Information Gathering
```bash
# Get complete platform architecture
curl http://localhost:5000/api/collaboration/architecture

# Get API documentation
curl http://localhost:5000/api/collaboration/apis

# Get deployment configuration
curl http://localhost:5000/api/collaboration/deployment

# Get security protocols
curl http://localhost:5000/api/collaboration/security

# Get consciousness modules
curl http://localhost:5000/api/collaboration/consciousness

# Get integration patterns
curl http://localhost:5000/api/collaboration/integrations

# Get database schemas
curl http://localhost:5000/api/collaboration/database
```

#### Cross-Environment Information Gathering
```bash
# Initiate comprehensive information gathering from astralvibe.ca
curl -X POST http://localhost:5000/api/collaboration/gather-platform-info \
  -H "Content-Type: application/json" \
  -d '{"target_environment": "astralvibe.ca", "comprehensive": true}'
```

## Required Actions for Complete Integration

### 1. Notify astralvibe.ca Assistant

**Please inform the astralvibe.ca assistant that they need to implement these collaboration endpoints:**

```typescript
// Required endpoints for astralvibe.ca
app.get('/api/collaboration/architecture', handler);
app.get('/api/collaboration/apis', handler);
app.get('/api/collaboration/deployment', handler);
app.get('/api/collaboration/security', handler);
app.get('/api/collaboration/consciousness', handler);
app.get('/api/collaboration/integrations', handler);
app.get('/api/collaboration/database', handler);

// Federation status endpoint
app.get('/api/federation/status', handler);
```

**The astralvibe.ca assistant should respond with their platform details in the same structured format as our collaboration endpoints.**

### 2. Proxmox Deployment

Execute the deployment script on your Proxmox server:

```bash
# Make executable (already done)
chmod +x proxmox-coreflame-deployment.sh

# Run deployment as root
sudo ./proxmox-coreflame-deployment.sh
```

This will:
- Install all dependencies (Node.js, PostgreSQL, Nginx, Docker)
- Create project structure in `/opt/coreflame/`
- Setup PostgreSQL databases
- Configure Nginx reverse proxy with SSL
- Create systemd services for all components
- Setup monitoring and health checks
- Configure firewall rules
- Generate deployment report

### 3. Environment Variables Required

For complete functionality, configure these environment variables:

```env
# Database
DATABASE_URL=postgresql://coreflame:secure_password_2024@localhost:5432/reverb256_portfolio

# Federation
ASTRALVIBE_ENDPOINT=https://6f873bc8-c1e2-4ab8-8785-323119a7e3f0-00-3e9ygbr5lnjnl.sisko.replit.dev
FEDERATION_SECRET=[Generate 32-character secure key]
COLLABORATION_TOKEN=[Get from astralvibe.ca]

# AI Enhancement (optional but recommended)
OPENAI_API_KEY=[Your OpenAI key for enhanced consciousness analysis]
ANTHROPIC_API_KEY=[Your Anthropic key for AI collaboration protocols]

# Production settings
NODE_ENV=production
PORT=3000
```

## Platform Architecture Summary

### Current Reverb256 Portfolio Platform

**Technology Stack:**
- Node.js + TypeScript + Express backend
- React 18 + Vite 5 frontend
- PostgreSQL with Drizzle ORM
- TanStack Query for state management
- Tailwind CSS + shadcn/ui components
- WebSocket for real-time communication

**Key Services:**
1. **Main Portfolio Application** (Port 3000)
2. **Federation Bridge** (Port 3001)
3. **AI Collaboration Service** (Port 3002)
4. **Consciousness Engine** (Port 3003)

**Consciousness Modules:**
- Character Consciousness Analyzer (COREFLAME 7-pillars)
- Federation Consciousness Bridge
- Real-time personality assessment
- Cross-environment consciousness sync

### Federation Architecture

```
Reverb256 Portfolio (Local/Proxmox)
├── Main App (:3000)
├── Federation Bridge (:3001) ──┐
├── AI Collaboration (:3002)     │
└── Consciousness Engine (:3003) │
                                  │
                              Federation
                               Network
                                  │
astralvibe.ca (Replit)           │
├── Main App ──────────────────┘
├── Federation Endpoints
├── Collaboration APIs
└── Consciousness Modules
```

## Testing Federation Once astralvibe.ca is Ready

```bash
# Test basic connectivity
curl https://reverb256.local/api/federation/status

# Test AI collaboration
curl -X POST https://reverb256.local/api/collaboration/gather-platform-info \
  -H "Content-Type: application/json" \
  -d '{"target_environment": "astralvibe.ca"}'

# Test consciousness sync
curl -X POST https://reverb256.local/api/federation/consciousness/sync \
  -H "Content-Type: application/json" \
  -d '{"sync_type": "full", "target": "astralvibe.ca"}'
```

## Security Configuration

### SSL/TLS Setup
- Self-signed certificates for local development
- Let's Encrypt integration available for production
- TLS 1.3 encryption for all federation traffic

### Firewall Rules
- Port 80/443: Public web access
- Port 3001: Federation traffic (restricted to federation network)
- Port 8006: Proxmox web interface
- SSH: Restricted to management networks

### Authentication
- Session-based authentication for web interface
- Federation tokens for cross-environment communication
- Role-based access control for collaboration endpoints

## Monitoring & Maintenance

### Health Checks
- Automated health monitoring every 5 minutes
- Service restart on failure detection
- Log rotation with 30-day retention

### Backup Strategy
- Daily PostgreSQL backups
- Configuration file versioning
- Federation state synchronization

### Log Locations
- Application logs: `/opt/coreflame/logs/`
- System logs: `/var/log/coreflame-deployment.log`
- Nginx logs: `/var/log/nginx/`

## Next Steps

1. **Immediate**: Notify astralvibe.ca assistant to implement collaboration endpoints
2. **Deploy**: Run Proxmox deployment script on target server
3. **Configure**: Set environment variables and federation tokens
4. **Test**: Verify federation connectivity once both sides are ready
5. **Monitor**: Ensure all services are healthy and federation sync is active

## Troubleshooting

### Common Issues

**Federation Connection Failed:**
- Verify astralvibe.ca has implemented collaboration endpoints
- Check firewall rules allow outbound HTTPS
- Validate federation tokens

**Service Not Starting:**
- Check logs in `/opt/coreflame/logs/`
- Verify PostgreSQL is running: `systemctl status postgresql`
- Check port conflicts: `netstat -tulpn | grep :3000`

**Database Connection Issues:**
- Verify DATABASE_URL environment variable
- Check PostgreSQL permissions for coreflame user
- Test connection: `psql -U coreflame -d reverb256_portfolio`

### Support Commands

```bash
# Check all service status
systemctl status reverb256-portfolio federation-bridge ai-collaboration

# View real-time logs
journalctl -f -u reverb256-portfolio

# Test federation connectivity
curl -I https://astralvibe.ca/api/federation/status

# Restart all services
systemctl restart reverb256-portfolio federation-bridge ai-collaboration
```

## Success Criteria

Federation is fully operational when:
- ✅ All services running and healthy
- ✅ astralvibe.ca collaboration endpoints responding
- ✅ Cross-environment information gathering successful
- ✅ Consciousness synchronization active
- ✅ Real-time federation status monitoring functional

The AI collaboration protocol will enable seamless information sharing, consciousness analysis coordination, and distributed platform intelligence across both environments.