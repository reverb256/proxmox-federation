# Usage Examples - Consciousness Control Center

## Overview
This document provides practical examples for using the Consciousness Control Center's various capabilities, from basic AI interactions to complex infrastructure orchestration.

## AI & Multimodal Examples

### 1. Chat Completions
**Basic chat interaction with automatic model selection:**

```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3-8b",
    "messages": [
      {"role": "system", "content": "You are a helpful AI assistant specialized in infrastructure and DevOps."},
      {"role": "user", "content": "Explain the benefits of using Talos Linux for Kubernetes clusters."}
    ],
    "max_tokens": 500,
    "temperature": 0.7
  }'
```

**Streaming responses for real-time interaction:**

```python
import requests
import json

def stream_chat(messages):
    response = requests.post(
        'http://localhost:8080/v1/chat/completions',
        headers={'Content-Type': 'application/json'},
        json={
            'model': 'llama-3-8b',
            'messages': messages,
            'stream': True,
            'max_tokens': 500
        },
        stream=True
    )
    
    for line in response.iter_lines():
        if line:
            data = json.loads(line.decode('utf-8').split('data: ')[1])
            if data.get('choices') and data['choices'][0].get('delta'):
                content = data['choices'][0]['delta'].get('content', '')
                if content:
                    print(content, end='', flush=True)

# Example usage
messages = [
    {"role": "user", "content": "Write a Python script to monitor Kubernetes pods"}
]
stream_chat(messages)
```

### 2. Image Generation
**Generate images with fallback providers:**

```bash
# Basic image generation
curl -X POST http://localhost:8080/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A futuristic data center with AI-powered infrastructure, cyberpunk style, high detail",
    "n": 1,
    "size": "1024x1024",
    "style": "vivid"
  }'

# Batch image generation
curl -X POST http://localhost:8080/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Infrastructure automation workflow diagram, clean modern design",
    "n": 4,
    "size": "512x512"
  }'
```

### 3. Audio Processing
**Text-to-Speech conversion:**

```bash
curl -X POST http://localhost:8080/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tts-1",
    "input": "Welcome to the Consciousness Control Center. Your AI-powered infrastructure orchestration platform is ready.",
    "voice": "alloy",
    "response_format": "mp3"
  }' \
  --output welcome.mp3
```

**Speech-to-Text transcription:**

```bash
curl -X POST http://localhost:8080/v1/audio/transcriptions \
  -H "Content-Type: multipart/form-data" \
  -F "file=@meeting_recording.mp3" \
  -F "model=whisper-1" \
  -F "language=en" \
  -F "response_format=json"
```

### 4. Embeddings
**Generate embeddings for similarity search:**

```bash
curl -X POST http://localhost:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "model": "text-embedding-ada-002",
    "input": [
      "Kubernetes cluster management",
      "Docker container orchestration",
      "Infrastructure as code",
      "CI/CD pipeline automation"
    ]
  }'
```

## RAG (Retrieval-Augmented Generation) Examples

### 1. Document Management
**Add documents to knowledge base:**

```python
import requests

def add_document(title, content, metadata=None):
    response = requests.post(
        'http://localhost:8080/v1/rag/add_document',
        json={
            'title': title,
            'content': content,
            'metadata': metadata or {}
        }
    )
    return response.json()

# Add technical documentation
add_document(
    title="Kubernetes Deployment Guide",
    content="""
    Kubernetes Deployments provide declarative updates for Pods and ReplicaSets.
    You can define the desired state in a Deployment object, and the Deployment 
    Controller changes the actual state to the desired state at a controlled rate.
    
    Basic deployment example:
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.14.2
            ports:
            - containerPort: 80
    """,
    metadata={
        "category": "kubernetes",
        "type": "deployment",
        "difficulty": "beginner"
    }
)

# Add infrastructure best practices
add_document(
    title="Talos Linux Best Practices",
    content="""
    Talos Linux is a modern OS designed for running Kubernetes. Best practices include:
    1. Use immutable infrastructure principles
    2. Configure proper networking with CNI
    3. Implement proper backup strategies
    4. Monitor cluster health continuously
    5. Use GitOps for configuration management
    """,
    metadata={
        "category": "talos",
        "type": "best-practices"
    }
)
```

**Web crawling for knowledge base:**

