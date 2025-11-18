#!/bin/bash

# ID0 - Identity Zero
# by cXuri
# GitHub: github.com/cxuri/id0

display_banner() {
    echo -e "\033[1;36m"
    cat << "EOF"
┌─────────────────────────────────────┐
│                                     │
│              .-.                    │
│             (o o)  boo!             │
│             | O \                   │
│              \   \                  │
│               `~~~'                 │
│         ID0 : Stay Hidden           │
│                                     │
│         developed by @cxuri         │
│           version 1.1               │
│                                     │
│          use -h for usage           │
│                                     │
│                                     │
└─────────────────────────────────────┘
EOF
    echo -e "\033[0m"
}

# Color codes for logging
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global vars
INTERFACE=""
MINUTES=10
MIN_MINUTES=3
TIME_IS_RANDOM=false
BACKUP_DIR="$HOME/.id0_backup"
NM_CONFIG_FILE="/etc/NetworkManager/conf.d/99-id0-compat.conf"
# --- FIX 1: New Log Path under /var/log/ ---
LOG_FILE="/var/log/id0/id0.log"

# --- FIX 2: Simplified Logging Functions (revert from tee) ---
# Logging functions with timestamps
log() { 
    local timestamp=$(date '+%H:%M:%S')
    echo -e "${GREEN}[ID0]${NC} $1"
    echo "[$timestamp] ID0: $1" >> "$LOG_FILE"
}
error() { 
    local timestamp=$(date '+%H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$timestamp] ERROR: $1" >> "$LOG_FILE"
}
warn() { 
    local timestamp=$(date '+%H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$timestamp] WARN: $1" >> "$LOG_FILE"
}
info() { 
    local timestamp=$(date '+%H:%M:%S')
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$timestamp] INFO: $1" >> "$LOG_FILE"
}
debug() { 
    local timestamp=$(date '+%H:%M:%S')
    echo -e "${PURPLE}[DEBUG]${NC} $1"
    echo "[$timestamp] DEBUG: $1" >> "$LOG_FILE"
}

# Initialize logging
init_logging() {
    # --- FIX 3: Explicitly create directory and clear log file as root ---
    sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
    sudo touch "$LOG_FILE" 2>/dev/null
    sudo truncate -s 0 "$LOG_FILE" 2>/dev/null
    log "ID0 started - PID: $$"
}

# Check if we're on WiFi
is_wireless() {
    local iface=$1
    iw dev $iface info &>/dev/null
    return $?
}

# Get a random time within the user's range
random_time() {
    local min=${1:-3}    # Default minimum 3 minutes
    local max=${2:-10}   # Default maximum 10 minutes
    echo $(( RANDOM % (max - min + 1) + min ))
}

# Enhanced interface detection with better formatting
get_interfaces() {
    echo -e "${CYAN}Available Network Interfaces:${NC}"
    echo "┌──────────────────────────────────────────────┐"
    
    local i=0
    local interfaces_list=()
    
    # Wireless interfaces
    local wireless_interfaces=($(iw dev 2>/dev/null | grep "Interface" | cut -d' ' -f2))
    if [[ ${#wireless_interfaces[@]} -gt 0 ]]; then
        for iface in "${wireless_interfaces[@]}"; do
            local mac=$(ip link show $iface 2>/dev/null | grep -oE 'link/ether [0-9a-f:]+' | cut -d' ' -f2)
            local status=$(ip link show $iface | grep -oE 'state (UP|DOWN)' | cut -d' ' -f2)
            [[ -z "$mac" ]] && mac="00:00:00:00:00:00"
            printf "  ${GREEN}%2d.${NC} %-12s ${YELLOW}%-9s${NC} ${BLUE}%s${NC}\n" $((i+1)) "$iface" "[WIFI]" "$mac"
            interfaces_list+=("$iface")
            i=$((i+1))
        done
    fi
    
    # Wired interfaces
    local all_interfaces=($(ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' ' | grep -v lo))
    local wired_interfaces=()
    
    for iface in "${all_interfaces[@]}"; do
        if [[ ! " ${wireless_interfaces[@]} " =~ " ${iface} " ]]; then
            wired_interfaces+=("$iface")
        fi
    done
    
    if [[ ${#wired_interfaces[@]} -gt 0 ]]; then
        for iface in "${wired_interfaces[@]}"; do
            local mac=$(ip link show $iface 2>/dev/null | grep -oE 'link/ether [0-9a-f:]+' | cut -d' ' -f2)
            local status=$(ip link show $iface | grep -oE 'state (UP|DOWN)' | cut -d' ' -f2)
            [[ -z "$mac" ]] && mac="00:00:00:00:00:00"
            printf "  ${GREEN}%2d.${NC} %-12s ${CYAN}%-9s${NC} ${BLUE}%s${NC}\n" $((i+1)) "$iface" "[WIRED]" "$mac"
            interfaces_list+=("$iface")
            i=$((i+1))
        done
    fi
    
    echo "└──────────────────────────────────────────────┘"
    echo "${interfaces_list[@]}"
}

select_interface() {
    local interfaces=($(get_interfaces | tail -1))
    local num_interfaces=${#interfaces[@]}
    
    if [[ $num_interfaces -eq 0 ]]; then
        error "No network interfaces found!"
        exit 1
    fi
    
    while true; do
        echo -en "${GREEN}[ID0]${NC} Select interface (1-${num_interfaces}): "
        read choice
        if [[ $choice =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $num_interfaces ]]; then
            INTERFACE="${interfaces[$((choice-1))]}"
            clear
            log "Selected interface: $INTERFACE"
            break
        else
            warn "Invalid selection. Please enter a number between 1 and ${num_interfaces}"
        fi
    done
}

get_minutes() {
    while true; do
        echo -en "${GREEN}[ID0]${NC} Enter rotation interval in minutes (default: random 3-10 min): "
        read input
        if [[ -z "$input" ]]; then
            MINUTES=10
            MIN_MINUTES=3
            TIME_IS_RANDOM=true
            log "Using random rotation interval (3-10 minutes)"
            break
        elif [[ $input =~ ^[0-9]+$ ]] && [[ $input -ge 1 ]]; then
            MINUTES=$input
            TIME_IS_RANDOM=false
            log "Using fixed rotation interval: $MINUTES minutes"
            break
        else
            warn "Please enter a valid number (1 or higher)"
        fi
    done
}

# Enhanced MAC address change with better error handling
change_mac_address() {
    local iface=$1
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        # Bring interface down
        if ! sudo ip link set $iface down 2>/dev/null; then
            error "Failed to bring interface $iface down"
            return 1
        fi
        
        # For wireless interfaces, disconnect first
        if is_wireless $iface; then
            sudo iw dev $iface disconnect 2>/dev/null
            sleep 1
        fi
        
        # Change MAC address using macchanger
        if sudo macchanger -r $iface > /dev/null 2>&1; then
            # Bring interface back up
            if sudo ip link set $iface up 2>/dev/null; then
                # Wait for interface to stabilize
                sleep 2
                
                # Verify the change was successful
                local new_mac=$(get_current_mac $iface)
                # Use sudo cat to safely read the root-owned backup file
                local original_mac=$(sudo cat "$BACKUP_DIR/mac" 2>/dev/null)
                
                if [[ -n "$new_mac" && "$new_mac" != "$original_mac" ]]; then
                    debug "MAC address successfully changed to: $new_mac"
                    return 0
                else
                    warn "MAC address may not have changed properly"
                fi
            else
                error "Failed to bring interface $iface up"
                return 1
            fi
        fi
        
        retry_count=$((retry_count + 1))
        warn "MAC change attempt $retry_count failed, retrying..."
        sleep 1
    done
    
    error "Failed to change MAC address after $max_retries attempts"
    return 1
}

get_current_mac() {
    local iface=$1
    macchanger -s $iface 2>/dev/null | grep "Current MAC" | awk '{print $3}' | tr -d ' '
}

# Save the original MAC and hostname
backup_identity() {
    # Ensure backup directory is created as root if necessary
    sudo mkdir -p "$BACKUP_DIR"
    
    # Backup MAC address
    local original_mac=$(get_current_mac $INTERFACE)
    if [[ -n "$original_mac" ]]; then
        # Use tee to write to the backup file with root privileges
        echo "$original_mac" | sudo tee "$BACKUP_DIR/mac" >/dev/null
    else
        error "Could not determine original MAC address"
        return 1
    fi
    
    # Backup hostname and hosts
    hostname | sudo tee "$BACKUP_DIR/hostname" >/dev/null 2>/dev/null
    sudo cp /etc/hosts "$BACKUP_DIR/hosts" 2>/dev/null
    
    # Backup interface type
    if is_wireless $INTERFACE; then
        echo "wireless" | sudo tee "$BACKUP_DIR/iface_type" >/dev/null
    else
        echo "wired" | sudo tee "$BACKUP_DIR/iface_type" >/dev/null
    fi
    
    # Backup current NetworkManager connections
    if command -v nmcli &>/dev/null; then
        nmcli -t -f NAME,UUID connection show | sudo tee "$BACKUP_DIR/nm_connections" >/dev/null 2>/dev/null
    fi
    
    log "Original identity backed up to $BACKUP_DIR/"
    debug "Original MAC: $original_mac, Hostname: $(hostname)"
    return 0 # Ensure success return after fixing backup writes
}

# Put everything back to normal
revert_identity() {
    log "Reverting to original identity..."
    
    # Revert MAC address
    if [[ -f "$BACKUP_DIR/mac" ]]; then
        local original_mac=$(sudo cat "$BACKUP_DIR/mac")
        sudo ip link set $INTERFACE down 2>/dev/null
        if sudo macchanger -m "$original_mac" $INTERFACE > /dev/null 2>&1; then
            sudo ip link set $INTERFACE up 2>/dev/null
            
            # Force DHCP renewal to use original connection settings
            if command -v nmcli &>/dev/null; then
                local active_conn
                active_conn=$(nmcli -t -f DEVICE,NAME connection show --active | grep "^$INTERFACE:" | cut -d: -f2)
                if [[ -n "$active_conn" ]]; then
                    sudo nmcli connection up "$active_conn" 2>/dev/null
                    debug "Restarted NetworkManager connection to revert DHCP settings"
                fi
            fi
            
            debug "Reverted MAC to: $original_mac"
        else
            error "Failed to revert MAC address"
        fi
    fi
    
    # Revert hostname
    if [[ -f "$BACKUP_DIR/hostname" ]]; then
        local original_hostname=$(sudo cat "$BACKUP_DIR/hostname")
        sudo hostnamectl set-hostname "$original_hostname" 2>/dev/null
        
        # Restore original hosts file
        if [[ -f "$BACKUP_DIR/hosts" ]]; then
            sudo cp "$BACKUP_DIR/hosts" /etc/hosts 2>/dev/null
        else
            update_hosts_file "$original_hostname"
        fi
        debug "Reverted hostname to: $original_hostname"
    fi
    
    log "Identity reverted successfully"
}

# Enhanced hostname generation
random_hostname() {
    # User-Friendly English words, including tech brands
    local adjectives=("Quiet" "Ghost" "Deep" "Hidden" "Swift" "Silent" "Safe" "New" "Pro" "Ultra")
    local nouns=("Hub" "Flow" "Spot" "Point" "Core" "Link" "Eye" "Shield" "Box" "Unit")
    local companies=("Dell" "Acer" "Asus" "Lenovo" "HP" "Sony" "Nokia" "Xiaomi" "OnePlus" "Global")
    local domains=("Zone" "Air" "Local" "Lab" "Office" "Link" "Net" "Device")
    
    local format=$((RANDOM % 4))
    
    case $format in
        0) # Format: [adjective]-[noun]-[random]
            echo "${adjectives[$RANDOM % ${#adjectives[@]}]}-${nouns[$RANDOM % ${#nouns[@]}]}-$(printf '%03d' $((RANDOM % 999)))"
            ;;
        1) # Format: [company]-[device]-[id]
            echo "${companies[$RANDOM % ${#companies[@]}]}${nouns[$RANDOM % ${#nouns[@]}]}$(printf '%02d' $((RANDOM % 99)))"
            ;;
        2) # Format: user-[random]-[domain]
            echo "user-$(printf '%03d' $((RANDOM % 999)))-${domains[$RANDOM % ${#domains[@]}]}"
            ;;
        3) # Format: [adjective][animal]-[random]
            local animals=("fox" "wolf" "hawk" "raven" "lynx" "puma" "falcon" "owl")
            echo "${adjectives[$RANDOM % ${#adjectives[@]}]}${animals[$RANDOM % ${#animals[@]}]}-$(printf '%02d' $((RANDOM % 99)))"
            ;;
    esac
}

# Fix /etc/hosts with the new hostname
update_hosts_file() {
    local new_hostname=$1
    local temp_hosts=$(mktemp)
    
    cat > "$temp_hosts" << EOF
127.0.0.1 localhost
127.0.1.1 $new_hostname

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    sudo cp "$temp_hosts" /etc/hosts
    sudo chmod 644 /etc/hosts
    rm -f "$temp_hosts"
}

# Enhanced log cleaning
clean_logs() {
    log "Cleaning system logs..."
    
    # Clear command history
    history -c && history -w 2>/dev/null
    
    # Clear various user logs
    [[ -f ~/.bash_history ]] && > ~/.bash_history
    [[ -f ~/.zsh_history ]] && > ~/.zsh_history
    
    # Clear system logs (keep last hour only)
    if command -v journalctl &>/dev/null; then
        sudo journalctl --vacuum-time=1h > /dev/null 2>&1
    fi
    
    # Clear temporary files
    sudo find /tmp /var/tmp -type f -atime +1 -delete 2>/dev/null
    
    debug "Log cleaning completed"
}

# Enhanced NetworkManager compatibility system
is_nm_fix_applied() {
    [[ -f "$NM_CONFIG_FILE" ]] && \
    grep -q "cloned-mac-address=preserve" "$NM_CONFIG_FILE" 2>/dev/null && \
    grep -q "scan-rand-mac-address=no" "$NM_CONFIG_FILE" 2>/dev/null
}

apply_networkmanager_fix() {
    log "Applying NetworkManager compatibility fix..."
    
    # Create directory if it doesn't exist
    sudo mkdir -p "/etc/NetworkManager/conf.d/"
    
    # Create comprehensive configuration
    sudo tee "$NM_CONFIG_FILE" > /dev/null << 'EOF'
[device]
# Preserve MAC address across connections
wifi.scan-rand-mac-address=no
wifi.cloned-mac-address=preserve
ethernet.cloned-mac-address=preserve

[connection]
# Stable ID generation
# Set dhcp-client-id=mac to ensure macchanger's MAC is used as the primary identifier
# Note: NetworkManager often sends the real hostname regardless, which is why we must restart the connection after rotation.
wifi.cloned-mac-address=preserve
ethernet.cloned-mac-address=preserve
connection.stable-id=${CONNECTION}/${BOOT}

# Disable MAC address randomization globally
[connection-mac-randomization]
wifi.cloned-mac-address=preserve
ethernet.cloned-mac-address=preserve
EOF

    if [[ $? -eq 0 ]]; then
        log "NetworkManager configuration updated"
        
        # Restart NetworkManager to apply changes
        log "Restarting NetworkManager service..."
        if sudo systemctl restart NetworkManager; then
            # Wait for service to stabilize
            sleep 3
            log "NetworkManager compatibility fix applied successfully"
            return 0
        else
            error "Failed to restart NetworkManager"
            warn "Please run manually: sudo systemctl restart NetworkManager"
            return 1
        fi
    else
        error "Failed to write NetworkManager configuration"
        return 1
    fi
}

check_networkmanager_compatibility() {
    local iface=$1
    
    # Check if NetworkManager is running
    if ! systemctl is-active NetworkManager &>/dev/null; then
        info "NetworkManager not active. No compatibility fix needed."
        return 0
    fi
    
    # Check if fix is already applied
    if is_nm_fix_applied; then
        echo -e "${GREEN}✓${NC} NetworkManager compatibility: Active"
        return 0
    fi
    
    # Apply fix automatically for wireless interfaces, ask for others
    if is_wireless $iface; then
        warn "NetworkManager may reset MAC addresses on WiFi connections"
        if apply_networkmanager_fix; then
            return 0
        else
            error "Failed to apply NetworkManager fix"
            return 1
        fi
    else
        warn "NetworkManager is active - MAC addresses may be reset on network changes"
        local choice
        read -p "${GREEN}[ID0]${NC} Apply NetworkManager compatibility fix? (Y/n): " choice
        if [[ ! "$choice" =~ ^[Nn]$ ]]; then
            apply_networkmanager_fix
            return $?
        else
            warn "NetworkManager fix skipped. MAC changes may not persist."
            return 1
        fi
    fi
}

# Show NetworkManager status
show_nm_status() {
    if systemctl is-active NetworkManager &>/dev/null; then
        if is_nm_fix_applied; then
            echo -e "NetworkManager: ${GREEN}Active ✓${NC} (Compatible)"
        else
            echo -e "NetworkManager: ${YELLOW}Active ⚠${NC} (Needs Fix)"
        fi
    else
        echo -e "NetworkManager: ${BLUE}Inactive${NC}"
    fi
}

# Enhanced identity rotation - FIXED TO HANDLE HOSTNAME RENEWAL
rotate_identity() {
    local rotation_count=${1:-1}
    
    log "Starting rotation #$rotation_count"
    
    # Change MAC address
    if change_mac_address $INTERFACE; then
        local new_mac=$(get_current_mac $INTERFACE)
        debug "MAC rotation successful: $new_mac"
    else
        error "MAC rotation failed"
        return 1
    fi
    
    # Clean logs
    clean_logs
    
    # Change hostname
    local new_hostname=$(random_hostname)
    # The hostname change and hosts file update happen before other 'sudo' calls
    if sudo hostnamectl set-hostname "$new_hostname" 2>/dev/null; then
        update_hosts_file "$new_hostname"
        debug "Hostname rotation successful: $new_hostname"
    else
        error "Hostname rotation failed"
        return 1
    fi
    
    # --- FIX: Force DHCP Renewal with New Hostname ---
    if command -v nmcli &>/dev/null; then
        local active_conn
        active_conn=$(nmcli -t -f DEVICE,NAME connection show --active | grep "^$INTERFACE:" | cut -d: -f2)

        if [[ -n "$active_conn" ]]; then
            # 1. Temporarily set dhcp-hostname on the active connection
            sudo nmcli connection modify "$active_conn" ipv4.dhcp-hostname "$new_hostname" ipv6.dhcp-hostname "$new_hostname" 2>/dev/null
            
            # 2. Restart connection to force DHCP renewal and broadcast new hostname/MAC
            if sudo nmcli connection down "$active_conn" && sudo nmcli connection up "$active_conn"; then
                log "Network connection restarted to broadcast new identity (Hostname/MAC)"
            else
                warn "Failed to restart NetworkManager connection. Hostname may not be updated on router."
            fi
        else
            warn "Could not find active NetworkManager connection for $INTERFACE. Hostname may not update on router."
        fi
    else
        # Fallback for systems without nmcli (using dhclient/dhcpcd)
        if command -v dhclient &>/dev/null; then
            sudo dhclient -r -v $INTERFACE 2>/dev/null # Release current lease
            sudo dhclient -v $INTERFACE 2>/dev/null    # Request new lease
            log "Forced DHCP renewal using dhclient"
        else
            warn "No NetworkManager or dhclient found. Could not force DHCP renewal."
        fi
    fi
    # ----------------------------------------------------

    log "New identity: MAC=${new_mac} Hostname=${new_hostname}"
    return 0
}

# Main rotation loop
start_rotation_loop() {
    local rotation_count=0
    
    # Initial rotation
    rotate_identity $((++rotation_count))
    
    while true; do
        local next_wait
        if [[ "$TIME_IS_RANDOM" == "true" ]]; then
            next_wait=$(random_time $MIN_MINUTES $MINUTES)
        else
            next_wait=$MINUTES
        fi
        
        info "Next rotation in $next_wait minutes..."
        info "Press Ctrl+C to stop and revert identity"
        
        # Countdown display
        local total_seconds=$((next_wait * 60))
        for ((i=total_seconds; i>0; i--)); do
            printf "\r${CYAN}Time until next rotation: %02d:%02d${NC}" $((i/60)) $((i%60))
            sleep 1
        done
        echo
        
        # Perform rotation
        rotate_identity $((++rotation_count))
    done
}

# Show comprehensive status
show_status() {
    echo -e "${CYAN}=== ID0 Status ===${NC}"
    echo -e "Interface: ${GREEN}$INTERFACE${NC} $(is_wireless $INTERFACE && echo "${YELLOW}[WIRELESS]${NC}" || echo "${BLUE}[WIRED]${NC}")"
    echo -e "MAC Address: ${BLUE}$(get_current_mac $INTERFACE)${NC}"
    echo -e "Hostname: ${GREEN}$(hostname)${NC}"
    show_nm_status
    echo -e "Rotation: $([[ "$TIME_IS_RANDOM" == "true" ]] && echo "Random ${MIN_MINUTES}-${MINUTES} min" || echo "Fixed ${MINUTES} min")"
    echo -e "Backup: $([[ -d "$BACKUP_DIR" ]] && echo "${GREEN}Available${NC}" || echo "${RED}None${NC}")"
    echo -e "Log File: ${BLUE}$LOG_FILE${NC}"
}

# Main function
main() {
    # Check for necessary utilities
    if ! command -v macchanger &>/dev/null; then
        error "macchanger is required but not found. Please install it."
        exit 1
    fi
    
    init_logging
    clear
    display_banner
    
    case "${1:-start}" in
        start)
            # Interface selection
            if [[ -n "$2" ]]; then
                INTERFACE=$2
            else
                get_interfaces
                select_interface
            fi
            
            # Time interval
            if [[ -n "$3" ]]; then
                MINUTES=$3
                TIME_IS_RANDOM=false
            else
                get_minutes
            fi
            
            # Verify interface
            if ! ip link show $INTERFACE &>/dev/null; then
                error "Interface $INTERFACE not found!"
                exit 1
            fi
            
            # NetworkManager compatibility
            check_networkmanager_compatibility $INTERFACE
            
            # Backup and start
            if backup_identity; then
                log "Starting identity rotation on $INTERFACE"
                # Add check for root permissions before starting rotation loop
                if [[ $EUID -ne 0 ]]; then
                    error "Starting rotation requires root privileges. Please run with sudo."
                    exit 1
                fi
                trap 'revert_identity; log "ID0 stopped by user"; exit 0' SIGINT SIGTERM
                start_rotation_loop
            else
                error "Failed to backup identity. Cannot start rotation."
                exit 1
            fi
            ;;
            
        revert)
            INTERFACE=${2:-$INTERFACE}
            if [[ -z "$INTERFACE" ]]; then
                error "No interface specified or backed up."
                if [[ -f "$BACKUP_DIR/iface_type" ]]; then
                    # Try to infer interface from original connection
                    warn "Attempting to guess interface from backup files..."
                    # This is complex and usually requires manual input, asking user to select from available interfaces.
                    get_interfaces
                    select_interface
                else
                    exit 1
                fi
            fi

            # Check for root permissions before reverting
            if [[ $EUID -ne 0 ]]; then
                error "Reverting identity requires root privileges. Please run with sudo."
                exit 1
            fi
            revert_identity
            ;;
            
        status)
            # Try to get interface if not provided
            if [[ -z "$INTERFACE" ]]; then
                # Attempt to read the interface name from the backup files if rotation was started
                if [[ -f "$BACKUP_DIR/iface_type" ]]; then
                    warn "Interface not specified. Using available interfaces to determine status."
                fi
                get_interfaces
                select_interface
            fi
            show_status
            ;;
            
        backup)
            if [[ -z "$INTERFACE" ]]; then
                get_interfaces
                select_interface
            fi
            backup_identity
            ;;
            
        interfaces|ifaces)
            get_interfaces
            ;;
            
        fix-networkmanager|fix-nm)
            if [[ $EUID -ne 0 ]]; then
                error "Applying fix requires root privileges. Please run with sudo."
                exit 1
            fi
            if apply_networkmanager_fix; then
                log "NetworkManager fix applied successfully"
            else
                error "Failed to apply NetworkManager fix"
            fi
            ;;
            
        nm-status)
            show_nm_status
            ;;
            
        logs)
            # Use sudo to ensure we can read the root-owned log file
            if [[ -f "$LOG_FILE" ]]; then
                sudo tail -20 "$LOG_FILE"
            else
                info "No log file found"
            fi
            ;;
            
        random-test)
            echo "Testing random hostname generation:"
            for i in {1..5}; do
                echo "  $i. $(random_hostname)"
            done
            echo -e "\nTesting random time generation (3-10 minutes):"
            for i in {1..5}; do
                echo "  $i. $(random_time 3 10) minutes"
            done
            ;;
            
        help|-h|--help)
            echo -e "${CYAN}ID0 - Identity Zero v1.1${NC}"
            echo "Complete MAC address and hostname rotation system"
            echo ""
            echo -e "${GREEN}Usage:${NC} $0 [command] [interface] [minutes]"
            echo ""
            echo -e "${CYAN}Commands:${NC}"
            echo "  start [iface] [mins]    Start identity rotation (requires sudo)"
            echo "  revert [iface]          Revert to original identity (requires sudo)"
            echo "  status                  Show current status"
            echo "  backup                  Backup current identity"
            echo "  interfaces              List available interfaces"
            echo "  fix-networkmanager      Apply NetworkManager compatibility fix (requires sudo)"
            echo "  nm-status               Show NetworkManager status"
            echo "  logs                    Show recent logs"
            echo "  random-test             Test random generators"
            echo "  help                    Show this help"
            echo ""
            echo -e "${YELLOW}Examples:${NC}"
            echo "  sudo $0 start wlan0 5      # Fixed 5-minute rotation"
            echo "  sudo $0 fix-networkmanager # Apply NetworkManager fix"
            echo "  $0 status                  # Show current status"
            echo "  sudo $0 revert wlan0       # Revert identity"
            echo ""
            echo -e "${BLUE}Features:${NC}"
            echo "  • MAC address rotation with NetworkManager compatibility"
            echo "  • Hostname rotation with proper /etc/hosts updates and DHCP renewal"
            echo "  • System log cleaning"
            echo "  • Random or fixed timing intervals"
            echo "  • Comprehensive logging"
            echo ""
            ;;
            
        *)
            error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
