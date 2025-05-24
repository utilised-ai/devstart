#!/bin/zsh
# Platform detection and compatibility checking for DevStart

# Global platform variables
PLATFORM_ARCH=""
PLATFORM_OS_VERSION=""
PLATFORM_CHIP=""
PLATFORM_MEMORY_GB=0
PLATFORM_DISK_FREE_GB=0
HOMEBREW_PREFIX=""
IS_APPLE_SILICON=false

# Detect platform details
detect_platform() {
    print_info "Detecting system configuration..."
    
    # Detect architecture
    PLATFORM_ARCH=$(uname -m)
    
    # Detect macOS version
    PLATFORM_OS_VERSION=$(sw_vers -productVersion)
    
    # Detect chip type
    if [[ "$PLATFORM_ARCH" == "arm64" ]]; then
        IS_APPLE_SILICON=true
        PLATFORM_CHIP=$(system_profiler SPHardwareDataType | grep "Chip" | cut -d: -f2 | xargs)
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        IS_APPLE_SILICON=false
        PLATFORM_CHIP=$(sysctl -n machdep.cpu.brand_string)
        HOMEBREW_PREFIX="/usr/local"
    fi
    
    # Detect memory
    local memory_bytes=$(sysctl -n hw.memsize)
    PLATFORM_MEMORY_GB=$((memory_bytes / 1024 / 1024 / 1024))
    
    # Detect available disk space
    local disk_info=$(df -g / | tail -1)
    PLATFORM_DISK_FREE_GB=$(echo "$disk_info" | awk '{print $4}')
    
    # Log platform details
    log INFO "Platform: macOS $PLATFORM_OS_VERSION"
    log INFO "Architecture: $PLATFORM_ARCH"
    log INFO "Chip: $PLATFORM_CHIP"
    log INFO "Memory: ${PLATFORM_MEMORY_GB}GB"
    log INFO "Free disk space: ${PLATFORM_DISK_FREE_GB}GB"
}

# Check macOS compatibility
check_macos_compatibility() {
    local min_version="11.0"  # Big Sur minimum
    
    # Compare versions
    if ! is_version_greater_or_equal "$PLATFORM_OS_VERSION" "$min_version"; then
        print_error "DevStart requires macOS $min_version or later"
        print_error "You are running macOS $PLATFORM_OS_VERSION"
        return 1
    fi
    
    # Check specific version issues
    case $PLATFORM_OS_VERSION in
        11.*)
            print_warning "macOS Big Sur detected. Some tools may require updates."
            ;;
        12.*)
            print_info "macOS Monterey detected. Good compatibility."
            ;;
        13.*)
            print_info "macOS Ventura detected. Good compatibility."
            ;;
        14.*)
            print_info "macOS Sonoma detected. Latest compatibility."
            ;;
        15.*)
            print_info "macOS Sequoia detected. Newest version - some tools may need updates."
            ;;
        *)
            print_warning "Unknown macOS version. Proceeding with caution."
            ;;
    esac
    
    return 0
}

