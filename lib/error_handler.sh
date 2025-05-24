#!/bin/zsh
# Error handling and rollback functionality for DevStart

# Global variables for error tracking
INSTALLATION_LOG="${HOME}/.devstart/installation.log"
ERROR_LOG="${HOME}/.devstart/error.log"
ROLLBACK_LOG="${HOME}/.devstart/rollback.log"
INSTALLED_TOOLS=()
FAILED_STEP=""

# Create log directory
mkdir -p "${HOME}/.devstart"

# Initialize logs
init_logs() {
    echo "DevStart Installation Log - $(date)" > "$INSTALLATION_LOG"
    echo "DevStart Error Log - $(date)" > "$ERROR_LOG"
    : > "$ROLLBACK_LOG"  # Empty rollback log
}

# Log function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)
            echo "[$timestamp] INFO: $message" >> "$INSTALLATION_LOG"
            ;;
        ERROR)
            echo "[$timestamp] ERROR: $message" >> "$ERROR_LOG"
            echo "[$timestamp] ERROR: $message" >> "$INSTALLATION_LOG"
            ;;
        SUCCESS)
            echo "[$timestamp] SUCCESS: $message" >> "$INSTALLATION_LOG"
            ;;
        ROLLBACK)
            echo "[$timestamp] ROLLBACK: $message" >> "$ROLLBACK_LOG"
            ;;
    esac
}

# Track installed tools for potential rollback
track_installation() {
    local tool=$1
    INSTALLED_TOOLS+=("$tool")
    log INFO "Tracked installation: $tool"
}

# Error handler
handle_error() {
    local exit_code=$?
    local error_message="${1:-Unknown error occurred}"
    local failed_command="${2:-Unknown command}"
    
    # Don't handle errors in dry run mode
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "${YELLOW}[DRY RUN]${NC} Would handle error: $error_message"
        return 0
    fi
    
    FAILED_STEP="$failed_command"
    
    print_error "Installation failed!"
    echo
    echo "${RED}Error Details:${NC}"
    echo "  • Exit code: $exit_code"
    echo "  • Failed step: $failed_command"
    echo "  • Error message: $error_message"
    echo
    
    log ERROR "Failed at: $failed_command"
    log ERROR "Exit code: $exit_code"
    log ERROR "Message: $error_message"
    
    # Show recovery options
    echo "${YELLOW}Recovery Options:${NC}"
    echo "  1) Try to continue from where it failed"
    echo "  2) Rollback all changes"
    echo "  3) View detailed error log"
    echo "  4) Exit and try again later"
    echo
    echo -n "Choose an option (1-4): "
    read recovery_choice
    
    case $recovery_choice in
        1)
            recover_and_continue
            ;;
        2)
            perform_rollback
            ;;
        3)
            less "$ERROR_LOG"
            handle_error "$error_message" "$failed_command"
            ;;
        4)
            save_progress
            exit 1
            ;;
        *)
            echo "Invalid choice. Exiting..."
            save_progress
            exit 1
            ;;
    esac
}

# Try to recover and continue
recover_and_continue() {
    echo
    print_info "Attempting to continue installation..."
    log INFO "User chose to continue after error"
    
    # Return to main script with special flag
    RECOVERY_MODE=true
    return 0
}

# Rollback function
perform_rollback() {
    echo
    print_warning "Starting rollback process..."
    log ROLLBACK "Starting rollback for ${#INSTALLED_TOOLS[@]} tools"
    
    for tool in "${INSTALLED_TOOLS[@]}"; do
        echo -n "  Removing $tool... "
        
        case $tool in
            brew:*)
                # Homebrew package
                package=${tool#brew:}
                if brew uninstall "$package" 2>/dev/null; then
                    echo "✓"
                    log ROLLBACK "Removed brew package: $package"
                else
                    echo "✗ (may not have been fully installed)"
                fi
                ;;
            cask:*)
                # Homebrew cask
                app=${tool#cask:}
                if brew uninstall --cask "$app" 2>/dev/null; then
                    echo "✓"
                    log ROLLBACK "Removed cask: $app"
                else
                    echo "✗ (may not have been fully installed)"
                fi
                ;;
            npm:*)
                # npm global package
                package=${tool#npm:}
                if npm uninstall -g "$package" 2>/dev/null; then
                    echo "✓"
                    log ROLLBACK "Removed npm package: $package"
                else
                    echo "✗"
                fi
                ;;
            pip:*)
                # Python package
                package=${tool#pip:}
                if pip uninstall -y "$package" 2>/dev/null; then
                    echo "✓"
                    log ROLLBACK "Removed pip package: $package"
                else
                    echo "✗"
                fi
                ;;
            dir:*)
                # Directory
                dir=${tool#dir:}
                if [[ -d "$dir" ]]; then
                    rm -rf "$dir"
                    echo "✓"
                    log ROLLBACK "Removed directory: $dir"
                else
                    echo "✗ (not found)"
                fi
                ;;
            *)
                echo "✗ (unknown type)"
                ;;
        esac
    done
    
    echo
    print_info "Rollback complete. Check $ROLLBACK_LOG for details."
    exit 0
}

