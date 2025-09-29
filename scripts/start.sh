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
REPO_URL="https://github.com/yourusername/archconfigs.git"  # Replace with your actual repo
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
    print_status "Checking and installing dependencies..."
    
    local missing_deps=()
    
    # Check which dependencies are missing
    for dep in "${DEPENDENCIES[@]}"; do
        if ! pacman -Qi "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        print_success "All dependencies are already installed"
        return 0
    fi
    
    print_status "Installing missing dependencies: ${missing_deps[*]}"
    pacman -S --noconfirm --needed "${missing_deps[@]}"
    
    # Verify installation
    for dep in "${missing_deps[@]}"; do
        if pacman -Qi "$dep" &>/dev/null; then
            print_success "$dep installed successfully"
        else
            print_error "Failed to install $dep"
            return 1
        fi
    done
    
    print_success "All dependencies installed successfully"
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
    
    # Check if the menu script exists
    local menu_script="$CLONE_DIR/menu.sh"
    if [[ ! -f "$menu_script" ]]; then
        print_error "Menu script not found at $menu_script"
        print_status "Available files in repository:"
        ls -la "$CLONE_DIR"
        exit 1
    fi
    
    # Make the script executable
    chmod +x "$menu_script"
    
    print_status "Executing the menu script..."
    echo "=========================================="
    
    # Execute the script
    if bash "$menu_script"; then
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