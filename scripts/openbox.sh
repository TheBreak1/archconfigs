#!/bin/bash

set -euo pipefail
shopt -s dotglob nullglob

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
    # Installing base desktop:
    pacman -S --noconfirm --needed openbox ly alacritty rofi adapta-gtk-theme noto-fonts lxappearance lxappearance-obconf nitrogen
    
    # Move config files if configs directory exists
    if [ -d "$CONFIGS_DIR" ]; then
        echo "Moving configuration files to $TARGET_HOME/.config/"
        echo "Source directory: $CONFIGS_DIR"
        echo "Listing source tree:"
        find "$CONFIGS_DIR" -maxdepth 3 -type d -print | sed 's/^/  - /'
        
        # Copy openbox config (from openbox/)
        if [ -d "$CONFIGS_DIR/openbox" ]; then
            SRC_DIR="$CONFIGS_DIR/openbox"
            DST_DIR="$TARGET_HOME/.config/openbox"
            echo "[DEBUG] Copying Openbox config"
            echo "  - from: $SRC_DIR"
            echo "  - to  : $DST_DIR"
            echo "  - contents of src:"
            ls -la "$SRC_DIR"
            install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R "$TARGET_UID":"$TARGET_GID" "$DST_DIR"
            echo "[OK] Openbox config copied to $DST_DIR"
            echo "  - contents of dst:"
            ls -la "$DST_DIR"
        else
            echo "Warning: Openbox config directory not found at: $CONFIGS_DIR/openbox"
        fi
        
        # Copy gtk-3.0 config
        if [ -d "$CONFIGS_DIR/gtk-3.0" ]; then
            SRC_DIR="$CONFIGS_DIR/gtk-3.0"
            DST_DIR="$TARGET_HOME/.config/gtk-3.0"
            echo "[DEBUG] Copying GTK-3.0 config"
            echo "  - from: $SRC_DIR"
            echo "  - to  : $DST_DIR"
            echo "  - contents of src:"
            ls -la "$SRC_DIR"
            install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R "$TARGET_UID":"$TARGET_GID" "$DST_DIR"
            echo "[OK] GTK-3.0 config copied to $DST_DIR"
            echo "  - contents of dst:"
            ls -la "$DST_DIR"
        else
            echo "Warning: GTK-3.0 config directory not found at: $CONFIGS_DIR/gtk-3.0"
        fi
        
        # Copy rofi config
        if [ -d "$CONFIGS_DIR/rofi" ]; then
            SRC_DIR="$CONFIGS_DIR/rofi"
            DST_DIR="$TARGET_HOME/.config/rofi"
            echo "[DEBUG] Copying Rofi config"
            echo "  - from: $SRC_DIR"
            echo "  - to  : $DST_DIR"
            echo "  - contents of src:"
            ls -la "$SRC_DIR"
            install -d -m 0755 -o "$TARGET_UID" -g "$TARGET_GID" "$DST_DIR"
            cp -av "$SRC_DIR/." "$DST_DIR/"
            chown -R "$TARGET_UID":"$TARGET_GID" "$DST_DIR"
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

    # Configure ly animation if config exists
    LY_CONF="/etc/ly/config.ini"
    if [ -f "$LY_CONF" ]; then
        echo "Found ly config: $LY_CONF"
        echo "Checking animation setting..."
        if grep -qE '^\s*animation\s*=\s*none\s*$' "$LY_CONF"; then
            echo "Updating 'animation = none' -> 'animation = colormix'"
            sed -i 's/^\s*animation\s*=\s*none\s*$/animation = colormix/' "$LY_CONF"
        else
            if grep -qE '^\s*animation\s*=' "$LY_CONF"; then
                echo "Setting existing animation to colormix"
                sed -i 's/^\s*animation\s*=.*/animation = colormix/' "$LY_CONF"
            else
                echo "Appending animation = colormix"
                printf '\nanimation = colormix\n' >> "$LY_CONF"
            fi
        fi
        echo "ly animation set to colormix (takes effect on next ly start)"
    else
        echo "ly config not found at $LY_CONF; skipping animation change"
    fi
}

install_applications() {
    echo "Installing applications..."
    #Then installing these things:
    pacman -S --noconfirm --needed chromium telegram-desktop discord brightnessctl mousepad nemo pavucontrol qt5ct nvidia-settings

    echo "Attempting to install AUR packages with paru (as $TARGET_USER)"
    if command -v paru >/dev/null 2>&1; then
        echo "paru found at $(command -v paru)"
        echo "Installing: obkey obmenu"
        sudo -u "$TARGET_USER" HOME="$TARGET_HOME" paru -S --noconfirm --needed obkey obmenu || echo "Warning: paru installation of obkey/obmenu failed"
    else
        echo "paru not found; skipping AUR install of obkey and obmenu"
    fi
}

pacman -Sy
install_desktop_components
install_applications
echo "Done!"