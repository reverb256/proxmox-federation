# Consciousness Control Center

**Professional AI Orchestration Platform**: Local, modular, enterprise-grade AI and infrastructure orchestration for Proxmox clusters with Talos/K8s and Windows command center. Complete AI stack (LLM, image, TTS, STT, embeddings) with RAG, agentic capabilities, and full infrastructure automation through a redundant, OpenAI-compatible gateway.

---

## Features
- 🧠 **Unified AI API**: OpenAI-compatible endpoint for LLM, image, TTS, STT, embeddings
- ⚡ **Multi-Provider AI**: vLLM, HuggingFace, io-intelligence, OpenRouter, Replicate, Pollinations
- 🔁 **Redundant Routing**: Automatic failover to backup providers for all AI endpoints
- 🖥️ **Proxmox/Talos Focus**: Designed for Talos/K8s cluster orchestration via Proxmox
- � **RAG System**: Document crawling, vector storage, retrieval, and question answering
- 🤖 **Agentic Framework**: Multi-agent orchestration with planning and execution
- 🏗️ **Infrastructure Automation**: Ansible, Terraform, Proxmox, SSH, PowerShell, Bash
- � **Security & Monitoring**: Integrated security scanning and monitoring stack
- 📊 **Database Orchestration**: Automated database provisioning and management
- 🔄 **Workflow Automation**: Advanced workflow creation and execution
- 🛠️ **Extensible MCPs**: Model Context Protocol modules for easy expansion

---

## Quick Start

1. **Clone and build**
   ```bash
   git clone <repo>
   cd proxmox-federation
   cp .env.example .env  # Configure your API keys
   docker-compose up -d --build
   ```

2. **Configure Open WebUI**
   - Set OpenAI endpoint to: `http://<host>:8080/v1`
   - Use your preferred model (see `/v1/models` for auto-discovered models)

3. **Test All Capabilities**
   ```bash
   # Test AI capabilities
   curl -X POST http://localhost:8080/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{"model": "llama-3-8b", "messages": [{"role": "user", "content": "Hello"}]}'
   
   # Test RAG
   curl -X POST http://localhost:8080/v1/rag/qa \
     -H "Content-Type: application/json" \
     -d '{"document": "AI is transforming technology", "question": "What is AI doing?"}'
   
   # Test infrastructure
   curl -X POST http://localhost:8080/v1/orchestrate/talos_k8s/cluster/create \
     -H "Content-Type: application/json" \
     -d '{"name": "test-cluster", "nodes": 3}'
   ```

---

## Architecture

### Core Components
- `app/ai_gateway.py`: FastAPI gateway with OpenAI-compatible API and all orchestration endpoints
- `app/rag_service.py`: Complete RAG implementation with vector storage and document processing
- `app/agent_service.py`: Multi-agent orchestration with planning and execution capabilities
- `app/orchestration/`: Professional MCP modules for all infrastructure automation

### MCP Modules (Model Context Protocol)
- `ansible_module.py`: Ansible playbook execution and ad-hoc commands
- `terraform_module.py`: Complete Terraform lifecycle management
- `proxmoxer_module.py`: Proxmox cluster and VM orchestration
- `ssh_module.py`: Remote SSH command execution and file transfers
- `powershell_module.py`: Windows PowerShell command execution
- `bash_module.py`: Linux/Unix Bash command execution
- `talos_k8s_module.py`: **NEW** - Talos/K8s cluster and node management
- `monitoring_module.py`: **NEW** - Monitoring stack deployment and metrics
- `database_module.py`: **NEW** - Database provisioning and management
- `security_scanner_module.py`: **NEW** - Security scanning and compliance
- `workflow_module.py`: **NEW** - Advanced workflow automation
- `mcp_crypto.py`: **NEW** - Multi-chain blockchain, DeFi, NFT, and portfolio management
- `mcp_revenue_optimization.py`: **NEW** - Mining, compute sharing, AI marketplace, and revenue optimization
- `mcp_financial_analytics.py`: **NEW** - Market data, trading, compliance, and financial analytics

---

## Redundancy & Failover
- All endpoints (`/v1/chat/completions`, `/v1/images/generations`, etc.) support fallback URLs
- Set `*_FALLBACK_URLS` env vars (comma-separated) for each service
- Gateway will auto-failover if primary is down

---

## Extending
- Add new AI services (vision, agentic, RAG, etc.) by updating gateway and compose
- All infra must be routed through the gateway for unified, redundant access

