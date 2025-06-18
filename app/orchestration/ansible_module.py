"""
Ansible Orchestration Module - Full implementation with playbook management
"""
import subprocess
import asyncio
import yaml
import json
import os
from typing import Dict, List, Any, Optional
from pathlib import Path
import tempfile
import logging

logger = logging.getLogger(__name__)

ANSIBLE_DIR = Path("/app/data/ansible")
PLAYBOOKS_DIR = ANSIBLE_DIR / "playbooks"
INVENTORIES_DIR = ANSIBLE_DIR / "inventories"
ANSIBLE_DIR.mkdir(parents=True, exist_ok=True)
PLAYBOOKS_DIR.mkdir(parents=True, exist_ok=True)
INVENTORIES_DIR.mkdir(parents=True, exist_ok=True)

class AnsibleOrchestrator:
    def __init__(self):
        self.base_dir = ANSIBLE_DIR
        self.playbooks_dir = PLAYBOOKS_DIR
        self.inventories_dir = INVENTORIES_DIR
        
    async def run_playbook(self, playbook_path: str, inventory: Optional[str] = None, 
                          extra_vars: Optional[Dict[str, Any]] = None, 
                          tags: Optional[List[str]] = None, 
                          limit: Optional[str] = None) -> Dict[str, Any]:
        """Run an Ansible playbook with full options"""
        try:
            # Resolve playbook path
            if not os.path.isabs(playbook_path):
                playbook_path = str(self.playbooks_dir / playbook_path)
            
            if not os.path.exists(playbook_path):
                return {"status": "error", "message": f"Playbook not found: {playbook_path}"}
            
            # Build command
            cmd = ["ansible-playbook", playbook_path]
            
            # Add inventory
            if inventory:
                if not os.path.isabs(inventory):
                    inventory = str(self.inventories_dir / inventory)
                cmd.extend(["-i", inventory])
            
            # Add extra vars
            if extra_vars:
                cmd.extend(["--extra-vars", json.dumps(extra_vars)])
            
            # Add tags
            if tags:
                cmd.extend(["--tags", ",".join(tags)])
            
            # Add limit
            if limit:
                cmd.extend(["--limit", limit])
            
            # Add verbose output
            cmd.append("-v")
            
            # Execute
            logger.info(f"Running Ansible command: {' '.join(cmd)}")
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(self.base_dir)
            )
            
            stdout, stderr = await process.communicate()
            
            result = {
                "command": " ".join(cmd),
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed"
            }
            
            return result
            
        except Exception as e:
            logger.error(f"Ansible playbook execution failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def run_adhoc(self, hosts: str, module: str, args: str = "", 
                       inventory: Optional[str] = None) -> Dict[str, Any]:
        """Run ad-hoc Ansible command"""
        try:
            cmd = ["ansible", hosts, "-m", module]
            
            if args:
                cmd.extend(["-a", args])
            
            if inventory:
                if not os.path.isabs(inventory):
                    inventory = str(self.inventories_dir / inventory)
                cmd.extend(["-i", inventory])
            
            logger.info(f"Running Ansible ad-hoc: {' '.join(cmd)}")
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(self.base_dir)
            )
            
            stdout, stderr = await process.communicate()
            
            return {
                "command": " ".join(cmd),
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed"
            }
            
        except Exception as e:
            logger.error(f"Ansible ad-hoc execution failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def create_playbook(self, name: str, plays: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Create a new Ansible playbook"""
        try:
            playbook_content = plays
            playbook_path = self.playbooks_dir / f"{name}.yml"
            
            with open(playbook_path, 'w') as f:
                yaml.dump(playbook_content, f, default_flow_style=False, indent=2)
            
            return {
                "status": "success",
                "playbook_path": str(playbook_path),
                "message": f"Playbook {name} created successfully"
            }
            
        except Exception as e:
            logger.error(f"Failed to create playbook: {e}")
            return {"status": "error", "message": str(e)}
    
    async def create_inventory(self, name: str, inventory_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new Ansible inventory"""
        try:
            inventory_path = self.inventories_dir / f"{name}.yml"
            
            with open(inventory_path, 'w') as f:
                yaml.dump(inventory_data, f, default_flow_style=False, indent=2)
            
            return {
                "status": "success",
                "inventory_path": str(inventory_path),
                "message": f"Inventory {name} created successfully"
            }
            
        except Exception as e:
            logger.error(f"Failed to create inventory: {e}")
            return {"status": "error", "message": str(e)}
    
    async def list_playbooks(self) -> Dict[str, Any]:
        """List all available playbooks"""
        try:
            playbooks = []
            for playbook_file in self.playbooks_dir.glob("*.yml"):
                playbooks.append({
                    "name": playbook_file.stem,
                    "path": str(playbook_file),
                    "size": playbook_file.stat().st_size
                })
            
            return {"status": "success", "playbooks": playbooks}
            
        except Exception as e:
            logger.error(f"Failed to list playbooks: {e}")
            return {"status": "error", "message": str(e)}
    
    async def list_inventories(self) -> Dict[str, Any]:
        """List all available inventories"""
        try:
            inventories = []
            for inventory_file in self.inventories_dir.glob("*.yml"):
                inventories.append({
                    "name": inventory_file.stem,
                    "path": str(inventory_file),
                    "size": inventory_file.stat().st_size
                })
            
            return {"status": "success", "inventories": inventories}
            
        except Exception as e:
            logger.error(f"Failed to list inventories: {e}")
            return {"status": "error", "message": str(e)}

# Global orchestrator instance
ansible_orchestrator = AnsibleOrchestrator()

# Functions for gateway integration
async def run_ansible_playbook(playbook_path: str, inventory: Optional[str] = None, 
                              extra_vars: Optional[Dict[str, Any]] = None, 
                              tags: Optional[List[str]] = None, 
                              limit: Optional[str] = None):
    return await ansible_orchestrator.run_playbook(playbook_path, inventory, extra_vars, tags, limit)

async def run_ansible_adhoc(hosts: str, module: str, args: str = "", inventory: Optional[str] = None):
    return await ansible_orchestrator.run_adhoc(hosts, module, args, inventory)

async def create_ansible_playbook(name: str, plays: List[Dict[str, Any]]):
    return await ansible_orchestrator.create_playbook(name, plays)

async def create_ansible_inventory(name: str, inventory_data: Dict[str, Any]):
    return await ansible_orchestrator.create_inventory(name, inventory_data)

async def list_ansible_playbooks():
    return await ansible_orchestrator.list_playbooks()

async def list_ansible_inventories():
    return await ansible_orchestrator.list_inventories()
