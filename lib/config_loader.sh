#!/bin/zsh
# Configuration file loader for DevStart

# Load configuration from file
load_config_file() {
    local config_file=$1
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    print_info "Loading configuration from: $config_file"
    
    # Source the config file
    source "$config_file"
    
    # Validate configuration
    validate_config
    
    # Set global variables based on config
    apply_config
    
    log INFO "Configuration loaded from $config_file"
}

# Validate configuration values
validate_config() {
    local errors=0
    
    # Validate environment choice
    if [[ -n "$ENVIRONMENT" ]]; then
        if [[ ! "$ENVIRONMENT" =~ ^[1-6]$ ]]; then
            print_error "Invalid ENVIRONMENT value: $ENVIRONMENT (must be 1-6)"
            ((errors++))
        fi
    fi
    
    # Validate yes/no values
    local yes_no_vars=(
        IS_BEGINNER SKIP_CONFIRMATIONS INSTALL_NODEJS INSTALL_PYTHON
        INSTALL_DATABASES INSTALL_DOCKER INSTALL_MOBILE INSTALL_POSTGRESQL
        INSTALL_MYSQL INSTALL_MONGODB INSTALL_REDIS INSTALL_CURSOR
        INSTALL_OH_MY_ZSH INSTALL_STARSHIP CREATE_PROJECT_DIRS VERBOSE_LOGGING
    )
    
    for var in "${yes_no_vars[@]}"; do
        local value="${(P)var}"
        if [[ -n "$value" ]] && [[ ! "$value" =~ ^(yes|no|y|n|YES|NO|Y|N)$ ]]; then
            print_error "Invalid $var value: $value (must be yes or no)"
            ((errors++))
        fi
    done
    
    # Validate Git config if provided
    if [[ -n "$GIT_USERNAME" ]] && [[ -z "$GIT_EMAIL" ]]; then
        print_error "GIT_EMAIL must be provided when GIT_USERNAME is set"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        print_error "Configuration validation failed with $errors errors"
        exit 1
    fi
    
    print_success "Configuration validated successfully"
}

# Apply configuration to global variables
apply_config() {
    # Convert yes/no to y/n for internal use
    normalize_bool() {
        local value=$1
        case ${value,,} in
            yes|y) echo "y" ;;
            no|n) echo "n" ;;
            *) echo "$value" ;;
        esac
    }
    
    # Apply environment choice
    if [[ -n "$ENVIRONMENT" ]]; then
        export choice="$ENVIRONMENT"
        CONFIG_MODE=true
    fi
    
    # Apply user type
    if [[ -n "$IS_BEGINNER" ]]; then
        export IS_BEGINNER=$(normalize_bool "$IS_BEGINNER")
    fi
    
    # Apply skip confirmations
    if [[ -n "$SKIP_CONFIRMATIONS" ]]; then
        export SKIP_CONFIRMATIONS=$(normalize_bool "$SKIP_CONFIRMATIONS")
    fi
    
    # Apply Git configuration
    if [[ -n "$GIT_USERNAME" ]]; then
        export CONFIG_GIT_USERNAME="$GIT_USERNAME"
    fi
    if [[ -n "$GIT_EMAIL" ]]; then
        export CONFIG_GIT_EMAIL="$GIT_EMAIL"
    fi
    
    # Apply component selections
    export CONFIG_COMPONENTS=(
        INSTALL_NODEJS INSTALL_PYTHON INSTALL_DATABASES
        INSTALL_DOCKER INSTALL_MOBILE INSTALL_POSTGRESQL
        INSTALL_MYSQL INSTALL_MONGODB INSTALL_REDIS
        INSTALL_CURSOR INSTALL_OH_MY_ZSH INSTALL_STARSHIP
    )
    
    # Apply project root
    if [[ -n "$PROJECT_ROOT" ]]; then
        export DEV_ROOT="$PROJECT_ROOT"
    else
        export DEV_ROOT="$HOME/Dev"
    fi
    
    # Apply logging preference
    if [[ -n "$VERBOSE_LOGGING" ]] && [[ $(normalize_bool "$VERBOSE_LOGGING") == "y" ]]; then
        export VERBOSE=true
    fi
}

