#!/bin/bash

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

# Function to manage pipewire session manager
# manage_pipewire_session() {
#     print_status "Managing pipewire session manager..."
#     
#     # Check if wireplumber is currently installed
#     if pacman -Q wireplumber >/dev/null 2>&1; then
#         print_status "wireplumber is currently installed, preparing for replacement..."
#         
#         # Stop and disable wireplumber service first
#         if systemctl --user is-active wireplumber.service >/dev/null 2>&1; then
#             print_status "Stopping wireplumber service..."
#             if sudo -u "$SUDO_USER" systemctl --user stop wireplumber.service; then
#                 print_success "wireplumber service stopped"
#             else
#                 print_warning "Failed to stop wireplumber service"
#             fi
#         fi
#         
#         if systemctl --user is-enabled wireplumber.service >/dev/null 2>&1; then
#             print_status "Disabling wireplumber service..."
#             if sudo -u "$SUDO_USER" systemctl --user disable wireplumber.service; then
#                 print_success "wireplumber service disabled"
#             else
#                 print_warning "Failed to disable wireplumber service"
#             fi
#         fi
#         
#         # Remove wireplumber first to avoid conflicts
#         print_status "Removing wireplumber to avoid conflicts..."
#         if pacman -R --noconfirm wireplumber; then
#             print_success "wireplumber removed successfully"
#         else
#             print_error "Failed to remove wireplumber"
#             print_status "Trying to force removal with --nodeps..."
#             if pacman -R --nodeps --noconfirm wireplumber; then
#                 print_success "wireplumber force-removed successfully"
#             else
#                 print_error "Failed to remove wireplumber even with --nodeps"
#                 return 1
#             fi
#         fi
#     else
#         print_warning "wireplumber is not installed"
#     fi
#     
#     # Install pipewire-media-session
#     print_status "Installing pipewire-media-session..."
#     if pacman -S --noconfirm pipewire-media-session; then
#         print_success "pipewire-media-session installed successfully"
#     else
#         print_error "Failed to install pipewire-media-session"
#         return 1
#     fi
#     
#     # Enable and start pipewire-media-session service
#     print_status "Enabling pipewire-media-session service..."
#     if sudo -u "$SUDO_USER" systemctl --user enable pipewire-media-session.service; then
#         print_success "pipewire-media-session service enabled"
#     else
#         print_error "Failed to enable pipewire-media-session service"
#         return 1
#     fi
#     
#     print_status "Starting pipewire-media-session service..."
#     if sudo -u "$SUDO_USER" systemctl --user start pipewire-media-session.service; then
#         print_success "pipewire-media-session service started"
#     else
#         print_warning "Failed to start pipewire-media-session service (may need to restart session)"
#     fi
# }

# Function to automatically download and install pipewire-media-session
download_pipewire() {
    print_status "Automatically downloading and installing pipewire-media-session..."
    
    # Install pipewire-media-session
    print_status "Installing pipewire-media-session..."
    if pacman -S --noconfirm pipewire-media-session; then
        print_success "pipewire-media-session installed successfully"
    else
        print_error "Failed to install pipewire-media-session"
        return 1
    fi
    
    # Enable pipewire-media-session service
    print_status "Enabling pipewire-media-session service..."
    if sudo -u "$SUDO_USER" systemctl --user enable pipewire-media-session.service; then
        print_success "pipewire-media-session service enabled"
    else
        print_warning "Failed to enable pipewire-media-session service"
    fi
    
    print_success "pipewire-media-session installation completed!"
}

# Function to copy pipewire configuration files
copy_pipewire_configs() {
    print_status "Copying pipewire configuration files to user config..."
    
    # Create ~/.config/pipewire directory if it doesn't exist
    if [[ ! -d "$HOME/.config/pipewire" ]]; then
        print_status "Creating ~/.config/pipewire directory..."
        if mkdir -p "$HOME/.config/pipewire"; then
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
        if cp -r /usr/share/pipewire/* "$HOME/.config/pipewire/"; then
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
    
    # Get the script directory to find the configs folder
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIGS_DIR="$SCRIPT_DIR/../configs/pipewire"
    
    # Check if the configs directory exists
    if [[ ! -d "$CONFIGS_DIR" ]]; then
        print_error "Configs directory not found: $CONFIGS_DIR"
        return 1
    fi
    
    # Create ~/.config/pipewire directory if it doesn't exist
    if [[ ! -d "$HOME/.config/pipewire" ]]; then
        print_status "Creating ~/.config/pipewire directory..."
        if mkdir -p "$HOME/.config/pipewire"; then
            print_success "~/.config/pipewire directory created"
        else
            print_error "Failed to create ~/.config/pipewire directory"
            return 1
        fi
    fi
    
    # Copy custom configuration files
    print_status "Copying custom configuration files from $CONFIGS_DIR to ~/.config/pipewire..."
    if cp -r "$CONFIGS_DIR"/* "$HOME/.config/pipewire/"; then
        print_success "Custom pipewire configuration files copied successfully"
    else
        print_error "Failed to copy custom pipewire configuration files"
        return 1
    fi
}

# Main execution
main() {
    print_status "Starting pipewire installation..."
    
    # Copy pipewire configuration files
    copy_pipewire_configs
    
    # Copy custom pipewire configurations
    copy_custom_configs
    
    # Ensure user has access to .config folder
    print_status "Ensuring user has access to .config folder..."
    if [[ -d "$HOME/.config" ]]; then
        if chown -R "$SUDO_USER:$SUDO_USER" "$HOME/.config"; then
            print_success "User permissions set for .config folder"
        else
            print_warning "Failed to set permissions for .config folder"
        fi
    else
        print_warning ".config folder does not exist"
    fi
    
    # Download and install pipewire (last step)
    download_pipewire
    
    print_success "Pipewire installation completed!"
    print_warning "You may need to restart your session or reboot for changes to take effect"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
