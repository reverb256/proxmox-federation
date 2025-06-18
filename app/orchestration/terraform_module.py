"""
Terraform Orchestration Module - Full implementation with state management
"""
import subprocess
import asyncio
import json
import os
from typing import Dict, List, Any, Optional
from pathlib import Path
import tempfile
import logging
import shutil

logger = logging.getLogger(__name__)

TERRAFORM_DIR = Path("/app/data/terraform")
TERRAFORM_DIR.mkdir(parents=True, exist_ok=True)

class TerraformOrchestrator:
    def __init__(self):
        self.base_dir = TERRAFORM_DIR
        
    async def init(self, working_dir: str) -> Dict[str, Any]:
        """Initialize Terraform in a directory"""
        try:
            work_path = self._resolve_path(working_dir)
            
            process = await asyncio.create_subprocess_exec(
                "terraform", "init",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_path
            )
            
            stdout, stderr = await process.communicate()
            
            return {
                "command": "terraform init",
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed",
                "working_dir": str(work_path)
            }
            
        except Exception as e:
            logger.error(f"Terraform init failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def plan(self, working_dir: str, var_file: Optional[str] = None, 
                  variables: Optional[Dict[str, str]] = None, 
                  target: Optional[str] = None) -> Dict[str, Any]:
        """Create Terraform plan"""
        try:
            work_path = self._resolve_path(working_dir)
            cmd = ["terraform", "plan", "-no-color"]
            
            if var_file:
                cmd.extend(["-var-file", var_file])
            
            if variables:
                for key, value in variables.items():
                    cmd.extend(["-var", f"{key}={value}"])
            
            if target:
                cmd.extend(["-target", target])
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_path
            )
            
            stdout, stderr = await process.communicate()
            
            return {
                "command": " ".join(cmd),
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed",
                "working_dir": str(work_path)
            }
            
        except Exception as e:
            logger.error(f"Terraform plan failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def apply(self, working_dir: str, auto_approve: bool = False,
                   var_file: Optional[str] = None, 
                   variables: Optional[Dict[str, str]] = None,
                   target: Optional[str] = None) -> Dict[str, Any]:
        """Apply Terraform configuration"""
        try:
            work_path = self._resolve_path(working_dir)
            cmd = ["terraform", "apply", "-no-color"]
            
            if auto_approve:
                cmd.append("-auto-approve")
            
            if var_file:
                cmd.extend(["-var-file", var_file])
            
            if variables:
                for key, value in variables.items():
                    cmd.extend(["-var", f"{key}={value}"])
            
            if target:
                cmd.extend(["-target", target])
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_path
            )
            
            stdout, stderr = await process.communicate()
            
            return {
                "command": " ".join(cmd),
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed",
                "working_dir": str(work_path)
            }
            
        except Exception as e:
            logger.error(f"Terraform apply failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def destroy(self, working_dir: str, auto_approve: bool = False,
                     var_file: Optional[str] = None, 
                     variables: Optional[Dict[str, str]] = None,
                     target: Optional[str] = None) -> Dict[str, Any]:
        """Destroy Terraform-managed infrastructure"""
        try:
            work_path = self._resolve_path(working_dir)
            cmd = ["terraform", "destroy", "-no-color"]
            
            if auto_approve:
                cmd.append("-auto-approve")
            
            if var_file:
                cmd.extend(["-var-file", var_file])
            
            if variables:
                for key, value in variables.items():
                    cmd.extend(["-var", f"{key}={value}"])
            
            if target:
                cmd.extend(["-target", target])
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_path
            )
            
            stdout, stderr = await process.communicate()
            
            return {
                "command": " ".join(cmd),
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed",
                "working_dir": str(work_path)
            }
            
        except Exception as e:
            logger.error(f"Terraform destroy failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def show_state(self, working_dir: str) -> Dict[str, Any]:
        """Show current Terraform state"""
        try:
            work_path = self._resolve_path(working_dir)
            
            process = await asyncio.create_subprocess_exec(
                "terraform", "show", "-json",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_path
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0 and stdout:
                try:
                    state_data = json.loads(stdout.decode())
                    return {
                        "status": "success",
                        "state": state_data,
                        "working_dir": str(work_path)
                    }
                except json.JSONDecodeError:
                    pass
            
            return {
                "command": "terraform show -json",
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed",
                "working_dir": str(work_path)
            }
            
        except Exception as e:
            logger.error(f"Terraform show failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def validate(self, working_dir: str) -> Dict[str, Any]:
        """Validate Terraform configuration"""
        try:
            work_path = self._resolve_path(working_dir)
            
            process = await asyncio.create_subprocess_exec(
                "terraform", "validate", "-json",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_path
            )
            
            stdout, stderr = await process.communicate()
            
            return {
                "command": "terraform validate",
                "returncode": process.returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "status": "success" if process.returncode == 0 else "failed",
                "working_dir": str(work_path)
            }
            
        except Exception as e:
            logger.error(f"Terraform validate failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def create_workspace(self, name: str, template: Optional[str] = None) -> Dict[str, Any]:
        """Create a new Terraform workspace"""
        try:
            workspace_dir = self.base_dir / name
            workspace_dir.mkdir(exist_ok=True)
            
            if template:
                # Copy template files
                template_dir = self.base_dir / "templates" / template
                if template_dir.exists():
                    shutil.copytree(template_dir, workspace_dir, dirs_exist_ok=True)
            else:
                # Create basic main.tf
                main_tf = workspace_dir / "main.tf"
                with open(main_tf, 'w') as f:
                    f.write("""# Terraform configuration
terraform {
  required_version = ">= 1.0"
}

# Add your resources here
""")
            
            return {
                "status": "success",
                "workspace_dir": str(workspace_dir),
                "message": f"Workspace {name} created successfully"
            }
            
        except Exception as e:
            logger.error(f"Failed to create workspace: {e}")
            return {"status": "error", "message": str(e)}
    
    def _resolve_path(self, path: str) -> Path:
        """Resolve working directory path"""
        if os.path.isabs(path):
            return Path(path)
        else:
            return self.base_dir / path

# Global orchestrator instance
terraform_orchestrator = TerraformOrchestrator()

# Functions for gateway integration
async def run_terraform_command(command: str, working_dir: str = "."):
    """Generic terraform command runner"""
    parts = command.split()
    if not parts or parts[0] != "terraform":
        parts.insert(0, "terraform")
    
    if "init" in parts:
        return await terraform_orchestrator.init(working_dir)
    elif "plan" in parts:
        return await terraform_orchestrator.plan(working_dir)
    elif "apply" in parts:
        return await terraform_orchestrator.apply(working_dir, auto_approve="-auto-approve" in parts)
    elif "destroy" in parts:
        return await terraform_orchestrator.destroy(working_dir, auto_approve="-auto-approve" in parts)
    elif "show" in parts:
        return await terraform_orchestrator.show_state(working_dir)
    elif "validate" in parts:
        return await terraform_orchestrator.validate(working_dir)
    else:
        return {"status": "error", "message": f"Unsupported terraform command: {command}"}

async def terraform_init(working_dir: str):
    return await terraform_orchestrator.init(working_dir)

async def terraform_plan(working_dir: str, var_file: Optional[str] = None, variables: Optional[Dict[str, str]] = None):
    return await terraform_orchestrator.plan(working_dir, var_file, variables)

async def terraform_apply(working_dir: str, auto_approve: bool = False, var_file: Optional[str] = None, variables: Optional[Dict[str, str]] = None):
    return await terraform_orchestrator.apply(working_dir, auto_approve, var_file, variables)

async def terraform_destroy(working_dir: str, auto_approve: bool = False, var_file: Optional[str] = None, variables: Optional[Dict[str, str]] = None):
    return await terraform_orchestrator.destroy(working_dir, auto_approve, var_file, variables)

async def terraform_show_state(working_dir: str):
    return await terraform_orchestrator.show_state(working_dir)

async def terraform_validate(working_dir: str):
    return await terraform_orchestrator.validate(working_dir)

async def create_terraform_workspace(name: str, template: Optional[str] = None):
    return await terraform_orchestrator.create_workspace(name, template)
