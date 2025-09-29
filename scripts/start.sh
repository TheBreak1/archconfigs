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
DEPENDENCIES=("wget" "git" "curl" "nano" "mc")  # Add your required dependencies

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
    
    # Verify menu.sh exists
    if [[ ! -f "$CLONE_DIR/menu.sh" ]]; then
        print_error "menu.sh not found in cloned repository"
        print_status "Contents of $CLONE_DIR:"
        ls -la "$CLONE_DIR"
        exit 1
    fi
    
    # Make the script executable
    chmod +x "$CLONE_DIR/menu.sh"
    
    print_status "Executing the menu script..."
    echo "=========================================="
    
    # Execute the script
    if bash "$CLONE_DIR/menu.sh"; then
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
    clone_and_execute_script
    
    echo "=========================================="
    print_success "All operations completed successfully!"
}

# Run main function
main "$@"