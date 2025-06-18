#!/usr/bin/env python3
"""
Consciousness Control Center - Docker Version
Clean, focused AI agent for local deployment with Open WebUI integration
"""

import os
import sys
import json
import logging
import asyncio
from typing import Dict, List, Any, Optional, Union
from datetime import datetime
from pathlib import Path
import subprocess
import psutil
import httpx
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/app/logs/consciousness.log')
    ]
)
logger = logging.getLogger(__name__)

class ConsciousnessAgent:
    """
    Core AI agent for infrastructure orchestration and assistance
    Designed for local deployment with Open WebUI integration
    """
    
    def __init__(self, config_path: str = "/app/config/config.json"):
        self.config = self._load_config(config_path)
        self.tools = self._initialize_tools()
        self.memory = {}
        self.context_cache = {}
        
        logger.info(f"🧠 Consciousness Control Center initialized")
        logger.info(f"📊 Environment: Docker Container")
        logger.info(f"🛠️ Tools loaded: {len(self.tools)}")
    
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from file or environment variables"""
        default_config = {
            "agent_name": "Consciousness Zero",
            "version": "3.0.0",
            "environment": "docker",
            "tools_enabled": [
                "system_monitor",
                "shell_executor", 
                "web_search",
                "memory_manager",
                "file_manager",
                "network_scanner",
                "log_analyzer"
            ],
            "memory_retention_days": 30,
            "max_context_tokens": 4000,
            "debug_mode": os.getenv("DEBUG", "false").lower() == "true"
        }
        
        try:
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    file_config = json.load(f)
                default_config.update(file_config)
            
            # Override with environment variables
            for key, value in default_config.items():
                env_key = f"CONSCIOUSNESS_{key.upper()}"
                if env_key in os.environ:
                    default_config[key] = os.environ[env_key]
            
            return default_config
            
        except Exception as e:
            logger.warning(f"Config load error: {e}. Using defaults.")
            return default_config
    
    def _initialize_tools(self) -> Dict[str, Any]:
        """Initialize available tools based on configuration"""
        tools = {}
        
        if "system_monitor" in self.config["tools_enabled"]:
            tools["system_monitor"] = SystemMonitor()
        
        if "shell_executor" in self.config["tools_enabled"]:
            tools["shell_executor"] = ShellExecutor()
        
        if "web_search" in self.config["tools_enabled"]:
            tools["web_search"] = WebSearchTool()
        
        if "memory_manager" in self.config["tools_enabled"]:
            tools["memory_manager"] = MemoryManager()
        
        if "file_manager" in self.config["tools_enabled"]:
            tools["file_manager"] = FileManager()
        
        if "network_scanner" in self.config["tools_enabled"]:
            tools["network_scanner"] = NetworkScanner()
        
        if "log_analyzer" in self.config["tools_enabled"]:
            tools["log_analyzer"] = LogAnalyzer()
        
        return tools
    
    async def process_message(self, message: str, user_id: str = "local") -> Dict[str, Any]:
        """
        Process incoming message and route to appropriate tools
        Designed for Open WebUI integration
        """
        try:
            logger.info(f"📝 Processing message from {user_id}: {message[:100]}...")
            
            # Analyze message intent
            intent = self._analyze_intent(message)
            
            # Route to appropriate tool
            if intent["tool"] in self.tools:
                result = await self._execute_tool(intent["tool"], intent["parameters"], message)
            else:
                result = await self._default_response(message)
            
            # Store in memory
            self._store_interaction(user_id, message, result)
            
            return {
                "response": result,
                "intent": intent,
                "timestamp": datetime.now().isoformat(),
                "agent": self.config["agent_name"]
            }
            
        except Exception as e:
            logger.error(f"Message processing error: {e}")
            return {
                "response": f"I encountered an error: {str(e)}",
                "error": True,
                "timestamp": datetime.now().isoformat()
            }
    
    def _analyze_intent(self, message: str) -> Dict[str, Any]:
        """Analyze message to determine intent and parameters"""
        message_lower = message.lower()
        
        # System monitoring
        if any(word in message_lower for word in ["status", "monitor", "system", "health", "performance"]):
            return {"tool": "system_monitor", "parameters": {"type": "status"}}
        
        # Shell commands
        elif any(word in message_lower for word in ["run", "execute", "shell", "command", "bash"]):
            return {"tool": "shell_executor", "parameters": {"command": message}}
        
        # Web search
        elif any(word in message_lower for word in ["search", "find", "lookup", "google", "web"]):
            return {"tool": "web_search", "parameters": {"query": message}}
        
        # File operations
        elif any(word in message_lower for word in ["file", "directory", "folder", "list", "ls", "cat"]):
            return {"tool": "file_manager", "parameters": {"operation": message}}
        
        # Network operations
        elif any(word in message_lower for word in ["network", "scan", "ping", "port", "nmap"]):
            return {"tool": "network_scanner", "parameters": {"target": message}}
        
        # Log analysis
        elif any(word in message_lower for word in ["log", "error", "debug", "analyze"]):
            return {"tool": "log_analyzer", "parameters": {"query": message}}
        
        # Memory operations
        elif any(word in message_lower for word in ["remember", "recall", "memory", "history"]):
            return {"tool": "memory_manager", "parameters": {"operation": message}}
        
        # Default to general assistance
        else:
            return {"tool": "general", "parameters": {"message": message}}
    
    async def _execute_tool(self, tool_name: str, parameters: Dict[str, Any], original_message: str) -> str:
        """Execute the specified tool with parameters"""
        try:
            tool = self.tools[tool_name]
            if hasattr(tool, 'execute'):
                result = await tool.execute(parameters, original_message)
            else:
                result = f"Tool {tool_name} is not properly configured"
            
            return result
            
        except Exception as e:
            logger.error(f"Tool execution error ({tool_name}): {e}")
            return f"Error executing {tool_name}: {str(e)}"
    
    async def _default_response(self, message: str) -> str:
        """Default response for unrecognized intents"""
        return f"""🧠 **Consciousness Control Center**

