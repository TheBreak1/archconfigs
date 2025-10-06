#!/bin/bash

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
CONFIGS_DIR="$SCRIPT_DIR/../configs/desktop/openbox"

install_desktop_components() {
    echo "Installing desktop components..."
    # Installing base desktop:
    pacman -S --noconfirm openbox ly alacritty rofi adapta-gtk-theme noto-fonts lxappearance lxappearance-obconf nitrogen
    
    # Move config files if configs directory exists
    if [ -d "$CONFIGS_DIR" ]; then
        echo "Moving configuration files to $USER_HOME/.config/"
        echo "Source directory: $CONFIGS_DIR"
        
        # Copy openbox config (from openbox/openbox/)
        if [ -d "$CONFIGS_DIR/openbox/openbox" ]; then
            echo "Copying openbox config from: $CONFIGS_DIR/openbox/openbox/"
            mkdir -p "$USER_HOME/.config/openbox"
            cp -r "$CONFIGS_DIR/openbox/openbox/"* "$USER_HOME/.config/openbox/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$USER_HOME/.config/openbox"
            echo "Openbox config copied successfully"
        else
            echo "Warning: Openbox config directory not found at: $CONFIGS_DIR/openbox/openbox"
        fi
        
        # Copy gtk-3.0 config
        if [ -d "$CONFIGS_DIR/gtk-3.0" ]; then
            echo "Copying gtk-3.0 config from: $CONFIGS_DIR/gtk-3.0/"
            mkdir -p "$USER_HOME/.config/gtk-3.0"
            cp -r "$CONFIGS_DIR/gtk-3.0/"* "$USER_HOME/.config/gtk-3.0/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$USER_HOME/.config/gtk-3.0"
            echo "GTK-3.0 config copied successfully"
        else
            echo "Warning: GTK-3.0 config directory not found at: $CONFIGS_DIR/gtk-3.0"
        fi
        
        # Copy rofi config
        if [ -d "$CONFIGS_DIR/rofi" ]; then
            echo "Copying rofi config from: $CONFIGS_DIR/rofi/"
            mkdir -p "$USER_HOME/.config/rofi"
            cp -r "$CONFIGS_DIR/rofi/"* "$USER_HOME/.config/rofi/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$USER_HOME/.config/rofi"
            echo "Rofi config copied successfully"
        else
            echo "Warning: Rofi config directory not found at: $CONFIGS_DIR/rofi"
        fi
        
        echo "Configuration files copying completed!"
    else
        echo "Error: Configs directory not found at: $CONFIGS_DIR"
        echo "Current working directory: $(pwd)"
        echo "Script directory: $SCRIPT_DIR"
    fi
}

install_applications() {
    echo "Installing applications..."
    #Then installing these things:
    pacman -S --noconfirm chromium telegram-desktop discord brightnessctl mousepad nemo pavucontrol qt5ct nvidia-settings
}

pacman -Sy
install_desktop_components
install_applications
echo "Done!"