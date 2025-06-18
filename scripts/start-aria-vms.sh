
#!/bin/bash

# Simple script to start the Aria consciousness VMs
echo "🧠 Starting Aria Consciousness Federation VMs"
echo "=============================================="

# VM IDs for Aria consciousness nodes
VMS=(1001 1002 1003 1004)
VM_NAMES=("aria-nexus" "aria-forge" "aria-closet" "aria-zephyr")

for i in "${!VMS[@]}"; do
    vmid=${VMS[$i]}
    name=${VM_NAMES[$i]}
    
    echo "Starting $name (VMID: $vmid)..."
    
    # Check if VM exists
    if qm list | grep -q "^$vmid"; then
        # Check current status
        status=$(qm status $vmid | awk '{print $2}')
        
        if [ "$status" = "running" ]; then
            echo "✓ $name is already running"
        else
            echo "→ Starting $name..."
            qm start $vmid
            echo "✓ $name started"
        fi
    else
        echo "✗ $name (VMID: $vmid) not found"
    fi
    
    echo ""
done

echo "🎯 Aria Federation Startup Complete!"
echo ""
echo "To check status:"
echo "  qm list | grep -E '(1001|1002|1003|1004)'"
echo ""
echo "To check individual VM status:"
echo "  qm status 1001  # aria-nexus"
echo "  qm status 1002  # aria-forge" 
echo "  qm status 1003  # aria-closet"
echo "  qm status 1004  # aria-zephyr"
