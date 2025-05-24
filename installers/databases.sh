#!/bin/zsh
# Database installation module for DevStart

install_databases() {
    local db_type=$1  # "web" or "python"
    
    print_info "Installing databases..."
    log INFO "Starting database installation for $db_type environment"
    
    case $db_type in
        web)
            install_postgresql
            install_mysql
            install_mongodb
            install_redis
            ;;
        python)
            install_postgresql
            install_redis
            ;;
        *)
            print_error "Unknown database configuration: $db_type"
            return 1
            ;;
    esac
    
    print_success "Database installation complete!"
    log SUCCESS "Database installation completed"
}

install_postgresql() {
    print_info "Installing PostgreSQL $POSTGRESQL_VERSION..."
    
    if ! command_exists psql; then
        safe_execute "Install PostgreSQL $POSTGRESQL_VERSION" "brew install postgresql@$POSTGRESQL_VERSION"
        track_installation "brew:postgresql@$POSTGRESQL_VERSION"
        
        # Start PostgreSQL service
        print_info "Starting PostgreSQL service..."
        safe_execute "Start PostgreSQL" "brew services start postgresql@$POSTGRESQL_VERSION"
        
        # Wait for PostgreSQL to start
        sleep 2
        
        # Create default database for user
        if command_exists createdb; then
            safe_execute "Create user database" "createdb $USER" || true
        fi
        
        verify_installation "psql"
    else
        print_success "PostgreSQL is already installed"
    fi
}

install_mysql() {
    print_info "Installing MySQL $MYSQL_VERSION..."
    
    if ! command_exists mysql; then
        safe_execute "Install MySQL $MYSQL_VERSION" "brew install mysql@$MYSQL_VERSION"
        track_installation "brew:mysql@$MYSQL_VERSION"
        
        # Start MySQL service
        print_info "Starting MySQL service..."
        safe_execute "Start MySQL" "brew services start mysql@$MYSQL_VERSION"
        
        # Secure installation reminder
        print_warning "Run 'mysql_secure_installation' to secure your MySQL installation"
        
        verify_installation "mysql"
    else
        print_success "MySQL is already installed"
    fi
}

install_mongodb() {
    print_info "Installing MongoDB $MONGODB_VERSION..."
    
    if ! command_exists mongod; then
        # Add MongoDB tap if not already added
        if ! brew tap | grep -q "mongodb/brew"; then
            safe_execute "Add MongoDB tap" "brew tap mongodb/brew"
        fi
        
        safe_execute "Install MongoDB $MONGODB_VERSION" "brew install mongodb-community@$MONGODB_VERSION"
        track_installation "brew:mongodb-community@$MONGODB_VERSION"
        
        # Start MongoDB service
        print_info "Starting MongoDB service..."
        safe_execute "Start MongoDB" "brew services start mongodb-community@$MONGODB_VERSION"
        
        verify_installation "mongod"
    else
        print_success "MongoDB is already installed"
    fi
}

install_redis() {
    print_info "Installing Redis $REDIS_VERSION..."
    
    if ! command_exists redis-server; then
        safe_execute "Install Redis $REDIS_VERSION" "brew install redis@$REDIS_VERSION"
        track_installation "brew:redis@$REDIS_VERSION"
        
        # Start Redis service
        print_info "Starting Redis service..."
        safe_execute "Start Redis" "brew services start redis@$REDIS_VERSION"
        
        verify_installation "redis-server"
    else
        print_success "Redis is already installed"
    fi
}

# Function to uninstall databases
uninstall_databases() {
    print_info "Removing databases..."
    
    # Stop services first
    local services=("postgresql@$POSTGRESQL_VERSION" "mysql@$MYSQL_VERSION" "mongodb-community@$MONGODB_VERSION" "redis@$REDIS_VERSION")
    for service in "${services[@]}"; do
        if brew services list | grep -q "$service"; then
            print_info "Stopping $service..."
            brew services stop "$service" 2>/dev/null || true
        fi
    done
    
    # Uninstall databases
    for db in "${services[@]}"; do
        if brew list | grep -q "$db"; then
            print_info "Removing $db..."
            brew uninstall "$db" 2>/dev/null || true
        fi
    done
    
    print_success "Databases removed"
}

# Function to check database status
check_database_status() {
    print_info "Database Status:"
    echo
    
    local databases=(
        "PostgreSQL:psql:postgresql@$POSTGRESQL_VERSION"
        "MySQL:mysql:mysql@$MYSQL_VERSION"
        "MongoDB:mongod:mongodb-community@$MONGODB_VERSION"
        "Redis:redis-cli:redis@$REDIS_VERSION"
    )
    
    for db_info in "${databases[@]}"; do
        IFS=':' read -r name command service <<< "$db_info"
        
        if command_exists "$command"; then
            if brew services list | grep -q "$service.*started"; then
                print_success "$name is installed and running"
            else
                print_warning "$name is installed but not running"
                echo "  Start with: brew services start $service"
            fi
        else
            echo "  $name is not installed"
        fi
    done
}