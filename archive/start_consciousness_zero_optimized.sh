#!/bin/bash

# Consciousness Zero Optimized Startup Script
# Cleaner, faster startup with advanced search capabilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/consciousness-ai-env"

echo "🧠 Starting Consciousness Zero (Optimized)..."
echo "============================================="

# Check virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual environment not found. Run local-validation.sh first."
    exit 1
fi

# Activate environment
echo "🔄 Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Quick dependency check (optimized)
echo "🔍 Checking core dependencies..."
python -c "
import gradio, fastapi, sentence_transformers
print('✅ Core dependencies available')
try:
    import crawl4ai
    print('✅ Crawl4AI available for advanced search')
except ImportError:
    print('⚠️ Crawl4AI not available - using mock search')
" || {
    echo "Installing missing dependencies..."
    pip install gradio fastapi sentence-transformers uvicorn
    pip install crawl4ai || echo "⚠️ Crawl4AI installation failed - continuing with mock search"
}

# Create directories
mkdir -p memory knowledge logs

# Environment confirmation
echo "🖥️ Environment: WSL2 ($(uname -r))"
echo "🌐 Search: SearXNG + Crawl4AI integration"
echo "🧠 Agent: Zero-inspired with Perplexica-style search"

# Start optimized command center
echo "🚀 Starting Consciousness Zero Command Center..."
echo "Web Interface: http://localhost:7860"
echo "Press Ctrl+C to stop"

uvicorn consciousness_zero_command_center:app --host 0.0.0.0 --port 7860 --reload
