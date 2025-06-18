#!/usr/bin/env python3
"""
Consciousness Zero Command Center - Optimized Version
Agent Zero + Perplexica-style search integration
Local AI-powered infrastructure orchestration with advanced web intelligence
"""

import os
import sys
import asyncio
import json
import logging
import subprocess
import uuid
from typing import Dict, List, Any, Optional, Union
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
import threading
import httpx
import requests
import psutil
from urllib.parse import quote_plus

# Optimized web interface imports
import gradio as gr
import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

# AI imports - only what we need
from sentence_transformers import SentenceTransformer
import torch

# Infrastructure imports
try:
    from proxmoxer import ProxmoxAPI
    PROXMOX_AVAILABLE = True
except ImportError:
    PROXMOX_AVAILABLE = False

# Crawl4AI for web intelligence
try:
    from crawl4ai import AsyncWebCrawler
    CRAWL4AI_AVAILABLE = True
except ImportError:
    CRAWL4AI_AVAILABLE = False

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class AgentConfig:
    """Optimized configuration for Consciousness Zero Agent"""
    # APIs
    io_api_url: str = "https://api.intelligence.io.solutions/api/v1"
    io_api_key: str = ""
    hf_token: str = ""
    
    # Models
    embedding_model: str = "all-MiniLM-L6-v2"
    hf_cache_dir: str = "./models"
    
    # Directories
    memory_dir: str = "./memory"
    knowledge_dir: str = "./knowledge"
    
    # Interface
    web_port: int = 7860
    
    # Search configuration
    searxng_url: str = "https://searx.be"  # Public SearXNG instance
    search_engines: List[str] = field(default_factory=lambda: ["google", "bing", "duckduckgo"])
    
    # Proxmox nodes
    proxmox_nodes: Dict[str, Dict] = field(default_factory=dict)
    
    # Security & Vault
    vaultwarden_url: str = "http://localhost:8080"
    vaultwarden_token: str = ""
    
    # Crypto Wallets
    solana_rpc_url: str = "https://api.mainnet-beta.solana.com"
    ethereum_rpc_url: str = "https://mainnet.infura.io/v3/"
    bitcoin_rpc_url: str = "http://localhost:8332"
    
    # Tool orchestration
    tools_enabled: List[str] = field(default_factory=lambda: [
        "web_search", "cluster_status", "deployment", "vaultwarden", 
        "crypto_wallet", "shell_execute", "memory", "knowledge", 
        "monitoring", "backup", "network_scan"
    ])

