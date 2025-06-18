# 🧠 Consciousness Zero Command Center

**Agent Zero + MCP Crawl4AI Inspired AI Infrastructure Orchestration**

An open-source, AI-powered command center for orchestrating Proxmox clusters and infrastructure management. Built with Agent Zero's hierarchical agent architecture and enhanced with MCP Crawl4AI RAG capabilities.

## ✨ Features

### 🏗️ **Agent Zero Architecture**
- **Hierarchical Agent System**: Multi-level agent delegation and communication
- **Tool Ecosystem**: Modular, extensible tools for various operations
- **Memory System**: Persistent learning with fragments and solutions storage
- **Dynamic Reasoning**: Context-aware decision making and problem solving

### 🌐 **MCP Crawl4AI Integration**
- **Intelligent Web Crawling**: AI-powered web search and information extraction
- **RAG Capabilities**: Retrieval-Augmented Generation for informed responses
- **Knowledge Management**: Local knowledge base with semantic search

### 🚀 **Infrastructure Orchestration**
- **Proxmox Federation**: Multi-node cluster management and monitoring
- **Workload Deployment**: Automated consciousness stack deployments
- **Resource Monitoring**: Real-time system and cluster health tracking
- **Self-Healing**: Automated problem detection and resolution

### 🤖 **AI-Powered Intelligence**
- **No Paid APIs**: Uses only Hugging Face and IO Intelligence (free tier available)
- **Local AI Models**: Offline-capable with local embedding and language models
- **Adaptive Learning**: Learns from interactions and saves successful solutions
- **Multi-Modal**: Supports text, code, and structured data processing

## 🚀 Quick Start

### Prerequisites
- Linux system with 4GB+ RAM (32GB detected ✅)
- Python 3.11+ with virtual environment
- Internet connection for model downloads
- Optional: NVIDIA GPU for acceleration

### Installation
```bash
# Clone and setup
cd /root/consciousness-control-center/proxmox-federation

# Validate environment (already done ✅)
./validate_consciousness_zero.sh

# Configure environment (optional)
cp .env.example .env
# Edit .env with your API keys

# Start the command center
./start_consciousness_zero.sh
```

### Access
- **Web Interface**: http://localhost:7860
- **API Documentation**: http://localhost:7860/docs
- **Health Check**: http://localhost:7860/status

## 🧠 Agent Architecture

### Core Components

#### 1. **ConsciousnessAgent**
Main AI agent with reasoning capabilities:
```python
agent = ConsciousnessAgent(config)
result = await agent.process_message("Deploy AI inference workload")
```

#### 2. **Tool System**
Modular tools for different operations:
- `cluster_status`: Monitor Proxmox federation health
- `deploy_workload`: Orchestrate workload deployments  
- `web_search`: AI-powered web research
- `shell_execute`: Safe command execution
- `memory_tool`: Save and recall information
- `knowledge_tool`: Access local documentation

#### 3. **Memory System**
Persistent learning and recall:
```python
# Save insights
agent.memory.save_fragment("Successful deployment config X")

# Search memories
results = agent.memory.search_fragments("deployment errors")

# Store solutions
agent.memory.save_solution("Deploy issue Y", "Solution Z")
```

#### 4. **Knowledge Base**
Local documentation and information:
- Markdown files in `knowledge/` directory
- Automated indexing and search
- Integration with web search results

## 🛠️ Available Tools

### Infrastructure Management
```bash
# Check cluster status
"Check cluster status"
"What's the health of my federation?"

# Deploy workloads  
"Deploy AI inference stack"
"Deploy web frontend on forge node"
```

### Information & Research
```bash
# Web search
"Search for Kubernetes best practices"
"Find latest Docker security updates"

# Knowledge base
"Show documentation about deployments"
"What are the memory management guidelines?"
```

### System Operations
```bash
# Safe command execution
"Execute ps aux command"
"Show system disk usage"
"Check service status"

# Memory operations
"Remember this configuration"
"What did I deploy yesterday?"
"Save this solution for later"
```

## 🔧 Configuration

### Environment Variables (.env)
```bash
# API Configuration
IO_API_KEY=your_io_intelligence_api_key
HF_TOKEN=your_huggingface_token

# Model Configuration  
EMBEDDING_MODEL=all-MiniLM-L6-v2
CONVERSATION_MODEL=microsoft/DialoGPT-medium

# Infrastructure
PROXMOX_HOST=your_proxmox_host
PROXMOX_USER=root@pam
PROXMOX_PASSWORD=your_password

# Server Settings
WEB_PORT=7860
API_PORT=8888
```

