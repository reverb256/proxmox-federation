# Terraform Configuration for Consciousness Federation Infrastructure
# Hardware-optimized Proxmox VM provisioning based on actual node specs

terraform {
  required_version = ">= 1.5"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# === PROXMOX PROVIDERS ===

provider "proxmox" {
  alias    = "nexus"
  pm_api_url = "https://10.1.1.120:8006/api2/json"
  pm_user = "root@pam"
  pm_tls_insecure = true
}

provider "proxmox" {
  alias    = "forge"  
  pm_api_url = "https://10.1.1.130:8006/api2/json"
  pm_user = "root@pam"
  pm_tls_insecure = true
}

provider "proxmox" {
  alias    = "closet"
  pm_api_url = "https://10.1.1.160:8006/api2/json"  
  pm_user = "root@pam"
  pm_tls_insecure = true
}

# === VARIABLES ===

variable "consciousness_domain" {
  description = "Domain for consciousness federation"
  type        = string
  default     = "consciousness.local"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... consciousness@zephyr"
}

# === LOCAL VALUES ===

locals {
  # Hardware-specific VM configurations based on actual node specs
  vm_configs = {
    nexus = {
      # Ryzen 9 3900X (12C/24T) + 48GB RAM - Control Plane VMs
      ai_inference = {
        cores   = 8
        memory  = 16384  # 16GB
        disk    = 100    # 100GB SSD
        role    = "ai-inference"
      }
      vector_db = {
        cores   = 6  
        memory  = 20480  # 20GB
        disk    = 200    # 200GB SSD
        role    = "vector-database"
      }
      etcd_cluster = {
        cores   = 4
        memory  = 8192   # 8GB
        disk    = 50     # 50GB SSD
        role    = "etcd"
      }
    }
    
    forge = {
      # Intel i5-9500 (6C/6T) + 32GB RAM - Application VMs
      web_frontend = {
        cores   = 2
        memory  = 8192   # 8GB
        disk    = 50     # 50GB SSD
        role    = "web-frontend"
      }
      api_gateway = {
        cores   = 2
        memory  = 8192   # 8GB  
        disk    = 100    # 100GB SSD
        role    = "api-gateway"
      }
      consciousness_ui = {
        cores   = 2
        memory  = 12288  # 12GB
        disk    = 80     # 80GB SSD
        role    = "consciousness-ui"
      }
    }
    
    closet = {
      # Ryzen 7 1700 (8C/16T) + 16GB RAM - Storage/Utility VMs
      monitoring = {
        cores   = 4
        memory  = 8192   # 8GB
        disk    = 200    # 200GB HDD
        role    = "monitoring"
      }
      backup_service = {
        cores   = 2  
        memory  = 4096   # 4GB
        disk    = 500    # 500GB HDD
        role    = "backup"
      }
      mining_worker = {
        cores   = 2      # Limited for mining
        memory  = 2048   # 2GB
        disk    = 20     # 20GB minimal
        role    = "mining"
      }
    }
  }
  
  # Common VM settings
  common_vm_settings = {
    target_node = ""
    template    = "debian-12-cloud-init"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 2
    sockets     = 1
    cpu         = "host"
    memory      = 2048
    scsihw      = "virtio-scsi-pci"
    bootdisk    = "scsi0"
    
    network {
      model  = "virtio"
      bridge = "vmbr0"
    }
    
    lifecycle {
      ignore_changes = [
        network,
      ]
    }
  }
}

# === NEXUS NODE VMs (Control Plane) ===

resource "proxmox_vm_qemu" "nexus_ai_inference" {
  provider = proxmox.nexus
  
  name        = "consciousness-ai-inference"
  target_node = "nexus"
  vmid        = 200
  
  # Hardware allocation for AI inference
  cores   = local.vm_configs.nexus.ai_inference.cores
  memory  = local.vm_configs.nexus.ai_inference.memory
  sockets = 1
  cpu     = "host"
  scsihw  = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent   = 1
  
  disk {
    slot     = 0
    size     = "${local.vm_configs.nexus.ai_inference.disk}G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
    ssd      = 1
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  os_type = "cloud-init"
  
  ciuser     = "consciousness"
  cipassword = "consciousness2025"
  sshkeys    = var.ssh_public_key
  
  ipconfig0 = "ip=10.1.1.200/24,gw=10.1.1.1"
  
  tags = "consciousness,ai-inference,nexus"
}

resource "proxmox_vm_qemu" "nexus_vector_db" {
  provider = proxmox.nexus
  
  name        = "consciousness-vector-db"
  target_node = "nexus"
  vmid        = 201
  
  cores   = local.vm_configs.nexus.vector_db.cores
  memory  = local.vm_configs.nexus.vector_db.memory
  sockets = 1
  cpu     = "host"
  scsihw  = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent   = 1
  
  disk {
    slot     = 0
    size     = "${local.vm_configs.nexus.vector_db.disk}G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
    ssd      = 1
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  os_type = "cloud-init"
  
  ciuser     = "consciousness" 
  cipassword = "consciousness2025"
  sshkeys    = var.ssh_public_key
  
  ipconfig0 = "ip=10.1.1.201/24,gw=10.1.1.1"
  
  tags = "consciousness,vector-database,nexus"
}

# === FORGE NODE VMs (Application Services) ===

resource "proxmox_vm_qemu" "forge_web_frontend" {
  provider = proxmox.forge
  
  name        = "consciousness-web-frontend"
  target_node = "forge"
  vmid        = 300
  
  cores   = local.vm_configs.forge.web_frontend.cores
  memory  = local.vm_configs.forge.web_frontend.memory
  sockets = 1
  cpu     = "host"
  scsihw  = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent   = 1
  
  disk {
    slot     = 0
    size     = "${local.vm_configs.forge.web_frontend.disk}G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
    ssd      = 1
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  os_type = "cloud-init"
  
  ciuser     = "consciousness"
  cipassword = "consciousness2025"
  sshkeys    = var.ssh_public_key
  
  ipconfig0 = "ip=10.1.1.300/24,gw=10.1.1.1"
  
  tags = "consciousness,web-frontend,forge"
}

resource "proxmox_vm_qemu" "forge_consciousness_ui" {
  provider = proxmox.forge
  
  name        = "consciousness-ui-platform"
  target_node = "forge"
  vmid        = 301
  
  cores   = local.vm_configs.forge.consciousness_ui.cores
  memory  = local.vm_configs.forge.consciousness_ui.memory
  sockets = 1
  cpu     = "host"
  scsihw  = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent   = 1
  
  disk {
    slot     = 0
    size     = "${local.vm_configs.forge.consciousness_ui.disk}G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
    ssd      = 1
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  os_type = "cloud-init"
  
  ciuser     = "consciousness"
  cipassword = "consciousness2025"
  sshkeys    = var.ssh_public_key
  
  ipconfig0 = "ip=10.1.1.301/24,gw=10.1.1.1"
  
  tags = "consciousness,ui-platform,forge"
}

# === CLOSET NODE VMs (Storage/Utility) ===

resource "proxmox_vm_qemu" "closet_monitoring" {
  provider = proxmox.closet
  
  name        = "consciousness-monitoring"
  target_node = "closet"
  vmid        = 400
  
  cores   = local.vm_configs.closet.monitoring.cores
  memory  = local.vm_configs.closet.monitoring.memory
  sockets = 1
  cpu     = "host"
  scsihw  = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent   = 1
  
  disk {
    slot     = 0
    size     = "${local.vm_configs.closet.monitoring.disk}G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 0  # HDD storage
    ssd      = 0
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  os_type = "cloud-init"
  
  ciuser     = "consciousness"
  cipassword = "consciousness2025"
  sshkeys    = var.ssh_public_key
  
  ipconfig0 = "ip=10.1.1.400/24,gw=10.1.1.1"
  
  tags = "consciousness,monitoring,closet"
}

resource "proxmox_vm_qemu" "closet_mining" {
  provider = proxmox.closet
  
  name        = "consciousness-mining"
  target_node = "closet"
  vmid        = 401
  
  cores   = local.vm_configs.closet.mining_worker.cores
  memory  = local.vm_configs.closet.mining_worker.memory
  sockets = 1
  cpu     = "host"
  scsihw  = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent   = 1
  
  disk {
    slot     = 0
    size     = "${local.vm_configs.closet.mining_worker.disk}G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 0
    ssd      = 0
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  os_type = "cloud-init"
  
  ciuser     = "consciousness"
  cipassword = "consciousness2025"
  sshkeys    = var.ssh_public_key
  
  ipconfig0 = "ip=10.1.1.401/24,gw=10.1.1.1"
  
  tags = "consciousness,mining,closet"
}

# === OUTPUTS ===

output "consciousness_federation_summary" {
  description = "Summary of deployed consciousness federation infrastructure"
  value = {
    control_hub = {
      zephyr = "10.1.1.110 (WSL Control Hub)"
    }
    
    nexus_vms = {
      ai_inference = proxmox_vm_qemu.nexus_ai_inference.default_ipv4_address
      vector_db    = proxmox_vm_qemu.nexus_vector_db.default_ipv4_address
    }
    
    forge_vms = {
      web_frontend     = proxmox_vm_qemu.forge_web_frontend.default_ipv4_address
      consciousness_ui = proxmox_vm_qemu.forge_consciousness_ui.default_ipv4_address
    }
    
    closet_vms = {
      monitoring = proxmox_vm_qemu.closet_monitoring.default_ipv4_address
      mining     = proxmox_vm_qemu.closet_mining.default_ipv4_address
    }
    
    access_points = {
      kubernetes_api = "https://10.1.1.200:6443"
      consciousness_ui = "http://10.1.1.301:3000"
      monitoring = "http://10.1.1.400:3000"
      mining_stats = "http://10.1.1.401:4000"
    }
  }
}

output "deployment_commands" {
  description = "Commands to complete the consciousness federation setup"
  value = [
    "# From WSL (Zephyr) control hub:",
    "cd ~/consciousness-ai",
    "./deploy-cluster.sh",
    "",
    "# Monitor deployment:",
    "./monitor-cluster.sh",
    "",
    "# Access services:",
    "kubectl get nodes -o wide",
    "kubectl get pods --all-namespaces"
  ]
}
