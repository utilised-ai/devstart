#!/bin/zsh
# Node.js installation module for DevStart

install_nodejs_env() {
    print_info "Setting up Node.js development environment..."
    log INFO "Starting Node.js environment installation"
    
    # Install nvm (Node Version Manager)
    if ! command_exists nvm; then
        print_info "Installing nvm version $NVM_VERSION..."
        safe_execute "Install nvm" "curl -o- \"https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh\" | bash"
        
        # Load nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        track_installation "dir:$HOME/.nvm"
    else
        print_success "nvm is already installed"
    fi
    
    # Install specific Node.js version
    print_info "Installing Node.js $NODE_VERSION (LTS)..."
    safe_execute "Install Node.js $NODE_VERSION" "nvm install $NODE_VERSION"
    safe_execute "Set Node.js $NODE_VERSION as default" "nvm use $NODE_VERSION && nvm alias default $NODE_VERSION"
    
    # Verify Node.js installation
    if verify_installation "node" "$NODE_VERSION"; then
        print_success "Node.js $NODE_VERSION installed successfully"
    else
        print_error "Node.js installation verification failed"
        return 1
    fi
    
    # Install global npm packages with specific versions
    install_npm_packages
    
    print_success "Node.js environment setup complete!"
    log SUCCESS "Node.js environment installation completed"
}

install_npm_packages() {
    print_info "Installing essential npm packages..."
    
    local npm_packages=(
        "yarn@$YARN_VERSION"
        "pnpm@$PNPM_VERSION"
        "typescript@$TYPESCRIPT_VERSION"
        "ts-node@$TS_NODE_VERSION"
        "nodemon@$NODEMON_VERSION"
        "pm2@$PM2_VERSION"
        "serve@$SERVE_VERSION"
        "http-server@$HTTP_SERVER_VERSION"
    )
    
    # Use parallel installation if available
    if [[ "$PARALLEL_ENABLED" == "true" ]] && command_exists install_npm_packages_parallel; then
        install_npm_packages_parallel "${npm_packages[@]}"
    else
        # Fallback to sequential installation
        for package in "${npm_packages[@]}"; do
            local package_name="${package%@*}"
            print_info "Installing $package..."
            
            if safe_execute "Install npm package $package" "npm install -g $package"; then
                track_installation "npm:$package_name"
                verify_installation "$package_name"
            fi
        done
    fi
    
    # Install React development tools (using npx is now recommended instead of global installs)
    print_info "Framework CLIs will be available via npx (recommended approach)"
}

# Function to uninstall Node.js environment
uninstall_nodejs_env() {
    print_info "Removing Node.js environment..."
    
    # Remove global npm packages
    local npm_packages=("yarn" "pnpm" "typescript" "ts-node" "nodemon" "pm2" "serve" "http-server")
    for package in "${npm_packages[@]}"; do
        if command_exists "$package"; then
            print_info "Removing $package..."
            npm uninstall -g "$package" 2>/dev/null || true
        fi
    done
    
    # Remove nvm and Node.js
    if [[ -d "$HOME/.nvm" ]]; then
        print_info "Removing nvm and all Node.js versions..."
        rm -rf "$HOME/.nvm"
        
        # Clean up shell config
        for config in ~/.zshrc ~/.bashrc ~/.profile; do
            if [[ -f "$config" ]]; then
                sed -i.bak '/NVM_DIR/d' "$config"
                sed -i.bak '/nvm.sh/d' "$config"
            fi
        done
    fi
    
    print_success "Node.js environment removed"
}