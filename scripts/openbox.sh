#!/bin/bash

#LOTS of chown's here, this is better running as user, everything is but i've spent too much time
set -euo pipefail
shopt -s dotglob nullglob

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

# Get the original user who invoked sudo
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (use sudo)." >&2
    exit 1
fi

# Determine the real target (non-root) user
TARGET_USER="${SUDO_USER:-}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
    # Fallback to logname (best-effort) if sudo did not set SUDO_USER
    TARGET_USER=$(logname 2>/dev/null || true)
fi

if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
    echo "Error: Could not determine the non-root target user. Make sure to run with sudo from a normal user session." >&2
    exit 1
fi

# Resolve target user's home from system database (robust even if $HOME is /root)
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
    echo "Error: Could not resolve home directory for user '$TARGET_USER'." >&2
    exit 1
fi

TARGET_UID=$(id -u "$TARGET_USER")
TARGET_GID=$(id -g "$TARGET_USER")

echo "Detected target user: $TARGET_USER (uid=$TARGET_UID gid=$TARGET_GID)"
echo "Target user home directory: $TARGET_HOME"

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(realpath "$SCRIPT_DIR/../configs/desktop/openbox")"

echo "Working directory: $(pwd)"
echo "Script directory: $SCRIPT_DIR"
echo "Configs directory (resolved): $CONFIGS_DIR"

install_desktop_components() {
    echo "Installing desktop components..."
    # Installing base desktop (requires root):
    pacman -S --noconfirm --needed openbox ly alacritty rofi adapta-gtk-theme noto-fonts lxappearance lxappearance-obconf nitrogen tint2
    
    # Ensure ~/.config directory exists with proper permissions
    print_status "Ensuring ~/.config directory exists with proper permissions"
    install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$TARGET_HOME/.config"
    chown "$TARGET_UID":"$TARGET_GID" "$TARGET_HOME/.config"
    print_success "~/.config directory permissions set correctly"

    # Move config files if configs directory exists
    if [ -d "$CONFIGS_DIR" ]; then
        print_status "Moving configuration files to $TARGET_HOME/.config/"
        
        # Copy openbox config (from openbox/)
        if [ -d "$CONFIGS_DIR/openbox" ]; then
            SRC_DIR="$CONFIGS_DIR/openbox"
            DST_DIR="$TARGET_HOME/.config/openbox"
            install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R "$TARGET_UID":"$TARGET_GID" "$DST_DIR"
            print_success "Openbox config copied to $DST_DIR"
        else
            print_warning "Openbox config directory not found at: $CONFIGS_DIR/openbox"
        fi
        
        # Copy gtk-3.0 config
        if [ -d "$CONFIGS_DIR/gtk-3.0" ]; then
            SRC_DIR="$CONFIGS_DIR/gtk-3.0"
            DST_DIR="$TARGET_HOME/.config/gtk-3.0"
            install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R "$TARGET_UID":"$TARGET_GID" "$DST_DIR"
            print_success "GTK-3.0 config copied to $DST_DIR"
        else
            print_warning "GTK-3.0 config directory not found at: $CONFIGS_DIR/gtk-3.0"
        fi
        
        # Copy rofi config
        if [ -d "$CONFIGS_DIR/rofi" ]; then
            SRC_DIR="$CONFIGS_DIR/rofi"
            DST_DIR="$TARGET_HOME/.config/rofi"
            install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R "$TARGET_UID":"$TARGET_GID" "$DST_DIR"
            print_success "Rofi config copied to $DST_DIR"
        else
            print_warning "Rofi config directory not found at: $CONFIGS_DIR/rofi"
        fi
        
        # Copy tint2 config
        if [ -d "$CONFIGS_DIR/tint2" ]; then
            SRC_DIR="$CONFIGS_DIR/tint2"
            DST_DIR="$TARGET_HOME/.config/tint2"
            install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R "$TARGET_UID":"$TARGET_GID" "$DST_DIR"
            print_success "Tint2 config copied to $DST_DIR"
        else
            print_warning "Tint2 config directory not found at: $CONFIGS_DIR/tint2"
        fi
        
        print_success "Configuration files copying completed!"
    else
        print_error "Configs directory not found at: $CONFIGS_DIR"
        print_status "Current working directory: $(pwd)"
        print_status "Script directory: $SCRIPT_DIR"
    fi

    print_status "Enabling ly display manager (no immediate start)"
    systemctl enable ly

    # Configure ly animation if config exists
    LY_CONF="/etc/ly/config.ini"
    if [ -f "$LY_CONF" ]; then
        print_status "Found ly config: $LY_CONF"
        print_status "Checking animation setting..."
        if grep -qE '^\s*animation\s*=\s*none\s*$' "$LY_CONF"; then
            print_status "Updating 'animation = none' -> 'animation = colormix'"
            sed -i 's/^\s*animation\s*=\s*none\s*$/animation = colormix/' "$LY_CONF"
        else
            if grep -qE '^\s*animation\s*=' "$LY_CONF"; then
                print_status "Setting existing animation to colormix"
                sed -i 's/^\s*animation\s*=.*/animation = colormix/' "$LY_CONF"
            else
                print_status "Appending animation = colormix"
                printf '\nanimation = colormix\n' >> "$LY_CONF"
            fi
        fi
        print_success "ly animation set to colormix (takes effect on next ly start)"
    else
        print_warning "ly config not found at $LY_CONF; skipping animation change"
    fi
}

install_applications() {
    print_status "Installing applications..."
    #Then installing these things (requires root):
    pacman -S --noconfirm --needed chromium telegram-desktop discord brightnessctl mousepad nemo pavucontrol qt5ct nvidia-settings
    

    # Ask user if they want to install AUR packages
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${YELLOW}Openbox Configuration Apps Installation${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${GREEN}AUR packages for installation:${NC} obkey obmenu obconf"
    echo -e "${YELLOW}Do you want to install AUR packages? (y/n):${NC} "
    echo -e "${YELLOW}This may take VERY long time, come back to it later!${NC} "
    read -r install_aur
    
    if [[ "$install_aur" =~ ^[Yy]$ ]]; then
        print_status "Attempting to install AUR packages with paru (as $TARGET_USER)"
        if command -v paru >/dev/null 2>&1; then
            print_status "paru found at $(command -v paru)"
            print_status "Installing: obkey obmenu obconf"
            sudo -u "$TARGET_USER" HOME="$TARGET_HOME" paru -S --noconfirm --needed obkey obmenu obconf || print_warning "paru installation of obkey/obmenu failed"
        else
            print_warning "paru not found; skipping AUR install of obkey and obmenu"
        fi
    else
        print_status "Skipping AUR package installation"
    fi
}

# Update package database (requires root)
pacman -Sy

install_desktop_components
install_applications
print_success "Done!"