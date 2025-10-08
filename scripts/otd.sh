#!/bin/bash

# OpenTabletDriver installation script
# Installs opentabletdriver using paru and configures system for tablet support

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        echo "Usage: sudo $0"
        exit 1
    fi
    print_success "Running with root privileges"
}

# Function to install opentabletdriver using paru
install_opentabletdriver() {
    print_status "Installing OpenTabletDriver using paru..."
    
    # Check if paru is installed
    if ! command -v paru &> /dev/null; then
        print_error "paru is not installed. Please restart the script or install it manually."
        print_status "You can install it with: sudo pacman -S paru if Chaotic AUR is configured."
        print_status "If not, please refer to paru's Github page."
        exit 1
    fi
    
    # Install opentabletdriver
    if paru -S --noconfirm opentabletdriver; then
        print_success "OpenTabletDriver installed successfully"
    else
        print_error "Failed to install OpenTabletDriver"
        exit 1
    fi
}

# Function to blacklist wacom module
blacklist_wacom() {
    print_status "Blacklisting wacom module..."
    
    # Check if blacklist.conf exists, create if it doesn't
    if [[ ! -f /etc/modprobe.d/blacklist.conf ]]; then
        print_status "Creating /etc/modprobe.d/blacklist.conf"
        touch /etc/modprobe.d/blacklist.conf
    fi
    
    # Check if wacom is already blacklisted
    if grep -q "blacklist wacom" /etc/modprobe.d/blacklist.conf; then
        print_warning "wacom is already blacklisted"
    else
        echo "blacklist wacom" >> /etc/modprobe.d/blacklist.conf
        print_success "wacom module blacklisted"
    fi
}

# Function to remove wacom module
remove_wacom_module() {
    print_status "Removing wacom module..."
    
    if lsmod | grep -q wacom; then
        if rmmod wacom; then
            print_success "wacom module removed successfully"
        else
            print_warning "Failed to remove wacom module (may not be loaded)"
        fi
    else
        print_warning "wacom module is not currently loaded"
    fi
}

# Function to blacklist hid_uclogic module
blacklist_hid_uclogic() {
    print_status "Blacklisting hid_uclogic module..."
    
    # Check if hid_uclogic is already blacklisted
    if grep -q "blacklist hid_uclogic" /etc/modprobe.d/blacklist.conf; then
        print_warning "hid_uclogic is already blacklisted"
    else
        echo "blacklist hid_uclogic" >> /etc/modprobe.d/blacklist.conf
        print_success "hid_uclogic module blacklisted"
    fi
}

# Function to remove hid_uclogic module
remove_hid_uclogic_module() {
    print_status "Removing hid_uclogic module..."
    
    if lsmod | grep -q hid_uclogic; then
        if rmmod hid_uclogic; then
            print_success "hid_uclogic module removed successfully"
        else
            print_warning "Failed to remove hid_uclogic module (may not be loaded)"
        fi
    else
        print_warning "hid_uclogic module is not currently loaded"
    fi
}

# Function to reload systemd user daemon
reload_systemd_daemon() {
    print_status "Reloading systemd user daemon..."
    
    # Get the original user who invoked sudo
    if [[ -n "$SUDO_USER" ]]; then
        # Set up proper environment for systemd user operations
        if sudo -u "$SUDO_USER" -E systemctl --user daemon-reload; then
            print_success "Systemd user daemon reloaded successfully"
        else
            print_warning "Failed to reload systemd user daemon (this is often not critical)"
            print_status "The service will still be enabled and will work on next login"
        fi
    else
        print_warning "Cannot determine original user for systemd user operations"
        print_status "Skipping daemon reload - service will still be enabled"
    fi
}

# Function to enable opentabletdriver service
enable_opentabletdriver() {
    print_status "Enabling OpenTabletDriver service..."
    
    # Get the original user who invoked sudo
    if [[ -n "$SUDO_USER" ]]; then
        # Only enable the service, don't start it immediately
        if sudo -u "$SUDO_USER" systemctl --user enable opentabletdriver; then
            print_success "OpenTabletDriver service enabled successfully"
            print_status "The service will start automatically on next login or reboot"
            print_status "You can manually start it now with: systemctl --user start opentabletdriver"
        else
            print_error "Failed to enable OpenTabletDriver service"
            exit 1
        fi
    else
        print_error "Cannot determine original user for systemd user operations"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting OpenTabletDriver installation and configuration..."
    echo "=========================================="
    
    check_root
    install_opentabletdriver
    blacklist_wacom
    remove_wacom_module
    blacklist_hid_uclogic
    remove_hid_uclogic_module
    reload_systemd_daemon
    enable_opentabletdriver
    
    echo "=========================================="
    print_success "OpenTabletDriver installation and configuration completed successfully!"
    print_status "You may need to reboot for all module changes to take effect."
}

# Run main function
main "$@"
