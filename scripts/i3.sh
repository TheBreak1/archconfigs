#!/bin/bash

# Colors for output (from start.sh)
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

# Function to install packages
install_packages() {
    print_status "Installing i3 window manager and related packages..."
    
    # Package list
    packages=(
        "dmenu"
        "i3-wm"
        "i3blocks"
        "i3lock"
        "i3status"
        "lightdm"
        "lightdm-gtk-greeter"
        "xss-lock"
        "xterm"
        "kitty"
        "nemo"
        "flameshot"
        "chromium"
    )
    
    # Install packages
    for package in "${packages[@]}"; do
        print_status "Installing $package..."
        if pacman -S --noconfirm "$package" >/dev/null 2>&1; then
            print_success "$package installed successfully"
        else
            print_error "Failed to install $package"
            return 1
        fi
    done
    
    print_success "All i3 packages installed successfully!"
}

# Main execution
main() {
    print_status "Starting i3 installation script..."
    
    # Install packages
    install_packages
    
    print_success "i3 installation completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
