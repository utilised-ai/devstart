#!/bin/zsh
# Parallel installation support for DevStart

# Global variables for parallel execution
PARALLEL_JOBS=()
PARALLEL_PIDS=()
MAX_PARALLEL_JOBS=4
PARALLEL_ENABLED=true

# Initialize parallel settings based on system
init_parallel_settings() {
    # Determine optimal parallel jobs based on CPU cores
    local cpu_cores=$(sysctl -n hw.ncpu)
    
    # Use half the CPU cores for parallel jobs (minimum 2, maximum 8)
    MAX_PARALLEL_JOBS=$((cpu_cores / 2))
    [[ $MAX_PARALLEL_JOBS -lt 2 ]] && MAX_PARALLEL_JOBS=2
    [[ $MAX_PARALLEL_JOBS -gt 8 ]] && MAX_PARALLEL_JOBS=8
    
    # Disable parallel for low memory systems
    if [[ $PLATFORM_MEMORY_GB -lt 8 ]]; then
        PARALLEL_ENABLED=false
        MAX_PARALLEL_JOBS=1
        print_warning "Low memory detected. Parallel installation disabled."
    fi
    
    # Check if in dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        PARALLEL_ENABLED=false
    fi
    
    log INFO "Parallel installation settings: enabled=$PARALLEL_ENABLED, max_jobs=$MAX_PARALLEL_JOBS"
}

# Add a job to parallel queue
queue_parallel_job() {
    local job_name=$1
    local job_command=$2
    
    PARALLEL_JOBS+=("$job_name:$job_command")
}

