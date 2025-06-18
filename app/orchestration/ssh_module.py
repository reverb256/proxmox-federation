"""
SSH Orchestration Module - Full SSH client with key management and connection pooling
"""
import asyncio
import logging
from typing import Dict, List, Any, Optional
import json
from datetime import datetime
from pathlib import Path
import tempfile

try:
    import paramiko
    PARAMIKO_AVAILABLE = True
except ImportError:
    PARAMIKO_AVAILABLE = False
    paramiko = None

logger = logging.getLogger(__name__)

SSH_KEYS_DIR = Path("/app/data/ssh/keys")
SSH_KEYS_DIR.mkdir(parents=True, exist_ok=True)

class SSHOrchestrator:
    def __init__(self):
        self.connections = {}
        self.connection_pool = {}
        
    async def connect(self, host: str, user: str, password: Optional[str] = None, 
                     private_key_path: Optional[str] = None, port: int = 22,
                     connection_id: str = "default") -> Dict[str, Any]:
        """Create SSH connection"""
        try:
            if not PARAMIKO_AVAILABLE:
                return {"status": "error", "message": "paramiko library not available"}
            
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            # Connection arguments
            connect_kwargs = {
                "hostname": host,
                "username": user,
                "port": port,
                "timeout": 30
            }
            
            if private_key_path:
                # Use private key authentication
                key_path = SSH_KEYS_DIR / private_key_path if not Path(private_key_path).is_absolute() else Path(private_key_path)
                if key_path.exists():
                    connect_kwargs["key_filename"] = str(key_path)
                else:
                    return {"status": "error", "message": f"Private key not found: {key_path}"}
            elif password:
                # Use password authentication
                connect_kwargs["password"] = password
            else:
                return {"status": "error", "message": "Either password or private_key_path must be provided"}
            
            # Establish connection
            ssh.connect(**connect_kwargs)
            
            # Test connection
            stdin, stdout, stderr = ssh.exec_command("echo 'SSH connection test'")
            test_output = stdout.read().decode().strip()
            
            if test_output != "SSH connection test":
                ssh.close()
                return {"status": "error", "message": "SSH connection test failed"}
            
            self.connections[connection_id] = {
                "ssh": ssh,
                "host": host,
                "user": user,
                "port": port,
                "connected_at": datetime.now().isoformat()
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "host": host,
                "user": user,
                "port": port,
                "message": f"SSH connected to {user}@{host}:{port}"
            }
            
        except Exception as e:
            logger.error(f"SSH connection failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def execute_command(self, command: str, connection_id: str = "default",
                             timeout: int = 30) -> Dict[str, Any]:
        """Execute command via SSH"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            ssh = self.connections[connection_id]["ssh"]
            
            # Execute command
            stdin, stdout, stderr = ssh.exec_command(command, timeout=timeout)
            
            # Get results
            stdout_data = stdout.read().decode()
            stderr_data = stderr.read().decode()
            exit_status = stdout.channel.recv_exit_status()
            
            return {
                "status": "success",
                "command": command,
                "stdout": stdout_data,
                "stderr": stderr_data,
                "exit_status": exit_status,
                "connection_id": connection_id,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"SSH command execution failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def upload_file(self, local_path: str, remote_path: str, 
                         connection_id: str = "default") -> Dict[str, Any]:
        """Upload file via SFTP"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            ssh = self.connections[connection_id]["ssh"]
            sftp = ssh.open_sftp()
            
            # Upload file
            sftp.put(local_path, remote_path)
            sftp.close()
            
            return {
                "status": "success",
                "local_path": local_path,
                "remote_path": remote_path,
                "connection_id": connection_id,
                "message": f"File uploaded: {local_path} -> {remote_path}"
            }
            
        except Exception as e:
            logger.error(f"File upload failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def download_file(self, remote_path: str, local_path: str,
                           connection_id: str = "default") -> Dict[str, Any]:
        """Download file via SFTP"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            ssh = self.connections[connection_id]["ssh"]
            sftp = ssh.open_sftp()
            
            # Download file
            sftp.get(remote_path, local_path)
            sftp.close()
            
            return {
                "status": "success",
                "remote_path": remote_path,
                "local_path": local_path,
                "connection_id": connection_id,
                "message": f"File downloaded: {remote_path} -> {local_path}"
            }
            
        except Exception as e:
            logger.error(f"File download failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def execute_script(self, script_content: str, connection_id: str = "default",
                            interpreter: str = "bash") -> Dict[str, Any]:
        """Execute script via SSH"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            # Create temporary script file
            with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as f:
                f.write(script_content)
                temp_script = f.name
            
            try:
                # Upload script
                remote_script = f"/tmp/ssh_script_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sh"
                upload_result = await self.upload_file(temp_script, remote_script, connection_id)
                
                if upload_result["status"] != "success":
                    return upload_result
                
                # Make executable and run
                chmod_result = await self.execute_command(f"chmod +x {remote_script}", connection_id)
                if chmod_result["status"] != "success":
                    return chmod_result
                
                # Execute script
                result = await self.execute_command(f"{interpreter} {remote_script}", connection_id)
                
                # Cleanup
                await self.execute_command(f"rm -f {remote_script}", connection_id)
                
                return {
                    "status": "success",
                    "script_result": result,
                    "interpreter": interpreter,
                    "connection_id": connection_id
                }
                
            finally:
                # Cleanup local temp file
                Path(temp_script).unlink(missing_ok=True)
            
        except Exception as e:
            logger.error(f"Script execution failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def disconnect(self, connection_id: str = "default") -> Dict[str, Any]:
        """Close SSH connection"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            ssh = self.connections[connection_id]["ssh"]
            ssh.close()
            
            del self.connections[connection_id]
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "message": f"SSH connection {connection_id} closed"
            }
            
        except Exception as e:
            logger.error(f"SSH disconnect failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def list_connections(self) -> Dict[str, Any]:
        """List all active SSH connections"""
        try:
            connections_info = []
            for conn_id, conn_data in self.connections.items():
                connections_info.append({
                    "connection_id": conn_id,
                    "host": conn_data["host"],
                    "user": conn_data["user"],
                    "port": conn_data["port"],
                    "connected_at": conn_data["connected_at"]
                })
            
            return {"status": "success", "connections": connections_info}
            
        except Exception as e:
            logger.error(f"Failed to list connections: {e}")
            return {"status": "error", "message": str(e)}
    
    async def generate_key_pair(self, key_name: str, key_type: str = "rsa", 
                               key_size: int = 2048) -> Dict[str, Any]:
        """Generate SSH key pair"""
        try:
            if not PARAMIKO_AVAILABLE:
                return {"status": "error", "message": "paramiko library not available"}
            
            # Generate key
            if key_type.lower() == "rsa":
                key = paramiko.RSAKey.generate(key_size)
            elif key_type.lower() == "ed25519":
                key = paramiko.Ed25519Key.generate()
            else:
                return {"status": "error", "message": f"Unsupported key type: {key_type}"}
            
            # Save private key
            private_key_path = SSH_KEYS_DIR / f"{key_name}"
            key.write_private_key_file(str(private_key_path))
            
            # Save public key
            public_key_path = SSH_KEYS_DIR / f"{key_name}.pub"
            with open(public_key_path, 'w') as f:
                f.write(f"{key.get_name()} {key.get_base64()}\n")
            
            return {
                "status": "success",
                "key_name": key_name,
                "private_key_path": str(private_key_path),
                "public_key_path": str(public_key_path),
                "public_key": f"{key.get_name()} {key.get_base64()}",
                "message": f"SSH key pair {key_name} generated successfully"
            }
            
        except Exception as e:
            logger.error(f"Key generation failed: {e}")
            return {"status": "error", "message": str(e)}

# Global orchestrator instance
ssh_orchestrator = SSHOrchestrator()

# Functions for gateway integration
async def ssh_connect(host: str, user: str, password: Optional[str] = None, 
                     private_key_path: Optional[str] = None, port: int = 22,
                     connection_id: str = "default"):
    return await ssh_orchestrator.connect(host, user, password, private_key_path, port, connection_id)

async def run_ssh_command(host: str, user: str, password: str, command: str):
    """Legacy function for backward compatibility"""
    # Create temporary connection
    conn_id = f"temp_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    # Connect
    connect_result = await ssh_orchestrator.connect(host, user, password, connection_id=conn_id)
    if connect_result["status"] != "success":
        return connect_result
    
    # Execute command
    result = await ssh_orchestrator.execute_command(command, conn_id)
    
    # Disconnect
    await ssh_orchestrator.disconnect(conn_id)
    
    return result

async def ssh_execute(command: str, connection_id: str = "default", timeout: int = 30):
    return await ssh_orchestrator.execute_command(command, connection_id, timeout)

async def ssh_upload_file(local_path: str, remote_path: str, connection_id: str = "default"):
    return await ssh_orchestrator.upload_file(local_path, remote_path, connection_id)

async def ssh_download_file(remote_path: str, local_path: str, connection_id: str = "default"):
    return await ssh_orchestrator.download_file(remote_path, local_path, connection_id)

async def ssh_execute_script(script_content: str, connection_id: str = "default", interpreter: str = "bash"):
    return await ssh_orchestrator.execute_script(script_content, connection_id, interpreter)

async def ssh_generate_keys(key_name: str, key_type: str = "rsa", key_size: int = 2048):
    return await ssh_orchestrator.generate_key_pair(key_name, key_type, key_size)

async def ssh_list_connections():
    return await ssh_orchestrator.list_connections()

async def ssh_disconnect(connection_id: str = "default"):
    return await ssh_orchestrator.disconnect(connection_id)