```bash
# Crawl documentation websites
curl -X POST http://localhost:8080/v1/rag/crawl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://kubernetes.io/docs/concepts/",
    "max_depth": 2,
    "include_patterns": ["*.html"],
    "exclude_patterns": ["**/api/**", "**/reference/**"],
    "max_pages": 50
  }'

# Crawl specific pages
curl -X POST http://localhost:8080/v1/rag/crawl \
  -H "Content-Type: application/json" \
  -d '{
    "urls": [
      "https://www.talos.dev/docs/",
      "https://prometheus.io/docs/",
      "https://grafana.com/docs/"
    ],
    "max_depth": 1
  }'
```

### 2. Information Retrieval
**Search knowledge base:**

```bash
curl -X POST http://localhost:8080/v1/rag/retrieve \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How to configure Prometheus monitoring for Kubernetes clusters?",
    "top_k": 5,
    "filters": {
      "category": ["kubernetes", "monitoring"]
    }
  }'
```

**Question answering with context:**

```python
import requests

def ask_question(question, context=None, use_history=True):
    response = requests.post(
        'http://localhost:8080/v1/rag/qa',
        json={
            'question': question,
            'context': context,
            'use_retrieval': True,
            'top_k': 3,
            'include_sources': True,
            'use_history': use_history
        }
    )
    return response.json()

# Infrastructure questions
result = ask_question(
    "What are the key advantages of using Talos Linux for Kubernetes clusters?"
)
print("Answer:", result['answer'])
print("Sources:", result['sources'])

# Follow-up questions with context
result = ask_question(
    "How do I implement high availability for this setup?",
    context="kubernetes cluster deployment"
)
print("Answer:", result['answer'])
```

### 3. Document Management
**List and manage documents:**

```bash
# List all documents
curl http://localhost:8080/v1/rag/documents

# List documents with filters
curl "http://localhost:8080/v1/rag/documents?category=kubernetes&limit=10"

# Search documents by content
curl -X POST http://localhost:8080/v1/rag/documents/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "deployment strategies",
    "filters": {"type": "best-practices"}
  }'
```

## Agentic Orchestration Examples

### 1. Agent Creation and Management
**Create specialized agents:**

```python
import requests

def create_agent(name, capabilities, tools):
    response = requests.post(
        'http://localhost:8080/v1/agent/create',
        json={
            'name': name,
            'capabilities': capabilities,
            'tools': tools,
            'personality': 'professional and helpful',
            'expertise_level': 'expert'
        }
    )
    return response.json()

# Create infrastructure automation agent
infra_agent = create_agent(
    name="InfrastructureExpert",
    capabilities=[
        "kubernetes_management",
        "talos_administration", 
        "monitoring_setup",
        "security_configuration"
    ],
    tools=[
        "kubectl",
        "talosctl",
        "ansible",
        "terraform",
        "prometheus_config"
    ]
)

# Create DevOps automation agent
devops_agent = create_agent(
    name="DevOpsAutomation",
    capabilities=[
        "ci_cd_setup",
        "deployment_automation",
        "monitoring_configuration",
        "troubleshooting"
    ],
    tools=[
        "github_actions",
        "jenkins",
        "docker",
        "helm",
        "monitoring_tools"
    ]
)
```

**List available agents:**

```bash
curl http://localhost:8080/v1/agent/list
```

### 2. Task Execution
**Execute complex infrastructure tasks:**

```bash
# Deploy complete monitoring stack
curl -X POST http://localhost:8080/v1/agent/act \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Set up comprehensive monitoring for a Kubernetes cluster including Prometheus, Grafana, and AlertManager with proper dashboards and alerts",
    "agent": "InfrastructureExpert",
    "parameters": {
      "cluster_name": "production-cluster",
      "namespace": "monitoring",
      "storage_size": "100Gi",
      "retention_period": "30d",
      "alert_channels": ["email", "slack"]
    },
    "context": {
      "cluster_size": "medium",
      "environment": "production",
      "compliance_requirements": ["SOC2", "PCI"]
    }
  }'

# Troubleshoot cluster issues
curl -X POST http://localhost:8080/v1/agent/act \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Diagnose and fix performance issues in Kubernetes cluster - pods are taking too long to start",
    "agent": "InfrastructureExpert",
    "parameters": {
      "cluster_name": "production-cluster",
      "affected_namespaces": ["default", "app-namespace"],
      "symptoms": ["slow_pod_startup", "high_cpu_usage", "network_timeouts"]
    }
  }'
```

