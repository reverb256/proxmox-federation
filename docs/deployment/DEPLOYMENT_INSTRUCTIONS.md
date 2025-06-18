# Aria Personal Trading System - Deployment Instructions

## Quick Deployment Guide

Your Aria system is ready for deployment on your Proxmox cluster. Execute these commands on your Proxmox host (nexus):

### 1. Deploy the Complete System
```bash
./complete-aria-deployment.sh
```

This will:
- Set up encrypted secrets management with aria-secrets command
- Create K3s cluster on containers 310-312  
- Deploy trading dashboard and AI agents
- Configure Proxmox API integration

### 2. Configure Trading API Keys (After Deployment)
```bash
aria-secrets setup-trading
```

Select your exchange (Binance, Coinbase, Kraken) and enter API credentials securely.

### 3. Access Your System
- **Dashboard**: http://[master-ip]:30080
- **Trading Interface**: Accessible through the dashboard
- **Secrets Management**: Use `aria-secrets` commands

## System Architecture

**Container Layout:**
- 310 (aria-master): K3s master node + dashboard (8GB RAM, 4 cores)
- 311 (aria-worker-1): Trading agent + strategies (6GB RAM, 3 cores)  
- 312 (aria-worker-2): Risk management + portfolio tracking (6GB RAM, 3 cores)

**Core Components:**
- Momentum trading strategy with trend detection
- Mean reversion strategy for oversold/overbought conditions
- Risk management with position sizing and portfolio limits
- Encrypted credential storage with local key management
- Web dashboard for monitoring and configuration

## Available Commands

After deployment, these commands will be available:

```bash
# System Status
aria-quick-status.sh              # Check all containers and services

# Secrets Management  
aria-secrets setup-trading        # Interactive API key setup
aria-secrets add <name> <value>   # Add individual secrets
aria-secrets list                 # Show configured secrets
aria-secrets remove <name>        # Remove secrets

# Manual Deployment (if needed)
./setup-aria-secrets.sh           # Setup secrets only
./deploy-aria-services.sh         # Deploy K8s services only
```

## Trading Configuration

Once API keys are configured, the system will:
1. Automatically analyze market data from your configured exchanges
2. Generate trading signals using momentum and mean reversion strategies
3. Calculate consensus recommendations with confidence scores
4. Apply risk management rules for position sizing
5. Display recommendations through the web dashboard

## Security Features

- All API keys encrypted with local master key
- Proxmox API tokens isolated to aria@pve user with minimal permissions
- Container isolation with resource limits
- No external data transmission of sensitive credentials

Your personal trading system will be accessible at the dashboard URL provided after deployment completes.