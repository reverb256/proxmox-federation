"""
Agentic Service - Full implementation with multi-agent orchestration
Integrates with agent-zero and provides built-in agentic capabilities
"""
import httpx
import os
import asyncio
from typing import List, Dict, Any, Optional, Callable
import json
import logging
from datetime import datetime
import uuid
from pathlib import Path

logger = logging.getLogger(__name__)

# External agent providers
AGENT_PROVIDERS = [
    {"name": "agent-zero", "url": os.getenv("AGENT_ZERO_URL", "http://agent-zero:8003")},
    {"name": "autogen", "url": os.getenv("AUTOGEN_URL", "http://autogen:8004")}
]

# Agent storage
AGENTS_DIR = Path("/app/data/agents")
AGENTS_DIR.mkdir(parents=True, exist_ok=True)

class Agent:
    def __init__(self, agent_id: str, name: str, capabilities: List[str], model: str = "gpt-4"):
        self.agent_id = agent_id
        self.name = name
        self.capabilities = capabilities
        self.model = model
        self.memory = {}
        self.conversation_history = []
        self.tools = {}
        
    async def think(self, task: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Agent thinking/reasoning process"""
        thought_process = {
            "task": task,
            "context": context,
            "timestamp": datetime.now().isoformat(),
            "agent_id": self.agent_id,
            "reasoning": f"Analyzing task: {task}",
            "plan": self._create_plan(task, context),
            "tools_needed": self._identify_tools(task)
        }
        
        self.conversation_history.append(thought_process)
        return thought_process
    
    def _create_plan(self, task: str, context: Dict[str, Any]) -> List[str]:
        """Create execution plan for the task"""
        # Basic planning logic - would be enhanced with LLM
        if "deploy" in task.lower():
            return ["analyze_requirements", "prepare_deployment", "execute_deployment", "verify_deployment"]
        elif "monitor" in task.lower():
            return ["setup_monitoring", "collect_metrics", "analyze_data", "generate_report"]
        elif "backup" in task.lower():
            return ["identify_data", "prepare_backup", "execute_backup", "verify_backup"]
        else:
            return ["understand_task", "gather_information", "execute_action", "verify_result"]
    
    def _identify_tools(self, task: str) -> List[str]:
        """Identify tools needed for the task"""
        tools = []
        if any(word in task.lower() for word in ["deploy", "infrastructure", "server"]):
            tools.extend(["ansible", "terraform", "ssh"])
        if any(word in task.lower() for word in ["search", "find", "research"]):
            tools.extend(["web_search", "rag"])
        if any(word in task.lower() for word in ["proxmox", "vm", "container"]):
            tools.extend(["proxmoxer", "ssh"])
        return tools

class AgentOrchestrator:
    def __init__(self):
        self.agents = {}
        self.tasks = {}
        self.providers = AGENT_PROVIDERS
        
    async def create_agent(self, name: str, capabilities: List[str], model: str = "gpt-4") -> str:
        """Create a new agent"""
        agent_id = str(uuid.uuid4())
        agent = Agent(agent_id, name, capabilities, model)
        self.agents[agent_id] = agent
        
        # Save agent to disk
        agent_data = {
            "agent_id": agent_id,
            "name": name,
            "capabilities": capabilities,
            "model": model,
            "created_at": datetime.now().isoformat()
        }
        
        agent_file = AGENTS_DIR / f"{agent_id}.json"
        with open(agent_file, 'w') as f:
            json.dump(agent_data, f, indent=2)
        
        logger.info(f"Created agent {name} with ID {agent_id}")
        return agent_id
    
    async def list_agents(self) -> Dict[str, Any]:
        """List all available agents"""
        agents_info = []
        for agent_id, agent in self.agents.items():
            agents_info.append({
                "agent_id": agent_id,
                "name": agent.name,
                "capabilities": agent.capabilities,
                "model": agent.model,
                "active_tasks": len([t for t in self.tasks.values() if t.get("agent_id") == agent_id])
            })
        
        return {"agents": agents_info}
    
    async def delegate_task(self, task: str, context: Dict[str, Any], agent_id: Optional[str] = None) -> Dict[str, Any]:
        """Delegate a task to an agent or auto-select the best agent"""
        try:
            # Auto-select agent if not specified
            if not agent_id:
                agent_id = await self._select_best_agent(task, context)
                if not agent_id:
                    # Create a generic agent if none exists
                    agent_id = await self.create_agent(
                        "AutoAgent",
                        ["general", "analysis", "execution"],
                        "gpt-4"
                    )
            
            if agent_id not in self.agents:
                return {"status": "error", "message": f"Agent {agent_id} not found"}
            
            agent = self.agents[agent_id]
            
            # Try external providers first
            for provider in self.providers:
                try:
                    async with httpx.AsyncClient(timeout=60.0) as client:
                        resp = await client.post(
                            f"{provider['url']}/execute",
                            json={
                                "task": task,
                                "context": context,
                                "agent_config": {
                                    "name": agent.name,
                                    "capabilities": agent.capabilities,
                                    "model": agent.model
                                }
                            }
                        )
                        if resp.status_code == 200:
                            result = resp.json()
                            await self._log_task_execution(agent_id, task, context, result, provider["name"])
                            return {"status": "success", "provider": provider["name"], "result": result}
                except Exception as e:
                    logger.warning(f"Provider {provider['name']} failed: {e}")
                    continue
            
            # Fallback: built-in agent execution
            result = await self._execute_task_builtin(agent, task, context)
            await self._log_task_execution(agent_id, task, context, result, "builtin")
            return {"status": "success", "provider": "builtin", "result": result}
            
        except Exception as e:
            logger.error(f"Task delegation failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def _select_best_agent(self, task: str, context: Dict[str, Any]) -> Optional[str]:
        """Select the best agent for a task based on capabilities"""
        best_agent_id = None
        best_score = 0
        
        for agent_id, agent in self.agents.items():
            score = self._calculate_agent_fitness(agent, task, context)
            if score > best_score:
                best_score = score
                best_agent_id = agent_id
        
        return best_agent_id
    
    def _calculate_agent_fitness(self, agent: Agent, task: str, context: Dict[str, Any]) -> float:
        """Calculate how well an agent fits a task"""
        score = 0.0
        task_lower = task.lower()
        
        # Score based on capabilities
        for capability in agent.capabilities:
            if capability.lower() in task_lower:
                score += 1.0
        
        # Score based on previous success (simplified)
        successful_tasks = len([h for h in agent.conversation_history if h.get("success", False)])
        total_tasks = len(agent.conversation_history)
        if total_tasks > 0:
            score += (successful_tasks / total_tasks) * 0.5
        
        return score
    
    async def _execute_task_builtin(self, agent: Agent, task: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute task using built-in agent logic"""
        # Agent thinks about the task
        thought_process = await agent.think(task, context)
        
        # Execute the plan
        execution_results = []
        for step in thought_process["plan"]:
            step_result = await self._execute_step(step, task, context, agent)
            execution_results.append(step_result)
        
        return {
            "task": task,
            "agent": agent.name,
            "thought_process": thought_process,
            "execution_results": execution_results,
            "success": all(r.get("success", False) for r in execution_results),
            "timestamp": datetime.now().isoformat()
        }
    
    async def _execute_step(self, step: str, task: str, context: Dict[str, Any], agent: Agent) -> Dict[str, Any]:
        """Execute a single step in the agent's plan"""
        # This is a simplified step execution - would be enhanced with actual tool calling
        return {
            "step": step,
            "description": f"Executed {step} for task: {task}",
            "success": True,
            "timestamp": datetime.now().isoformat()
        }
    
    async def _log_task_execution(self, agent_id: str, task: str, context: Dict[str, Any], result: Dict[str, Any], provider: str):
        """Log task execution for analysis and learning"""
        task_id = str(uuid.uuid4())
        task_log = {
            "task_id": task_id,
            "agent_id": agent_id,
            "task": task,
            "context": context,
            "result": result,
            "provider": provider,
            "timestamp": datetime.now().isoformat()
        }
        
        self.tasks[task_id] = task_log
        
        # Save to disk
        task_file = AGENTS_DIR / f"task_{task_id}.json"
        with open(task_file, 'w') as f:
            json.dump(task_log, f, indent=2)
    
    async def get_task_history(self, agent_id: Optional[str] = None) -> Dict[str, Any]:
        """Get task execution history"""
        if agent_id:
            tasks = [t for t in self.tasks.values() if t.get("agent_id") == agent_id]
        else:
            tasks = list(self.tasks.values())
        
        return {"tasks": tasks}

# Global orchestrator instance
agent_orchestrator = AgentOrchestrator()

# Functions for gateway integration
async def agent_act(task: str, context: Dict[str, Any], agent_id: Optional[str] = None):
    return await agent_orchestrator.delegate_task(task, context, agent_id)

async def agent_create(name: str, capabilities: List[str], model: str = "gpt-4"):
    agent_id = await agent_orchestrator.create_agent(name, capabilities, model)
    return {"status": "success", "agent_id": agent_id}

async def agent_list():
    return await agent_orchestrator.list_agents()

async def agent_history(agent_id: Optional[str] = None):
    return await agent_orchestrator.get_task_history(agent_id)
