"""
Proxmoxer Orchestration Module - Full Proxmox VE API integration
"""
import asyncio
import logging
from typing import Dict, List, Any, Optional
import json
from datetime import datetime

try:
    from proxmoxer import ProxmoxAPI
    PROXMOXER_AVAILABLE = True
except ImportError:
    PROXMOXER_AVAILABLE = False
    ProxmoxAPI = None

logger = logging.getLogger(__name__)

class ProxmoxOrchestrator:
    def __init__(self):
        self.connections = {}
        
    async def connect(self, host: str, user: str, password: str, 
                     verify_ssl: bool = False, connection_id: str = "default") -> Dict[str, Any]:
        """Connect to Proxmox VE"""
        try:
            if not PROXMOXER_AVAILABLE:
                return {"status": "error", "message": "proxmoxer library not available"}
            
            # Create connection
            proxmox = ProxmoxAPI(host, user=user, password=password, verify_ssl=verify_ssl)
            
            # Test connection
            version = proxmox.version.get()
            
            self.connections[connection_id] = {
                "api": proxmox,
                "host": host,
                "user": user,
                "connected_at": datetime.now().isoformat(),
                "version": version
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "host": host,
                "version": version,
                "message": f"Connected to Proxmox VE at {host}"
            }
            
        except Exception as e:
            logger.error(f"Proxmox connection failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def list_nodes(self, connection_id: str = "default") -> Dict[str, Any]:
        """List all nodes in the cluster"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            nodes = proxmox.nodes.get()
            
            return {"status": "success", "nodes": nodes}
            
        except Exception as e:
            logger.error(f"Failed to list nodes: {e}")
            return {"status": "error", "message": str(e)}
    
    async def list_vms(self, node: str, connection_id: str = "default") -> Dict[str, Any]:
        """List VMs on a specific node"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            vms = proxmox.nodes(node).qemu.get()
            
            return {"status": "success", "node": node, "vms": vms}
            
        except Exception as e:
            logger.error(f"Failed to list VMs: {e}")
            return {"status": "error", "message": str(e)}
    
    async def create_vm(self, node: str, vmid: int, config: Dict[str, Any], 
                       connection_id: str = "default") -> Dict[str, Any]:
        """Create a new VM"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            
            # Default VM configuration
            vm_config = {
                "vmid": vmid,
                "memory": config.get("memory", 2048),
                "cores": config.get("cores", 2),
                "sockets": config.get("sockets", 1),
                "ostype": config.get("ostype", "l26"),
                "net0": config.get("net0", "virtio,bridge=vmbr0"),
                **config
            }
            
            result = proxmox.nodes(node).qemu.create(**vm_config)
            
            return {
                "status": "success",
                "node": node,
                "vmid": vmid,
                "task": result,
                "message": f"VM {vmid} creation initiated"
            }
            
        except Exception as e:
            logger.error(f"Failed to create VM: {e}")
            return {"status": "error", "message": str(e)}
    
    async def start_vm(self, node: str, vmid: int, connection_id: str = "default") -> Dict[str, Any]:
        """Start a VM"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            result = proxmox.nodes(node).qemu(vmid).status.start.post()
            
            return {
                "status": "success",
                "node": node,
                "vmid": vmid,
                "task": result,
                "message": f"VM {vmid} start initiated"
            }
            
        except Exception as e:
            logger.error(f"Failed to start VM: {e}")
            return {"status": "error", "message": str(e)}
    
    async def stop_vm(self, node: str, vmid: int, connection_id: str = "default") -> Dict[str, Any]:
        """Stop a VM"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            result = proxmox.nodes(node).qemu(vmid).status.stop.post()
            
            return {
                "status": "success",
                "node": node,
                "vmid": vmid,
                "task": result,
                "message": f"VM {vmid} stop initiated"
            }
            
        except Exception as e:
            logger.error(f"Failed to stop VM: {e}")
            return {"status": "error", "message": str(e)}
    
    async def delete_vm(self, node: str, vmid: int, connection_id: str = "default") -> Dict[str, Any]:
        """Delete a VM"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            result = proxmox.nodes(node).qemu(vmid).delete()
            
            return {
                "status": "success",
                "node": node,
                "vmid": vmid,
                "task": result,
                "message": f"VM {vmid} deletion initiated"
            }
            
        except Exception as e:
            logger.error(f"Failed to delete VM: {e}")
            return {"status": "error", "message": str(e)}
    
    async def get_vm_status(self, node: str, vmid: int, connection_id: str = "default") -> Dict[str, Any]:
        """Get VM status"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            status = proxmox.nodes(node).qemu(vmid).status.current.get()
            
            return {"status": "success", "node": node, "vmid": vmid, "vm_status": status}
            
        except Exception as e:
            logger.error(f"Failed to get VM status: {e}")
            return {"status": "error", "message": str(e)}
    
    async def list_containers(self, node: str, connection_id: str = "default") -> Dict[str, Any]:
        """List LXC containers on a specific node"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            containers = proxmox.nodes(node).lxc.get()
            
            return {"status": "success", "node": node, "containers": containers}
            
        except Exception as e:
            logger.error(f"Failed to list containers: {e}")
            return {"status": "error", "message": str(e)}
    
    async def create_container(self, node: str, vmid: int, config: Dict[str, Any], 
                              connection_id: str = "default") -> Dict[str, Any]:
        """Create a new LXC container"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            
            # Default container configuration
            ct_config = {
                "vmid": vmid,
                "memory": config.get("memory", 512),
                "cores": config.get("cores", 1),
                "ostemplate": config.get("ostemplate", "local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz"),
                "storage": config.get("storage", "local-lvm"),
                "net0": config.get("net0", "name=eth0,bridge=vmbr0,ip=dhcp"),
                **config
            }
            
            result = proxmox.nodes(node).lxc.create(**ct_config)
            
            return {
                "status": "success",
                "node": node,
                "vmid": vmid,
                "task": result,
                "message": f"Container {vmid} creation initiated"
            }
            
        except Exception as e:
            logger.error(f"Failed to create container: {e}")
            return {"status": "error", "message": str(e)}
    
    async def get_cluster_status(self, connection_id: str = "default") -> Dict[str, Any]:
        """Get overall cluster status"""
        try:
            if connection_id not in self.connections:
                return {"status": "error", "message": f"Connection {connection_id} not found"}
            
            proxmox = self.connections[connection_id]["api"]
            
            cluster_status = proxmox.cluster.status.get()
            resources = proxmox.cluster.resources.get()
            
            return {
                "status": "success",
                "cluster_status": cluster_status,
                "resources": resources
            }
            
        except Exception as e:
            logger.error(f"Failed to get cluster status: {e}")
            return {"status": "error", "message": str(e)}

# Global orchestrator instance
proxmox_orchestrator = ProxmoxOrchestrator()

# Functions for gateway integration
async def connect_proxmox(host: str, user: str, password: str, verify_ssl: bool = False, connection_id: str = "default"):
    return await proxmox_orchestrator.connect(host, user, password, verify_ssl, connection_id)

async def proxmox_list_nodes(connection_id: str = "default"):
    return await proxmox_orchestrator.list_nodes(connection_id)

async def proxmox_list_vms(node: str, connection_id: str = "default"):
    return await proxmox_orchestrator.list_vms(node, connection_id)

async def proxmox_create_vm(node: str, vmid: int, config: Dict[str, Any], connection_id: str = "default"):
    return await proxmox_orchestrator.create_vm(node, vmid, config, connection_id)

async def proxmox_start_vm(node: str, vmid: int, connection_id: str = "default"):
    return await proxmox_orchestrator.start_vm(node, vmid, connection_id)

async def proxmox_stop_vm(node: str, vmid: int, connection_id: str = "default"):
    return await proxmox_orchestrator.stop_vm(node, vmid, connection_id)

async def proxmox_delete_vm(node: str, vmid: int, connection_id: str = "default"):
    return await proxmox_orchestrator.delete_vm(node, vmid, connection_id)

async def proxmox_get_vm_status(node: str, vmid: int, connection_id: str = "default"):
    return await proxmox_orchestrator.get_vm_status(node, vmid, connection_id)

async def proxmox_get_cluster_status(connection_id: str = "default"):
    return await proxmox_orchestrator.get_cluster_status(connection_id)