### Agent Configuration
```python
config = AgentConfig(
    io_api_key="your_key",
    hf_token="your_token", 
    tools_enabled=["cluster_status", "deploy_workload", "web_search"],
    memory_dir="./memory",
    knowledge_dir="./knowledge"
)
```

## 🌐 Web Interface

### Gradio Dashboard
- **Chat Interface**: Natural language interaction with the AI agent
- **Quick Actions**: One-click status checks and deployments
- **System Monitoring**: Real-time resource usage display
- **Tool Results**: Detailed output from agent tool executions

### API Endpoints
- `POST /chat`: Send messages to the agent
- `GET /status`: System health and agent status
- `GET /tools`: List available tools
- `GET /memory/search/{query}`: Search agent memory

## 🧪 Testing & Validation

### Validation Script
```bash
./validate_consciousness_zero.sh
```
Checks:
- ✅ Virtual environment setup
- ✅ Python dependencies  
- ✅ Agent functionality
- ✅ Tool availability
- ✅ Memory system
- ✅ Network connectivity
- ✅ System resources

### Manual Testing
```python
# Test agent interaction
from consciousness_zero_command_center import AgentConfig, ConsciousnessAgent

config = AgentConfig()
agent = ConsciousnessAgent(config)

# Test message processing
result = await agent.process_message("Hello, check cluster status")
print(result['response'])
```

## 📚 Architecture Inspiration

### Agent Zero Framework
- **Hierarchical Agents**: Parent-child agent delegation
- **Tool Integration**: Modular tool system with standardized interfaces
- **Memory Management**: Persistent storage of interactions and solutions
- **Reasoning Engine**: Context-aware problem solving and decision making

### MCP Crawl4AI Features  
- **Web Intelligence**: Advanced web crawling and content extraction
- **RAG Integration**: Retrieval-Augmented Generation for contextual responses
- **Model Context Protocol**: Standardized AI tool interactions
- **Semantic Search**: Vector-based information retrieval

## 🔒 Security Features

### Safe Command Execution
- Whitelist of allowed commands
- Input sanitization and validation
- Execution timeout limits
- Audit logging of all commands

### API Security
- CORS configuration
- Request rate limiting
- Input validation
- Error handling and logging

## 📊 Monitoring & Observability

### System Metrics
- CPU, memory, and disk usage
- Network connectivity status
- Agent performance metrics
- Tool execution statistics

### Logging
- Structured logging with timestamps
- Error tracking and alerting
- Agent decision audit trail
- Tool execution history

## 🛡️ Troubleshooting

### Common Issues

#### "Virtual environment not found"
```bash
# Run the setup script
./local-validation.sh
```

#### "Missing dependencies"
```bash
# Install requirements
pip install -r requirements.txt
pip install crawl4ai
```

#### "Agent import errors"
```bash
# Validate setup
./validate_consciousness_zero.sh
```

#### "GPU not detected"
- Optional for acceleration
- CPU-only operation is fully supported
- For GPU: install CUDA toolkit

### Debug Mode
```bash
# Enable debug logging
export LOG_LEVEL=DEBUG
./start_consciousness_zero.sh
```

## 🚀 Deployment Options

### Local Development
```bash
./start_consciousness_zero.sh
```

### Docker Deployment
```bash
# Build image
docker build -t consciousness-zero .

# Run container
docker run -p 7860:7860 consciousness-zero
```

### Production Deployment
- Use reverse proxy (nginx/traefik)
- Configure TLS certificates
- Set up monitoring and alerting
- Configure backup for memory/knowledge

## 🤝 Contributing

### Adding New Tools
1. Inherit from `Tool` base class
2. Implement `execute()` method
3. Add to agent configuration
4. Update documentation

### Extending Memory System
- Custom fragment types
- Enhanced search algorithms
- Integration with vector databases
- Export/import capabilities

### Web Interface Enhancements
- Custom Gradio components
- Advanced visualizations
- Mobile responsiveness
- Real-time updates

## 📈 Performance

### Benchmarks (Current System)
- **RAM Usage**: ~2GB baseline + models
- **CPU Cores**: 32 available (2+ recommended)
- **Disk Space**: 933GB free (5GB+ required)
- **Response Time**: < 2s for most operations
- **Concurrent Users**: 10+ supported

### Optimization Tips
- Use GPU for model acceleration
- Enable model quantization for memory efficiency  
- Configure connection pooling for external APIs
- Implement caching for frequent operations

## 📄 License

Open source project - see LICENSE file for details.

---

**🧠 Built with consciousness, orchestrated with intelligence.**

For support or questions, check the agent's built-in help system or review the knowledge base documentation.
