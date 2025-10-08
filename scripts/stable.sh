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

# Function to install custom Wine version. This needs either to be moved to a single repo or cloud for speed.
install_custom_wine() {
    print_status "Installing custom Wine 9.22-1..."
    
    # Create Downloads directory and navigate to it
    mkdir -p ~/Downloads && cd ~/Downloads
    
    # Download Wine package
    print_status "Downloading Wine 9.22-1 package..."
    if wget https://github.com/Vudek/wine-9.22-1-x86_64/releases/download/wine-9.22-1-x86_64.pkg.tar.zst/wine-9.22-1-x86_64.pkg.tar.zst; then
        print_success "Wine package downloaded successfully!"
    else
        print_error "Failed to download Wine package."
        return 1
    fi
    
    # Install Wine package
    print_status "Installing Wine 9.22-1..."
    if sudo pacman -U wine-9.22-1-x86_64.pkg.tar.zst; then
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
    
    # Get the actual user's home directory (not root's)
    local user_home="/home/$SUDO_USER"
    local wine_prefix="$user_home/.wineosu"
    
    # Setup Wine prefix and install components as the actual user
    if sudo -u "$SUDO_USER" env WINEARCH=win32 WINEPREFIX="$wine_prefix" winetricks dotnet45 cjkfonts gdiplus; then
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
    
    # Get the actual user's home directory (not root's)
    local user_home="/home/$SUDO_USER"
    local osu_dir="$user_home/osu"
    local wine_prefix="$user_home/.wineosu"
    
    # Create osu! directory in user's home
    print_status "Creating osu! directory in user's home..."
    mkdir -p "$osu_dir"
    
    # Set proper ownership
    chown -R "$SUDO_USER:$SUDO_USER" "$osu_dir"
    
    # Download osu! installer
    print_status "Downloading osu! installer..."
    if wget --output-document "$osu_dir/osu\!.exe" https://m1.ppy.sh/r/osu\!install.exe; then
        print_success "osu! installer downloaded successfully!"
    else
        print_error "Failed to download osu! installer."
        return 1
    fi
    
    # Set proper ownership of downloaded file
    chown "$SUDO_USER:$SUDO_USER" "$osu_dir/osu\!.exe"
    
    # Run osu! installer with Wine as the actual user
    print_status "Running osu! installer..."
    print_warning "The osu! installer will now open. Follow the installation prompts."
    print_warning "Do not restart during installation!"
    
    if sudo -u "$SUDO_USER" env WINEARCH=win32 WINEPREFIX="$wine_prefix" wine "$osu_dir/osu\!.exe"; then
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
    
    # Remove wireplumber if installed
    if pacman -Q wireplumber >/dev/null 2>&1; then
        print_status "Removing wireplumber..."
        if pacman -R --noconfirm wireplumber; then
            print_success "wireplumber removed successfully"
        else
            print_error "Failed to remove wireplumber"
            return 1
        fi
    else
        print_warning "wireplumber is not installed"
    fi
    
    # Install pipewire-media-session
    print_status "Installing pipewire-media-session..."
    if pacman -S --noconfirm pipewire-media-session; then
        print_success "pipewire-media-session installed successfully"
    else
        print_error "Failed to install pipewire-media-session"
        return 1
    fi
    
    # Enable the service (run as the actual user, not root)
    print_status "Enabling pipewire-media-session service..."
    if sudo -u "$SUDO_USER" systemctl --user enable pipewire-media-session.service; then
        print_success "pipewire-media-session service enabled"
    else
        print_error "Failed to enable pipewire-media-session service"
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