# Save progress for resume
save_progress() {
    local progress_file="${HOME}/.devstart/progress.conf"
    
    {
        echo "# DevStart Progress File - $(date)"
        echo "LAST_SUCCESSFUL_STEP=\"$LAST_SUCCESSFUL_STEP\""
        echo "FAILED_STEP=\"$FAILED_STEP\""
        echo "ENVIRONMENT_CHOICE=\"$choice\""
        echo "IS_BEGINNER=\"$IS_BEGINNER\""
        echo "INSTALLED_TOOLS=(${INSTALLED_TOOLS[@]})"
    } > "$progress_file"
    
    log INFO "Progress saved to $progress_file"
    echo
    print_info "Progress saved. Run the installer again to resume."
}

# Load previous progress
load_progress() {
    local progress_file="${HOME}/.devstart/progress.conf"
    
    if [[ -f "$progress_file" ]]; then
        echo
        print_question "Previous installation detected. Resume from where you left off? (y/n)"
        echo -n "Your choice: "
        read resume_choice
        
        if [[ "$resume_choice" == "y" || "$resume_choice" == "Y" ]]; then
            source "$progress_file"
            RESUME_MODE=true
            log INFO "Resuming from previous installation"
            return 0
        fi
    fi
    
    RESUME_MODE=false
    return 1
}

# Wrapper for commands with error handling
safe_execute() {
    local description=$1
    shift
    local command="$@"
    
    log INFO "Executing: $description"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "${BLUE}[DRY RUN]${NC} Would execute: $command"
        
        # Simulate success for verification checks
        if [[ "$description" =~ "Verify" ]]; then
            sleep 0.1  # Simulate work
        fi
        
        return 0
    fi
    
    # Execute command and capture output
    local output_file=$(mktemp)
    local error_file=$(mktemp)
    
    if eval "$command" > "$output_file" 2> "$error_file"; then
        LAST_SUCCESSFUL_STEP="$description"
        log SUCCESS "$description completed"
        
        # Clean up temp files
        rm -f "$output_file" "$error_file"
        return 0
    else
        local exit_code=$?
        local error_output=$(cat "$error_file")
        
        # Log the error
        log ERROR "Command failed: $command"
        log ERROR "Error output: $error_output"
        
        # Clean up temp files
        rm -f "$output_file" "$error_file"
        
        # Call error handler
        handle_error "$error_output" "$description"
        
        # If we get here, user chose to continue
        if [[ "$RECOVERY_MODE" == "true" ]]; then
            RECOVERY_MODE=false
            return 0
        fi
        
        return $exit_code
    fi
}

# Check if a tool is installed
is_installed() {
    local tool=$1
    command -v "$tool" >/dev/null 2>&1
}

# Verify installation
verify_installation() {
    local tool=$1
    local expected_version=$2
    
    if is_installed "$tool"; then
        if [[ -n "$expected_version" ]]; then
            local actual_version=$("$tool" --version 2>/dev/null | head -n1)
            log INFO "Verified $tool installation: $actual_version"
        else
            log INFO "Verified $tool is installed"
        fi
        return 0
    else
        log ERROR "$tool installation verification failed"
        return 1
    fi
}

# Setup error trap
setup_error_trap() {
    # Don't trap errors in dry run mode
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
        trap 'handle_error "Unexpected error" "$BASH_COMMAND"' ERR
    fi
}

# Cleanup function
cleanup() {
    # Remove any temporary files (suppress error if no matches)
    rm -f /tmp/devstart_* 2>/dev/null || true
    
    # Save final state
    if [[ ${#INSTALLED_TOOLS[@]} -gt 0 ]]; then
        save_progress
    fi
}

# Setup cleanup trap
setup_cleanup_trap() {
    trap cleanup EXIT
}