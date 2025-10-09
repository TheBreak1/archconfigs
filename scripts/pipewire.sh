#!/bin/bash

# Pipewire installation script
# Installs pipewire-media-session and configures system for audio

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

# Function to install pipewire-media-session using paru
install_pipewire() {
    print_status "Installing pipewire-media-session using paru..."
    
    # Check if paru is installed
    if ! command -v paru &> /dev/null; then
        print_error "paru is not installed. Please restart the script or install it manually."
        print_status "You can install it with: sudo pacman -S paru if Chaotic AUR is configured."
        print_status "If not, please refer to paru's Github page."
        exit 1
    fi
    
    # Install pipewire-media-session
    if paru -S --noconfirm pipewire-media-session; then
        print_success "pipewire-media-session installed successfully"
    else
        print_error "Failed to install pipewire-media-session"
        exit 1
    fi
}

# Function to copy pipewire configuration files
copy_pipewire_configs() {
    print_status "Copying pipewire configuration files to user config..."
    
    # Get current user info
    CURRENT_USER=$(whoami)
    CURRENT_HOME=$(getent passwd "$CURRENT_USER" | cut -d: -f6)
    print_status "Current user: $CURRENT_USER"
    print_status "User home: $CURRENT_HOME"
    
    # Ensure user has access to .config folder
    print_status "Ensuring user has access to .config folder..."
    if [[ ! -d "$CURRENT_HOME/.config" ]]; then
        print_status "Creating ~/.config directory..."
        if mkdir -p "$CURRENT_HOME/.config"; then
            print_success "~/.config directory created"
        else
            print_error "Failed to create ~/.config directory"
            return 1
        fi
    else
        print_warning "~/.config directory already exists"
    fi
    
    # Create ~/.config/pipewire directory if it doesn't exist
    if [[ ! -d "$CURRENT_HOME/.config/pipewire" ]]; then
        print_status "Creating ~/.config/pipewire directory..."
        if mkdir -p "$CURRENT_HOME/.config/pipewire"; then
            print_success "~/.config/pipewire directory created"
        else
            print_error "Failed to create ~/.config/pipewire directory"
            return 1
        fi
    else
        print_warning "~/.config/pipewire directory already exists"
    fi
    
    # Copy configuration files from system directory
    if [[ -d "/usr/share/pipewire" ]]; then
        print_status "Copying files from /usr/share/pipewire to ~/.config/pipewire..."
        if cp -r /usr/share/pipewire/* "$CURRENT_HOME/.config/pipewire/"; then
            print_success "Pipewire configuration files copied successfully"
        else
            print_error "Failed to copy pipewire configuration files"
            return 1
        fi
    else
        print_error "/usr/share/pipewire directory not found"
        return 1
    fi
}

# Function to copy custom pipewire configurations
copy_custom_configs() {
    print_status "Copying custom pipewire configurations..."
    
    # Get current user info
    CURRENT_USER=$(whoami)
    CURRENT_HOME=$(getent passwd "$CURRENT_USER" | cut -d: -f6)
    
    # Get the script directory to find the configs folder
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIGS_DIR="$SCRIPT_DIR/../configs/pipewire"
    
    # Check if the configs directory exists
    if [[ ! -d "$CONFIGS_DIR" ]]; then
        print_error "Configs directory not found: $CONFIGS_DIR"
        return 1
    fi
    
    # Create ~/.config/pipewire directory if it doesn't exist
    if [[ ! -d "$CURRENT_HOME/.config/pipewire" ]]; then
        print_status "Creating ~/.config/pipewire directory..."
        if mkdir -p "$CURRENT_HOME/.config/pipewire"; then
            print_success "~/.config/pipewire directory created"
        else
            print_error "Failed to create ~/.config/pipewire directory"
            return 1
        fi
    fi
    
    # Copy custom configuration files
    print_status "Copying custom configuration files from $CONFIGS_DIR to ~/.config/pipewire..."
    if cp -r "$CONFIGS_DIR"/* "$CURRENT_HOME/.config/pipewire/"; then
        print_success "Custom pipewire configuration files copied successfully"
    else
        print_error "Failed to copy custom pipewire configuration files"
        return 1
    fi
}

# Function to enable and start pipewire-media-session service
enable_pipewire() {
    print_status "Enabling and starting pipewire-media-session service..."
    
    # Get current user info
    CURRENT_USER=$(whoami)
    CURRENT_HOME=$(getent passwd "$CURRENT_USER" | cut -d: -f6)
    print_status "Current user: $CURRENT_USER"
    print_status "User home: $CURRENT_HOME"
    
    # Set proper environment variables for systemd user session
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
    
    print_status "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    print_status "DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS"
    
    # Enable and start the service as the current user
    if systemctl --user enable pipewire-media-session --now; then
        print_success "pipewire-media-session service enabled and started successfully"
    else
        print_error "Failed to enable/start pipewire-media-session service"
        print_status "Trying with explicit environment variables..."
        
        # Try with explicit environment
        if env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" systemctl --user enable pipewire-media-session --now; then
            print_success "pipewire-media-session service enabled and started with explicit environment"
        else
            print_error "Failed to enable/start pipewire-media-session service even with explicit environment"
            print_status "You may need to log out and log back in to establish a proper user session"
            exit 1
        fi
    fi
}

# Main execution
main() {
    print_status "Starting pipewire installation and configuration..."
    echo "=========================================="
    
    check_user
    install_pipewire
    copy_pipewire_configs
    copy_custom_configs
    enable_pipewire
    
    echo "=========================================="
    print_success "Pipewire installation and configuration completed successfully!"
    print_status "All pipewire services have been automatically configured."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