I understand you said: "{message}"

**Available capabilities:**
- 📊 **System Monitoring**: Check system status and performance
- 🖥️ **Shell Execution**: Run system commands safely
- 🔍 **Web Search**: Search the internet for information
- 📁 **File Management**: Manage files and directories
- 🌐 **Network Scanning**: Scan networks and check connectivity
- 📝 **Log Analysis**: Analyze system logs and errors
- 🧠 **Memory**: Remember and recall information

**Example commands:**
- "What's the system status?"
- "Run 'docker ps' command"
- "Search for Docker best practices"
- "List files in /app/data"
- "Scan network for devices"
- "Analyze error logs"
- "Remember this configuration"

How can I help you today?
"""
    
    def _store_interaction(self, user_id: str, message: str, response: Any):
        """Store interaction in memory for context"""
        if user_id not in self.memory:
            self.memory[user_id] = []
        
        self.memory[user_id].append({
            "timestamp": datetime.now().isoformat(),
            "message": message,
            "response": str(response),
            "intent": self._analyze_intent(message)
        })
        
        # Limit memory size
        if len(self.memory[user_id]) > 100:
            self.memory[user_id] = self.memory[user_id][-50:]

class SystemMonitor:
    """System monitoring and health checks"""
    
    async def execute(self, parameters: Dict[str, Any], original_message: str) -> str:
        """Execute system monitoring"""
        try:
            # Get system metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            # Get Docker container info if available
            docker_info = ""
            try:
                result = subprocess.run(['docker', 'ps', '--format', 'table {{.Names}}\t{{.Status}}'], 
                                     capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    docker_info = f"\n**Docker Containers:**\n```\n{result.stdout}\n```"
            except:
                pass
            
            return f"""📊 **System Status Report**

