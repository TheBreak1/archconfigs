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

# Function to check if running in desktop environment
check_desktop_environment() {
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        print_success "Running in desktop environment (X11/Wayland)"
        return 0
    else
        print_error "This script must be run from a desktop environment (X11/Wayland), not from TTY."
        print_status "Please run this script from a terminal within your desktop environment."
        return 1
    fi
}

# Function to check and handle resume flag
check_resume_flag() {
    FLAG_FILE="$HOME/.osu_stable_install_flag"
    
    if [[ -f "$FLAG_FILE" ]]; then
        print_warning "Resume flag detected. Previous installation was interrupted."
        print_status "Continuing from where we left off..."
        
        # Read the flag to see where we left off
        local flag_content=$(cat "$FLAG_FILE")
        case $flag_content in
            "copy_stable_files_complete")
                print_status "Stable files already copied. Proceeding to wine-osu setup..."
                setup_wine_osu || exit 1
                ;;
            *)
                print_warning "Unknown flag content: $flag_content"
                print_status "Starting fresh installation..."
                rm -f "$FLAG_FILE"
                ;;
        esac
        return 0
    fi
    return 1
}

# Function to create resume flag
create_resume_flag() {
    FLAG_FILE="$HOME/.osu_stable_install_flag"
    echo "$1" > "$FLAG_FILE"
    print_status "Created resume flag: $1"
}

# Function to remove resume flag
remove_resume_flag() {
    FLAG_FILE="$HOME/.osu_stable_install_flag"
    if [[ -f "$FLAG_FILE" ]]; then
        rm -f "$FLAG_FILE"
        print_status "Removed resume flag"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install extended dependency list for osu!/Wine environment
    if sudo pacman -S --noconfirm --needed \
        giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
        mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
        lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
        sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
        ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 \
        lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader lib32-nvidia-utils \
        winetricks; then
        print_success "Dependencies installed successfully!"
    else
        print_error "Failed to install dependencies"
        return 1
    fi
}

# Function to check and install pipewire-media-session
install_pipewire_media_session() {
    print_status "Checking pipewire-media-session installation..."
    
    # Check if pipewire-media-session is already installed
    if pacman -Q pipewire-media-session >/dev/null 2>&1; then
        print_success "pipewire-media-session is already installed"
        return 0
    fi
    
    print_status "Installing pipewire-media-session..."
    # Use --ask=4 to automatically answer "yes" to wireplumber override
    if sudo pacman -S --noconfirm --ask=4 pipewire-media-session; then
        print_success "pipewire-media-session installed successfully!"
    else
        print_error "Failed to install pipewire-media-session"
        return 1
    fi
}

# Function to downgrade wine to x86 compatible version
downgrade_wine() {
    print_status "Downgrading wine to x86 compatible version..."
    
    # Create Downloads directory and navigate to it
    mkdir -p ~/Downloads && cd ~/Downloads
    
    # Download and install wine 9.22-1
    if wget https://files.lopij.xyz/files/94b1719101a66673.zst; then
        print_status "Renaming downloaded file to wine-9.22-1-x86_64.pkg.tar.zst..."
        mv 94b1719101a66673.zst wine-9.22-1-x86_64.pkg.tar.zst
        print_success "File renamed successfully!"
        
        if sudo pacman -U wine-9.22-1-x86_64.pkg.tar.zst && cd; then
            print_success "Wine downgraded successfully!"
        else
            print_error "Failed to install wine package"
            return 1
        fi
    else
        print_error "Failed to download wine package"
        return 1
    fi
}

# Function to create wineprefix
create_wineprefix() {
    print_status "Creating wineprefix with required components..."
    print_warning "This process may take several minutes and may require user interaction."
    print_warning "Do not restart during installation!"
    
    # Create wineprefix with dotnet45, cjkfonts, and gdiplus
    if WINEARCH=win32 WINEPREFIX=~/.wineosu winetricks dotnet45 cjkfonts gdiplus; then
        print_success "Wineprefix created successfully!"
    else
        print_error "Failed to create wineprefix"
        return 1
    fi
}

