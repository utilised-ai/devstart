#!/bin/zsh
# Python installation module for DevStart

install_python_env() {
    print_info "Setting up Python development environment..."
    log INFO "Starting Python environment installation"
    
    # Install pyenv
    if ! command_exists pyenv; then
        print_info "Installing pyenv..."
        safe_execute "Install pyenv" "brew install pyenv pyenv-virtualenv"
        
        # Add to shell config
        local shell_config="$HOME/.zshrc"
        if ! grep -q "PYENV_ROOT" "$shell_config"; then
            {
                echo 'export PYENV_ROOT="$HOME/.pyenv"'
                echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
                echo 'eval "$(pyenv init -)"'
                echo 'eval "$(pyenv virtualenv-init -)"'
            } >> "$shell_config"
        fi
        
        # Load pyenv for current session
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
        
        track_installation "brew:pyenv"
        track_installation "brew:pyenv-virtualenv"
    else
        print_success "pyenv is already installed"
    fi
    
    # Install Python
    print_info "Installing Python $PYTHON_VERSION..."
    if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
        safe_execute "Install Python $PYTHON_VERSION" "pyenv install $PYTHON_VERSION"
    fi
    safe_execute "Set Python $PYTHON_VERSION as global" "pyenv global $PYTHON_VERSION"
    
    # Verify Python installation
    if verify_installation "python" "$PYTHON_VERSION"; then
        print_success "Python $PYTHON_VERSION installed successfully"
    else
        print_error "Python installation verification failed"
        return 1
    fi
    
    # Install Poetry with specific version
    if ! command_exists poetry; then
        print_info "Installing Poetry $POETRY_VERSION..."
        safe_execute "Install Poetry" "curl -sSL https://install.python-poetry.org | python3 - --version $POETRY_VERSION"
        
        # Add Poetry to PATH
        export PATH="$HOME/.local/bin:$PATH"
        track_installation "dir:$HOME/.local/bin/poetry"
    else
        print_success "Poetry is already installed"
    fi
    
    # Install Python development tools
    install_python_tools
    
    print_success "Python environment setup complete!"
    log SUCCESS "Python environment installation completed"
}

install_python_tools() {
    print_info "Installing Python development tools..."
    
    # Upgrade pip first
    safe_execute "Upgrade pip" "python -m pip install --upgrade pip"
    
    # Install pipx for isolated tool installations
    if ! command_exists pipx; then
        safe_execute "Install pipx" "python -m pip install --user pipx"
        safe_execute "Ensure pipx path" "python -m pipx ensurepath"
    fi
    
    # Install development tools via pipx
    local python_tools=(
        "black==$BLACK_VERSION"
        "flake8==$FLAKE8_VERSION"
        "mypy==$MYPY_VERSION"
        "pytest==$PYTEST_VERSION"
        "ipython==$IPYTHON_VERSION"
        "jupyter==$JUPYTER_VERSION"
    )
    
    # Use parallel installation if available
    if [[ "$PARALLEL_ENABLED" == "true" ]] && command_exists install_python_tools_parallel; then
        install_python_tools_parallel "${python_tools[@]}"
    else
        # Fallback to sequential installation
        for tool_spec in "${python_tools[@]}"; do
            local tool_name="${tool_spec%%=*}"
            print_info "Installing $tool_name..."
            
            if safe_execute "Install $tool_name" "pipx install $tool_spec"; then
                track_installation "pip:$tool_name"
                verify_installation "$tool_name"
            fi
        done
    fi
}

# Function to uninstall Python environment
uninstall_python_env() {
    print_info "Removing Python environment..."
    
    # Remove pipx tools
    local python_tools=("black" "flake8" "mypy" "pytest" "ipython" "jupyter")
    for tool in "${python_tools[@]}"; do
        if command_exists "$tool"; then
            print_info "Removing $tool..."
            pipx uninstall "$tool" 2>/dev/null || true
        fi
    done
    
    # Remove Poetry
    if command_exists poetry; then
        print_info "Removing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 - --uninstall 2>/dev/null || true
    fi
    
    # Remove pyenv (but keep brew installation)
    if [[ -d "$HOME/.pyenv" ]]; then
        print_info "Removing Python versions..."
        rm -rf "$HOME/.pyenv/versions"
    fi
    
    print_success "Python environment removed"
}