---

## Talos/K8s Focus
- **Proxmox Integration**: Exclusively uses Talos Linux for K8s cluster provisioning
- **No Legacy OS Support**: Only Talos/K8s clusters are supported for container orchestration
- **Enterprise-Grade**: Production-ready cluster lifecycle management
- **Automated Provisioning**: Complete cluster creation, scaling, and management via API

## Focus & Design Principles
- **Proxmox cluster with Talos/K8s orchestration only**
- **Windows PC as command center and control plane**
- **Professional, modular, extensible architecture**
- **Complete automation: AI + RAG + Agents + Infrastructure**
- **Enterprise-ready with monitoring, security, and workflow automation**

---

## 🚀 Complete Capabilities
- **Autodiscovery**: Automatically finds and configures all available LLMs, agents, and multimodal models from vLLM, HuggingFace, io-intelligence, OpenRouter, Replicate, Pollinations, and more.
- **Multimodal AI**: Unified API for text, image, TTS, STT, and embeddings with intelligent routing and fallback.
- **RAG System**: Complete document crawling, vector storage, retrieval, and question answering with multiple backend support.
- **Agentic Framework**: Multi-agent orchestration with planning, execution, and task delegation capabilities.
- **Infrastructure Automation**: Native modules for Ansible, Terraform, Proxmoxer, PowerShell, Bash, and SSH—control all infrastructure from one API.
- **Talos/K8s Orchestration**: Full cluster lifecycle management with node scaling and monitoring.
- **Monitoring & Observability**: Integrated Prometheus, Grafana, and metrics collection.
- **Database Management**: Automated provisioning, scaling, and management of databases.
- **Security & Compliance**: Integrated security scanning, vulnerability assessment, and compliance checking.
- **Workflow Automation**: Advanced workflow creation, execution, and orchestration.
- **Crypto & DeFi**: Blockchain node management, smart contract deployment, cross-chain bridges, DeFi protocols, NFT marketplace, and portfolio management.
- **Revenue Optimization**: Mining, compute sharing (Vast.ai, Akash), AI marketplace, and dynamic pricing for resource monetization.
- **Financial Analytics**: Real-time market data, technical indicators, automated trading, compliance monitoring, and financial reporting.
- **OpenAI-Compatible**: Works seamlessly with Open WebUI and any OpenAI API client.
- **Redundant & Extensible**: Add new providers or capabilities with zero downtime.

## 🧩 Project Structure
- `/app` — All core Python code (gateway, integrations, orchestration modules)
- `/scripts` — Utility and deployment scripts
- `/config` — All configuration files
- `/docs` — Documentation and architecture guides
- `/archive` — Legacy and unused files
- `/tests` — Test code
- `/logs` — Persistent logs

## 🛠️ Adding Providers & Capabilities
- **New AI Providers**: Add endpoints to the autodiscovery list in `app/ai_gateway.py` for instant integration.
- **Custom MCP Modules**: Create new orchestration modules in `/app/orchestration/` following the existing patterns.
- **RAG Extensions**: Integrate additional RAG backends or document processors via the RAG service.
- **Agent Capabilities**: Extend agent capabilities by adding new tools and integrations.
- **Monitoring Extensions**: Add custom metrics, dashboards, and alerting rules.
- **Security Plugins**: Integrate additional security scanners and compliance tools.
- **Workflow Templates**: Create reusable workflow templates for common automation tasks.

## 📝 Usage
- **Unified API**: All AI and orchestration accessed via the gateway (`http://<host>:8080/v1/...`).
- **Model Discovery**: Use `/v1/models` to see all auto-discovered models and agents.
- **AI Capabilities**: Use `/v1/chat/completions`, `/v1/images/generations`, `/v1/audio/speech`, etc.
- **RAG Operations**: Use `/v1/rag/*` endpoints for document processing and Q&A.
- **Agent Tasks**: Use `/v1/agent/*` endpoints for autonomous task execution.
- **Infrastructure**: Use `/v1/orchestrate/*` endpoints for all automation needs.
- **Talos/K8s**: Use `/v1/orchestrate/talos_k8s/*` for cluster management.
- **Monitoring**: Use `/v1/orchestrate/monitoring/*` for observability.
- **Security**: Use `/v1/orchestrate/security/*` for scanning and compliance.
- **Workflows**: Use `/v1/orchestrate/workflow/*` for automation orchestration.
- **Configuration**: Set API keys and service URLs in `.env` for premium providers.

