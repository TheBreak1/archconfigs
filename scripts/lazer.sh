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

# Retry helper for paru installs to mitigate transient network/EOF errors
install_with_retry() {
    local attempts=0
    local max_attempts=3
    local delay_seconds=5

    while (( attempts < max_attempts )); do
        paru -S --noconfirm --needed "$@" && return 0
        attempts=$((attempts + 1))
        if (( attempts < max_attempts )); then
            print_warning "Install failed (attempt ${attempts}/${max_attempts}). Retrying in ${delay_seconds}s..."
            sleep "${delay_seconds}"
        fi
    done

    return 1
}

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

# Install the chosen package, osu-handler, and osu-mime using paru with retries
print_status "Installing packages with paru..."
if install_with_retry "$package" osu-handler osu-mime; then
    echo ""
    print_success "Installation complete!"
    print_status "Installed packages:"
    echo -e "${GREEN}-${NC} $package"
    echo -e "${GREEN}-${NC} osu-handler"
    echo -e "${GREEN}-${NC} osu-mime"
else
    echo ""
    print_error "Installation failed after multiple attempts. This may be a temporary network or AUR issue."
    print_status "Tips: check internet connectivity, update ca-certificates, or try again later."
    exit 1
fi
