"""
Open WebUI Integration for Consciousness Control Center
This module provides integration between Consciousness Control Center and Open WebUI
"""

import asyncio
import json
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

# Import our consciousness agent
from consciousness_zero_optimized import initialize_agent, process_openwebui_message

logger = logging.getLogger(__name__)

class ConsciousnessOpenWebUIFunction:
    """
    Open WebUI Function for Consciousness Control Center
    
    This class provides the interface for Open WebUI to communicate with
    the Consciousness Control Center agent.
    """
    
    def __init__(self):
        self.agent = initialize_agent()
        self.name = "consciousness_control"
        self.description = "Access to Consciousness Control Center for system management and AI assistance"
    
    async def __call__(self, 
                      message: str,
                      user_id: str = "openwebui_user",
                      **kwargs) -> Dict[str, Any]:
        """
        Main function called by Open WebUI
        
        Args:
            message: User message/query
            user_id: User identifier from Open WebUI
            **kwargs: Additional parameters from Open WebUI
            
        Returns:
            Dictionary with response and metadata
        """
        try:
            logger.info(f"Consciousness function called by {user_id}: {message[:100]}...")
            
            # Process message through consciousness agent
            result = await self.agent.process_message(message, user_id)
            
            return {
                "success": True,
                "response": result["response"],
                "metadata": {
                    "agent": result.get("agent", "Consciousness Zero"),
                    "timestamp": result.get("timestamp"),
                    "intent": result.get("intent", {}),
                    "tools_used": result.get("tools_used", [])
                }
            }
            
        except Exception as e:
            logger.error(f"Consciousness function error: {e}")
            return {
                "success": False,
                "error": str(e),
                "response": f"I encountered an error: {str(e)}"
            }

# Function registry for Open WebUI
def get_openwebui_functions() -> List[Dict[str, Any]]:
    """
    Return function definitions for Open WebUI
    
    This is the format expected by Open WebUI for custom functions
    """
    return [
        {
            "name": "consciousness_control",
            "description": "Access Consciousness Control Center for system management, monitoring, and AI assistance",
            "parameters": {
                "type": "object",
                "properties": {
                    "message": {
                        "type": "string",
                        "description": "The message or command to send to Consciousness Control Center"
                    },
                    "user_id": {
                        "type": "string", 
                        "description": "User identifier (optional)",
                        "default": "openwebui_user"
                    }
                },
                "required": ["message"]
            },
            "function": ConsciousnessOpenWebUIFunction()
        }
    ]

# Example usage and testing
async def test_integration():
    """Test the Open WebUI integration"""
    print("🧠 Testing Consciousness Control Center - Open WebUI Integration")
    print("=" * 60)
    
    # Initialize function
    consciousness_func = ConsciousnessOpenWebUIFunction()
    
    # Test messages
    test_messages = [
        "What's the system status?",
        "List files in the current directory",
        "Run 'docker ps' command",
        "Search for Docker best practices",
        "What can you help me with?"
    ]
    
    for message in test_messages:
        print(f"\n💬 Test: {message}")
        result = await consciousness_func(message, "test_user")
        
        if result["success"]:
            print(f"✅ Response: {result['response'][:200]}...")
        else:
            print(f"❌ Error: {result['error']}")

if __name__ == "__main__":
    # Run test
    asyncio.run(test_integration())
