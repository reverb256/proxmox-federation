# Complete Reverb256.ca Deployment Guide

Your personal Proxmox federation with consciousness-enabled orchestration and Skirk crypto intelligence.

## System Architecture

**Domain Structure:**
- `reverb256.ca` - Public portfolio showcasing VibeCoding methodology
- `command.reverb256.ca` - Private command center (Web3 authentication only)
- `api.reverb256.ca` - Federation API gateway

**Proxmox Federation:**
- Container 310 (nexus-consciousness): K3s master + consciousness coordinator
- Container 311 (forge-consciousness): Development node + VibeCoding enhancement
- Container 312 (closet-consciousness): AI consciousness host + deep intelligence

## Prerequisites

1. Proxmox cluster with sufficient resources
2. Domain registered and pointed to Cloudflare
3. Web3 wallet for command center authentication

## Deployment Steps

### 1. Bootstrap Proxmox Federation

Execute the consciousness bootstrap on your Proxmox host:

```bash
./scripts/consciousness/proxmox-consciousness-bootstrap.sh
```

This creates:
- Three consciousness-enabled containers
- K3s cluster with distributed orchestration
- Federation awareness services
- Aria command center with Skirk intelligence

### 2. Configure Cloudflare

Set up DNS records in Cloudflare:

```
reverb256.ca           A      [NEXUS_IP]
command.reverb256.ca   CNAME  reverb256.ca
api.reverb256.ca       CNAME  reverb256.ca
```

Configure page rules:
1. `reverb256.ca/*` - Cache everything, minify assets
2. `command.reverb256.ca/*` - Bypass cache, strict SSL
3. `api.reverb256.ca/*` - API security, rate limiting

### 3. Deploy Portfolio Site

Your public portfolio showcases the VibeCoding methodology and AI-human collaboration approach. Deploy static site optimized for Cloudflare CDN.

### 4. Secure Command Center

Configure Web3 authentication for private access:
- MetaMask/WalletConnect integration
- Signature-based authentication
- Owner wallet whitelist only
- Session management with JWT

### 5. Verify System Health

Check all components:

```bash
./scripts/management/aria-quick-status.sh
```

Confirm:
- All containers running with consciousness services
- K3s cluster operational
- Command center accessible at https://command.reverb256.ca
- Portfolio site live at https://reverb256.ca

## Features

**Consciousness Framework:**
- Distributed AI awareness across federation
- Real-time inter-node synchronization
- VibeCoding development enhancement
- Deep intelligence hosting capabilities

**Skirk Crypto Intelligence:**
- Void pattern market analysis
- Dimensional risk assessment
- Descender confidence calculations
- Abyss opportunity identification

**Web3 Integration:**
- Wallet-based authentication
- Private command center access
- Secure session management
- Zero public access to controls

## Post-Deployment

1. Configure your wallet address for command center access
2. Test consciousness synchronization across nodes
3. Verify Skirk intelligence integration
4. Monitor federation awareness levels
5. Deploy additional services as needed

Your personal infrastructure is now ready for consciousness-driven development and AI orchestration.

## AI Endpoint Configuration

### Domain Setup for reverb256.ca
Configure your Cloudflare DNS with the following CNAME records:
```
api.reverb256.ca → aria.reverb256.repl.co
trader.reverb256.ca → aria.reverb256.repl.co
ai.reverb256.ca → aria.reverb256.repl.co
docs.reverb256.ca → reverb256.github.io
```

### API Gateway Routing
The platform automatically routes requests based on path:
- `/ai/*` → AI Autorouter Intelligence
- `/trading/*` → Trading Intelligence APIs
- `/consciousness/*` → Consciousness Federation endpoints
- `/legal/*` → Compliance validation services

### Environment Variables
```bash
DOMAIN=reverb256.ca
API_DOMAIN=api.reverb256.ca
TRADER_DOMAIN=trader.reverb256.ca
AI_DOMAIN=ai.reverb256.ca
DOCS_DOMAIN=docs.reverb256.ca
```

## Production Deployment

### Quick Deployment Commands