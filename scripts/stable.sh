#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Install required 32-bit libraries
print_status "Installing lib32-gnutls and lib32-libxcomposite..."

if sudo pacman -S --noconfirm lib32-gnutls lib32-libxcomposite; then
    print_success "lib32-gnutls and lib32-libxcomposite installed successfully!"
else
    print_error "Failed to install lib32-gnutls and lib32-libxcomposite."
    exit 1
fi

# Check if NVIDIA GPU is present
print_status "Checking for NVIDIA GPU..."

if lspci | grep -i nvidia > /dev/null 2>&1; then
    print_success "NVIDIA GPU detected!"
    
    # Check if lib32-nvidia-utils is already installed
    if pacman -Q lib32-nvidia-utils > /dev/null 2>&1; then
        print_warning "lib32-nvidia-utils is already installed."
        exit 0
    fi
    
    print_status "Installing lib32-nvidia-utils..."
    
    if sudo pacman -S --noconfirm lib32-nvidia-utils; then
        print_success "lib32-nvidia-utils installed successfully!"
    else
        print_error "Failed to install lib32-nvidia-utils."
        exit 1
    fi
else
    print_warning "No NVIDIA GPU detected. Skipping lib32-nvidia-utils installation."
fi