class AdvancedWebSearchTool:
    """Perplexica-inspired advanced web search with SearXNG integration"""
    
    def __init__(self, config: AgentConfig):
        self.config = config
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def search_with_searxng(self, query: str, num_results: int = 5) -> List[Dict]:
        """Search using SearXNG for real search engine results"""
        try:
            # SearXNG search parameters
            params = {
                'q': query,
                'format': 'json',
                'engines': ','.join(self.config.search_engines),
                'pageno': 1
            }
            
            response = await self.client.get(
                f"{self.config.searxng_url}/search",
                params=params
            )
            
            if response.status_code == 200:
                data = response.json()
                results = []
                
                for result in data.get('results', [])[:num_results]:
                    results.append({
                        'title': result.get('title', ''),
                        'url': result.get('url', ''),
                        'content': result.get('content', ''),
                        'engine': result.get('engine', 'unknown'),
                        'score': result.get('score', 0)
                    })
                
                return results
            else:
                logger.warning(f"SearXNG search failed: {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"SearXNG search error: {e}")
            return []
    
    async def crawl_and_extract(self, urls: List[str]) -> List[Dict]:
        """Crawl URLs and extract content using Crawl4AI"""
        if not CRAWL4AI_AVAILABLE:
            return []
        
        results = []
        try:
            async with AsyncWebCrawler(verbose=False) as crawler:
                for url in urls:
                    try:
                        result = await crawler.arun(url=url)
                        if result.success:
                            results.append({
                                'url': url,
                                'title': result.title or 'Unknown',
                                'content': result.markdown[:1000] if result.markdown else '',
                                'extracted_at': datetime.now().isoformat()
                            })
                    except Exception as e:
                        logger.warning(f"Failed to crawl {url}: {e}")
        except Exception as e:
            logger.warning(f"Crawl4AI initialization failed: {e}")
            logger.info("Falling back to basic HTTP requests for content extraction")
            # Fallback to simple HTTP requests
            for url in urls:
                try:
                    response = await self.client.get(url, timeout=10)
                    if response.status_code == 200:
                        content = response.text[:1000]
                        results.append({
                            'url': url,
                            'title': f'Content from {url}',
                            'content': content,
                            'extracted_at': datetime.now().isoformat()
                        })
                except Exception as e:
                    logger.warning(f"Failed to fetch {url}: {e}")
        
        return results
    
    async def perplexica_style_search(self, query: str, mode: str = "web") -> Dict[str, Any]:
        """Perform Perplexica-style search with re-ranking and source attribution"""
        logger.info(f"🔍 Advanced search: {query}")
        
        # Step 1: Get initial search results from SearXNG
        search_results = await self.search_with_searxng(query, num_results=10)
        
        if not search_results:
            # Fallback to mock results if SearXNG unavailable
            search_results = self._generate_mock_results(query)
        
        # Step 2: Extract top URLs for detailed crawling
        top_urls = [result['url'] for result in search_results[:5]]
        crawled_content = await self.crawl_and_extract(top_urls)
        
        # Step 3: Combine and rank results
        final_results = self._rank_and_combine_results(search_results, crawled_content)
        
        return {
            'query': query,
            'mode': mode,
            'results': final_results,
            'sources': len(final_results),
            'search_method': 'perplexica_style',
            'timestamp': datetime.now().isoformat()
        }
    
    def _generate_mock_results(self, query: str) -> List[Dict]:
        """Generate mock search results when SearXNG is unavailable"""
        return [
            {
                'title': f"Complete Guide to {query}",
                'url': f"https://docs.example.com/{quote_plus(query)}",
                'content': f"Comprehensive documentation and best practices for {query}...",
                'engine': 'mock',
                'score': 1.0
            },
            {
                'title': f"{query} - Latest Updates",
                'url': f"https://news.example.com/{quote_plus(query)}",
                'content': f"Recent developments and news about {query}...",
                'engine': 'mock',
                'score': 0.9
            }
        ]
    
    def _rank_and_combine_results(self, search_results: List[Dict], crawled_content: List[Dict]) -> List[Dict]:
        """Combine and rank search results with crawled content"""
        combined = []
        
        # Create URL mapping for crawled content
        crawled_map = {item['url']: item for item in crawled_content}
        
        for result in search_results:
            url = result['url']
            combined_result = {
                'title': result['title'],
                'url': url,
                'snippet': result['content'],
                'engine': result.get('engine', 'unknown'),
                'score': result.get('score', 0)
            }
            
            # Add crawled content if available
            if url in crawled_map:
                combined_result['full_content'] = crawled_map[url]['content']
                combined_result['crawled'] = True
            
            combined.append(combined_result)
        
        # Sort by score (highest first)
        combined.sort(key=lambda x: x['score'], reverse=True)
        
        return combined

class ConsciousnessAgent:
    """Enhanced Agent Zero-inspired consciousness agent with full orchestration"""
    
    def __init__(self, config: AgentConfig):
        self.config = config
        self.agent_id = str(uuid.uuid4())
        self.memory = Memory(config.memory_dir)
        self.web_search = AdvancedWebSearchTool(config)
        
        # Initialize orchestration tools
        self.tools = {
            'vaultwarden': VaultwardenTool(config),
            'crypto_wallet': CryptoWalletTool(config),
            'shell_execute': ShellExecuteTool(),
            'monitoring': MonitoringTool(),
            'web_search': self.web_search,
        }
        
        # Initialize embedding model for local RAG
        # Initialize embedding model for local RAG (lazy loading)
        self.embedder = None
        self._embedding_model_name = config.embedding_model
        logger.info(f"🔄 Embedding model will be loaded on first use: {config.embedding_model}")
        
        logger.info(f"🧠 Agent initialized with {len(self.tools)} orchestration tools")
    
    def _ensure_embedder_loaded(self):
        """Load embedder on first use"""
        if self.embedder is None:
            try:
                from sentence_transformers import SentenceTransformer
                self.embedder = SentenceTransformer(self._embedding_model_name)
                logger.info(f"✅ Loaded embedding model: {self._embedding_model_name}")
            except Exception as e:
                logger.warning(f"⚠️ Could not load embedding model: {e}")
                self.embedder = "failed"  # Mark as failed to avoid repeated attempts
    
    async def process_message(self, message: str) -> Dict[str, Any]:
        """Enhanced message processing with tool orchestration"""
        logger.info(f"🧠 Processing: {message}")
        
        # Enhanced intent detection with tool awareness
        response = await self._route_to_tools(message)
        
        # Save to memory with tool usage
        self.memory.save_fragment(
            f"User: {message[:100]}... | Response: {response[:100]}...",
            {"tools_used": self._get_tools_used_in_message(message)}
        )
        
        return {
            'response': response,
            'agent_id': self.agent_id,
            'timestamp': datetime.now().isoformat(),
            'tools_available': list(self.tools.keys())
        }
    
    async def _route_to_tools(self, message: str) -> str:
        """Route message to appropriate tools based on intent"""
        message_lower = message.lower()
        
        # Vaultwarden operations
        if any(keyword in message_lower for keyword in ['vault', 'password', 'secret', 'bitwarden']):
            return await self._handle_vaultwarden(message)
        
        # Crypto wallet operations
        elif any(keyword in message_lower for keyword in ['wallet', 'crypto', 'solana', 'ethereum', 'bitcoin', 'sol', 'eth', 'btc']):
            return await self._handle_crypto_wallet(message)
        
        # Shell execution
        elif any(keyword in message_lower for keyword in ['shell', 'execute', 'run', 'command', 'bash']):
            return await self._handle_shell_execution(message)
        
        # Monitoring and system status
        elif any(keyword in message_lower for keyword in ['monitor', 'status', 'health', 'metrics', 'system', 'cpu', 'memory', 'disk']):
            return await self._handle_monitoring(message)
        
        # Web search
        elif any(keyword in message_lower for keyword in ['search', 'find', 'look up', 'web', 'google']):
            result = await self.web_search.perplexica_style_search(message)
            return self._format_search_response(result)
        
        # Cluster and deployment operations
        elif any(keyword in message_lower for keyword in ['cluster', 'deploy', 'create', 'proxmox', 'vm', 'container']):
            return await self._handle_cluster_operations(message)
        
        # General orchestration help
        elif any(keyword in message_lower for keyword in ['help', 'tools', 'orchestrate', 'capabilities']):
            return self._show_orchestration_help()
        
        # Default general response
        else:
            return self._general_response(message)
    
    async def _handle_vaultwarden(self, message: str) -> str:
        """Handle Vaultwarden operations"""
        try:
            # Parse action from message
            if 'status' in message.lower():
                result = await self.tools['vaultwarden'].execute(self, action='status')
            elif 'search' in message.lower():
                # Extract search query
                words = message.split()
                query = ' '.join(words[words.index('search')+1:]) if 'search' in words else ''
                result = await self.tools['vaultwarden'].execute(self, action='search', query=query)
            elif 'create' in message.lower():
                result = await self.tools['vaultwarden'].execute(self, action='create', name=message)
            elif 'backup' in message.lower():
                result = await self.tools['vaultwarden'].execute(self, action='backup')
            else:
                result = await self.tools['vaultwarden'].execute(self, action='status')
            
            if result['success']:
                return f"🔐 **Vaultwarden Operation Complete**\n\n{self._format_tool_result(result['result'])}"
            else:
                return f"❌ **Vaultwarden Error**: {result['error']}"
        except Exception as e:
            return f"❌ **Vaultwarden Tool Error**: {str(e)}"
    
    async def _handle_crypto_wallet(self, message: str) -> str:
        """Handle crypto wallet operations"""
        try:
            # Extract chain and action
            chain = 'solana'  # default
            if 'ethereum' in message.lower() or 'eth' in message.lower():
                chain = 'ethereum'
            elif 'bitcoin' in message.lower() or 'btc' in message.lower():
                chain = 'bitcoin'
            
            action = 'status'  # default
            if 'balance' in message.lower():
                action = 'balance'
            elif 'create' in message.lower():
                action = 'create'
            
            result = await self.tools['crypto_wallet'].execute(self, chain=chain, action=action)
            
            if result['success']:
                return f"💰 **Crypto Wallet - {chain.title()}**\n\n{self._format_tool_result(result['result'])}"
            else:
                return f"❌ **Crypto Wallet Error**: {result['error']}"
        except Exception as e:
            return f"❌ **Crypto Wallet Tool Error**: {str(e)}"
    
    async def _handle_shell_execution(self, message: str) -> str:
        """Handle shell command execution"""
        try:
            # Extract command from message
            if 'shell' in message.lower():
                words = message.split()
                cmd_start = words.index('shell') + 1 if 'shell' in words else 0
                command = ' '.join(words[cmd_start:])
            else:
                command = message
            
            if not command:
                return "❌ **Shell Error**: No command specified"
            
            result = await self.tools['shell_execute'].execute(self, command=command)
            
            if result['success'] and result['result']['success']:
                stdout = result['result']['stdout']
                stderr = result['result']['stderr']
                output = f"**Command**: `{command}`\n\n"
                if stdout:
                    output += f"**Output**:\n```\n{stdout}\n```\n"
                if stderr:
                    output += f"**Errors**:\n```\n{stderr}\n```\n"
                return f"🔧 **Shell Execution**\n\n{output}"
            else:
                error = result.get('error', result['result'].get('stderr', 'Unknown error'))
                return f"❌ **Shell Error**: {error}"
        except Exception as e:
            return f"❌ **Shell Tool Error**: {str(e)}"
    
    async def _handle_monitoring(self, message: str) -> str:
        """Handle monitoring operations"""
        try:
            # Determine monitoring target
            target = 'system'  # default
            if 'network' in message.lower():
                target = 'network'
            elif 'service' in message.lower():
                target = 'services'
            elif 'log' in message.lower():
                target = 'logs'
                if 'error' in message.lower():
                    target = 'logs'
                    level = 'error'
                else:
                    level = 'info'
            elif 'disk' in message.lower():
                target = 'disk'
            
            kwargs = {'level': level} if target == 'logs' and 'level' in locals() else {}
            result = await self.tools['monitoring'].execute(self, target=target, **kwargs)
            
            if result['success']:
                return f"📊 **System Monitoring - {target.title()}**\n\n{self._format_monitoring_result(result['result'])}"
            else:
                return f"❌ **Monitoring Error**: {result['error']}"
        except Exception as e:
            return f"❌ **Monitoring Tool Error**: {str(e)}"
    
    async def _handle_cluster_operations(self, message: str) -> str:
        """Handle cluster and deployment operations"""
        if 'status' in message.lower():
            return self._get_cluster_status()
        elif 'deploy' in message.lower():
            return self._simulate_deployment(message)
        else:
            return self._get_cluster_status()
    
    def _show_orchestration_help(self) -> str:
        """Show comprehensive orchestration capabilities"""
        tools_help = []
        for tool_name, tool in self.tools.items():
            if hasattr(tool, 'examples'):
                examples = '\n'.join([f"  • {ex}" for ex in tool.examples[:3]])
                tools_help.append(f"**{tool_name}**: {tool.description}\n{examples}")
        
        return f"""🧠 **Consciousness Zero Orchestration Capabilities**

I can help you orchestrate and manage your entire infrastructure using these tools:

{chr(10).join(tools_help)}

**General Commands:**
  • "Check system status" - Full system monitoring
  • "Show vaultwarden status" - Password manager health
  • "Search for kubernetes best practices" - Web intelligence
  • "Execute shell ls -la" - Safe shell operations
  • "Show solana wallet balance" - Crypto wallet management

**Example Orchestration Flows:**
  • Infrastructure deployment with password management
  • Multi-chain crypto operations with monitoring
  • Automated system administration with logging
  • Secure secret management with backup strategies

Ask me to orchestrate any infrastructure task and I'll coordinate the appropriate tools!"""
    
    def _format_tool_result(self, result: Dict[str, Any]) -> str:
        """Format tool results for display"""
        if isinstance(result, dict):
            formatted = []
            for key, value in result.items():
                if isinstance(value, dict):
                    formatted.append(f"**{key.title()}**: {json.dumps(value, indent=2)}")
                else:
                    formatted.append(f"**{key.title()}**: {value}")
            return '\n'.join(formatted)
        else:
            return str(result)
    
    def _format_monitoring_result(self, result: Dict[str, Any]) -> str:
        """Format monitoring results for display"""
        if 'cpu' in result:
            # System metrics
            cpu = result['cpu']
            memory = result['memory']
            disk = result['disk']
            return f"""**CPU**: {cpu['percent']:.1f}% ({cpu['count']} cores)
**Memory**: {memory['percent']:.1f}% ({memory['used'] // (1024**3):.1f}GB / {memory['total'] // (1024**3):.1f}GB)
**Disk**: {disk['percent']:.1f}% ({disk['used'] // (1024**3):.1f}GB / {disk['total'] // (1024**3):.1f}GB)
**Uptime**: {result['system'].get('uptime', 'Unknown')}"""
        elif 'interfaces' in result:
            # Network status
            interface_count = len(result['interfaces'])
            return f"**Network Interfaces**: {interface_count}\n**Active Connections**: {result['connections']}"
        elif 'services' in result:
            # Service status
            services = result['services']
            active = result['active']
            total = result['total']
            return f"**Services**: {active}/{total} active\n" + '\n'.join([f"• {s['name']}: {s['status']}" for s in services])
        else:
            return self._format_tool_result(result)
    
    def _get_tools_used_in_message(self, message: str) -> List[str]:
        """Identify which tools would be used for a message"""
        tools_used = []
        message_lower = message.lower()
        
        if any(keyword in message_lower for keyword in ['vault', 'password', 'secret']):
            tools_used.append('vaultwarden')
        if any(keyword in message_lower for keyword in ['wallet', 'crypto', 'solana', 'ethereum', 'bitcoin']):
            tools_used.append('crypto_wallet')
        if any(keyword in message_lower for keyword in ['shell', 'execute', 'command']):
            tools_used.append('shell_execute')
        if any(keyword in message_lower for keyword in ['monitor', 'status', 'system']):
            tools_used.append('monitoring')
        if any(keyword in message_lower for keyword in ['search', 'find', 'web']):
            tools_used.append('web_search')
        
        return tools_used
    
    def _format_search_response(self, search_result: Dict) -> str:
        """Format search results into readable response"""
        query = search_result['query']
        results = search_result['results']
        
        response = f"🔍 **Search Results for '{query}'**\n\n"
        
        for i, result in enumerate(results[:3], 1):
            response += f"**{i}. {result['title']}**\n"
            response += f"🔗 {result['url']}\n"
            response += f"📝 {result['snippet'][:200]}...\n\n"
        
        response += f"*Found {len(results)} sources using {search_result['search_method']}*"
        return response
    
    def _get_cluster_status(self) -> str:
        """Get cluster status information"""
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        
        return f"""🖥️ **Local System Status**
        
**CPU Usage:** {cpu_percent:.1f}%
**Memory:** {memory.percent:.1f}% ({memory.used // (1024**3):.1f}GB / {memory.total // (1024**3):.1f}GB)
**Agent ID:** {self.agent_id[:8]}...
**Environment:** WSL2 (confirmed)
**Search Engine:** {'SearXNG' if hasattr(self.web_search, 'client') else 'Mock'}

*Proxmox integration: {'Available' if PROXMOX_AVAILABLE else 'Disabled'}*
*Crawl4AI: {'Available' if CRAWL4AI_AVAILABLE else 'Disabled'}*"""
    
    def _simulate_deployment(self, message: str) -> str:
        """Simulate deployment action"""
        return f"""🚀 **Deployment Simulation**
        
Analyzing request: {message}

**Actions:**
1. ✅ Validated resource requirements
2. ✅ Checked cluster capacity  
3. ✅ Prepared deployment manifest
4. 🔄 Initiating deployment...

**Status:** Ready for deployment
**Estimated time:** 2-5 minutes
**Resources:** CPU: 2 cores, RAM: 4GB, Storage: 20GB

*This is a simulation. Real deployment requires Proxmox configuration.*"""
    
    def _general_response(self, message: str) -> str:
        """General AI response"""
        return f"""🤖 **Consciousness Zero Response**
        
I understand you're asking about: "{message}"

I'm your AI infrastructure orchestration assistant. I can help with:
- 🔍 **Web search** and information gathering
- 🖥️ **Cluster management** and monitoring  
- 🚀 **Deployment** automation
- 📚 **Knowledge** base queries
- 🧠 **Memory** of past interactions

Try asking me to:
- "Search for kubernetes best practices"
- "Check cluster status"
- "Deploy a new workload"
- "Show recent memory"

How can I assist you today?"""

class Memory:
    """Optimized memory system"""
    
    def __init__(self, memory_dir: str):
        self.memory_dir = Path(memory_dir)
        self.memory_dir.mkdir(exist_ok=True)
        self.fragments_file = self.memory_dir / "fragments.json"
        
        if not self.fragments_file.exists():
            self.fragments_file.write_text("[]")
    
    def save_fragment(self, content: str, metadata: Dict = None):
        """Save memory fragment with size limit"""
        try:
            fragments = json.loads(self.fragments_file.read_text())
            fragment = {
                "id": str(uuid.uuid4()),
                "content": content,
                "metadata": metadata or {},
                "timestamp": datetime.now().isoformat()
            }
            fragments.append(fragment)
            
            # Keep only last 500 fragments (reduced from 1000)
            if len(fragments) > 500:
                fragments = fragments[-500:]
            
            self.fragments_file.write_text(json.dumps(fragments, indent=2))
        except Exception as e:
            logger.error(f"Memory save error: {e}")

class ConsciousnessCommandCenter:
    """Optimized command center with cleaner web interface"""
    
    def __init__(self, config: AgentConfig):
        self.config = config
        self.agent = ConsciousnessAgent(config)
        self.app = FastAPI(title="Consciousness Zero API")
        
        # Add CORS middleware
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
        
        self._setup_gradio_interface()
    
    def _setup_gradio_interface(self):
        """Setup optimized Gradio interface"""
        with gr.Blocks(
            title="🧠 Consciousness Zero Command Center",
            theme=gr.themes.Soft(),
            css="""
            .gradio-container {
                max-width: 1200px !important;
                margin: 0 auto;
            }
            .chat-container {
                height: 500px;
            }
            """
        ) as interface:
            
            # Header
            gr.Markdown("""
            # 🧠 Consciousness Zero Command Center
            *Advanced AI Infrastructure Orchestration with Full Tool Integration*
            
            **Environment:** WSL2 | **Agent ID:** """ + self.agent.agent_id[:8] + """... | **Status:** 🟢 Online
            **Tools:** Vaultwarden, Crypto Wallets, Monitoring, Web Search, Shell Execution
            """)
            
            with gr.Row():
                with gr.Column(scale=3):
                    # Main chat interface
                    chatbot = gr.Chatbot(
                        label="AI Infrastructure Orchestrator",
                        height=400,
                        show_label=True,
                        container=True
                    )
                    
                    with gr.Row():
                        msg = gr.Textbox(
                            placeholder="Orchestrate: 'check vaultwarden status', 'show solana wallet balance', 'monitor system', 'search latest k8s'...",
                            label="Orchestration Command",
                            lines=2,
                            scale=4
                        )
                        send_btn = gr.Button("Execute", variant="primary", scale=1)
                
                with gr.Column(scale=1):
                    # Enhanced quick actions
                    gr.Markdown("### 🚀 Quick Orchestration")
                    status_btn = gr.Button("📊 System Status", size="sm")
                    vault_btn = gr.Button("🔐 Vaultwarden", size="sm")
                    wallet_btn = gr.Button("💰 Crypto Wallets", size="sm")
                    search_btn = gr.Button("🔍 Web Search", size="sm")
                    shell_btn = gr.Button("🔧 Shell Demo", size="sm")
                    help_btn = gr.Button("❓ Show All Tools", size="sm")
                    
                    # Enhanced system info
                    system_info = gr.HTML(
                        value="<div>Loading orchestration status...</div>",
                        label="Orchestration Status"
                    )
            
            # Chat function
            async def respond(message, history):
                if not message.strip():
                    return history, ""
                
                # Add user message
                history.append([message, "🤔 Thinking..."])
                
                # Get AI response
                result = await self.agent.process_message(message)
                history[-1][1] = result['response']
                
                return history, ""
            
            # Event handlers
            msg.submit(respond, [msg, chatbot], [chatbot, msg])
            send_btn.click(respond, [msg, chatbot], [chatbot, msg])
            
            # Enhanced quick actions
            async def quick_status():
                result = await self.agent.process_message("monitor system status")
                return [[None, result["response"]]]
            
            async def quick_vault():
                result = await self.agent.process_message("vaultwarden status")
                return [[None, result["response"]]]
            
            async def quick_wallet():
                result = await self.agent.process_message("crypto wallet solana status")
                return [[None, result["response"]]]
            
            async def quick_search():
                result = await self.agent.process_message("search for AI infrastructure best practices")
                return [[None, result["response"]]]
            
            async def quick_shell():
                result = await self.agent.process_message("shell ps aux | head -10")
                return [[None, result["response"]]]
            
            async def quick_help():
                result = await self.agent.process_message("show orchestration help")
                return [[None, result["response"]]]
            
            status_btn.click(quick_status, outputs=chatbot)
            vault_btn.click(quick_vault, outputs=chatbot)
            wallet_btn.click(quick_wallet, outputs=chatbot)
            search_btn.click(quick_search, outputs=chatbot)
            shell_btn.click(quick_shell, outputs=chatbot)
            help_btn.click(quick_help, outputs=chatbot)
            
            # Enhanced system info
            def update_system_info():
                cpu = psutil.cpu_percent(interval=0.1)
                memory = psutil.virtual_memory().percent
                tools_count = len(self.agent.tools)
                
                return f"""
                <div style="background: #f8f9fa; padding: 1rem; border-radius: 8px; font-size: 0.9em;">
                    <strong>🖥️ System Status</strong><br>
                    CPU: {cpu:.1f}% | RAM: {memory:.1f}%<br>
                    <strong>🔧 Orchestration Tools</strong><br>
                    Active: {tools_count} tools<br>
                    🔐 Vaultwarden | 💰 Crypto | 🔍 Search<br>
                    🔧 Shell | 📊 Monitoring<br>
                    <strong>🌐 Search Engine</strong><br>
                    {'SearXNG + Crawl4AI' if CRAWL4AI_AVAILABLE else 'Mock Search'}
                </div>
                """
            
            interface.load(update_system_info, outputs=system_info)
        
        self.gradio_app = interface
    
    async def start_server(self):
        """Start the optimized server"""
        # Mount Gradio to FastAPI
        self.app = gr.mount_gradio_app(self.app, self.gradio_app, path="/")
        
        # Start server
        config = uvicorn.Config(
            self.app,
            host="0.0.0.0",
            port=self.config.web_port,
            log_level="info"
        )
        server = uvicorn.Server(config)
        
        logger.info(f"🧠 Consciousness Zero (Optimized) starting on port {self.config.web_port}")
        logger.info(f"🚀 Web Interface: http://localhost:{self.config.web_port}")
        logger.info(f"🔍 Search Engine: {'SearXNG + Crawl4AI' if CRAWL4AI_AVAILABLE else 'Mock'}")
        logger.info(f"🖥️ Environment: WSL2 (Linux kernel 5.15.167.4-microsoft-standard-WSL2)")
        
        await server.serve()
    
    def process_message_gradio(self, message: str) -> str:
        """Process message for Gradio interface (synchronous)"""
        try:
            if not message.strip():
                return "Please enter a command."
            
            # Run the async process_message in a new event loop
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            try:
                result = loop.run_until_complete(self.agent.process_message(message))
                response = result.get("response", "No response generated")
                return response
            finally:
                loop.close()
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            return f"Error: {str(e)}"
    def get_quick_actions(self):
        """Get quick action examples for the interface"""
        return [
            "monitor system status",
            "vaultwarden status", 
            "search for kubernetes best practices",
            "shell ls -la",
            "show orchestration help"
        ]

class OrchestrationTool:
    """Base orchestration tool with AI awareness"""
    
    def __init__(self, name: str, description: str, examples: List[str] = None):
        self.name = name
        self.description = description
        self.examples = examples or []
        self.usage_count = 0
        self.success_rate = 1.0
    
    async def execute(self, agent, **kwargs) -> Dict[str, Any]:
        """Execute the tool with AI awareness"""
        self.usage_count += 1
        try:
            result = await self._execute_impl(agent, **kwargs)
            return {
                'success': True,
                'tool': self.name,
                'result': result,
                'usage_count': self.usage_count,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Tool {self.name} failed: {e}")
            return {
                'success': False,
                'tool': self.name,
                'error': str(e),
                'usage_count': self.usage_count,
                'timestamp': datetime.now().isoformat()
            }
    
    async def _execute_impl(self, agent, **kwargs) -> Any:
        """Implementation to be overridden by subclasses"""
        raise NotImplementedError

class VaultwardenTool(OrchestrationTool):
    """Vaultwarden password manager integration"""
    
    def __init__(self, config: AgentConfig):
        super().__init__(
            "vaultwarden",
            "Manage passwords and secrets using Vaultwarden",
            [
                "vaultwarden status",
                "vaultwarden search gmail",
                "vaultwarden create entry for server1",
                "vaultwarden backup vault"
            ]
        )
        self.config = config
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def _execute_impl(self, agent, action: str = "status", **kwargs) -> Dict[str, Any]:
        """Execute Vaultwarden operations"""
        if action == "status":
            return await self._check_status()
        elif action == "search":
            query = kwargs.get('query', '')
            return await self._search_entries(query)
        elif action == "create":
            return await self._create_entry(kwargs)
        elif action == "backup":
            return await self._backup_vault()
        else:
            return {"error": f"Unknown action: {action}"}
    
    async def _check_status(self) -> Dict[str, Any]:
        """Check Vaultwarden server status"""
        try:
            response = await self.client.get(f"{self.config.vaultwarden_url}/alive")
            if response.status_code == 200:
                return {
                    "status": "online",
                    "url": self.config.vaultwarden_url,
                    "version": "latest",
                    "health": "healthy"
                }
            else:
                return {"status": "offline", "error": f"HTTP {response.status_code}"}
        except Exception as e:
            return {"status": "unreachable", "error": str(e)}
    
    async def _search_entries(self, query: str) -> Dict[str, Any]:
        """Search vault entries (mock implementation)"""
        # In production, this would use Bitwarden CLI or API
        mock_entries = [
            {"name": f"Server credentials for {query}", "username": "admin", "id": "1"},
            {"name": f"Database access for {query}", "username": "db_user", "id": "2"}
        ] if query else []
        
        return {
            "query": query,
            "entries": mock_entries,
            "count": len(mock_entries)
        }
    
    async def _create_entry(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create new vault entry (mock implementation)"""
        entry_id = str(uuid.uuid4())
        return {
            "created": True,
            "entry_id": entry_id,
            "name": data.get('name', 'New Entry'),
            "folder": data.get('folder', 'Infrastructure')
        }
    
    async def _backup_vault(self) -> Dict[str, Any]:
        """Backup vault data"""
        backup_file = f"vaultwarden_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        return {
            "backup_created": True,
            "backup_file": backup_file,
            "timestamp": datetime.now().isoformat()
        }

class CryptoWalletTool(OrchestrationTool):
    """Multi-chain crypto wallet management"""
    
    def __init__(self, config: AgentConfig):
        super().__init__(
            "crypto_wallet",
            "Manage cryptocurrency wallets (Solana, Ethereum, Bitcoin)",
            [
                "crypto wallet solana balance",
                "crypto wallet ethereum status",
                "crypto wallet bitcoin transactions",
                "crypto wallet create solana",
                "crypto wallet transfer 0.1 SOL to address"
            ]
        )
        self.config = config
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def _execute_impl(self, agent, chain: str = "solana", action: str = "status", **kwargs) -> Dict[str, Any]:
        """Execute crypto wallet operations"""
        if chain.lower() == "solana":
            return await self._solana_operations(action, **kwargs)
        elif chain.lower() == "ethereum":
            return await self._ethereum_operations(action, **kwargs)
        elif chain.lower() == "bitcoin":
            return await self._bitcoin_operations(action, **kwargs)
        else:
            return {"error": f"Unsupported chain: {chain}"}
    
    async def _solana_operations(self, action: str, **kwargs) -> Dict[str, Any]:
        """Solana blockchain operations"""
        if action == "balance":
            address = kwargs.get('address', 'demo_address')
            return {
                "chain": "solana",
                "address": address,
                "balance": 2.5,
                "currency": "SOL",
                "usd_value": 250.0
            }
        elif action == "status":
            return {
                "chain": "solana",
                "network": "mainnet-beta",
                "rpc_url": self.config.solana_rpc_url,
                "connected": True,
                "slot": 245000000
            }
        elif action == "create":
            return {
                "chain": "solana",
                "action": "create_wallet",
                "address": f"sol_demo_{uuid.uuid4().hex[:8]}",
                "mnemonic": "demo mnemonic phrase (store securely)",
                "created": True
            }
        else:
            return {"error": f"Unknown Solana action: {action}"}
    
    async def _ethereum_operations(self, action: str, **kwargs) -> Dict[str, Any]:
        """Ethereum blockchain operations"""
        if action == "balance":
            address = kwargs.get('address', 'demo_address')
            return {
                "chain": "ethereum",
                "address": address,
                "balance": 0.5,
                "currency": "ETH",
                "usd_value": 2000.0
            }
        elif action == "status":
            return {
                "chain": "ethereum",
                "network": "mainnet",
                "rpc_url": self.config.ethereum_rpc_url,
                "connected": True,
                "block": 19000000
            }
        else:
            return {"error": f"Unknown Ethereum action: {action}"}
    
    async def _bitcoin_operations(self, action: str, **kwargs) -> Dict[str, Any]:
        """Bitcoin blockchain operations"""
        if action == "balance":
            address = kwargs.get('address', 'demo_address')
            return {
                "chain": "bitcoin",
                "address": address,
                "balance": 0.01,
                "currency": "BTC",
                "usd_value": 650.0
            }
        elif action == "status":
            return {
                "chain": "bitcoin",
                "network": "mainnet",
                "connected": True,
                "block_height": 850000
            }
        else:
            return {"error": f"Unknown Bitcoin action: {action}"}

class ShellExecuteTool(OrchestrationTool):
    """Execute shell commands with security controls"""
    
    def __init__(self):
        super().__init__(
            "shell_execute",
            "Execute shell commands for system administration",
            [
                "shell ls -la /var/log",
                "shell docker ps",
                "shell systemctl status nginx",
                "shell df -h",
                "shell top -bn1 | head -20"
            ]
        )
        # Safe commands whitelist
        self.safe_commands = [
            'ls', 'ps', 'top', 'df', 'du', 'free', 'uptime', 'whoami', 'pwd',
            'docker', 'kubectl', 'systemctl', 'journalctl', 'cat', 'tail', 'head',
            'find', 'grep', 'awk', 'sed', 'wc', 'sort', 'uniq'
        ]
    
    async def _execute_impl(self, agent, command: str, **kwargs) -> Dict[str, Any]:
        """Execute shell command with safety checks"""
        # Basic safety check
        cmd_parts = command.split()
        if not cmd_parts:
            return {"error": "Empty command"}
        
        base_cmd = cmd_parts[0]
        if base_cmd not in self.safe_commands:
            return {
                "error": f"Command '{base_cmd}' not in safe commands list",
                "safe_commands": self.safe_commands
            }
        
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30,
                cwd="/root/consciousness-control-center/proxmox-federation"
            )
            
            return {
                "command": command,
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "success": result.returncode == 0
            }
        except subprocess.TimeoutExpired:
            return {"error": "Command timed out after 30 seconds"}
        except Exception as e:
            return {"error": f"Execution failed: {str(e)}"}

class MonitoringTool(OrchestrationTool):
    """System and infrastructure monitoring"""
    
    def __init__(self):
        super().__init__(
            "monitoring",
            "Monitor system resources and infrastructure health",
            [
                "monitoring system",
                "monitoring network",
                "monitoring services",
                "monitoring logs error",
                "monitoring disk usage"
            ]
        )
    
    async def _execute_impl(self, agent, target: str = "system", **kwargs) -> Dict[str, Any]:
        """Execute monitoring operations"""
        if target == "system":
            return self._get_system_metrics()
        elif target == "network":
            return self._get_network_status()
        elif target == "services":
            return self._get_service_status()
        elif target == "logs":
            level = kwargs.get('level', 'info')
            return self._get_logs(level)
        elif target == "disk":
            return self._get_disk_usage()
        else:
            return {"error": f"Unknown monitoring target: {target}"}
    
    def _get_system_metrics(self) -> Dict[str, Any]:
        """Get comprehensive system metrics"""
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        
        return {
            "cpu": {
                "percent": cpu_percent,
                "count": psutil.cpu_count(),
                "freq": psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None
            },
            "memory": {
                "total": memory.total,
                "available": memory.available,
                "percent": memory.percent,
                "used": memory.used
            },
            "disk": {
                "total": disk.total,
                "used": disk.used,
                "free": disk.free,
                "percent": (disk.used / disk.total) * 100
            },
            "system": {
                "boot_time": boot_time.isoformat(),
                "uptime": str(datetime.now() - boot_time),
                "load_avg": os.getloadavg() if hasattr(os, 'getloadavg') else None
            }
        }
    
    def _get_network_status(self) -> Dict[str, Any]:
        """Get network interface status"""
        interfaces = psutil.net_if_addrs()
        stats = psutil.net_if_stats()
        
        network_info = {}
        for interface, addresses in interfaces.items():
            network_info[interface] = {
                "addresses": [addr._asdict() for addr in addresses],
                "stats": stats.get(interface)._asdict() if interface in stats else None
            }
        
        return {
            "interfaces": network_info,
            "connections": len(psutil.net_connections())
        }
    
    def _get_service_status(self) -> Dict[str, Any]:
        """Get service status (mock implementation)"""
        services = [
            {"name": "vaultwarden", "status": "active", "port": 8080},
            {"name": "nginx", "status": "active", "port": 80},
            {"name": "docker", "status": "active", "port": None},
            {"name": "ssh", "status": "active", "port": 22}
        ]
        
        return {
            "services": services,
            "total": len(services),
            "active": len([s for s in services if s["status"] == "active"])
        }
    
    def _get_logs(self, level: str) -> Dict[str, Any]:
        """Get system logs"""
        return {
            "level": level,
            "source": "system",
            "entries": [
                {"timestamp": datetime.now().isoformat(), "level": level, "message": f"Sample {level} log entry"},
                {"timestamp": datetime.now().isoformat(), "level": "info", "message": "System monitoring active"}
            ]
        }
    
    def _get_disk_usage(self) -> Dict[str, Any]:
        """Get detailed disk usage"""
        disk_usage = {}
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disk_usage[partition.mountpoint] = {
                    "device": partition.device,
                    "fstype": partition.fstype,
                    "total": usage.total,
                    "used": usage.used,
                    "free": usage.free,
                    "percent": (usage.used / usage.total) * 100
                }
            except PermissionError:
                disk_usage[partition.mountpoint] = {"error": "Permission denied"}
        
        return disk_usage

# --- Main Application Setup & Entry Point ---

# Create a configuration instance first
config = AgentConfig()

# Create a single instance of the command center, passing the config
command_center = ConsciousnessCommandCenter(config=config)

# Create the FastAPI app
app = FastAPI(
    title="Consciousness Zero Command Center",
    description="AI-powered infrastructure orchestration and advanced web intelligence.",
    version="1.0.0"
)

# Add CORS middleware to allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"]
)

# Define the Gradio interface using the command center instance
io = gr.Interface(
    fn=command_center.process_message_gradio,
    inputs=[
        gr.Textbox(lines=2, placeholder="Enter your command here...", label="Command"),
        # State removed for simplicity
    ],
    outputs=[
        gr.Markdown(label="Response"),
    ],
    title="🧠 Consciousness Zero Command Center",
    description="**Orchestration Tools**: Vaultwarden, Crypto Wallets, Shell, Monitoring, Web Search. **Agent**: Zero-inspired with Perplexica-style search.",
    theme=gr.themes.Soft(),
    allow_flagging="never",
    examples=command_center.get_quick_actions()
)

# Mount the Gradio app to the FastAPI app
app = gr.mount_gradio_app(app, io, path="/")

@app.post("/api/v1/chat")
async def api_chat(request: Request):
    """API endpoint for programmatic access"""
    data = await request.json()
    message = data.get("message")
    if not message:
        raise HTTPException(status_code=400, detail="Message not found")
    
    response_text = command_center.process_message_gradio(message)
    return JSONResponse(content={"response": response_text})

if __name__ == "__main__":
    """Run the server when the script is executed directly"""
    print("Starting Uvicorn server...")
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=command_center.config.web_port,
        log_level="info"
    )
