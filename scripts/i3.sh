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

# Resolve target home directory (supports running via sudo)
get_target_home() {
    if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
        eval echo ~"$SUDO_USER"
    else
        echo "$HOME"
    fi
}

# Deploy i3 config to user's ~/.config/i3/config
deploy_i3_config() {
    print_status "Deploying i3 configuration to user's home directory..."

    # Determine repository root robustly
    local script_dir repo_root src_config
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if command -v git >/dev/null 2>&1; then
        repo_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)"
    fi
    if [[ -z "$repo_root" ]]; then
        repo_root="$(cd "$script_dir/.." && pwd)"
    fi

    src_config="$repo_root/configs/desktop/i3/config"
    print_status "Using source i3 config at: $src_config"

    if [[ ! -f "$src_config" ]]; then
        print_error "Source i3 config not found at $src_config"
        return 1
    fi

    local target_home target_dir target_config
    target_home="$(get_target_home)"
    target_dir="$target_home/.config/i3"
    target_config="$target_dir/config"

    mkdir -p "$target_dir" || { print_error "Failed to create $target_dir"; return 1; }
    if cp -f "$src_config" "$target_config"; then
        :
    else
        print_error "Failed to copy i3 config to $target_config"
        return 1
    fi

    # Ensure ownership matches the target user when running under sudo
    if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
        chown "$SUDO_USER":"$SUDO_USER" "$target_config" >/dev/null 2>&1 || true
        chown -R "$SUDO_USER":"$SUDO_USER" "$target_dir" >/dev/null 2>&1 || true
    fi

    print_success "i3 configuration deployed to $target_config"
}

# Function to install packages
install_packages() {
    print_status "Installing i3 window manager and related packages..."
    
    # Package list
    packages=("dmenu" "i3-wm" "i3blocks" "i3lock" "i3status" "lightdm" "lightdm-gtk-greeter" "xss-lock" "xterm" "kitty" "nemo" "flameshot" "chromium")
    
    # Install all packages in a single command
    print_status "Installing packages: ${packages[*]}"
    if pacman -S --noconfirm "${packages[@]}" >/dev/null 2>&1; then
        print_success "All packages installed successfully"
    else
        print_error "Failed to install packages"
        return 1
    fi
    
    print_success "All i3 packages installed successfully!"
}

# Main execution
main() {
    print_status "Starting i3 installation script..."
    
    # Install packages
    install_packages
    if [[ $? -ne 0 ]]; then
        print_error "Package installation failed, aborting LightDM enable step."
        return 1
    fi
    
    # Enable LightDM display manager (will start on next boot)
    print_status "Enabling LightDM service to start on boot..."
    if systemctl enable lightdm.service >/dev/null 2>&1; then
        print_success "LightDM enabled to start on boot."
    else
        print_error "Failed to enable LightDM."
        return 1
    fi

    # Deploy user i3 config
    deploy_i3_config || return 1
    
    print_success "i3 installation completed!"
    print_warning "Reboot your system to start LightDM and log into i3."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