**Multi-step automation workflows:**

```python
import requests
import time

def execute_workflow(steps):
    task_ids = []
    
    for step in steps:
        response = requests.post(
            'http://localhost:8080/v1/agent/act',
            json=step
        )
        task_id = response.json().get('task_id')
        task_ids.append(task_id)
        
        # Wait for step completion before proceeding
        while True:
            status = requests.get(f'http://localhost:8080/v1/agent/status/{task_id}')
            if status.json().get('status') == 'completed':
                break
            time.sleep(10)
    
    return task_ids

# Complex deployment workflow
workflow_steps = [
    {
        "task": "Create and configure a new Talos Kubernetes cluster",
        "agent": "InfrastructureExpert",
        "parameters": {
            "cluster_name": "staging-cluster",
            "nodes": {"controlplane": 3, "worker": 5},
            "network_config": "cilium"
        }
    },
    {
        "task": "Deploy monitoring stack on the new cluster",
        "agent": "InfrastructureExpert", 
        "parameters": {
            "cluster_name": "staging-cluster",
            "monitoring_type": "full_stack"
        }
    },
    {
        "task": "Set up CI/CD pipeline for the new cluster",
        "agent": "DevOpsAutomation",
        "parameters": {
            "cluster_name": "staging-cluster",
            "pipeline_type": "github_actions",
            "deploy_strategy": "blue_green"
        }
    }
]

task_ids = execute_workflow(workflow_steps)
print(f"Workflow completed with tasks: {task_ids}")
```

### 3. Agent History and Analytics
**Track agent performance:**

```bash
# Get agent execution history
curl "http://localhost:8080/v1/agent/history?agent=InfrastructureExpert&limit=20"

# Get task details
curl "http://localhost:8080/v1/agent/task/12345/details"

# Agent performance metrics
curl "http://localhost:8080/v1/agent/metrics?timeframe=7d"
```

## Talos/K8s Orchestration Examples

### 1. Cluster Management
**Create production-ready cluster:**

```python
import requests

def create_talos_cluster(config):
    response = requests.post(
        'http://localhost:8080/v1/orchestrate/talos_k8s/cluster/create',
        json={'cluster_config': config}
    )
    return response.json()

# Production cluster configuration
cluster_config = {
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
            },
            "talos_config": {
                "install_disk": "/dev/sda",
                "network_interface": "eth0"
            }
        },
        {
            "type": "worker", 
            "count": 5,
            "resources": {
                "cpu": 8,
                "memory": "16Gi", 
                "disk": "200Gi"
            },
            "labels": {
                "node-type": "worker",
                "zone": "us-west-2a"
            }
        }
    ],
    "network": {
        "pod_subnet": "10.244.0.0/16",
        "service_subnet": "10.96.0.0/12",
        "cni": "cilium"
    },
    "features": {
        "encryption_at_rest": true,
        "audit_logging": true,
        "admission_controllers": [
            "PodSecurityPolicy",
            "NetworkPolicy"
        ]
    }
}

result = create_talos_cluster(cluster_config)
print(f"Cluster creation initiated: {result}")
```

**Scale cluster nodes:**

```bash
# Add worker nodes
curl -X POST http://localhost:8080/v1/orchestrate/talos_k8s/node/add \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_id": "production-cluster",
    "node_config": {
      "type": "worker",
      "count": 2,
      "resources": {
        "cpu": 8,
        "memory": "16Gi",
        "disk": "200Gi"
      },
      "labels": {
        "node-type": "high-memory",
        "workload": "data-processing"
      }
    }
  }'

# Remove nodes
curl -X POST http://localhost:8080/v1/orchestrate/talos_k8s/node/remove \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_id": "production-cluster", 
    "node_id": "worker-node-6"
  }'
```

### 2. Cluster Monitoring
**Monitor cluster health:**

```bash
# Get comprehensive cluster status
curl "http://localhost:8080/v1/orchestrate/talos_k8s/cluster/status?cluster_id=production-cluster"

# Get node-specific information
curl "http://localhost:8080/v1/orchestrate/talos_k8s/nodes?cluster_id=production-cluster"

# Check cluster resource usage
curl "http://localhost:8080/v1/orchestrate/talos_k8s/cluster/resources?cluster_id=production-cluster"
```