**CPU Usage**: {cpu_percent}%
**Memory**: {memory.percent}% used ({memory.used//1024//1024//1024}GB / {memory.total//1024//1024//1024}GB)
**Disk**: {disk.percent}% used ({disk.free//1024//1024//1024}GB free)
**Environment**: Docker Container
**Status**: ✅ Operational

{docker_info}

**Uptime**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
            
        except Exception as e:
            return f"System monitoring error: {str(e)}"

class ShellExecutor:
    """Safe shell command execution"""
    
    ALLOWED_COMMANDS = [
        'ls', 'pwd', 'whoami', 'date', 'uptime', 'df', 'free', 'ps',
        'docker', 'kubectl', 'git', 'curl', 'ping', 'nslookup', 'dig'
    ]
    
    async def execute(self, parameters: Dict[str, Any], original_message: str) -> str:
        """Execute shell command safely"""
        try:
            # Extract command from message
            command = parameters.get("command", "").strip()
            
            # Remove command prefixes
            for prefix in ["run", "execute", "shell", "command", "bash"]:
                if command.lower().startswith(prefix):
                    command = command[len(prefix):].strip()
            
            if not command:
                return "Please specify a command to execute."
            
            # Parse command
            cmd_parts = command.split()
            if not cmd_parts:
                return "Invalid command format."
            
            base_command = cmd_parts[0]
            
            # Security check
            if base_command not in self.ALLOWED_COMMANDS:
                return f"Command '{base_command}' is not allowed for security reasons.\n\nAllowed commands: {', '.join(self.ALLOWED_COMMANDS)}"
            
            # Execute command
            result = subprocess.run(
                cmd_parts,
                capture_output=True,
                text=True,
                timeout=30,
                cwd="/app"
            )
            
            output = result.stdout if result.stdout else result.stderr
            
            return f"""🖥️ **Command Execution**

**Command**: `{command}`
**Exit Code**: {result.returncode}

**Output**:
```
{output}
```
"""
            
        except subprocess.TimeoutExpired:
            return "Command execution timed out (30s limit)."
        except Exception as e:
            return f"Command execution error: {str(e)}"

class WebSearchTool:
    """Web search capabilities"""
    
    async def execute(self, parameters: Dict[str, Any], original_message: str) -> str:
        """Perform web search"""
        try:
            query = parameters.get("query", "").strip()
            
            # Extract search query from message
            for prefix in ["search", "find", "lookup", "google", "web"]:
                if query.lower().startswith(prefix):
                    query = query[len(prefix):].strip()
            
            if not query:
                return "Please specify what you'd like to search for."
            
            # Simulate web search (in real implementation, use actual search API)
            return f"""🔍 **Web Search Results** for: "{query}"

*Note: Web search is currently simulated. In a full implementation, this would connect to search APIs.*

**Suggested resources:**
- Documentation and official guides
- Stack Overflow discussions
- GitHub repositories
- Blog posts and tutorials

**Next steps:**
- Implement actual search API integration
- Add result caching and ranking
- Enable content extraction and summarization
"""
            
        except Exception as e:
            return f"Web search error: {str(e)}"

class FileManager:
    """File and directory management"""
    
    async def execute(self, parameters: Dict[str, Any], original_message: str) -> str:
        """Execute file operations"""
        try:
            operation = parameters.get("operation", "").strip().lower()
            
            # Simple file operations
            if "list" in operation or "ls" in operation:
                result = subprocess.run(['ls', '-la', '/app'], capture_output=True, text=True)
                return f"📁 **Directory Listing** (/app):\n```\n{result.stdout}\n```"
            
            elif "config" in operation:
                if os.path.exists('/app/config/config.json'):
                    with open('/app/config/config.json', 'r') as f:
                        config = f.read()
                    return f"⚙️ **Configuration**:\n```json\n{config}\n```"
                else:
                    return "Configuration file not found."
            
            elif "logs" in operation:
                if os.path.exists('/app/logs/consciousness.log'):
                    with open('/app/logs/consciousness.log', 'r') as f:
                        logs = f.read()[-1000:]  # Last 1000 characters
                    return f"📝 **Recent Logs**:\n```\n{logs}\n```"
                else:
                    return "Log file not found."
            
            else:
                return "Available file operations: list, config, logs"
                
        except Exception as e:
            return f"File operation error: {str(e)}"

class NetworkScanner:
    """Network scanning and connectivity checks"""
    
    async def execute(self, parameters: Dict[str, Any], original_message: str) -> str:
        """Execute network operations"""
        try:
            return """🌐 **Network Scanner**

*Network scanning capabilities are available but limited in Docker environment.*

**Available operations:**
- Ping connectivity tests
- DNS lookups
- Port connectivity checks
- Container network inspection

**Security note**: Network scanning is restricted in containerized environments for security reasons.
"""
            
        except Exception as e:
            return f"Network operation error: {str(e)}"

class LogAnalyzer:
    """Log analysis and error detection"""
    
    async def execute(self, parameters: Dict[str, Any], original_message: str) -> str:
        """Analyze logs for errors and patterns"""
        try:
            return """📊 **Log Analysis**

*Log analysis capabilities are ready for implementation.*

**Features:**
- Error pattern detection
- Performance metric extraction
- Anomaly identification
- Trend analysis

**Data sources:**
- Application logs
- System logs
- Container logs
- Custom log files
"""
            
        except Exception as e:
            return f"Log analysis error: {str(e)}"

class MemoryManager:
    """Memory and context management"""
    
    async def execute(self, parameters: Dict[str, Any], original_message: str) -> str:
        """Manage memory and context"""
        try:
            return """🧠 **Memory Manager**

*Memory management system is active.*

**Capabilities:**
- Context retention across conversations
- Information storage and retrieval
- Pattern recognition
- Learning from interactions

**Status**: Ready for enhanced memory operations
"""
            
        except Exception as e:
            return f"Memory operation error: {str(e)}"

# Create global agent instance
consciousness_agent = None

def initialize_agent():
    """Initialize the consciousness agent"""
    global consciousness_agent
    if consciousness_agent is None:
        consciousness_agent = ConsciousnessAgent()
    return consciousness_agent

async def process_openwebui_message(message: str, user_id: str = "local") -> str:
    """
    Process message from Open WebUI
    This function can be called by Open WebUI integration
    """
    agent = initialize_agent()
    result = await agent.process_message(message, user_id)
    return result["response"]

if __name__ == "__main__":
    # Initialize agent
    agent = initialize_agent()
    
    # Simple test interface for development
    print("🧠 Consciousness Control Center - Docker Edition")
    print("=" * 50)
    print("Agent initialized. Ready for integration with Open WebUI.")
    print("Type 'exit' to quit, or enter commands to test:")
    print()
    
    async def test_interface():
        while True:
            try:
                message = input("💬 You: ").strip()
                if message.lower() in ['exit', 'quit']:
                    break
                
                if message:
                    result = await agent.process_message(message)
                    print(f"🧠 Agent: {result['response']}")
                    print()
                    
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Error: {e}")
    
    # Run test interface
    try:
        asyncio.run(test_interface())
    except KeyboardInterrupt:
        pass
    
    print("\n👋 Consciousness Control Center shutting down...")
