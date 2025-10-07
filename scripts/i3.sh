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

# Require root and resolve target user info similar to openbox.sh
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (use sudo)." >&2
    exit 1
fi

# Determine the real target (non-root) user
TARGET_USER="${SUDO_USER:-}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
    TARGET_USER=$(logname 2>/dev/null || true)
fi

if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
    echo "Error: Could not determine the non-root target user. Make sure to run with sudo from a normal user session." >&2
    exit 1
fi

# Resolve target user's home from system database
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
    echo "Error: Could not resolve home directory for user '$TARGET_USER'." >&2
    exit 1
fi

TARGET_UID=$(id -u "$TARGET_USER")
TARGET_GID=$(id -g "$TARGET_USER")

# Resolve script and configs directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(realpath "$SCRIPT_DIR/../configs/desktop/i3")"

# Deploy i3 config to user's ~/.config/i3/config (mirroring openbox.sh approach)
deploy_i3_config() {
    print_status "Deploying i3 configuration to user's home directory..."

    if [[ ! -d "$CONFIGS_DIR" ]]; then
        print_error "Configs directory not found at: $CONFIGS_DIR"
        return 1
    fi

    local src_file dst_dir dst_config
    src_file="$CONFIGS_DIR/config"
    dst_dir="$TARGET_HOME/.config/i3"
    dst_config="$dst_dir/config"

    if [[ ! -f "$src_file" ]]; then
        print_error "Source i3 config not found at $src_file"
        return 1
    fi

    install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$dst_dir" || {
        print_error "Failed to create $dst_dir"; return 1; }
    if cp -av "$src_file" "$dst_config"; then
        chown -R "$TARGET_UID":"$TARGET_GID" "$dst_dir"
        print_success "i3 config copied to $dst_config"
    else
        print_error "Failed to copy i3 config to $dst_config"
        return 1
    fi
}

# Function to install packages
install_packages() {
    print_status "Installing i3 window manager and related packages..."
    
    # Package list
    packages=("dmenu" "i3-wm" "i3blocks" "i3lock" "i3status" "lightdm" "lightdm-gtk-greeter" "rofi" "xss-lock" "xterm" "kitty" "nemo" "flameshot" "chromium")
    
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
