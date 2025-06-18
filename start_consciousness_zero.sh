#!/bin/bash

# Consciousness Zero Command Center Startup Script
# Agent Zero + MCP Crawl4AI inspired AI infrastructure orchestration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/consciousness-ai-env"

echo "🧠 Starting Consciousness Zero Command Center..."
echo "================================================"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual environment not found at $VENV_DIR"
    echo "Please run local-validation.sh first to set up the environment"
    exit 1
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Verify required packages
echo "🔍 Verifying dependencies..."
python -c "import gradio, fastapi, sentence_transformers, crawl4ai" 2>/dev/null || {
    echo "❌ Missing required packages. Installing..."
    pip install -r requirements.txt
    pip install crawl4ai
}

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p memory knowledge logs

# Setup initial knowledge base
echo "📚 Setting up knowledge base..."
mkdir -p knowledge/docs

cat > knowledge/docs/consciousness-zero-guide.md << 'EOF'
# Consciousness Zero Command Center Guide

## Overview
The Consciousness Zero Command Center is an AI-powered infrastructure orchestration platform inspired by Agent Zero and MCP Crawl4AI architectures.

## Key Features
- **Agent Zero Architecture**: Hierarchical agent system with tools, memory, and reasoning
- **MCP Crawl4AI Integration**: Intelligent web crawling and information extraction
- **Proxmox Federation**: Multi-node cluster orchestration
- **Memory System**: Persistent learning and solution storage
- **Tool Ecosystem**: Modular tools for various operations

## Available Tools
1. **Cluster Status**: Monitor Proxmox federation health
2. **Deployment**: Orchestrate workload deployments
3. **Web Search**: AI-powered web research
4. **Shell Execute**: Safe command execution
5. **Memory Tool**: Save and recall information
6. **Knowledge Tool**: Access local documentation

## Usage Examples
- "Check cluster status"
- "Deploy AI inference workload"
- "Search for Kubernetes best practices"
- "Execute ps aux command"
- "Remember this configuration"
- "What did I deploy yesterday?"

## Architecture Components
- **ConsciousnessAgent**: Main AI agent with reasoning and tool usage
- **Memory System**: Fragment storage and solution recall
- **Tool Framework**: Extensible tool ecosystem
- **Web Interface**: Gradio-based chat interface
- **API Endpoints**: FastAPI REST interface
EOF

# Set environment variables if .env exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "🔧 Loading environment variables..."
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Check for required environment variables
if [ -z "$IO_API_KEY" ]; then
    echo "⚠️  IO_API_KEY not set. Some features may be limited."
fi

if [ -z "$HF_TOKEN" ]; then
    echo "⚠️  HF_TOKEN not set. Some AI features may be limited."
fi

# Start the command center
echo "🚀 Launching Consciousness Zero Command Center..."
echo "   Web Interface: http://localhost:7860"
echo "   API Documentation: http://localhost:7860/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run with proper error handling
cd "$SCRIPT_DIR"
python consciousness_zero_command_center.py
