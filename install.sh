#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[*] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root" 
   exit 1
fi

uninstall() {
    info "Uninstalling ID0..."
    
    if systemctl is-active --quiet id0; then
        systemctl stop id0
        systemctl disable id0
        echo "    -> Service stopped and disabled"
    fi

    rm -f /usr/local/bin/id0
    rm -f /etc/systemd/system/id0.service
    rm -f /etc/id0.conf
    
    systemctl daemon-reload
    info "Uninstallation Complete."
}

install() {
    if [[ ! -f "bin/id0.sh" ]]; then
        error "id0.sh not found in current directory!"
        exit 1
    fi
    if [[ ! -d "service" ]]; then
        error "'service' directory not found!"
        exit 1
    fi

    info "Installing ID0..."

    cp bin/id0.sh /usr/local/bin/id0
    chmod +x /usr/local/bin/id0
    echo "    -> Installed /usr/local/bin/id0"

    if [ ! -f /etc/id0.conf ]; then
        cp service/id0.conf /etc/id0.conf
        echo "    -> Installed /etc/id0.conf"
    else
        warn "Config file already exists at /etc/id0.conf (Skipping overwrite)"
    fi

    cp service/id0.service /etc/systemd/system/id0.service
    echo "    -> Installed systemd service"

    systemctl daemon-reload
    
    info "Installation Complete!"
    echo ""
    warn "NEXT STEPS:"
    echo "    1. Edit configuration:  sudo nano /etc/id0.conf"
    echo "    2. Fix NetworkManager:  sudo id0 fix-nm"
    echo "    3. Start service:       sudo systemctl enable --now id0"
}

case "$1" in
    uninstall|remove)
        uninstall
        ;;
    *)
        install
        ;;
esac