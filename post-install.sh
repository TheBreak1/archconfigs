#!/bin/bash

# Ensure the script is running with root privileges for pacman installs
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define the home directory
HOME_DIR="/home/$(whoami)"

# Prompt the user for action
clear
echo "Choose an action:"
echo " "
echo "1. Install desktop (Openbox) and its configs"
echo "2. Install paru and chaotic-aur"
echo "3. Install osu-lazer-bin (fallback to paru if needed)"
echo " "
read -p "Enter your choice (1, 2, or 3): " ACTION

# Install packages and copy specific configs if option 1 is chosen
if [[ "$ACTION" == "1" ]]; then
    echo "Installing required packages..."
    pacman -Syu --noconfirm git openbox ly alacritty rofi adapta-gtk-theme nano mc chromium

    if [[ $? -ne 0 ]]; then
        echo "Failed to install packages"
        exit 1
    fi

    # Ask if iwd needs to be installed
    echo " "
    read -t 5 -p "Do you want to install iwd (Wireless Daemon)? (y/N): " INSTALL_IWD
    INSTALL_IWD=${INSTALL_IWD:-n}  # Default to 'n' if no input is provided

    if [[ "$INSTALL_IWD" == "y" || "$INSTALL_IWD" == "Y" ]]; then
        echo "Installing iwd..."
        pacman -S --noconfirm iwd

        if [[ $? -ne 0 ]]; then
            echo "Failed to install iwd"
            exit 1
        fi
    fi

    # Copy specific folders (gtk-3.0, openbox, rofi) from the repository's /configs/desktop folder to the user's .config directory
	# NO EXISTENCE CHECKS, EVERITHING HERE IS HARD CODED.
    echo "Copying gtk-3.0, openbox, and rofi folders from /configs/desktop to $HOME_DIR/.config..."

    # Create the .config directory if it doesn't exist
    mkdir -p "$HOME_DIR/.config"

    # Copy the specified folders
    for folder in gtk-3.0 openbox rofi; do
        cp -r "configs/desktop/$folder" "$HOME_DIR/.config/"
        if [[ $? -ne 0 ]]; then
            echo "Failed to copy $folder folder"
            exit 1
        fi
    done

    echo "Packages installed and

# Install paru and chaotic-aur if option 2 is chosen
if [[ "$ACTION" == "2" ]]; then
    echo "Installing paru (AUR helper)..."
    # Install dependencies for paru
    pacman -S --noconfirm --needed base-devel git
    # Clone and install paru
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd ~

    if [[ $? -ne 0 ]]; then
        echo "Failed to install paru"
        exit 1
    fi

    echo "Adding chaotic-aur repository..."
    # Import chaotic-aur keys
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB
	pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
	pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    # Add chaotic-aur repository to pacman.conf
    echo "" >> /etc/pacman.conf
	echo "[chaotic-aur]" >> /etc/pacman.conf
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
    # Update package database
    pacman -Syu --noconfirm

    if [[ $? -ne 0 ]]; then
        echo "Failed to add chaotic-aur repository"
        exit 1
    fi

    echo "paru and chaotic-aur have been installed and configured successfully."
fi

# Install osu-lazer-bin if option 3 is chosen
if [[ "$ACTION" == "3" ]]; then
    echo "Attempting to install osu-lazer-bin using pacman..."
    pacman -S --noconfirm osu-lazer-bin

    if [[ $? -ne 0 ]]; then
        echo "osu-lazer-bin not found in pacman repositories. Falling back to paru..."
        # Check if paru is installed
        if ! command -v paru &> /dev/null; then
            echo "Paru is missing. Abort."
            exit 1
        fi

        echo "Installing osu-lazer-bin using paru..."
        paru -S --noconfirm osu-lazer-bin

        if [[ $? -ne 0 ]]; then
            echo "Failed to install osu-lazer-bin using paru"
            exit 1
        fi
    fi

    echo "osu-lazer-bin installed successfully."
fi

echo "Script completed successfully!"