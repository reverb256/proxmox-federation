# 🧠 AI Command Center - Consciousness Orchestration Hub

A comprehensive AI orchestration platform that integrates **Hugging Face** and **IO Intelligence** models with specialized agents to serve as a consciousness orchestration hub.

## 🌟 Features

### 🤖 Multi-Model Integration
- **IO Intelligence API**: Access to 40+ advanced models including Llama 3.3 70B, DeepSeek R1, Qwen 3 235B
- **Hugging Face Models**: Local and cloud-based model support
- **OpenAI Compatibility**: Seamless integration with OpenAI-compatible APIs

### 🎯 Specialized AI Agents
- **Reasoning Agent**: Logic-driven problem solving and analysis
- **Code Assistant**: Programming expert with debugging capabilities
- **Summary Agent**: Content summarization and key information extraction
- **Research Agent**: Information gathering and synthesis
- **Creative Assistant**: Creative writing and brainstorming

### 🔄 Advanced Workflows
- **IO Intelligence Workflows**: Specialized agent workflows for complex tasks
- **Model Comparison**: Side-by-side comparison of different models
- **Streaming Responses**: Real-time response streaming
- **Conversation History**: Persistent conversation tracking

### 🌐 Dual Interface
- **Gradio Web UI**: User-friendly interface for interactive sessions
- **FastAPI Backend**: RESTful API for programmatic access
- **Real-time Monitoring**: System status and performance metrics

## 🚀 Quick Start

### 1. Prerequisites
```bash
# Ensure Python 3.8+ is installed
python3 --version

# Optional: NVIDIA GPU for accelerated inference
nvidia-smi
```

### 2. Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your API keys
nano .env
```

Required API keys:
- `IOINTELLIGENCE_API_KEY`: Get from [IO Intelligence Dashboard](https://ai.io.net/ai/api-keys)
- `HUGGINGFACE_TOKEN`: Get from [Hugging Face Settings](https://huggingface.co/settings/tokens)

### 3. Launch the AI Command Center
```bash
# Start all services
./start_ai_command_center.sh

# Or start with explicit command
./start_ai_command_center.sh start
```

### 4. Access the Interfaces
- **Gradio Web UI**: http://localhost:7860
- **FastAPI Docs**: http://localhost:8000/docs
- **API Status**: http://localhost:8000/status

## 📖 Usage Guide

### Web Interface (Gradio)

#### 🤖 Agent Chat
1. Select an agent from the dropdown
2. View agent capabilities
3. Adjust temperature and max tokens
4. Start chatting with the selected agent

#### 🔄 IO Intelligence Workflows
1. Enter text for processing
2. Select workflow type (summarize, analyze, general)
3. Execute workflow and view results

#### ⚖️ Model Comparison
1. Select two models to compare
2. Enter a prompt
3. Compare responses side-by-side

#### 📊 System Status
- View system health and configuration
- Monitor conversation history
- Check API connectivity

### API Usage (FastAPI)

#### Chat with an Agent
```python
import requests

response = requests.post("http://localhost:8000/chat", json={
    "agent_name": "Reasoning Agent",
    "message": "Explain quantum computing",
    "temperature": 0.7,
    "max_tokens": 1024
})

print(response.json())
```

#### Execute Workflow
```python
response = requests.post("http://localhost:8000/workflow", json={
    "prompt": "Artificial intelligence is transforming industries...",
    "workflow_type": "summarize"
})

print(response.json())
```

#### Compare Models
```python
response = requests.post("http://localhost:8000/compare", json={
    "prompt": "Write a Python function to sort a list",
    "models": ["Llama 3.3 70B", "CodeLlama 13B"],
    "temperature": 0.3
})

print(response.json())
```

## 🏗️ Architecture

### Core Components

```
AI Command Center
├── ai_command_center.py      # Main Gradio application
├── api_backend.py            # FastAPI backend service
├── start_ai_command_center.sh # Startup script
├── requirements.txt          # Python dependencies
└── .env                     # Configuration file
```

### Model Integration

```
ConsciousnessOrchestrator
├── IO Intelligence Models
│   ├── Llama 3.3 70B Instruct
│   ├── DeepSeek R1
│   ├── Qwen 3 235B
│   └── 40+ other models
└── Hugging Face Models
    ├── Mistral 7B Instruct
    ├── CodeLlama 13B
    ├── Phi-3.5 Mini
    └── Custom models