# Override prompts with config values
override_prompts() {
    # Override show_menu if environment is set
    if [[ -n "$choice" ]] && [[ "$CONFIG_MODE" == "true" ]]; then
        original_show_menu() { :; }  # No-op
        
        # Show what was selected
        echo
        print_info "Using configuration file settings:"
        echo "  • Environment: Option $choice"
        echo "  • Beginner mode: $IS_BEGINNER"
        if [[ -n "$CONFIG_GIT_USERNAME" ]]; then
            echo "  • Git user: $CONFIG_GIT_USERNAME <$CONFIG_GIT_EMAIL>"
        fi
        echo
        
        if [[ "$SKIP_CONFIRMATIONS" != "y" ]]; then
            print_question "Proceed with these settings? (y/n)"
            echo -n "Your choice: "
            read confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                print_info "Installation cancelled."
                exit 0
            fi
        fi
    fi
}

# Custom install based on component selection
custom_component_install() {
    if [[ "$choice" == "6" ]] || [[ "$CUSTOM_INSTALL" == "true" ]]; then
        print_info "Installing selected components..."
        
        # Install based on individual component settings
        if [[ $(normalize_bool "${INSTALL_NODEJS:-no}") == "y" ]]; then
            start_step "Setting up Node.js environment"
            install_nodejs_env
            complete_step "Node.js environment ready"
        fi
        
        if [[ $(normalize_bool "${INSTALL_PYTHON:-no}") == "y" ]]; then
            start_step "Setting up Python environment"
            install_python_env
            complete_step "Python environment ready"
        fi
        
        # Install selected databases
        local selected_dbs=()
        [[ $(normalize_bool "${INSTALL_POSTGRESQL:-no}") == "y" ]] && selected_dbs+=("postgresql")
        [[ $(normalize_bool "${INSTALL_MYSQL:-no}") == "y" ]] && selected_dbs+=("mysql")
        [[ $(normalize_bool "${INSTALL_MONGODB:-no}") == "y" ]] && selected_dbs+=("mongodb")
        [[ $(normalize_bool "${INSTALL_REDIS:-no}") == "y" ]] && selected_dbs+=("redis")
        
        if [[ ${#selected_dbs[@]} -gt 0 ]]; then
            start_step "Installing selected databases"
            for db in "${selected_dbs[@]}"; do
                case $db in
                    postgresql) install_postgresql ;;
                    mysql) install_mysql ;;
                    mongodb) install_mongodb ;;
                    redis) install_redis ;;
                esac
            done
            complete_step "Databases installed"
        fi
    fi
}

# Generate config file from current settings
generate_config() {
    local output_file="${1:-devstart.conf}"
    
    cat > "$output_file" << EOF
# DevStart Configuration File
# Generated on $(date)

# Environment selection
ENVIRONMENT=$choice

# User preferences
IS_BEGINNER=$IS_BEGINNER
SKIP_CONFIRMATIONS=no

# Git configuration
GIT_USERNAME="$CONFIG_GIT_USERNAME"
GIT_EMAIL="$CONFIG_GIT_EMAIL"

# Component installation
INSTALL_NODEJS=yes
INSTALL_PYTHON=yes
INSTALL_DATABASES=yes
INSTALL_DOCKER=no
INSTALL_MOBILE=no

# Database selections
INSTALL_POSTGRESQL=yes
INSTALL_MYSQL=yes
INSTALL_MONGODB=yes
INSTALL_REDIS=yes

# Additional tools
INSTALL_CURSOR=$([[ "$IS_BEGINNER" == "y" ]] && echo "yes" || echo "no")
INSTALL_OH_MY_ZSH=yes
INSTALL_STARSHIP=yes

# Project structure
CREATE_PROJECT_DIRS=yes
PROJECT_ROOT="$HOME/Dev"

# Logging
VERBOSE_LOGGING=no
EOF
    
    print_success "Configuration saved to: $output_file"
    echo "Use it with: ./setup.sh --config $output_file"
}