# Function to download and install osu!
install_osu() {
    print_status "Downloading osu! installer..."
    
    # Create osu directory if it doesn't exist
    mkdir -p ~/osu
    
    # Download osu! installer
    if wget --output-document ~/osu/osu\!.exe https://m1.ppy.sh/r/osu\!install.exe; then
        print_success "osu! installer downloaded successfully!"
    else
        print_error "Failed to download osu! installer"
        return 1
    fi
    
    print_status "Running osu! installer..."
    print_warning "The osu! installer will now open. Follow the installation prompts."
    print_warning "Do not restart during installation!"
    
    # Run osu! installer with Wine
    WINEARCH=win32 WINEPREFIX=~/.wineosu wine ~/osu/osu\!.exe
    print_success "osu! installation completed!"
    
    # Warn about game launch and ask to close it
    print_warning "osu! will now launch automatically."
    print_warning "Please close the game when you're done testing it."
    echo
    read -p "Press Enter when you have closed osu! to continue..."
}

# Function to download and setup wine-osu
setup_wine_osu() {
    print_status "Downloading and setting up wine-osu..."
    
    # Download, extract, and setup wine-osu
    if cd ~/Downloads && wget https://files.lopij.xyz/files/981ea24e3c6662bc.xz -O wine-osu-7.15.2-x86_64.tar.xz && tar -xvf wine-osu-7.15.2-x86_64.tar.xz && cp -r wine-osu ~/wine-osu && rm -rf wine-osu && cd; then
        print_success "wine-osu setup completed successfully!"
        # Remove resume flag after successful completion
        remove_resume_flag
    else
        print_error "Failed to setup wine-osu"
        return 1
    fi
}


# Function to copy stable files
copy_stable_files() {
    print_status "Copying stable files..."
    
    # Get the script directory to find the stable_files folder
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    STABLE_FILES_DIR="$SCRIPT_DIR/../stable_files"
    
    # Check if the stable_files directory exists
    if [[ ! -d "$STABLE_FILES_DIR" ]]; then
        print_error "stable_files directory not found: $STABLE_FILES_DIR"
        return 1
    fi
    
    # Create ~/.local/bin directory if it doesn't exist
    mkdir -p ~/.local/bin
    
    # Copy osu script to ~/.local/bin/osu
    print_status "Copying osu script to ~/.local/bin/osu..."
    if cp "$STABLE_FILES_DIR/osu" ~/.local/bin/osu; then
        print_success "osu script copied successfully!"
        # Make it executable
        chmod +x ~/.local/bin/osu
    else
        print_error "Failed to copy osu script"
        return 1
    fi
    
    # Create ~/.local/share/applications directory if it doesn't exist
    mkdir -p ~/.local/share/applications
    
    # Copy osu.desktop to ~/.local/share/applications/osu.desktop
    print_status "Copying osu.desktop to ~/.local/share/applications/osu.desktop..."
    if cp "$STABLE_FILES_DIR/osu.desktop" ~/.local/share/applications/osu.desktop; then
        print_success "osu.desktop copied successfully!"
    else
        print_error "Failed to copy osu.desktop"
        return 1
    fi
    
    # Create resume flag after successful completion
    create_resume_flag "copy_stable_files_complete"
}

# Main execution
main() {
    # Check if we need to resume from a previous installation
    if check_resume_flag; then
        return 0
    fi
    
    # Fresh installation
    check_desktop_environment || exit 1
    install_dependencies || exit 1
    install_pipewire_media_session || exit 1
    downgrade_wine || exit 1
    create_wineprefix || exit 1
    copy_stable_files || exit 1
    install_osu || exit 1
    setup_wine_osu || exit 1
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi