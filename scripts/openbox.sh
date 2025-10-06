#!/bin/bash

set -euo pipefail
shopt -s dotglob nullglob

# Get the original user who invoked sudo
if [[ -z "$SUDO_USER" ]]; then
    echo "Error: SUDO_USER is not set. This script must be run with sudo."
    echo "Please run this script through the menu.sh or with sudo directly."
    exit 1
fi

USER_HOME=$(eval echo "~${SUDO_USER}")
echo "Detected user: $SUDO_USER"
echo "User home directory: $USER_HOME"

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(realpath "$SCRIPT_DIR/../configs/desktop/openbox")"

echo "Working directory: $(pwd)"
echo "Script directory: $SCRIPT_DIR"
echo "Configs directory (resolved): $CONFIGS_DIR"

install_desktop_components() {
    echo "Installing desktop components..."
    # Installing base desktop:
    pacman -S --noconfirm --needed openbox ly alacritty rofi adapta-gtk-theme noto-fonts lxappearance lxappearance-obconf nitrogen
    
    # Move config files if configs directory exists
    if [ -d "$CONFIGS_DIR" ]; then
        echo "Moving configuration files to $USER_HOME/.config/"
        echo "Source directory: $CONFIGS_DIR"
        echo "Listing source tree:"
        find "$CONFIGS_DIR" -maxdepth 3 -type d -print | sed 's/^/  - /'
        
        # Copy openbox config (from openbox/openbox/)
        if [ -d "$CONFIGS_DIR/openbox/openbox" ]; then
            SRC_DIR="$CONFIGS_DIR/openbox/openbox"
            DST_DIR="$USER_HOME/.config/openbox"
            echo "[DEBUG] Copying Openbox config"
            echo "  - from: $SRC_DIR"
            echo "  - to  : $DST_DIR"
            echo "  - contents of src:"
            ls -la "$SRC_DIR"
            mkdir -p "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$DST_DIR"
            echo "[OK] Openbox config copied to $DST_DIR"
            echo "  - contents of dst:"
            ls -la "$DST_DIR"
        else
            echo "Warning: Openbox config directory not found at: $CONFIGS_DIR/openbox/openbox"
        fi
        
        # Copy gtk-3.0 config
        if [ -d "$CONFIGS_DIR/gtk-3.0" ]; then
            SRC_DIR="$CONFIGS_DIR/gtk-3.0"
            DST_DIR="$USER_HOME/.config/gtk-3.0"
            echo "[DEBUG] Copying GTK-3.0 config"
            echo "  - from: $SRC_DIR"
            echo "  - to  : $DST_DIR"
            echo "  - contents of src:"
            ls -la "$SRC_DIR"
            mkdir -p "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$DST_DIR"
            echo "[OK] GTK-3.0 config copied to $DST_DIR"
            echo "  - contents of dst:"
            ls -la "$DST_DIR"
        else
            echo "Warning: GTK-3.0 config directory not found at: $CONFIGS_DIR/gtk-3.0"
        fi
        
        # Copy rofi config
        if [ -d "$CONFIGS_DIR/rofi" ]; then
            SRC_DIR="$CONFIGS_DIR/rofi"
            DST_DIR="$USER_HOME/.config/rofi"
            echo "[DEBUG] Copying Rofi config"
            echo "  - from: $SRC_DIR"
            echo "  - to  : $DST_DIR"
            echo "  - contents of src:"
            ls -la "$SRC_DIR"
            mkdir -p "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$DST_DIR"
            echo "[OK] Rofi config copied to $DST_DIR"
            echo "  - contents of dst:"
            ls -la "$DST_DIR"
        else
            echo "Warning: Rofi config directory not found at: $CONFIGS_DIR/rofi"
        fi
        
        echo "Configuration files copying completed!"
    else
        echo "Error: Configs directory not found at: $CONFIGS_DIR"
        echo "Current working directory: $(pwd)"
        echo "Script directory: $SCRIPT_DIR"
    fi

    echo "Enabling ly display manager (no immediate start)"
    systemctl enable ly
}

install_applications() {
    echo "Installing applications..."
    #Then installing these things:
    pacman -S --noconfirm --needed chromium telegram-desktop discord brightnessctl mousepad nemo pavucontrol qt5ct nvidia-settings
}

pacman -Sy
install_desktop_components
install_applications
echo "Done!"