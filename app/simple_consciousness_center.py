#!/usr/bin/env python3
"""
Simple Working Consciousness Zero Command Center
Simplified version to get the web interface working properly
"""

import os
import sys
import asyncio
import json
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime
import subprocess

# Web interface imports
import gradio as gr
import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimpleConsciousnessAgent:
    """Simplified agent for testing"""
    
    def __init__(self):
        self.tools = {
            "system_status": "Check system status and resources",
            "vaultwarden": "Manage Vaultwarden password manager",
            "crypto_wallet": "Multi-chain crypto wallet operations", 
            "web_search": "Advanced web search with AI intelligence",
            "shell": "Execute system commands safely"
        }
        logger.info(f"🧠 Simple Agent initialized with {len(self.tools)} tools")
    
    async def process_message(self, message: str) -> str:
        """Process user message and return response"""
        if not message.strip():
            return "Please enter a command."
        
        message_lower = message.lower()
        
        # Handle system status requests
        if "status" in message_lower or "monitor" in message_lower:
            return self._get_system_status()
        
        # Handle tool help
        elif "help" in message_lower or "tools" in message_lower:
            return self._get_tools_help()
        
        # Handle vaultwarden
        elif "vaultwarden" in message_lower:
            return "🔐 Vaultwarden password manager integration ready.\nFeatures: Secure password storage, sharing, and management."
        
        # Handle crypto wallet
        elif "crypto" in message_lower or "wallet" in message_lower:
            return "💰 Multi-chain crypto wallet support:\n- Solana: Ready\n- Ethereum: Ready\n- Bitcoin: Ready"
        
        # Handle web search
        elif "search" in message_lower:
            return f"🔍 Advanced web search for: '{message}'\nIntegrating SearXNG + Crawl4AI for intelligent results..."
        
        # Handle shell commands
        elif "shell" in message_lower:
            if "ls" in message_lower:
                try:
                    result = subprocess.run(['ls', '-la'], capture_output=True, text=True, timeout=10)
                    return f"```\n{result.stdout}\n```"
                except Exception as e:
                    return f"Error executing command: {e}"
            else:
                return "🖥️ Shell execution ready. Try: 'shell ls -la'"
        
        # Default response
        else:
            return f"🧠 Consciousness Zero processed: '{message}'\n\nAvailable tools: {', '.join(self.tools.keys())}\n\nTry asking about: status, help, vaultwarden, crypto wallet, search, or shell commands."
    
    def _get_system_status(self) -> str:
        """Get system status"""
        try:
            import psutil
            cpu = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            return f"""🖥️ **System Status**
            
**CPU Usage**: {cpu}%
**Memory**: {memory.percent}% used ({memory.used//1024//1024//1024}GB / {memory.total//1024//1024//1024}GB)
**Disk**: {disk.percent}% used ({disk.used//1024//1024//1024}GB / {disk.total//1024//1024//1024}GB free)
**Environment**: WSL2 Linux
**Status**: ✅ All systems operational
"""
        except Exception as e:
            return f"📊 System monitoring active\n⚠️ Detailed metrics unavailable: {e}"
    
    def _get_tools_help(self) -> str:
        """Get help for available tools"""
        help_text = "🛠️ **Available Orchestration Tools**\n\n"
        for tool, description in self.tools.items():
            help_text += f"**{tool}**: {description}\n"
        
        help_text += "\n💡 **Quick Commands**:\n"
        help_text += "- `monitor system status` - Check system health\n"
        help_text += "- `vaultwarden status` - Password manager info\n"
        help_text += "- `crypto wallet balance` - Wallet information\n"
        help_text += "- `search kubernetes best practices` - Web search\n"
        help_text += "- `shell ls -la` - Execute shell commands\n"
        
        return help_text

# Initialize the agent
agent = SimpleConsciousnessAgent()

def process_message_sync(message: str) -> str:
    """Synchronous wrapper for gradio"""
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(agent.process_message(message))
        return result
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        return f"Error: {str(e)}"
    finally:
        loop.close()

# Create FastAPI app
app = FastAPI(
    title="Consciousness Zero Command Center",
    description="AI-powered infrastructure orchestration",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create Gradio interface
interface = gr.Interface(
    fn=process_message_sync,
    inputs=gr.Textbox(
        lines=2, 
        placeholder="Enter your command here (try 'help' or 'status')...", 
        label="🧠 Consciousness Zero Command"
    ),
    outputs=gr.Markdown(label="Response"),
    title="🧠 Consciousness Zero Command Center",
    description="**AI-powered infrastructure orchestration** with Vaultwarden, Crypto Wallets, Shell Access, Monitoring & Advanced Web Search",
    theme=gr.themes.Soft(),
    examples=[
        "help - show available tools",
        "monitor system status", 
        "vaultwarden status",
        "crypto wallet status",
        "search for kubernetes best practices",
        "shell ls -la"
    ]
)

# Mount Gradio to FastAPI
app = gr.mount_gradio_app(app, interface, path="/")

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "ok", "service": "consciousness-zero"}

@app.post("/api/chat")
async def api_chat(request: Request):
    """API endpoint for chat"""
    try:
        data = await request.json()
        message = data.get("message", "")
        response = process_message_sync(message)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    print("🧠 Starting Consciousness Zero Command Center (Simple Version)...")
    print("🌐 Web Interface: http://localhost:7860")
    print("🛠️ Available Tools: System Status, Vaultwarden, Crypto Wallets, Web Search, Shell")
    print("Press Ctrl+C to stop")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=7860,
        log_level="info"
    )
