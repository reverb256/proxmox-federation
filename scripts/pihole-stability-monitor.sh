
#!/bin/bash

# PiHole Stability Monitor
# Prevents random PiHole movements during federation deployments

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check current PiHole status
check_pihole_status() {
    log_step "Checking PiHole Status"
    
    # Common PiHole locations
    PIHOLE_LOCATIONS=(
        "192.168.1.100"
        "10.0.0.100" 
        "172.16.0.100"
        "pihole.lan"
        "pi.hole"
    )
    
    for location in "${PIHOLE_LOCATIONS[@]}"; do
        if ping -c 1 -W 2 "$location" >/dev/null 2>&1; then
            log_success "Found PiHole at: $location"
            CURRENT_PIHOLE="$location"
            
            # Check if it's actually PiHole
            if curl -s --connect-timeout 3 "http://$location/admin/" | grep -q "Pi-hole"; then
                log_success "Confirmed PiHole web interface at $location"
                return 0
            fi
        fi
    done
    
    log_error "No PiHole found at expected locations"
    return 1
}

# Check DNS resolution
check_dns_resolution() {
    log_step "Testing DNS Resolution"
    
    # Test basic DNS
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS resolution working"
    else
        log_error "DNS resolution failed"
    fi
    
    # Check current DNS servers
    echo "Current DNS servers:"
    cat /etc/resolv.conf | grep nameserver
}

# Monitor for changes
monitor_pihole_changes() {
    log_step "Starting PiHole monitoring (Press Ctrl+C to stop)"
    
    LAST_PIHOLE=""
    
    while true; do
        if check_pihole_status >/dev/null 2>&1; then
            if [ "$CURRENT_PIHOLE" != "$LAST_PIHOLE" ] && [ -n "$LAST_PIHOLE" ]; then
                log_warning "PiHole location changed from $LAST_PIHOLE to $CURRENT_PIHOLE"
                
                # Log the change with timestamp
                echo "[$(date)] PiHole moved from $LAST_PIHOLE to $CURRENT_PIHOLE" >> /tmp/pihole-movements.log
            fi
            LAST_PIHOLE="$CURRENT_PIHOLE"
        else
            if [ -n "$LAST_PIHOLE" ]; then
                log_error "PiHole at $LAST_PIHOLE became unreachable"
                echo "[$(date)] PiHole at $LAST_PIHOLE went offline" >> /tmp/pihole-movements.log
                LAST_PIHOLE=""
            fi
        fi
        
        sleep 10
    done
}

# Fix DNS to static PiHole
fix_dns_to_pihole() {
    local pihole_ip="$1"
    
    if [ -z "$pihole_ip" ]; then
        log_error "Please provide PiHole IP address"
        echo "Usage: $0 fix <pihole_ip>"
        return 1
    fi
    
    log_step "Setting DNS to static PiHole: $pihole_ip"
    
    # Backup current resolv.conf
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    
    # Set static DNS
    sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver $pihole_ip
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
    
    # Make it immutable to prevent changes
    sudo chattr +i /etc/resolv.conf
    
    log_success "DNS locked to PiHole at $pihole_ip"
    log_warning "DNS is now immutable. Use 'sudo chattr -i /etc/resolv.conf' to unlock"
}

# Unlock DNS changes
unlock_dns() {
    log_step "Unlocking DNS configuration"
    sudo chattr -i /etc/resolv.conf 2>/dev/null || true
    log_success "DNS configuration unlocked"
}

# Show recent movements
show_movements() {
    log_step "Recent PiHole movements:"
    if [ -f /tmp/pihole-movements.log ]; then
        tail -20 /tmp/pihole-movements.log
    else
        echo "No movements recorded yet"
    fi
}

case "${1:-status}" in
    "status")
        check_pihole_status
        check_dns_resolution
        ;;
    "monitor")
        monitor_pihole_changes
        ;;
    "fix")
        fix_dns_to_pihole "$2"
        ;;
    "unlock")
        unlock_dns
        ;;
    "movements")
        show_movements
        ;;
    *)
        echo "Usage: $0 {status|monitor|fix <ip>|unlock|movements}"
        echo ""
        echo "Commands:"
        echo "  status     - Check current PiHole status"
        echo "  monitor    - Monitor for PiHole location changes"
        echo "  fix <ip>   - Lock DNS to specific PiHole IP"
        echo "  unlock     - Unlock DNS configuration"
        echo "  movements  - Show recent PiHole movements"
        ;;
esac
