# Consciousness Control Center - Deployment Instructions

## Quick Deployment Guide

Your Consciousness Control Center is ready for deployment on your Proxmox cluster. This system provides comprehensive AI orchestration with RAG, agentic capabilities, and complete infrastructure automation.

### 1. Deploy the Complete System
```bash
# Clone and setup
git clone <repository>
cd proxmox-federation

# Configure environment
cp .env.example .env
# Edit .env with your API keys and Proxmox settings

# Deploy services
docker-compose up -d --build
```

This will:
- Set up unified AI gateway with OpenAI compatibility
- Deploy RAG system with document processing
- Initialize agentic orchestration framework
- Configure all MCP modules (Talos/K8s, monitoring, database, security, workflow)
- Set up Proxmox API integration

### 2. Configure API Keys and Services
```bash
# Edit environment configuration
nano .env

# Required configurations:
# - AI Provider API keys (OpenAI, HuggingFace, etc.)
# - Proxmox credentials
# - Database settings
# - Security keys
```

### 3. Access Your System
- **API Gateway**: http://[host]:8080
- **API Documentation**: http://[host]:8080/docs
- **Health Check**: http://[host]:8080/health
- **Model Discovery**: http://[host]:8080/v1/models

## System Architecture

**Core Components:**
- **AI Gateway**: Unified OpenAI-compatible API with provider redundancy
- **RAG Service**: Document processing, vector storage, and Q&A
- **Agent Service**: Multi-agent orchestration with autonomous task execution
- **MCP Modules**: Professional orchestration for infrastructure, monitoring, security
- **Talos/K8s**: Container cluster lifecycle management
- **Workflow Engine**: Complex automation and task orchestration

**Container Layout:**
- Gateway: FastAPI application with all endpoints
- Database: PostgreSQL for persistent storage
- AI Services: vLLM, Stable Diffusion, TTS, STT, Embeddings
- Monitoring: Prometheus, Grafana, AlertManager (optional)

## Available Endpoints

After deployment, these endpoints will be available:

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