# Check system requirements
check_system_requirements() {
    echo
    print_info "Checking system requirements..."
    echo
    
    local issues=0
    
    # Show system info
    echo "${CYAN}System Information:${NC}"
    echo "  • macOS: $PLATFORM_OS_VERSION"
    echo "  • Chip: $PLATFORM_CHIP"
    echo "  • Architecture: $PLATFORM_ARCH $([ "$IS_APPLE_SILICON" = true ] && echo "(Apple Silicon)" || echo "(Intel)")"
    echo "  • Memory: ${PLATFORM_MEMORY_GB}GB RAM"
    echo "  • Free disk space: ${PLATFORM_DISK_FREE_GB}GB"
    echo
    
    # Check minimum requirements
    echo "${CYAN}Requirement Checks:${NC}"
    
    # Memory check (recommend 8GB minimum)
    if [[ $PLATFORM_MEMORY_GB -lt 8 ]]; then
        print_warning "Low memory: ${PLATFORM_MEMORY_GB}GB (8GB recommended)"
        ((issues++))
    else
        print_success "Memory: ${PLATFORM_MEMORY_GB}GB ✓"
    fi
    
    # Disk space check based on environment
    local required_space_gb=0
    case $choice in
        1) required_space_gb=10 ;;  # Full stack
        2) required_space_gb=5 ;;   # Python
        3) required_space_gb=15 ;;  # Mobile (Android Studio is large)
        4) required_space_gb=10 ;;  # DevOps
        5) required_space_gb=2 ;;   # Basic
        *) required_space_gb=5 ;;   # Default
    esac
    
    if [[ $PLATFORM_DISK_FREE_GB -lt $required_space_gb ]]; then
        print_error "Insufficient disk space: ${PLATFORM_DISK_FREE_GB}GB free (${required_space_gb}GB required)"
        ((issues++))
    else
        print_success "Disk space: ${PLATFORM_DISK_FREE_GB}GB free ✓"
    fi
    
    # Architecture-specific checks
    if [[ "$IS_APPLE_SILICON" == "true" ]]; then
        print_success "Apple Silicon detected - native performance ✓"
        
        # Check for Rosetta 2
        if ! pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
            print_warning "Rosetta 2 not installed (needed for some Intel-only tools)"
            echo "  Install with: softwareupdate --install-rosetta"
        fi
    else
        print_info "Intel Mac detected - all tools compatible"
    fi
    
    echo
    
    if [[ $issues -gt 0 ]]; then
        print_warning "Some requirements not met. Installation may have issues."
        if [[ "$SKIP_CONFIRMATIONS" != "y" ]]; then
            print_question "Continue anyway? (y/n)"
            echo -n "Your choice: "
            read continue_choice
            if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
                return 1
            fi
        fi
    fi
    
    return 0
}

# Version comparison helper
is_version_greater_or_equal() {
    local version1=$1
    local version2=$2
    
    # Convert versions to comparable format
    local v1_parts=(${(s:.:)version1})
    local v2_parts=(${(s:.:)version2})
    
    # Compare each part
    for i in {1..3}; do
        local v1_part=${v1_parts[$i]:-0}
        local v2_part=${v2_parts[$i]:-0}
        
        if [[ $v1_part -gt $v2_part ]]; then
            return 0
        elif [[ $v1_part -lt $v2_part ]]; then
            return 1
        fi
    done
    
    return 0
}

# Setup Homebrew path for current session
setup_homebrew_path() {
    if [[ "$IS_APPLE_SILICON" == "true" ]]; then
        # Ensure Homebrew is in PATH for Apple Silicon
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        # Intel Mac Homebrew path
        if [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

# Get Homebrew prefix
get_homebrew_prefix() {
    if command_exists brew; then
        brew --prefix
    else
        echo "$HOMEBREW_PREFIX"
    fi
}

# Check if running in a VM
check_virtualization() {
    if sysctl -n machdep.cpu.features | grep -q "VMM"; then
        print_warning "Virtual machine detected. Performance may be reduced."
        return 0
    fi
    
    # Check for common VM indicators
    if system_profiler SPHardwareDataType | grep -q -E "(VMware|VirtualBox|Parallels|QEMU)"; then
        print_warning "Virtual machine detected. Some features may not work correctly."
        return 0
    fi
    
    return 1
}

# Get optimal installation settings based on platform
get_platform_optimizations() {
    local optimizations=()
    
    if [[ "$IS_APPLE_SILICON" == "true" ]]; then
        # Apple Silicon optimizations
        optimizations+=(
            "Use native ARM builds when available"
            "Avoid x86-only tools"
            "Enable parallel compilation with -j$(sysctl -n hw.ncpu)"
        )
    fi
    
    if [[ $PLATFORM_MEMORY_GB -lt 16 ]]; then
        # Low memory optimizations
        optimizations+=(
            "Limit concurrent installations"
            "Close other applications during install"
            "Consider lighter alternatives"
        )
    fi
    
    if [[ $PLATFORM_DISK_FREE_GB -lt 20 ]]; then
        # Low disk space optimizations
        optimizations+=(
            "Clean Homebrew cache after install"
            "Use pnpm for Node.js projects (saves space)"
            "Regular cleanup of unused packages"
        )
    fi
    
    if [[ ${#optimizations[@]} -gt 0 ]]; then
        echo
        print_info "Platform-specific recommendations:"
        for opt in "${optimizations[@]}"; do
            echo "  • $opt"
        done
    fi
}

# Initialize platform detection
init_platform_detection() {
    detect_platform
    setup_homebrew_path
    
    if ! check_macos_compatibility; then
        exit 1
    fi
    
    if ! check_system_requirements; then
        exit 1
    fi
    
    get_platform_optimizations
}