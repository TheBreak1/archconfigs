#!/bin/bash

# Get the original user who invoked sudo
USER_HOME=$(eval echo "~${SUDO_USER}")

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
        
        # Copy openbox config (from openbox/openbox/)
        if [ -d "$CONFIGS_DIR/openbox" ]; then
            mkdir -p "$USER_HOME/.config/openbox"
            cp -r "$CONFIGS_DIR/openbox/"* "$USER_HOME/.config/openbox/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$USER_HOME/.config/openbox"
        fi
        
        # Copy gtk-3.0 config
        if [ -d "$CONFIGS_DIR/gtk-3.0" ]; then
            mkdir -p "$USER_HOME/.config/gtk-3.0"
            cp -r "$CONFIGS_DIR/gtk-3.0/"* "$USER_HOME/.config/gtk-3.0/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$USER_HOME/.config/gtk-3.0"
        fi
        
        # Copy rofi config
        if [ -d "$CONFIGS_DIR/rofi" ]; then
            mkdir -p "$USER_HOME/.config/rofi"
            cp -r "$CONFIGS_DIR/rofi/"* "$USER_HOME/.config/rofi/"
            chown -R ${SUDO_USER}:${SUDO_USER} "$USER_HOME/.config/rofi"
        fi
        
        echo "Configuration files copied successfully!"
    else
        echo "Configs directory not found at: $CONFIGS_DIR"
    fi
}

install_applications() {
    echo "Installing applications..."
    #Then installing these things:
    pacman -S --noconfirm chromium telegram-desktop discord brightnessctl mousepad nemo pavucontrol qt5ct
}

pacman -Sy
install_desktop_components
install_applications
echo "Done!"