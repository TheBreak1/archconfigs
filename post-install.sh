#!/bin/bash

# Define the home directory
HOME_DIR="/home/$(whoami)"

# Prompt the user for action
clear
echo "Choose an action:"
echo " "
echo "1. Install desktop (Openbox) and its configs"
echo "2. Install paru and chaotic-aur"
echo "3. Install osu!lazer "
echo "4. Install osu!stable "
echo " "
read -p "Enter your choice (1, 2, or 3): " ACTION

# Install packages and copy specific configs if option 1 is chosen
if [[ "$ACTION" == "1" ]]; then
    echo " "
	echo " "
	echo "Installing required packages..."
    sudo pacman -Syu --noconfirm git openbox ly alacritty rofi adapta-gtk-theme nano mc chromium telegram-desktop discord brightnessctl cjk-fonts

    if [[ $? -ne 0 ]]; then
        echo " "
		echo " "
		echo "Failed to install packages"
        exit 1
    fi

    # Ask if iwd needs to be installed
    echo " "
    echo " "
    read -t 5 -p "Do you want to install iwd (Wireless Daemon)? (y/N): " INSTALL_IWD
    INSTALL_IWD=${INSTALL_IWD:-n}  # Default to 'n' if no input is provided

    if [[ "$INSTALL_IWD" == "y" || "$INSTALL_IWD" == "Y" ]]; then
        echo " "
		echo " "
		echo "Installing iwd..."
        sudo pacman -S --noconfirm iwd

        if [[ $? -ne 0 ]]; then
            echo " "
			echo " "
			echo "Failed to install iwd"
            exit 1
        fi
    fi

    # Copy specific folders (gtk-3.0, openbox, rofi) from the repository's /configs/desktop folder to the user's .config directory
    echo " "
	echo " "
	echo "Copying gtk-3.0, openbox, and rofi folders from /configs/desktop to $HOME_DIR/.config..."

    # Create the .config directory if it doesn't exist
    mkdir -p "$HOME_DIR/.config"

    # Copy the specified folders
    cp -r "configs/desktop/gtk-3.0" "$HOME_DIR/.config/"
    if [[ $? -ne 0 ]]; then
        echo " "
		echo " "
		echo "Failed to copy gtk-3.0 folder"
        exit 1
    fi
    cp -r "configs/desktop/openbox" "$HOME_DIR/.config/"
    if [[ $? -ne 0 ]]; then
        echo " "
		echo " "
		echo "Failed to copy openbox folder"
        exit 1
    fi
    cp -r "configs/desktop/rofi" "$HOME_DIR/.config/"
    if [[ $? -ne 0 ]]; then
        echo " "
		echo " "
		echo "Failed to copy rofi folder"
        exit 1
    fi

    echo "Packages installed and configs copied successfully."
fi

# Install paru and chaotic-aur if option 2 is chosen
if [[ "$ACTION" == "2" ]]; then
    echo " "
    echo " "
    echo "Adding chaotic-aur repository..."
    # Import chaotic-aur keys
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    # Add chaotic-aur repository to pacman.conf
    echo "" | sudo tee -a /etc/pacman.conf
    echo "[chaotic-aur]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    # Update package database
    sudo pacman -Syu --noconfirm

    if [[ $? -ne 0 ]]; then
        echo " "
        echo " "
        echo "Failed to add chaotic-aur repository"
        exit 1
    fi

    echo " "
    echo " "
    echo "Installing paru (AUR helper) from chaotic-aur..."
    sudo pacman -S --noconfirm paru

    if [[ $? -ne 0 ]]; then
        echo " "
        echo " "
        echo "Failed to install paru"
        exit 1
    fi

    echo " "
    echo " "
    echo "paru and chaotic-aur have been installed and configured successfully."
fi

# Install osu-lazer-bin if option 3 is chosen
if [[ "$ACTION" == "3" ]]; then
    echo " "
	echo " "
	echo "Attempting to install osu-lazer-bin using pacman..."
    sudo pacman -S --noconfirm osu-lazer-bin

    if [[ $? -ne 0 ]]; then
        echo " "
		echo " "
		echo "osu-lazer-bin not found in pacman repositories. Falling back to paru..."
        # Check if paru is installed
        if ! command -v paru &> /dev/null; then
            echo " "
			echo " "
			echo "Paru is missing. Please install paru."
            exit 1
        fi

        echo " "
		echo " "
		echo "Installing osu-lazer-bin using paru..."
        paru -S --noconfirm osu-lazer-bin

        if [[ $? -ne 0 ]]; then
            echo " "
			echo " "
			echo "Failed to install osu-lazer-bin using paru"
            exit 1
        fi
    fi

    echo " "
	echo " "
	echo "osu-lazer-bin installed successfully."
fi

echo " "
echo " "
echo "Script completed successfully!"
