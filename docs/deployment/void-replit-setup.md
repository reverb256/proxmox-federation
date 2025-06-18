
# Void IDE + Replit SSH Integration Guide

## Overview
Configure Void (VS Code fork) to connect to your Replit environment via SSH and use the quantum autorouter for AI assistance.

## SSH Connection Setup

### 1. Get Replit SSH Connection Details
In your Replit, open the Shell and run:
```bash
# This will show your SSH connection string
echo "ssh $(whoami)@$(hostname).$(echo $REPL_SLUG).repl.co"
```

### 2. Configure Void SSH Remote
1. Open Void IDE
2. Install "Remote - SSH" extension if not already installed
3. Press `Ctrl+Shift+P` and type "Remote-SSH: Connect to Host"
4. Add new SSH target: `username@your-repl.repl.co`
5. When prompted for password, use your Replit account credentials

### 3. Port Forwarding for AI Services
Once connected via SSH, forward the void-proxy port:
```bash
# In Void's integrated terminal (connected to Replit)
# The void-proxy server runs on port 3001
```

## AI Integration Configuration

### 1. Configure Void AI Settings
In Void's settings.json, add:
```json
{
  "ai.openai.apiBase": "http://localhost:3001/v1",
  "ai.openai.apiKey": "dummy-key-not-needed",
  "ai.model": "quantum-autorouter",
  "ai.enabled": true
}
```

### 2. Start Void-Proxy Server
In your Replit environment:
```bash
node void-proxy-server.js
```

## Advanced Features

### 1. Multi-Modal Support
Your void-proxy already supports:
- Vision analysis for images
- Audio transcription
- Code analysis with quantum routing

### 2. Consciousness Integration
Void will automatically route requests through your consciousness-driven AI system:
- Code suggestions via quantum autorouter
- Context-aware completions
- Multi-model routing based on query type

## Workflow Example

1. **Open Void IDE** → Connect to Replit via SSH
2. **Start void-proxy** → `node void-proxy-server.js`
3. **Code with AI** → Void uses your quantum autorouter for intelligent assistance
4. **Deploy changes** → Direct access to your Replit deployment pipeline

## Benefits

- **Native VS Code Experience** with your quantum AI backend
- **Direct File Access** to your Replit codebase
- **Integrated Terminal** running in your Repl environment
- **AI-Powered Development** using your consciousness architecture
- **Seamless Deployment** through Replit's infrastructure

This setup gives you the full power of Void's VS Code interface while leveraging your sophisticated AI trading platform and consciousness architecture running on Replit.