# Execute jobs in parallel batches
execute_parallel_jobs() {
    local job_category=$1
    
    if [[ ${#PARALLEL_JOBS[@]} -eq 0 ]]; then
        return 0
    fi
    
    if [[ "$PARALLEL_ENABLED" != "true" ]]; then
        # Execute sequentially
        execute_jobs_sequentially
        return $?
    fi
    
    print_info "Installing $job_category in parallel (up to $MAX_PARALLEL_JOBS at once)..."
    echo
    
    local completed=0
    local total=${#PARALLEL_JOBS[@]}
    local failed_jobs=()
    
    # Process jobs in batches
    while [[ ${#PARALLEL_JOBS[@]} -gt 0 ]] || [[ ${#PARALLEL_PIDS[@]} -gt 0 ]]; do
        # Start new jobs if we have capacity
        while [[ ${#PARALLEL_PIDS[@]} -lt $MAX_PARALLEL_JOBS ]] && [[ ${#PARALLEL_JOBS[@]} -gt 0 ]]; do
            local job_spec="${PARALLEL_JOBS[1]}"
            PARALLEL_JOBS=("${PARALLEL_JOBS[@]:1}")  # Remove first element
            
            local job_name="${job_spec%%:*}"
            local job_command="${job_spec#*:}"
            
            # Start job in background
            start_parallel_job "$job_name" "$job_command"
        done
        
        # Check for completed jobs
        check_parallel_jobs
        
        # Update progress
        local running=${#PARALLEL_PIDS[@]}
        printf "\r${CYAN}Progress:${NC} $completed/$total completed, $running running"
        
        # Small delay to prevent CPU spinning
        sleep 0.1
    done
    
    echo  # New line after progress
    
    # Report results
    if [[ ${#failed_jobs[@]} -gt 0 ]]; then
        print_error "Some installations failed:"
        for job in "${failed_jobs[@]}"; do
            echo "  • $job"
        done
        return 1
    else
        print_success "All $job_category installed successfully!"
        return 0
    fi
}

# Execute jobs sequentially (fallback)
execute_jobs_sequentially() {
    local total=${#PARALLEL_JOBS[@]}
    local current=0
    
    for job_spec in "${PARALLEL_JOBS[@]}"; do
        ((current++))
        local job_name="${job_spec%%:*}"
        local job_command="${job_spec#*:}"
        
        echo -ne "\r${CYAN}Installing:${NC} $job_name ($current/$total)"
        
        if eval "$job_command" >/dev/null 2>&1; then
            track_installation "parallel:$job_name"
        else
            print_error "Failed to install $job_name"
        fi
    done
    
    echo  # New line
    PARALLEL_JOBS=()
}

# Start a job in parallel
start_parallel_job() {
    local job_name=$1
    local job_command=$2
    local log_file="/tmp/devstart_parallel_${job_name//[^a-zA-Z0-9]/_}.log"
    
    # Run job in background with logging
    (
        echo "Starting: $job_command" > "$log_file"
        if eval "$job_command" >> "$log_file" 2>&1; then
            echo "SUCCESS" >> "$log_file"
            track_installation "parallel:$job_name"
        else
            echo "FAILED" >> "$log_file"
        fi
    ) &
    
    local pid=$!
    PARALLEL_PIDS+=("$pid:$job_name:$log_file")
    
    log INFO "Started parallel job: $job_name (PID: $pid)"
}

# Check status of parallel jobs
check_parallel_jobs() {
    local remaining_pids=()
    
    for pid_spec in "${PARALLEL_PIDS[@]}"; do
        local pid="${pid_spec%%:*}"
        local job_name="${pid_spec#*:}"
        job_name="${job_name%%:*}"
        local log_file="${pid_spec##*:}"
        
        if ! kill -0 "$pid" 2>/dev/null; then
            # Job completed
            wait "$pid"
            local exit_code=$?
            
            if [[ $exit_code -eq 0 ]] && grep -q "SUCCESS" "$log_file" 2>/dev/null; then
                ((completed++))
                log SUCCESS "Parallel job completed: $job_name"
            else
                failed_jobs+=("$job_name")
                log ERROR "Parallel job failed: $job_name"
                
                # Show error from log
                if [[ -f "$log_file" ]]; then
                    local error=$(tail -n 5 "$log_file" | grep -v "SUCCESS\|FAILED" | head -n 3)
                    [[ -n "$error" ]] && log ERROR "Error details: $error"
                fi
            fi
            
            # Clean up log file
            rm -f "$log_file"
        else
            # Job still running
            remaining_pids+=("$pid_spec")
        fi
    done
    
    PARALLEL_PIDS=("${remaining_pids[@]}")
}

# Install multiple brew packages in parallel
install_brew_packages_parallel() {
    local packages=("$@")
    
    print_info "Preparing to install ${#packages[@]} packages..."
    
    # Queue all packages
    for package in "${packages[@]}"; do
        if ! command_exists "$package"; then
            queue_parallel_job "$package" "brew install $package"
        fi
    done
    
    # Execute in parallel
    execute_parallel_jobs "Homebrew packages"
}

# Install npm packages in parallel
install_npm_packages_parallel() {
    local packages=("$@")
    
    print_info "Preparing to install ${#packages[@]} npm packages..."
    
    # Queue all packages
    for package_spec in "${packages[@]}"; do
        local package_name="${package_spec%%@*}"
        if ! command_exists "$package_name"; then
            queue_parallel_job "$package_name" "npm install -g $package_spec"
        fi
    done
    
    # Execute in parallel
    execute_parallel_jobs "npm packages"
}

# Install Python tools in parallel
install_python_tools_parallel() {
    local tools=("$@")
    
    print_info "Preparing to install ${#tools[@]} Python tools..."
    
    # Queue all tools
    for tool_spec in "${tools[@]}"; do
        local tool_name="${tool_spec%%=*}"
        if ! command_exists "$tool_name"; then
            queue_parallel_job "$tool_name" "pipx install $tool_spec"
        fi
    done
    
    # Execute in parallel
    execute_parallel_jobs "Python tools"
}

# Cleanup parallel installation
cleanup_parallel() {
    # Kill any remaining background jobs
    for pid_spec in "${PARALLEL_PIDS[@]}"; do
        local pid="${pid_spec%%:*}"
        kill "$pid" 2>/dev/null || true
    done
    
    # Clean up temp files
    rm -f /tmp/devstart_parallel_*.log
    
    PARALLEL_JOBS=()
    PARALLEL_PIDS=()
}