```

### Agent Architecture

```
Specialized Agents
├── Reasoning Agent (Logic & Analysis)
├── Code Assistant (Programming)
├── Summary Agent (Content Analysis)
├── Research Agent (Information Synthesis)
└── Creative Assistant (Writing & Ideas)
```

## 🛠️ Advanced Configuration

### Environment Variables

```bash
# API Configuration
IOINTELLIGENCE_API_KEY=your_io_key_here
HUGGINGFACE_TOKEN=your_hf_token_here
OPENAI_API_KEY=your_openai_key_here

# Server Configuration
API_HOST=0.0.0.0
API_PORT=8000
GRADIO_HOST=0.0.0.0
GRADIO_PORT=7860

# Model Configuration
DEFAULT_TEMPERATURE=0.7
DEFAULT_MAX_TOKENS=1024
ENABLE_CUDA=true

# Performance
MAX_CONCURRENT_REQUESTS=10
ENABLE_MODEL_CACHING=true
```

### Custom Agent Configuration

You can extend the system by adding custom agents:

```python
# Add to load_default_agents() in ai_command_center.py
AgentConfig(
    name="Custom Agent",
    description="Your custom agent description",
    instructions="Custom agent instructions",
    model_config=self.models["Preferred Model"],
    capabilities=["custom_capability_1", "custom_capability_2"]
)
```

## 📊 System Requirements

### Minimum Requirements
- **CPU**: 4+ cores
- **RAM**: 8GB+ (16GB recommended)
- **Storage**: 10GB+ free space
- **Network**: Stable internet connection for API access

### Recommended Requirements
- **CPU**: 8+ cores
- **RAM**: 32GB+ 
- **GPU**: NVIDIA GPU with 8GB+ VRAM (for local model inference)
- **Storage**: 50GB+ SSD storage

### IO Intelligence Usage Limits

| Model Category | Daily Chat Quota | Daily API Quota | Context Length |
|----------------|------------------|-----------------|----------------|
| Large Models   | 1,000,000 tokens | 500,000 tokens | 128,000 tokens |
| Vision Models  | 0 tokens        | 500,000 tokens | Variable       |
| Embeddings     | N/A              | 50,000,000 tk   | 4,096 tokens   |

## 🔧 Management Commands

```bash
# Start services
./start_ai_command_center.sh start

# Stop services
./start_ai_command_center.sh stop

# Restart services
./start_ai_command_center.sh restart

# Check status
./start_ai_command_center.sh status

# View logs
./start_ai_command_center.sh logs

# Install/update requirements
./start_ai_command_center.sh install

# Update requirements only
./start_ai_command_center.sh update

# Show help
./start_ai_command_center.sh help
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Virtual Environment Issues
```bash
# Recreate virtual environment
rm -rf consciousness-ai-env
./start_ai_command_center.sh install
```

#### 2. API Key Issues
```bash
# Check environment variables
./start_ai_command_center.sh status

# Verify .env file
cat .env
```

#### 3. Port Conflicts
```bash
# Check if ports are in use
netstat -tulpn | grep -E ':7860|:8000'

# Kill conflicting processes
sudo fuser -k 7860/tcp
sudo fuser -k 8000/tcp
```

#### 4. Model Loading Issues
```bash
# Check CUDA availability
python3 -c "import torch; print(torch.cuda.is_available())"

# Check disk space
df -h

# Check memory usage
free -h
```

### Logs and Debugging

```bash
# View detailed logs
./start_ai_command_center.sh logs

# Monitor logs in real-time
tail -f logs/gradio.log
tail -f logs/api.log

# Enable debug mode
export LOG_LEVEL=DEBUG
./start_ai_command_center.sh restart
```

## 🔒 Security Considerations

1. **API Key Management**: Store API keys securely in `.env` file
2. **Network Security**: Use firewalls to restrict access
3. **CORS Configuration**: Adjust CORS settings for production
4. **Rate Limiting**: Monitor API usage to stay within limits
5. **Conversation Privacy**: Clear conversation history regularly

## 🚀 Production Deployment

### Docker Deployment

```dockerfile
# Dockerfile example
FROM python:3.10-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 7860 8000

CMD ["./start_ai_command_center.sh", "start"]
```

### Reverse Proxy Configuration

```nginx
# Nginx configuration
server {
    listen 80;
    server_name your-domain.com;

    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        proxy_pass http://localhost:7860/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **IO Intelligence**: For providing powerful AI models and agents
- **Hugging Face**: For the extensive model ecosystem
- **Gradio**: For the excellent web interface framework
- **FastAPI**: For the high-performance API framework

## 📞 Support

For support and questions:
- Open an issue on GitHub
- Check the troubleshooting section
- Review the API documentation at http://localhost:8000/docs

---

**AI Command Center** - Empowering consciousness orchestration through advanced AI integration 🧠✨
