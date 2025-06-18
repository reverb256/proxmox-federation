#!/usr/bin/env python3
"""
AI Command Center FastAPI Backend
Advanced API service for consciousness orchestration
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Dict, List, Optional, Any
import asyncio
import json
import logging
import os
from datetime import datetime
import uvicorn

# Import the orchestrator from the main application
from ai_command_center import ConsciousnessOrchestrator

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Pydantic models for API
class ChatRequest(BaseModel):
    agent_name: str
    message: str
    temperature: float = 0.7
    max_tokens: int = 1024
    stream: bool = False

class ChatResponse(BaseModel):
    response: str
    agent: str
    timestamp: str
    model_used: str
    tokens_used: Optional[int] = None

class WorkflowRequest(BaseModel):
    prompt: str
    workflow_type: str = "general"
    agents: List[str] = []
    parameters: Dict[str, Any] = {}

class WorkflowResponse(BaseModel):
    results: Any
    workflow_type: str
    timestamp: str
    agents_used: List[str]

class ModelComparisonRequest(BaseModel):
    prompt: str
    models: List[str]
    temperature: float = 0.7
    max_tokens: int = 1024

class ModelComparisonResponse(BaseModel):
    prompt: str
    results: Dict[str, str]
    timestamp: str

class SystemStatus(BaseModel):
    io_intelligence_available: bool
    huggingface_available: bool
    cuda_available: bool
    models_count: int
    agents_count: int
    uptime: str
    memory_usage: Optional[Dict[str, Any]] = None

# Initialize FastAPI app
app = FastAPI(
    title="AI Command Center API",
    description="Advanced API service for consciousness orchestration with Hugging Face and IO Intelligence",
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

# Global orchestrator instance
orchestrator = ConsciousnessOrchestrator()

# Startup time for uptime calculation
startup_time = datetime.now()

@app.on_event("startup")
async def startup_event():
    """Initialize the application on startup"""
    logger.info("🚀 AI Command Center API starting up...")
    logger.info(f"Loaded {len(orchestrator.models)} models and {len(orchestrator.agents)} agents")

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "AI Command Center API",
        "description": "Consciousness orchestration hub with Hugging Face and IO Intelligence",
        "version": "1.0.0",
        "docs": "/docs",
        "status": "/status"
    }

@app.get("/status", response_model=SystemStatus)
async def get_status():
    """Get system status and health information"""
    try:
        import torch
        import psutil
        
        # Calculate uptime
        uptime_delta = datetime.now() - startup_time
        uptime_str = str(uptime_delta).split('.')[0]  # Remove microseconds
        
        # Get memory usage
        memory_info = {
            "total": psutil.virtual_memory().total,
            "available": psutil.virtual_memory().available,
            "percent": psutil.virtual_memory().percent,
            "used": psutil.virtual_memory().used
        }
        
        if torch.cuda.is_available():
            memory_info["gpu_memory"] = {
                "allocated": torch.cuda.memory_allocated(),
                "cached": torch.cuda.memory_reserved()
            }
        
        return SystemStatus(
            io_intelligence_available=orchestrator.io_client is not None,
            huggingface_available=orchestrator.hf_api is not None,
            cuda_available=torch.cuda.is_available(),
            models_count=len(orchestrator.models),
            agents_count=len(orchestrator.agents),
            uptime=uptime_str,
            memory_usage=memory_info
        )
    except Exception as e:
        logger.error(f"Error getting system status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/models")
async def get_models():
    """Get list of available models"""
    return {
        "models": [
            {
                "name": name,
                "type": config.type,
                "model_id": config.model_id,
                "max_tokens": config.max_tokens
            }
            for name, config in orchestrator.models.items()
        ]
    }

@app.get("/agents")
async def get_agents():
    """Get list of available agents"""
    return {
        "agents": [
            {
                "name": name,
                "description": config.description,
                "capabilities": config.capabilities,
                "model": config.model_config.name
            }
            for name, config in orchestrator.agents.items()
        ]
    }

@app.post("/chat", response_model=ChatResponse)
async def chat_with_agent(request: ChatRequest):
    """Chat with a specific agent"""
    try:
        if request.agent_name not in orchestrator.agents:
            raise HTTPException(status_code=404, detail=f"Agent '{request.agent_name}' not found")
        
        response = await orchestrator.query_agent(
            request.agent_name,
            request.message,
            temperature=request.temperature,
            max_tokens=request.max_tokens
        )
        
        agent_config = orchestrator.agents[request.agent_name]
        
        return ChatResponse(
            response=response,
            agent=request.agent_name,
            timestamp=datetime.now().isoformat(),
            model_used=agent_config.model_config.name
        )
    
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat/stream")
async def chat_with_agent_stream(request: ChatRequest):
    """Chat with agent using streaming response"""
    if not request.stream:
        # Fall back to regular chat
        result = await chat_with_agent(request)
        return result
    
    async def generate_stream():
        try:
            # For now, we'll simulate streaming by chunking the response
            response = await orchestrator.query_agent(
                request.agent_name,
                request.message,
                temperature=request.temperature,
                max_tokens=request.max_tokens
            )
            
            # Split response into chunks for streaming
            words = response.split()
            chunk_size = 5
            
            for i in range(0, len(words), chunk_size):
                chunk = " ".join(words[i:i+chunk_size])
                yield f"data: {json.dumps({'chunk': chunk})}\n\n"
                await asyncio.sleep(0.1)  # Small delay for streaming effect
            
            yield f"data: {json.dumps({'done': True})}\n\n"
            
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
    
    return StreamingResponse(generate_stream(), media_type="text/plain")

@app.post("/workflow", response_model=WorkflowResponse)
async def execute_workflow(request: WorkflowRequest):
    """Execute IO Intelligence workflow"""
    try:
        results = await orchestrator.query_iointel_agent_workflow(
            request.prompt,
            request.workflow_type
        )
        
        return WorkflowResponse(
            results=results,
            workflow_type=request.workflow_type,
            timestamp=datetime.now().isoformat(),
            agents_used=request.agents
        )
    
    except Exception as e:
        logger.error(f"Error in workflow endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/compare", response_model=ModelComparisonResponse)
async def compare_models(request: ModelComparisonRequest):
    """Compare responses from different models"""
    try:
        results = {}
        
        for model_name in request.models:
            if model_name not in orchestrator.models:
                results[model_name] = f"Error: Model '{model_name}' not found"
                continue
            
            model_config = orchestrator.models[model_name]
            
            if model_config.type == "iointel":
                response = await orchestrator.query_iointel_model(
                    model_config,
                    request.prompt,
                    temperature=request.temperature,
                    max_tokens=request.max_tokens
                )
            elif model_config.type == "huggingface":
                response = orchestrator.query_huggingface_model(
                    model_config,
                    request.prompt,
                    temperature=request.temperature,
                    max_tokens=request.max_tokens
                )
            else:
                response = "Error: Unknown model type"
            
            results[model_name] = response
        
        return ModelComparisonResponse(
            prompt=request.prompt,
            results=results,
            timestamp=datetime.now().isoformat()
        )
    
    except Exception as e:
        logger.error(f"Error in compare endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/conversations")
async def get_conversations(limit: int = 10):
    """Get conversation history"""
    try:
        conversations = orchestrator.conversation_history[-limit:] if orchestrator.conversation_history else []
        return {
            "conversations": conversations,
            "total_count": len(orchestrator.conversation_history)
        }
    except Exception as e:
        logger.error(f"Error getting conversations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/conversations")
async def clear_conversations():
    """Clear conversation history"""
    try:
        count = len(orchestrator.conversation_history)
        orchestrator.conversation_history.clear()
        return {"message": f"Cleared {count} conversations"}
    except Exception as e:
        logger.error(f"Error clearing conversations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/agents/{agent_name}/capabilities")
async def get_agent_capabilities(agent_name: str):
    """Get capabilities of a specific agent"""
    try:
        if agent_name not in orchestrator.agents:
            raise HTTPException(status_code=404, detail=f"Agent '{agent_name}' not found")
        
        agent_config = orchestrator.agents[agent_name]
        return {
            "agent": agent_name,
            "capabilities": agent_config.capabilities,
            "description": agent_config.description,
            "model": agent_config.model_config.name
        }
    except Exception as e:
        logger.error(f"Error getting agent capabilities: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "uptime": str(datetime.now() - startup_time).split('.')[0]
    }

# Background task for periodic cleanup
async def cleanup_old_conversations():
    """Clean up old conversations periodically"""
    while True:
        try:
            # Keep only last 1000 conversations
            if len(orchestrator.conversation_history) > 1000:
                orchestrator.conversation_history = orchestrator.conversation_history[-1000:]
                logger.info("Cleaned up old conversations")
        except Exception as e:
            logger.error(f"Error in cleanup task: {e}")
        
        await asyncio.sleep(3600)  # Run every hour

@app.on_event("startup")
async def start_background_tasks():
    """Start background tasks"""
    asyncio.create_task(cleanup_old_conversations())

def main():
    """Main function to start the FastAPI server"""
    print("🚀 Starting AI Command Center FastAPI Backend")
    print("=" * 50)
    
    # Environment check
    print("Environment Check:")
    print(f"- IO Intelligence: {'✅' if orchestrator.io_client else '❌'}")
    print(f"- Hugging Face: {'✅' if orchestrator.hf_api else '❌'}")
    
    # Start server
    uvicorn.run(
        "api_backend:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )

if __name__ == "__main__":
    main()
