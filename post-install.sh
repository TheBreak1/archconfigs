#!/bin/bash

# Ensure the script is running with root privileges for pacman installs
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define the repository URL and the local destination for the .config folder
REPO_URL="https://github.com/TheBreak1/archconfigs.git"
CONFIG_DIR=".config"
HOME_DIR="/home/$(whoami)"

# Prompt the user for action
echo "Choose an action:"
echo "1. Clone a repository"
echo "2. Install packages (nano, mc)"
echo "3. Clone a repository and install packages"
read -p "Enter your choice (1, 2, or 3): " ACTION

# Clone the repository if option 1 or 3 is chosen
if [[ "$ACTION" == "1" || "$ACTION" == "3" ]]; then
    echo "Cloning the GitHub repository..."
    git clone "$REPO_URL" /tmp/repo

    if [[ $? -ne 0 ]]; then
        echo "Failed to clone the repository"
        exit 1
    fi

    echo "Moving .config folder to $HOME_DIR..."
    mv -f /tmp/repo/$CONFIG_DIR $HOME_DIR/

    if [[ $? -ne 0 ]]; then
        echo "Failed to move the .config folder"
        exit 1
    fi
fi

# Install packages if option 2 or 3 is chosen
if [[ "$ACTION" == "2" || "$ACTION" == "3" ]]; then
    echo "Installing required packages: nano and mc..."
    pacman -Syu --noconfirm nano mc

    if [[ $? -ne 0 ]]; then
        echo "Failed to install packages"
        exit 1
    fi
fi

# Clean up the cloned repository if it was cloned
if [[ "$ACTION" == "1" || "$ACTION" == "3" ]]; then
    echo "Cleaning up temporary repository..."
    rm -rf /tmp/repo
fi

echo "Script completed successfully!"
