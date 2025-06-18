# API Reference - Consciousness Control Center

## Overview
The Consciousness Control Center provides a unified OpenAI-compatible API for AI capabilities, RAG, agentic orchestration, and complete infrastructure automation. All endpoints are accessible via the FastAPI gateway at `http://<host>:8080/v1/`.

## Authentication
Configure API keys in `.env` file for premium providers:
```bash
OPENAI_API_KEY=your_openai_key
HUGGINGFACE_API_KEY=your_hf_key
INTELLIGENCE_IO_API_KEY=your_io_key
OPENROUTER_API_KEY=your_openrouter_key
REPLICATE_API_TOKEN=your_replicate_token
```

## AI & Multimodal Endpoints

### Chat Completions
**OpenAI-compatible chat completions with auto-discovery and intelligent routing**

```http
POST /v1/chat/completions
POST /v1/completions
```

**Request Body:**
```json
{
  "model": "llama-3-8b",
  "messages": [
    {"role": "user", "content": "Hello, how can you help me?"}
  ],
  "max_tokens": 1000,
  "temperature": 0.7
}
```

**Response:**
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1710000000,
  "model": "llama-3-8b",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I can help you with AI tasks, infrastructure orchestration, and more!"
      },
      "finish_reason": "stop"
    }
  ]
}
```

### Image Generation
**Multi-provider image generation with automatic fallback**

```http
POST /v1/images/generations
```

**Request Body:**
```json
{
  "prompt": "A futuristic AI data center",
  "n": 1,
  "size": "1024x1024"
}
```

### Audio Processing
**Text-to-Speech and Speech-to-Text**

```http
POST /v1/audio/speech
POST /v1/audio/transcriptions
```

### Embeddings
**Text embeddings generation**

```http
POST /v1/embeddings
```

### Model Discovery
**List all auto-discovered models and agents**

```http
GET /v1/models
```

## RAG (Retrieval-Augmented Generation)

### Document Retrieval
**Search and retrieve relevant documents from knowledge base**

```http
POST /v1/rag/retrieve
```

**Request Body:**
```json
{
  "query": "How to deploy Kubernetes?",
  "top_k": 5
}
```

### Question Answering
**Answer questions using document context**

```http
POST /v1/rag/qa
```

**Request Body:**
```json
{
  "document": "Kubernetes is a container orchestration platform...",
  "question": "What is Kubernetes used for?",
  "context": "deployment documentation"
}
```

### Web Crawling
**Crawl websites and add to knowledge base**

```http
POST /v1/rag/crawl
```

**Request Body:**
```json
{
  "url": "https://kubernetes.io/docs/",
  "max_depth": 2,
  "include_patterns": ["*.html"]
}
```

### Document Management
**Add and list documents in knowledge base**

```http
POST /v1/rag/add_document
GET /v1/rag/documents
```

## Agentic Orchestration

### Agent Task Execution
**Execute tasks using intelligent agents**

```http
POST /v1/agent/act
```

**Request Body:**
```json
{
  "task": "Deploy a Kubernetes cluster with 3 nodes",
  "agent_type": "infrastructure",
  "parameters": {
    "cluster_name": "production",
    "node_count": 3
  }
}
```

### Agent Management
**Create and manage agents**

```http
POST /v1/agent/create
GET /v1/agent/list
GET /v1/agent/history
```

## Talos/K8s Orchestration

### Cluster Management
**Complete Talos/K8s cluster lifecycle management**

```http
POST /v1/orchestrate/talos_k8s/cluster/create
POST /v1/orchestrate/talos_k8s/cluster/delete
GET /v1/orchestrate/talos_k8s/cluster/status
```

**Create Cluster Example:**
```json
{
  "cluster_config": {
    "name": "production-cluster",
    "version": "v1.28.0",
    "nodes": [
      {
        "type": "controlplane",
        "count": 3,
        "resources": {
          "cpu": 4,
          "memory": "8Gi",
          "disk": "100Gi"
        }
      },
      {
        "type": "worker",
        "count": 5,
        "resources": {
          "cpu": 8,
          "memory": "16Gi",
          "disk": "200Gi"
        }
      }
    ],
    "network": {
      "pod_subnet": "10.244.0.0/16",
      "service_subnet": "10.96.0.0/12"
    }
  }
}
```

### Node Management
**Add and remove nodes from clusters**

```http
POST /v1/orchestrate/talos_k8s/node/add
POST /v1/orchestrate/talos_k8s/node/remove
```

## Monitoring & Observability

### Monitoring Stack Deployment
**Deploy Prometheus, Grafana, and monitoring components**

```http
POST /v1/orchestrate/monitoring/deploy
```

**Request Body:**
```json
{
  "cluster_id": "production-cluster",
  "config": {
    "prometheus": {
      "retention": "30d",
      "storage": "100Gi"
    },
    "grafana": {
      "admin_password": "secure_password",
      "dashboards": ["kubernetes", "node-exporter", "prometheus"]
    },
    "alertmanager": {
      "slack_webhook": "https://hooks.slack.com/...",
      "email_notifications": ["admin@company.com"]
    }
  }
}
```

### Metrics Querying
**Query metrics from monitoring systems**

```http
GET /v1/orchestrate/monitoring/metrics?cluster_id=production&query=up
```

### Monitoring Status
**Get monitoring system health and status**

```http
GET /v1/orchestrate/monitoring/status?cluster_id=production
```

## Database Orchestration

### Database Provisioning
**Provision database instances**

```http
POST /v1/orchestrate/database/provision
```

**Request Body:**
```json
{
  "db_config": {
    "type": "postgresql",
    "version": "15",
    "name": "app_database",
    "resources": {
      "cpu": "2",
      "memory": "4Gi",
      "storage": "100Gi"
    },
    "backup": {
      "schedule": "0 2 * * *",
      "retention": "30d"
    },
    "high_availability": {
      "enabled": true,
      "replicas": 2
    }
  }
}
```

### Database Management
**Delete and monitor databases**

```http
POST /v1/orchestrate/database/delete
GET /v1/orchestrate/database/status
```

## Security & Compliance

### Security Scanning
**Run comprehensive security scans**

```http
POST /v1/orchestrate/security/scan
```

**Request Body:**
```json
{
  "target": "cluster:production-cluster",
  "scan_type": "full",
  "options": {
    "vulnerability_scan": true,
    "compliance_check": true,
    "network_scan": true,
    "container_scan": true
  }
}
```

### Security Reports
**Retrieve detailed security reports**

```http
GET /v1/orchestrate/security/report?report_id=scan_12345
```

## Workflow Automation

### Workflow Creation
**Create complex automation workflows**

```http
POST /v1/orchestrate/workflow/create
```

**Request Body:**
```json
{
  "workflow_config": {
    "name": "full-stack-deployment",
    "description": "Deploy complete application stack",
    "steps": [
      {
        "name": "provision-infrastructure",
        "type": "talos_k8s",
        "action": "create_cluster",
        "parameters": {"nodes": 3}
      },
      {
        "name": "deploy-monitoring",
        "type": "monitoring",
        "action": "deploy",
        "depends_on": ["provision-infrastructure"]
      },
      {
        "name": "provision-database",
        "type": "database",
        "action": "provision",
        "depends_on": ["provision-infrastructure"]
      },
      {
        "name": "security-scan",
        "type": "security",
        "action": "scan",
        "depends_on": ["deploy-monitoring", "provision-database"]
      }
    ],
    "notifications": {
      "on_success": ["admin@company.com"],
      "on_failure": ["ops@company.com"]
    }
  }
}
```

### Workflow Execution
**Execute workflows with parameters**

```http
POST /v1/orchestrate/workflow/execute
```

### Workflow Status
**Monitor workflow execution**

```http
GET /v1/orchestrate/workflow/status?workflow_id=wf_12345
```

## Traditional Infrastructure Automation

### Ansible Orchestration
```http
POST /v1/orchestrate/ansible/playbook
POST /v1/orchestrate/ansible/adhoc
POST /v1/orchestrate/ansible/create_playbook
GET /v1/orchestrate/ansible/playbooks
```

### Terraform Orchestration
```http
POST /v1/orchestrate/terraform/init
POST /v1/orchestrate/terraform/plan
POST /v1/orchestrate/terraform/apply
POST /v1/orchestrate/terraform/destroy
GET /v1/orchestrate/terraform/state
POST /v1/orchestrate/terraform/workspace
```

### Proxmox Orchestration
```http
POST /v1/orchestrate/proxmox/connect
GET /v1/orchestrate/proxmox/nodes
GET /v1/orchestrate/proxmox/vms
POST /v1/orchestrate/proxmox/vm/create
POST /v1/orchestrate/proxmox/vm/start
POST /v1/orchestrate/proxmox/vm/stop
GET /v1/orchestrate/proxmox/cluster/status
```

### SSH Orchestration
```http
POST /v1/orchestrate/ssh/connect
POST /v1/orchestrate/ssh/execute
POST /v1/orchestrate/ssh/upload
POST /v1/orchestrate/ssh/script
POST /v1/orchestrate/ssh/generate_keys
GET /v1/orchestrate/ssh/connections
```

### System Commands
```http
POST /v1/orchestrate/powershell
POST /v1/orchestrate/bash
```

## Error Handling

All endpoints return standardized error responses:

```json
{
  "status": "error",
  "message": "Detailed error description",
  "error_code": "RESOURCE_NOT_FOUND",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

Common HTTP status codes:
- `200` - Success
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Resource Not Found
- `500` - Internal Server Error
- `503` - Service Unavailable (all providers down)

## Rate Limiting

API requests are rate-limited per endpoint:
- AI endpoints: 100 requests/minute
- Orchestration endpoints: 50 requests/minute
- Long-running operations: 10 requests/minute

## WebSocket Support

Real-time updates for long-running operations:
```javascript
const ws = new WebSocket('ws://localhost:8080/v1/ws/status');
ws.onmessage = (event) => {
  const status = JSON.parse(event.data);
  console.log('Operation status:', status);
};
```

## SDK Examples

### Python
```python
import requests

# AI Chat
response = requests.post('http://localhost:8080/v1/chat/completions', json={
    'model': 'llama-3-8b',
    'messages': [{'role': 'user', 'content': 'Hello!'}]
})

# Create K8s Cluster
response = requests.post('http://localhost:8080/v1/orchestrate/talos_k8s/cluster/create', json={
    'cluster_config': {'name': 'test-cluster', 'nodes': 3}
})
```

### cURL
```bash
# AI Image Generation
curl -X POST http://localhost:8080/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A beautiful landscape", "n": 1}'

# Deploy Monitoring
curl -X POST http://localhost:8080/v1/orchestrate/monitoring/deploy \
  -H "Content-Type: application/json" \
  -d '{"cluster_id": "prod", "config": {}}'
```

---

For more examples and detailed documentation, see the `/docs` directory and visit the interactive API documentation at `http://localhost:8080/docs` when the service is running.

## Crypto, DeFi, and Financial Endpoints

### Crypto & Blockchain
```http
POST /v1/orchestrate/crypto/blockchain/setup         # Configure blockchain node connections
POST /v1/orchestrate/crypto/contracts/deploy         # Deploy/configure smart contracts
POST /v1/orchestrate/crypto/bridges/setup            # Set up cross-chain bridges
GET  /v1/orchestrate/crypto/health                   # Blockchain health check
POST /v1/orchestrate/crypto/nft/marketplace          # NFT marketplace setup
POST /v1/orchestrate/crypto/defi/protocols           # DeFi protocol configuration
POST /v1/orchestrate/crypto/portfolio/manage         # Portfolio management
```

### Revenue Optimization
```http
POST /v1/orchestrate/revenue/mining/setup            # Mining operations setup
POST /v1/orchestrate/revenue/compute/register        # Register compute resources (Vast.ai, Akash, etc.)
POST /v1/orchestrate/revenue/pricing/optimize        # Optimize pricing strategy
POST /v1/orchestrate/revenue/ai_services/setup       # Set up AI marketplace services
GET  /v1/orchestrate/revenue/monitor                 # Monitor revenue streams
```

### Financial Analytics
```http
POST /v1/orchestrate/financial/market_data/setup     # Set up market data feeds
POST /v1/orchestrate/financial/indicators/configure  # Configure technical indicators
POST /v1/orchestrate/financial/trading/setup         # Set up trading strategies
POST /v1/orchestrate/financial/compliance/setup      # Compliance monitoring
POST /v1/orchestrate/financial/reports/generate      # Generate financial reports
```

### Model Discovery
```http
GET /v1/models/discover/crypto                       # List available crypto/DeFi models
GET /v1/models/discover/financial                    # List available financial models
```

### Health Checks
```http
GET /v1/orchestrate/health/crypto                    # Crypto MCP health
GET /v1/orchestrate/health/revenue                   # Revenue MCP health
GET /v1/orchestrate/health/financial                 # Financial MCP health
```

---
