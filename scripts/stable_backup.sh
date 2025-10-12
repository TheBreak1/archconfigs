#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if running in TTY or desktop environment
check_environment() {
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        print_status "Running in desktop environment (X11/Wayland)"
        return 0
    elif [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; then
        print_status "Running in TTY"
        return 1
    else
        print_warning "Unable to determine environment (not TTY or desktop)"
        return 2
    fi
}

# Function to handle environment validation and user interaction
validate_environment() {
    print_status "Checking execution environment..."
    check_environment
    environment_status=$?

    # Exit if running in TTY
    if [ $environment_status -eq 1 ]; then
        print_error "This script must be run from a desktop environment (X11/Wayland), not from TTY."
        print_status "Please run this script from a terminal within your desktop environment."
        exit 1
    fi

    # Pause if unable to detect environment
    if [ $environment_status -eq 2 ]; then
        print_warning "Unable to determine if running in TTY or desktop environment."
        print_status "Please ensure you are running this script from a terminal within your desktop environment."
        print_status "Press Enter to continue or Ctrl+C to exit..."
        read -r
    fi
}

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

# Function to install dependencies
install_dependencies() {
    # Install required 32-bit libraries
    print_status "Installing first batch of dependencies..."
    
    if sudo pacman -S --noconfirm --needed lib32-gnutls lib32-libxcomposite winetricks; then
        print_success "First batch of dependencies installed successfully!"
    else
        print_error "Failed to install... idk what happened, go play lazer"
        return 1
    fi
    
    # Check if NVIDIA GPU is present
    print_status "Checking for NVIDIA GPU..."
    
    if lspci | grep -i nvidia > /dev/null 2>&1; then
        print_success "NVIDIA GPU detected!"
        
        # Check if lib32-nvidia-utils is already installed
        print_status "Installing lib32-nvidia-utils (if needed)..."
        if sudo pacman -S --noconfirm --needed lib32-nvidia-utils; then
            print_success "lib32-nvidia-utils is installed or was just installed successfully!"
        else
            print_error "Failed to install lib32-nvidia-utils."
            return 1
        fi
    else
        print_warning "No NVIDIA GPU detected. Skipping lib32-nvidia-utils installation."
    fi
}

# Function to install Wine with 32-bit support.
install_custom_wine() {
    print_status "Installing custom Wine 9.22-1..."
    
    # Create Downloads directory and navigate to it
    mkdir -p ~/Downloads && cd ~/Downloads
    
    # Download Wine package
    print_status "Downloading Wine 9.22-1 package..."
    if wget https://files.lopij.xyz/files/94b1719101a66673.zst; then
        print_success "Wine package downloaded successfully!"
        # Rename the downloaded file to wine1.tar.zst
        print_status "Renaming downloaded file to wine1.tar.zst..."
        mv 94b1719101a66673.zst wine1.tar.zst
        print_success "File renamed successfully!"
    else
        print_error "Failed to download Wine package."
        return 1
    fi
    
    # Install Wine package
    print_status "Installing Wine 9.22-1..."
    if sudo pacman -U wine1.tar.zst; then
        print_success "Wine 9.22-1 installed successfully!"
    else
        print_error "Failed to install Wine package. go play lazer"
        return 1
    fi
    
    # Return to home directory. Huh.
    cd ~
}

# Function to setup Wine prefix and install components
setup_wine_prefix() {
    print_status "Setting up Wine prefix for osu!..."
    print_status "This will install dotnet45, cjkfonts, and gdiplus components."
    print_warning "This process may take several minutes and may require user interaction."
    print_warning "Do not restart. DO NOT INSTALL MONO!"
    
    # Get the current user's home directory
    local user_home="$HOME"
    local wine_prefix="$user_home/.wineosu"
    
    # Setup Wine prefix and install components
    if env WINEARCH=win32 WINEPREFIX="$wine_prefix" winetricks dotnet45 cjkfonts gdiplus; then
        print_success "Wine prefix setup completed successfully!"
    else
        print_error "Failed to setup Wine prefix or install components."
        return 1
    fi
    
    # Wait for user to continue
    print_status "Wine prefix setup completed. Press Enter to continue..."
    read -r
}

# Function to download and install osu!
install_osu() {
    print_status "Setting up osu! installation..."
    
    # Get the current user's home directory
    local user_home="$HOME"
    local osu_dir="$user_home/osu"
    local wine_prefix="$user_home/.wineosu"
    
    # Create osu! directory in user's home
    print_status "Creating osu! directory in user's home..."
    mkdir -p "$osu_dir"
    
    # Download osu! installer
    print_status "Downloading osu! installer..."
    if wget --output-document "$osu_dir/osu\!.exe" https://m1.ppy.sh/r/osu\!install.exe; then
        print_success "osu! installer downloaded successfully!"
    else
        print_error "Failed to download osu! installer."
        return 1
    fi
    
    # Run osu! installer with Wine
    print_status "Running osu! installer..."
    print_warning "The osu! installer will now open. Follow the installation prompts."
    print_warning "Do not restart during installation!"
    
    if env WINEARCH=win32 WINEPREFIX="$wine_prefix" wine "$osu_dir/osu\!.exe"; then
        print_success "osu! installation completed!"
    else
        print_error "osu! installation failed or was interrupted."
        return 1
    fi
    
    # Wait for user to continue
    print_status "osu! installation completed. Press Enter to continue..."
    read -r
}

# Function to manage pipewire session manager
manage_pipewire_session() {
    print_status "Managing pipewire session manager..."
    
    # Install pipewire-media-session using pacman (will replace wireplumber if present)
    print_status "Installing pipewire-media-session using pacman..."
    if sudo pacman -S --noconfirm --ask=4 pipewire-media-session; then
        print_success "pipewire-media-session installed successfully"
    else
        print_error "Failed to install pipewire-media-session"
        return 1
    fi
    
    # Copy pipewire configuration files
    print_status "Copying pipewire configuration files to user config..."
    
    # Get current user info
    CURRENT_USER="$(whoami)"
    CURRENT_HOME="$HOME"
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
    
    # Copy custom pipewire configurations
    print_status "Copying custom pipewire configurations..."
    
    # Get the script directory to find the configs folder
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIGS_DIR="$SCRIPT_DIR/../configs/pipewire"
    
    # Check if the configs directory exists
    if [[ ! -d "$CONFIGS_DIR" ]]; then
        print_error "Configs directory not found: $CONFIGS_DIR"
        return 1
    fi
    
    # Copy custom configuration files
    print_status "Copying custom configuration files from $CONFIGS_DIR to ~/.config/pipewire..."
    if cp -r "$CONFIGS_DIR"/* "$CURRENT_HOME/.config/pipewire/"; then
        print_success "Custom pipewire configuration files copied successfully"
    else
        print_error "Failed to copy custom pipewire configuration files"
        return 1
    fi
    
    # Enable and start pipewire-media-session service
    print_status "Enabling and starting pipewire-media-session service..."
    
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
        print_status "You may need to log out and log back in to establish a proper user session"
        return 1
    fi
}

# Validate environment before proceeding
validate_environment

# Manage pipewire session manager
manage_pipewire_session

# Install dependencies
install_dependencies

# Install custom Wine version
install_custom_wine

# Setup Wine prefix and install components
setup_wine_prefix

# Download and install osu!
install_osu
