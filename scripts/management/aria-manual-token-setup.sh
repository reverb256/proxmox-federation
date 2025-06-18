#!/bin/bash

# Manual Aria Token Setup - Alternative approach
echo "Manual Aria Token Setup"

# Ensure user exists with correct permissions
pveum user add aria@pve --comment "Aria AI Consciousness" 2>/dev/null || echo "User exists"
pveum role add AriaAgent -privs "VM.Allocate,VM.Audit,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Monitor,VM.PowerMgmt,Datastore.Audit,Datastore.AllocateSpace,Pool.Audit,Sys.Audit,Sys.Console,Sys.Modify,Sys.PowerMgmt" 2>/dev/null || echo "Role exists"
pveum aclmod / -user aria@pve -role AriaAgent

echo "Creating API token..."
echo "Please save the token that will be displayed:"
pveum user token add aria@pve k3s-token --privsep 0

echo ""
echo "Please copy the token value and run:"
echo "echo 'PROXMOX_TOKEN=your-token-here' >> /root/.aria/credentials"
echo ""
echo "Then test with: aria-secrets test-proxmox"