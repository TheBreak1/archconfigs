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

# Function to check if running as user (not root)
check_user() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should be run as a regular user, not as root"
        echo "Usage: $0"
        exit 1
    fi
    print_success "Running as user: $(whoami)"
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

# Function to check if modules need to be blacklisted
check_module_blacklist() {
    print_status "Checking if kernel modules need to be blacklisted..."
    
    # Check if wacom module is loaded using sudo
    if sudo lsmod | grep -q wacom; then
        print_warning "wacom module is currently loaded. You may need to blacklist it."
        print_status "To blacklist wacom, run:"
        echo "  echo 'blacklist wacom' | sudo tee -a /etc/modprobe.d/blacklist.conf"
        echo "  sudo rmmod wacom"
    fi
    
    # Check if hid_uclogic module is loaded using sudo
    if sudo lsmod | grep -q hid_uclogic; then
        print_warning "hid_uclogic module is currently loaded. You may need to blacklist it."
        print_status "To blacklist hid_uclogic, run:"
        echo "  echo 'blacklist hid_uclogic' | sudo tee -a /etc/modprobe.d/blacklist.conf"
        echo "  sudo rmmod hid_uclogic"
    fi
    
    print_status "Note: Module blacklisting requires root privileges."
    print_status "You can run these commands manually or use a separate script with sudo."
}


# Function to enable and start opentabletdriver service
enable_opentabletdriver() {
    print_status "Enabling and starting OpenTabletDriver service..."
    
    # Enable and start the service as the current user
    if systemctl --user enable opentabletdriver --now; then
        print_success "OpenTabletDriver service enabled and started successfully"
    else
        print_error "Failed to enable/start OpenTabletDriver service"
        print_status "Make sure you have a systemd user session running"
        print_status "You may need to log out and log back in, or run: systemctl --user daemon-reload"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting OpenTabletDriver installation and configuration..."
    echo "=========================================="
    
    check_user
    install_opentabletdriver
    check_module_blacklist
    enable_opentabletdriver
    
    echo "=========================================="
    print_success "OpenTabletDriver installation and configuration completed successfully!"
    print_warning "If you have wacom or hid_uclogic modules loaded, you may need to blacklist them manually."
    print_status "Check the output above for specific commands to run with sudo."
}

# Run main function
main "$@"