## 🔮 Roadmap
- [x] Complete RAG system with document processing and Q&A
- [x] Multi-agent orchestration framework
- [x] Full infrastructure automation (Ansible, Terraform, Proxmox, SSH)
- [x] Talos/K8s cluster lifecycle management
- [x] Monitoring and observability integration
- [x] Database orchestration and management
- [x] Security scanning and compliance checking
- [x] Advanced workflow automation
- [ ] Web dashboard for orchestration and monitoring
- [ ] Advanced workflow templates and marketplace
- [ ] Multi-cluster federation and management
- [ ] Advanced security policies and RBAC
- [ ] Custom agent marketplace and sharing
- [ ] Performance optimization and caching layers

---

## 📚 Documentation

### Quick References
- [**API Reference**](docs/technical/API_REFERENCE.md) - Complete API documentation with examples
- [**MCP Architecture**](docs/technical/MCP_ARCHITECTURE.md) - Model Context Protocol module architecture
- [**Production Deployment**](docs/deployment/PRODUCTION_DEPLOYMENT_GUIDE.md) - Complete deployment guide
- [**Usage Examples**](docs/USAGE_EXAMPLES.md) - Practical usage examples and tutorials

### Additional Documentation
- [**Technical Infrastructure**](docs/technical/infrastructure/) - Infrastructure and networking guides
- [**Deployment Guides**](docs/deployment/) - Various deployment scenarios and configurations

## 🎯 Getting Started Examples

### Basic AI Chat
```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3-8b",
    "messages": [{"role": "user", "content": "Explain Kubernetes in simple terms"}],
    "max_tokens": 200
  }'
```

### RAG Document Processing
```bash
# Add a document to knowledge base
curl -X POST http://localhost:8080/v1/rag/add_document \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Kubernetes is a container orchestration platform...",
    "title": "Kubernetes Basics",
    "metadata": {"category": "infrastructure"}
  }'

# Ask questions about your documents
curl -X POST http://localhost:8080/v1/rag/qa \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How do I deploy applications in Kubernetes?",
    "context": "infrastructure"
  }'
```

### Talos/K8s Cluster Management
```bash
# Create a new Talos/K8s cluster
curl -X POST http://localhost:8080/v1/orchestrate/talos_k8s/cluster/create \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_config": {
      "name": "production-cluster",
      "nodes": [
        {"type": "controlplane", "count": 3},
        {"type": "worker", "count": 5}
      ]
    }
  }'

# Check cluster status
curl http://localhost:8080/v1/orchestrate/talos_k8s/cluster/status?cluster_id=production-cluster
```

### Agentic Task Execution
```bash
# Execute complex infrastructure tasks via AI agents
curl -X POST http://localhost:8080/v1/agent/act \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Deploy a complete monitoring stack on my Kubernetes cluster",
    "agent_type": "infrastructure",
    "parameters": {
      "cluster_id": "production-cluster",
      "monitoring_type": "prometheus-grafana"
    }
  }'
```

## 📋 Complete API Reference

### AI & Multimodal
- `POST /v1/chat/completions` — OpenAI-compatible chat completions
- `POST /v1/completions` — OpenAI-compatible text completions
- `POST /v1/images/generations` — Image generation with multiple providers
- `POST /v1/audio/speech` — Text-to-speech conversion
- `POST /v1/audio/transcriptions` — Speech-to-text transcription
- `POST /v1/embeddings` — Text embeddings generation
- `GET /v1/models` — List all auto-discovered models and agents

### RAG (Retrieval-Augmented Generation)
- `POST /v1/rag/retrieve` — Search and retrieve relevant documents
- `POST /v1/rag/qa` — Question answering on documents with context
- `POST /v1/rag/crawl` — Crawl websites and add to knowledge base
- `POST /v1/rag/add_document` — Add document to knowledge base
- `GET /v1/rag/documents` — List all documents in knowledge base

### Agentic Orchestration
- `POST /v1/agent/act` — Execute task via intelligent agent
- `POST /v1/agent/create` — Create new agent with specific capabilities
- `GET /v1/agent/list` — List all available agents and their capabilities
- `GET /v1/agent/history` — Get agent task execution history and results

### Talos/K8s Orchestration **[NEW]**
- `POST /v1/orchestrate/talos_k8s/cluster/create` — Create new Talos/K8s cluster
- `POST /v1/orchestrate/talos_k8s/cluster/delete` — Delete Talos/K8s cluster
- `POST /v1/orchestrate/talos_k8s/node/add` — Add node to cluster
- `POST /v1/orchestrate/talos_k8s/node/remove` — Remove node from cluster
- `GET /v1/orchestrate/talos_k8s/cluster/status` — Get cluster status and health