## Monitoring & Observability Examples

### 1. Deploy Monitoring Stack
**Full monitoring deployment:**

```bash
curl -X POST http://localhost:8080/v1/orchestrate/monitoring/deploy \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_id": "production-cluster",
    "config": {
      "prometheus": {
        "retention": "30d",
        "storage_size": "100Gi",
        "scrape_interval": "15s",
        "evaluation_interval": "15s",
        "external_labels": {
          "cluster": "production",
          "environment": "prod"
        }
      },
      "grafana": {
        "admin_password": "secure_password_here",
        "persistence": {
          "enabled": true,
          "size": "10Gi"
        },
        "dashboards": [
          "kubernetes-cluster-overview",
          "kubernetes-node-overview", 
          "kubernetes-pod-overview",
          "talos-system-metrics"
        ],
        "plugins": [
          "grafana-piechart-panel",
          "grafana-worldmap-panel"
        ]
      },
      "alertmanager": {
        "storage_size": "10Gi",
        "config": {
          "global": {
            "smtp_smarthost": "smtp.company.com:587",
            "smtp_from": "alerts@company.com"
          },
          "receivers": [
            {
              "name": "team-slack",
              "slack_configs": [
                {
                  "api_url": "https://hooks.slack.com/services/...",
                  "channel": "#infrastructure-alerts",
                  "title": "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"
                }
              ]
            },
            {
              "name": "email-alerts",
              "email_configs": [
                {
                  "to": "devops@company.com",
                  "subject": "{{ .GroupLabels.alertname }} - {{ .Status }}"
                }
              ]
            }
          ],
          "routes": [
            {
              "match": {"severity": "critical"},
              "receiver": "team-slack"
            },
            {
              "match": {"severity": "warning"},
              "receiver": "email-alerts"
            }
          ]
        }
      },
      "node_exporter": {
        "enabled": true,
        "collect_systemd": true
      },
      "kube_state_metrics": {
        "enabled": true
      }
    }
  }'
```

### 2. Query Metrics
**Prometheus queries:**

```bash
# CPU usage across nodes
curl "http://localhost:8080/v1/orchestrate/monitoring/metrics?cluster_id=production-cluster&query=100-(avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)"

# Memory usage
curl "http://localhost:8080/v1/orchestrate/monitoring/metrics?cluster_id=production-cluster&query=(1-(node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))*100"

# Pod status
curl "http://localhost:8080/v1/orchestrate/monitoring/metrics?cluster_id=production-cluster&query=kube_pod_status_phase"

# Custom application metrics
curl "http://localhost:8080/v1/orchestrate/monitoring/metrics?cluster_id=production-cluster&query=rate(http_requests_total[5m])"
```

### 3. Monitoring Status
**Check monitoring health:**

```bash
curl "http://localhost:8080/v1/orchestrate/monitoring/status?cluster_id=production-cluster"
```

## Database Orchestration Examples

### 1. Database Provisioning
**Deploy PostgreSQL cluster:**

```bash
curl -X POST http://localhost:8080/v1/orchestrate/database/provision \
  -H "Content-Type: application/json" \
  -d '{
    "db_config": {
      "type": "postgresql",
      "version": "15",
      "name": "application_database",
      "resources": {
        "cpu": "4",
        "memory": "8Gi",
        "storage": "200Gi"
      },
      "high_availability": {
        "enabled": true,
        "replicas": 2,
        "sync_mode": "synchronous"
      },
      "backup": {
        "schedule": "0 2 * * *",
        "retention": "30d",
        "storage_class": "fast-ssd"
      },
      "monitoring": {
        "enabled": true,
        "custom_metrics": true
      },
      "security": {
        "ssl_enabled": true,
        "encryption_at_rest": true,
        "connection_limit": 100
      },
      "configuration": {
        "shared_buffers": "2GB",
        "effective_cache_size": "6GB",
        "maintenance_work_mem": "512MB",
        "max_connections": 200
      }
    }
  }'
```

**Deploy Redis cluster:**

