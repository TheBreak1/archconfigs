#!/bin/bash

# archconfigs start script
# Gets some dependencies, clones the repository and starts the menu script
# 

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/TheBreak1/archconfigs.git"
CLONE_DIR="/tmp/archconfigs"
DEPENDENCIES=("wget" "git" "curl" "nano" "mc" "btop")  # Add your required dependencies

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

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        echo "Usage: sudo $0"
        exit 1
    fi
    print_success "Running with root privileges"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies: ${DEPENDENCIES[*]}"
    pacman -S --noconfirm --needed "${DEPENDENCIES[@]}" >/dev/null 2>&1 || print_warning "Some dependencies may not have installed correctly, continuing anyway"
}

# Function to configure Chaotic AUR repository
setup_chaotic_aur() {
    if grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
        print_status "Chaotic AUR repository already configured"
    else
        print_status "Configuring Chaotic AUR repository"
        # Import and locally sign Chaotic AUR key
        if pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com  || \
           pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keys.openpgp.org ; then
            pacman-key --lsign-key 3056513887B78AEB  || print_warning "Failed to locally sign Chaotic AUR key (continuing)"
        else
            print_warning "Failed to import Chaotic AUR key (continuing)"
        fi

        # Append repo stanza
        {
            echo ""
            echo "[chaotic-aur]"
            echo "Include = /etc/pacman.d/chaotic-mirrorlist"
        } | tee -a /etc/pacman.conf >/dev/null

        # Refresh databases
        pacman -Syy >/dev/null 2>&1 || true
    fi

    # Ensure keyring and mirrorlist are installed (install directly from Chaotic CDN)
    if pacman -Qi chaotic-keyring >/dev/null 2>&1 && pacman -Qi chaotic-mirrorlist >/dev/null 2>&1; then
        print_status "Chaotic keyring and mirrorlist already installed"
    else
        print_status "Installing Chaotic AUR keyring and mirrorlist from CDN"
        if pacman -U --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' >/dev/null 2>&1; then
            print_success "Chaotic keyring and mirrorlist installed"
        else
            print_warning "Failed to install chaotic keyring/mirrorlist from CDN (continuing)"
        fi
        pacman -Syy >/dev/null 2>&1 || true
    fi
}

# Function to install paru helper
install_paru() {
    print_status "Installing paru (from Chaotic AUR if available)"
    if pacman -S --noconfirm --needed paru >/dev/null 2>&1; then
        print_success "paru installed successfully"
    else
        print_warning "Failed to install paru via pacman"
    fi
}

# Function to clone repository and execute script
clone_and_execute_script() {
    print_status "Cloning repository from: $REPO_URL"
    
    # Remove existing clone directory if it exists
    if [[ -d "$CLONE_DIR" ]]; then
        print_warning "Directory $CLONE_DIR already exists, removing it"
        rm -rf "$CLONE_DIR"
    fi
    
    # Clone the repository
    if git clone "$REPO_URL" "$CLONE_DIR"; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository from $REPO_URL"
        exit 1
    fi
    
    # Wait a moment for files to be fully written
    sleep 1
    
    # Verify menu.sh exists in scripts folder
    if [[ ! -f "$CLONE_DIR/scripts/menu.sh" ]]; then
        print_error "menu.sh not found in $CLONE_DIR/scripts/"
        print_status "Contents of $CLONE_DIR:"
        ls -la "$CLONE_DIR"
        print_status "Contents of $CLONE_DIR/scripts/:"
        ls -la "$CLONE_DIR/scripts/"
        exit 1
    fi
    
    # Make the script executable
    chmod +x "$CLONE_DIR/scripts/menu.sh"
    
    print_status "Executing the menu script..."
    echo "=========================================="
    
    # Execute the script
    if bash "$CLONE_DIR/scripts/menu.sh"; then
        echo "=========================================="
        print_success "Menu script executed successfully"
    else
        echo "=========================================="
        print_error "Menu script execution failed with exit code $?"
        exit 1
    fi
    
    # Clean up
    rm -rf "$CLONE_DIR"
    print_status "Temporary files cleaned up"
}

# Function to handle script interruption
cleanup() {
    print_status "Cleaning up..."
    rm -rf "$CLONE_DIR"
    print_status "Cleanup completed"
    exit 1
}

# Set trap for cleanup on interrupt
trap cleanup SIGINT SIGTERM

# Main execution
main() {
    print_status "Starting installation process..."
    echo "=========================================="
    
    check_root
    install_dependencies
    setup_chaotic_aur
    install_paru
    clone_and_execute_script
    
    echo "=========================================="
    print_success "All operations completed successfully!"
}

# Run main function
main "$@"