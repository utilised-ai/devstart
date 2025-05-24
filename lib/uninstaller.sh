#!/bin/zsh
# Uninstaller for DevStart

# Run uninstall mode
run_uninstall_mode() {
    clear
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${RED}                         DevStart Uninstaller${NC}"
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    print_warning "This will remove tools installed by DevStart."
    echo
    echo "What would you like to uninstall?"
    echo
    echo "  1) Everything (Full uninstall)"
    echo "  2) Node.js environment only"
    echo "  3) Python environment only"
    echo "  4) Databases only"
    echo "  5) Show installed components"
    echo "  6) Cancel"
    echo
    echo -n "Your choice (1-6): "
    read uninstall_choice
    
    case $uninstall_choice in
        1)
            uninstall_everything
            ;;
        2)
            uninstall_nodejs_env
            ;;
        3)
            uninstall_python_env
            ;;
        4)
            uninstall_databases
            ;;
        5)
            show_installed_components
            run_uninstall_mode
            ;;
        6)
            echo
            print_info "Uninstall cancelled."
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            run_uninstall_mode
            ;;
    esac
}

# Uninstall everything
uninstall_everything() {
    echo
    print_warning "This will remove:"
    echo "  • Node.js and all npm packages"
    echo "  • Python environments and tools"
    echo "  • All databases (PostgreSQL, MySQL, MongoDB, Redis)"
    echo "  • Shell enhancements (Oh My Zsh, Starship)"
    echo
    echo -n "Are you sure? (yes/no): "
    read confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Uninstall cancelled."
        return
    fi
    
    echo
    print_info "Starting full uninstall..."
    
    # Uninstall in reverse order
    uninstall_databases
    uninstall_python_env
    uninstall_nodejs_env
    uninstall_shell_enhancements
    
    # Clean up DevStart files
    cleanup_devstart_files
    
    echo
    print_success "DevStart has been uninstalled."
    echo
    print_info "Note: Basic tools (Git, VS Code, etc.) were not removed."
    print_info "To remove them, use: brew uninstall <tool-name>"
}

# Show installed components
show_installed_components() {
    echo
    echo "${CYAN}Installed Components:${NC}"
    echo
    
    # Check Node.js
    if command_exists node; then
        echo "${GREEN}✓${NC} Node.js $(node --version)"
        if command_exists npm; then
            echo "  • npm $(npm --version)"
        fi
        if command_exists yarn; then
            echo "  • yarn $(yarn --version)"
        fi
        if command_exists pnpm; then
            echo "  • pnpm $(pnpm --version)"
        fi
    else
        echo "${RED}✗${NC} Node.js not installed"
    fi
    
    echo
    
    # Check Python
    if command_exists pyenv; then
        echo "${GREEN}✓${NC} Python (via pyenv)"
        if pyenv versions | grep -q "$PYTHON_VERSION"; then
            echo "  • Python $PYTHON_VERSION"
        fi
        if command_exists poetry; then
            echo "  • Poetry $(poetry --version | cut -d' ' -f3)"
        fi
    else
        echo "${RED}✗${NC} Python environment not installed"
    fi
    
    echo
    
    # Check databases
    check_database_status
    
    echo
    
    # Check shell enhancements
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "${GREEN}✓${NC} Oh My Zsh installed"
    fi
    if command_exists starship; then
        echo "${GREEN}✓${NC} Starship prompt installed"
    fi
    
    echo
    echo -n "Press Enter to continue..."
    read
}

# Uninstall shell enhancements
uninstall_shell_enhancements() {
    print_info "Removing shell enhancements..."
    
    # Remove Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Removing Oh My Zsh..."
        rm -rf "$HOME/.oh-my-zsh"
        
        # Restore default .zshrc
        if [[ -f "$HOME/.zshrc.pre-oh-my-zsh" ]]; then
            mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc"
        fi
    fi
    
    # Remove Starship
    if command_exists starship; then
        print_info "Removing Starship..."
        brew uninstall starship 2>/dev/null || true
    fi
    
    # Clean up shell config
    for config in ~/.zshrc ~/.bashrc; do
        if [[ -f "$config" ]]; then
            # Remove DevStart additions
            sed -i.bak '/# DevStart/,/# End DevStart/d' "$config" 2>/dev/null || true
            # Remove starship init
            sed -i.bak '/eval "$(starship init/d' "$config" 2>/dev/null || true
        fi
    done
}

# Clean up DevStart files
cleanup_devstart_files() {
    print_info "Cleaning up DevStart files..."
    
    # Remove logs and progress files
    rm -rf "$HOME/.devstart"
    
    # Remove project structure (only if empty)
    for dir in ~/Dev/projects ~/Dev/sandbox ~/Dev/learning ~/Dev/tools; do
        if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir")" ]]; then
            rmdir "$dir" 2>/dev/null || true
        fi
    done
    
    # Try to remove main Dev directory if empty
    if [[ -d "$HOME/Dev" ]] && [[ -z "$(ls -A "$HOME/Dev")" ]]; then
        rmdir "$HOME/Dev" 2>/dev/null || true
    fi
}

# Dry run uninstall
dry_run_uninstall() {
    echo
    echo "${YELLOW}[DRY RUN] Would uninstall:${NC}"
    echo
    
    # Show what would be removed
    if command_exists node; then
        echo "  • Node.js and npm packages"
    fi
    if command_exists pyenv; then
        echo "  • Python environment and tools"
    fi
    if command_exists psql || command_exists mysql || command_exists mongod || command_exists redis-server; then
        echo "  • Databases"
    fi
    if [[ -d "$HOME/.oh-my-zsh" ]] || command_exists starship; then
        echo "  • Shell enhancements"
    fi
    
    echo
    echo "No changes would be made in dry run mode."
}