```bash
curl -X POST http://localhost:8080/v1/orchestrate/database/provision \
  -H "Content-Type: application/json" \
  -d '{
    "db_config": {
      "type": "redis",
      "version": "7.0",
      "name": "cache_cluster",
      "mode": "cluster",
      "nodes": 6,
      "resources": {
        "cpu": "2",
        "memory": "4Gi",
        "storage": "50Gi"
      },
      "persistence": {
        "enabled": true,
        "backup_schedule": "0 */6 * * *"
      },
      "security": {
        "auth_enabled": true,
        "tls_enabled": true
      }
    }
  }'
```

### 2. Database Management
**Monitor database status:**

```bash
# Get detailed database status
curl "http://localhost:8080/v1/orchestrate/database/status?db_id=application_database"

# List all databases
curl "http://localhost:8080/v1/orchestrate/database/list"
```

## Security Scanning Examples

### 1. Comprehensive Security Scans
**Full cluster security assessment:**

```bash
curl -X POST http://localhost:8080/v1/orchestrate/security/scan \
  -H "Content-Type: application/json" \
  -d '{
    "target": "cluster:production-cluster",
    "scan_type": "comprehensive",
    "options": {
      "vulnerability_scan": true,
      "compliance_check": true,
      "network_scan": true,
      "container_scan": true,
      "configuration_scan": true,
      "rbac_analysis": true,
      "policy_violations": true
    },
    "compliance_frameworks": [
      "CIS_Kubernetes",
      "NIST_800-53",
      "SOC2",
      "PCI_DSS"
    ],
    "severity_levels": ["critical", "high", "medium", "low"],
    "output_format": "json"
  }'
```

**Container image scanning:**

```bash
curl -X POST http://localhost:8080/v1/orchestrate/security/scan \
  -H "Content-Type: application/json" \
  -d '{
    "target": "image:nginx:1.21",
    "scan_type": "container",
    "options": {
      "vulnerability_scan": true,
      "malware_scan": true,
      "secret_detection": true,
      "license_check": true
    }
  }'
```

### 2. Security Reports
**Retrieve and analyze reports:**

```bash
# Get scan report
curl "http://localhost:8080/v1/orchestrate/security/report?report_id=scan_12345"

# Get security summary
curl "http://localhost:8080/v1/orchestrate/security/summary?cluster_id=production-cluster&timeframe=30d"
```

## Workflow Automation Examples

### 1. Complex Deployment Workflows
**Full-stack application deployment:**

```python
import requests

def create_deployment_workflow():
    workflow_config = {
        "name": "full-stack-deployment",
        "description": "Deploy complete application stack with monitoring and security",
        "version": "1.0",
        "steps": [
            {
                "name": "provision-infrastructure",
                "type": "talos_k8s",
                "action": "create_cluster",
                "parameters": {
                    "cluster_name": "app-cluster",
                    "nodes": {"controlplane": 3, "worker": 5}
                },
                "timeout": "30m"
            },
            {
                "name": "deploy-monitoring",
                "type": "monitoring",
                "action": "deploy_stack", 
                "depends_on": ["provision-infrastructure"],
                "parameters": {
                    "cluster_id": "app-cluster",
                    "monitoring_type": "full"
                },
                "timeout": "15m"
            },
            {
                "name": "provision-database",
                "type": "database",
                "action": "provision",
                "depends_on": ["provision-infrastructure"],
                "parameters": {
                    "type": "postgresql",
                    "high_availability": True
                },
                "timeout": "20m"
            },
            {
                "name": "security-baseline",
                "type": "security",
                "action": "baseline_scan",
                "depends_on": ["deploy-monitoring", "provision-database"],
                "parameters": {
                    "target": "cluster:app-cluster",
                    "compliance": ["CIS_Kubernetes"]
                },
                "timeout": "10m"
            },
            {
                "name": "deploy-application",
                "type": "agent",
                "action": "deploy_app",
                "depends_on": ["security-baseline"],
                "parameters": {
                    "app_name": "web-application",
                    "replicas": 3,
                    "health_checks": True
                },
                "timeout": "10m"
            }
        ],
        "error_handling": {
            "on_failure": "rollback",
            "retry_attempts": 2,
            "rollback_steps": ["cleanup-resources", "notify-team"]
        },
        "notifications": {
            "on_success": {
                "channels": ["email", "slack"],
                "recipients": ["devops@company.com", "#deployments"]
            },
            "on_failure": {
                "channels": ["email", "slack", "pagerduty"],
                "recipients": ["oncall@company.com", "#critical-alerts"]
            }
        }
    }
    
    response = requests.post(
        'http://localhost:8080/v1/orchestrate/workflow/create',
        json={'workflow_config': workflow_config}
    )
    return response.json()

# Create the workflow
workflow = create_deployment_workflow()
print(f"Workflow created: {workflow['workflow_id']}")
```

