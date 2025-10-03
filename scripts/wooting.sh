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

# Copy Wooting udev rules to system directory
print_status "Copying Wooting udev rules..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory (archconfigs root)
ARCHCONFIGS_DIR="$(dirname "$SCRIPT_DIR")"

sudo cp "$ARCHCONFIGS_DIR/configs/70-wooting.rules" /etc/udev/rules.d/
sudo chmod 644 /etc/udev/rules.d/70-wooting.rules

print_success "Wooting udev rules installed successfully!"
print_warning "You may need to reload udev rules or restart your system for changes to take effect."