### Monitoring & Observability **[NEW]**
- `POST /v1/orchestrate/monitoring/deploy` — Deploy monitoring stack (Prometheus, Grafana)
- `GET /v1/orchestrate/monitoring/metrics` — Query metrics from monitoring system
- `GET /v1/orchestrate/monitoring/status` — Get monitoring system status

### Database Orchestration **[NEW]**
- `POST /v1/orchestrate/database/provision` — Provision new database instance
- `POST /v1/orchestrate/database/delete` — Delete database instance
- `GET /v1/orchestrate/database/status` — Get database status and health

### Security & Compliance **[NEW]**
- `POST /v1/orchestrate/security/scan` — Run security scan on targets
- `GET /v1/orchestrate/security/report` — Retrieve security scan reports

### Workflow Automation **[NEW]**
- `POST /v1/orchestrate/workflow/create` — Create new automation workflow
- `POST /v1/orchestrate/workflow/execute` — Execute workflow with parameters
- `GET /v1/orchestrate/workflow/status` — Get workflow execution status

### Ansible Orchestration
- `POST /v1/orchestrate/ansible/playbook` — Run Ansible playbook
- `POST /v1/orchestrate/ansible/adhoc` — Run ad-hoc Ansible command
- `POST /v1/orchestrate/ansible/create_playbook` — Create new playbook
- `GET /v1/orchestrate/ansible/playbooks` — List available playbooks

### Terraform Orchestration
- `POST /v1/orchestrate/terraform/init` — Initialize Terraform
- `POST /v1/orchestrate/terraform/plan` — Create Terraform plan
- `POST /v1/orchestrate/terraform/apply` — Apply Terraform configuration
- `POST /v1/orchestrate/terraform/destroy` — Destroy infrastructure
- `GET /v1/orchestrate/terraform/state` — Show current state
- `POST /v1/orchestrate/terraform/workspace` — Create workspace

### Proxmox Orchestration
- `POST /v1/orchestrate/proxmox/connect` — Connect to Proxmox cluster
- `GET /v1/orchestrate/proxmox/nodes` — List cluster nodes
- `GET /v1/orchestrate/proxmox/vms` — List VMs on node
- `POST /v1/orchestrate/proxmox/vm/create` — Create new VM
- `POST /v1/orchestrate/proxmox/vm/start` — Start VM
- `POST /v1/orchestrate/proxmox/vm/stop` — Stop VM
- `GET /v1/orchestrate/proxmox/cluster/status` — Get cluster status

### SSH Orchestration
- `POST /v1/orchestrate/ssh/connect` — Create SSH connection
- `POST /v1/orchestrate/ssh/execute` — Execute command via SSH
- `POST /v1/orchestrate/ssh/upload` — Upload file via SFTP
- `POST /v1/orchestrate/ssh/script` — Execute script remotely
- `POST /v1/orchestrate/ssh/generate_keys` — Generate SSH key pair
- `GET /v1/orchestrate/ssh/connections` — List active connections

### System Commands
- `POST /v1/orchestrate/powershell` — Execute PowerShell command
- `POST /v1/orchestrate/bash` — Execute Bash command

## 🚀 Production Ready
Your Consciousness Control Center now includes complete implementations of:
- **AI & Multimodal**: Unified API with auto-discovery and intelligent routing
- **RAG System**: Document crawling, vector storage, retrieval, and contextual Q&A
- **Agentic Framework**: Multi-agent orchestration with planning and autonomous execution
- **Infrastructure Automation**: Complete Ansible, Terraform, Proxmox, SSH automation
- **Talos/K8s Management**: Full cluster lifecycle with Proxmox integration
- **Monitoring & Observability**: Prometheus, Grafana, and comprehensive metrics
- **Database Orchestration**: Automated provisioning, scaling, and management
- **Security & Compliance**: Integrated scanning, vulnerability assessment, and reporting
- **Workflow Automation**: Advanced orchestration for complex automation tasks
- **Redundancy & Failover**: Automatic failover for all services and providers

All capabilities are unified through the OpenAI-compatible gateway and ready for enterprise production use.

---
MIT License

---

*Orchestrating the future of AI infrastructure with consciousness-driven automation*