### 2. Execute Workflows
**Run workflow with parameters:**

```bash
curl -X POST http://localhost:8080/v1/orchestrate/workflow/execute \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id": "wf_12345",
    "parameters": {
      "environment": "staging",
      "app_version": "v2.1.0",
      "scale_factor": 1.5,
      "enable_debugging": true
    },
    "scheduling": {
      "execution_time": "immediate",
      "max_duration": "2h"
    }
  }'
```

### 3. Monitor Workflow Execution
**Track workflow progress:**

```python
import requests
import time

def monitor_workflow(workflow_id):
    while True:
        response = requests.get(
            f'http://localhost:8080/v1/orchestrate/workflow/status?workflow_id={workflow_id}'
        )
        status = response.json()
        
        print(f"Workflow Status: {status['status']}")
        print(f"Current Step: {status['current_step']}")
        print(f"Progress: {status['progress']}%")
        
        if status['status'] in ['completed', 'failed', 'cancelled']:
            break
            
        time.sleep(30)
    
    return status

# Monitor workflow execution
final_status = monitor_workflow('wf_12345')
print(f"Final Status: {final_status}")
```

## Integration Examples

### 1. Open WebUI Integration
**Configure Open WebUI to use the gateway:**

```yaml
# docker-compose.openwebui.yml
version: '3.8'
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "3000:8080"
    environment:
      - OPENAI_API_BASE_URL=http://gateway:8080/v1
      - OPENAI_API_KEY=consciousness-api-key
      - WEBUI_NAME=Consciousness Control Center
      - WEBUI_AUTH=false
      - ENABLE_RAG_TOOL=true
      - ENABLE_SEARCH_TOOL=true
    volumes:
      - open-webui-data:/app/backend/data
    depends_on:
      - gateway
```

### 2. CI/CD Pipeline Integration
**GitHub Actions workflow:**

```yaml
# .github/workflows/deploy.yml
name: Deploy with Consciousness Control Center

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy Infrastructure
        run: |
          curl -X POST ${{ secrets.CONSCIOUSNESS_API_URL }}/v1/agent/act \
            -H "Authorization: Bearer ${{ secrets.CONSCIOUSNESS_API_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{
              "task": "Deploy application infrastructure for ${{ github.repository }}",
              "agent": "InfrastructureExpert", 
              "parameters": {
                "repository": "${{ github.repository }}",
                "branch": "${{ github.ref_name }}",
                "environment": "production"
              }
            }'
      
      - name: Run Security Scan
        run: |
          curl -X POST ${{ secrets.CONSCIOUSNESS_API_URL }}/v1/orchestrate/security/scan \
            -H "Authorization: Bearer ${{ secrets.CONSCIOUSNESS_API_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{
              "target": "repository:${{ github.repository }}",
              "scan_type": "comprehensive"
            }'
```

### 3. Custom Application Integration
**Python application using the API:**

