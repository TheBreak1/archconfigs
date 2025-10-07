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

# Ensure paru runs as the invoking non-root user if this script is executed with sudo
run_paru() {
    if [ "$EUID" -eq 0 ]; then
        if [ -z "$SUDO_USER" ]; then
            print_error "Running as root but SUDO_USER is not set. Cannot execute paru as root."
            exit 1
        fi
        sudo -H -u "$SUDO_USER" --preserve-env=PATH,XDG_CACHE_HOME,XDG_CONFIG_HOME paru "$@"
    else
        paru "$@"
    fi
}

# (no retry logic needed)

# Check if paru is installed
if ! command -v paru &> /dev/null; then
    print_error "paru is not installed when it should be. Please restart the script or install it manually."
    print_status "You can install it with: sudo pacman -S paru if Chaotic AUR is configured."
    print_status "If not, please refer to paru's Github page."
    exit 1
fi

print_success "paru is installed, continuing..."

# Ask user to choose between osu-lazer-bin and osu-lazer-tachyon-bin
echo ""
print_status "Choose which osu!lazer version to install:"
echo -e "${GREEN}1)${NC} osu!lazer"
echo -e "${GREEN}2)${NC} osu!lazer tachyon"
echo -e "${GREEN}3)${NC} Cancel installation"
echo ""
read -p "Enter your choice (1, 2, or 3): " choice

case $choice in
    1)
        package="osu-lazer-bin"
        print_status "Installing osu-lazer-bin..."
        ;;
    2)
        package="osu-lazer-tachyon-bin"
        print_status "Installing osu-lazer-tachyon-bin..."
        ;;
    3)
        print_warning "Installation cancelled by user."
        exit 0
        ;;
    *)
        print_error "Invalid choice. Please run the script again and choose 1, 2, or 3."
        exit 1
        ;;
esac

# Refresh package databases (helps with mirror issues)
print_status "Refreshing package databases..."
sudo pacman -Syy --noconfirm || true

# Install the chosen package and osu-mime using paru (single attempt)
print_status "Installing packages with paru..."
if [ "$EUID" -eq 0 ]; then
    if sudo -H -u "$SUDO_USER" --preserve-env=PATH,XDG_CACHE_HOME,XDG_CONFIG_HOME paru -S --noconfirm --needed "$package" osu-mime; then
        echo ""
        print_success "Installation complete!"
        print_status "Installed packages:"
        echo -e "${GREEN}-${NC} $package"
        echo -e "${GREEN}-${NC} osu-mime"
    else
        echo ""
        print_error "Installation failed. See Applist.md for manual installation."
        exit 1
    fi
else
    if paru -S --noconfirm --needed "$package" osu-mime; then
        echo ""
        print_success "Installation complete!"
        print_status "Installed packages:"
        echo -e "${GREEN}-${NC} $package"
        echo -e "${GREEN}-${NC} osu-mime"
    else
        echo ""
        print_error "Installation failed. See Applist.md for manual installation."
        exit 1
    fi
fi