```python
import asyncio
import aiohttp
from typing import Dict, List

class ConsciousnessClient:
    def __init__(self, base_url: str, api_key: str = None):
        self.base_url = base_url
        self.api_key = api_key
        self.session = None
    
    async def __aenter__(self):
        headers = {}
        if self.api_key:
            headers['Authorization'] = f'Bearer {self.api_key}'
        
        self.session = aiohttp.ClientSession(
            base_url=self.base_url,
            headers=headers
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def chat(self, messages: List[Dict], model: str = "llama-3-8b"):
        async with self.session.post('/v1/chat/completions', json={
            'model': model,
            'messages': messages
        }) as response:
            return await response.json()
    
    async def ask_rag(self, question: str, context: str = None):
        async with self.session.post('/v1/rag/qa', json={
            'question': question,
            'context': context
        }) as response:
            return await response.json()
    
    async def execute_task(self, task: str, agent: str = "InfrastructureExpert"):
        async with self.session.post('/v1/agent/act', json={
            'task': task,
            'agent': agent
        }) as response:
            return await response.json()
    
    async def create_cluster(self, cluster_config: Dict):
        async with self.session.post('/v1/orchestrate/talos_k8s/cluster/create', 
                                   json={'cluster_config': cluster_config}) as response:
            return await response.json()

# Usage example
async def main():
    async with ConsciousnessClient('http://localhost:8080', 'your-api-key') as client:
        # Chat with AI
        response = await client.chat([
            {"role": "user", "content": "Explain Kubernetes networking"}
        ])
        print("AI Response:", response)
        
        # Ask RAG question
        answer = await client.ask_rag(
            "How do I configure persistent volumes in Kubernetes?"
        )
        print("RAG Answer:", answer)
        
        # Execute infrastructure task
        task_result = await client.execute_task(
            "Set up a production-ready Kubernetes cluster with monitoring"
        )
        print("Task Result:", task_result)

if __name__ == "__main__":
    asyncio.run(main())
```

## Performance and Optimization Examples

### 1. Load Testing
**Stress test the API:**

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test chat completions
ab -n 100 -c 10 -T 'application/json' -p chat_payload.json \
  http://localhost:8080/v1/chat/completions

# Test RAG queries
ab -n 50 -c 5 -T 'application/json' -p rag_payload.json \
  http://localhost:8080/v1/rag/qa

# Test orchestration endpoints
ab -n 20 -c 2 -T 'application/json' -p cluster_status_payload.json \
  http://localhost:8080/v1/orchestrate/talos_k8s/cluster/status
```

### 2. Monitoring Performance
**Track API performance:**

```python
import requests
import time
import statistics

def benchmark_endpoint(url, payload, iterations=10):
    response_times = []
    
    for i in range(iterations):
        start_time = time.time()
        response = requests.post(url, json=payload)
        end_time = time.time()
        
        response_times.append(end_time - start_time)
        print(f"Request {i+1}: {response.status_code} - {end_time - start_time:.2f}s")
    
    print(f"Average response time: {statistics.mean(response_times):.2f}s")
    print(f"Median response time: {statistics.median(response_times):.2f}s")
    print(f"Min response time: {min(response_times):.2f}s")
    print(f"Max response time: {max(response_times):.2f}s")

# Benchmark chat completions
chat_payload = {
    "model": "llama-3-8b",
    "messages": [{"role": "user", "content": "Hello, world!"}],
    "max_tokens": 50
}

benchmark_endpoint(
    'http://localhost:8080/v1/chat/completions',
    chat_payload,
    iterations=20
)
```

## Crypto, DeFi, and Financial Examples

### 1. Blockchain Node Setup
```bash
curl -X POST http://localhost:8080/v1/orchestrate/crypto/blockchain/setup \
  -H "Content-Type: application/json" \
  -d '{"chain_configs": [{"chain": "ethereum", "rpc_url": "https://mainnet.infura.io/v3/KEY"}]}'
```

### 2. Mining Operations Setup
```bash
curl -X POST http://localhost:8080/v1/orchestrate/revenue/mining/setup \
  -H "Content-Type: application/json" \
  -d '{"mining_configs": [{"coin": "ethereum", "software": "t-rex", "pool": "stratum+tcp://ethpool.org:3333", "wallet": "0x..."}]}'
```

### 3. Financial Market Data Feed
```bash
curl -X POST http://localhost:8080/v1/orchestrate/financial/market_data/setup \
  -H "Content-Type: application/json" \
  -d '{"feed_configs": [{"provider": "binance", "symbols": ["BTCUSDT", "ETHUSDT"]}]}'
```

### 4. NFT Marketplace Setup
```bash
curl -X POST http://localhost:8080/v1/orchestrate/crypto/nft/marketplace \
  -H "Content-Type: application/json" \
  -d '{"marketplace_config": {"name": "MyNFTMarket", "chains": ["ethereum"], "enable_auctions": true}}'
```

### 5. Revenue Stream Monitoring
```bash
curl -X GET "http://localhost:8080/v1/orchestrate/revenue/monitor?stream_ids=['mining_eth','compute_vast']"
```

This comprehensive usage guide provides practical examples for all major features of the Consciousness Control Center, from basic AI interactions to complex infrastructure orchestration workflows.
