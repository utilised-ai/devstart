#!/bin/zsh
# Progress tracking and time estimation for DevStart

# Global variables for progress tracking
TOTAL_STEPS=0
CURRENT_STEP=0
STEP_START_TIME=0
INSTALLATION_START_TIME=$(date +%s)
ESTIMATED_TIMES=()

# Progress bar width
PROGRESS_BAR_WIDTH=50

# Initialize progress tracking based on selected environment
init_progress() {
    local env_choice=$1
    
    # Reset counters
    CURRENT_STEP=0
    TOTAL_STEPS=0
    
    # Calculate total steps based on environment
    case $env_choice in
        1)  # Full Stack Web
            TOTAL_STEPS=8
            ESTIMATED_TIMES=(
                "Basic tools:3:minutes"
                "Node.js setup:4:minutes"
                "npm packages:2:minutes"
                "Python setup:3:minutes"
                "Python tools:2:minutes"
                "PostgreSQL:1:minute"
                "MySQL:1:minute"
                "MongoDB:2:minutes"
                "Redis:1:minute"
                "Project setup:1:minute"
            )
            ;;
        2)  # Python Development
            TOTAL_STEPS=5
            ESTIMATED_TIMES=(
                "Basic tools:3:minutes"
                "Python setup:3:minutes"
                "Python tools:2:minutes"
                "PostgreSQL:1:minute"
                "Redis:1:minute"
                "Project setup:1:minute"
            )
            ;;
        3)  # Mobile Development
            TOTAL_STEPS=5
            ESTIMATED_TIMES=(
                "Basic tools:3:minutes"
                "CocoaPods:2:minutes"
                "Flutter:3:minutes"
                "Android Studio:5:minutes"
                "Project setup:1:minute"
            )
            ;;
        4)  # DevOps & Cloud
            TOTAL_STEPS=6
            ESTIMATED_TIMES=(
                "Basic tools:3:minutes"
                "Docker Desktop:3:minutes"
                "Kubernetes tools:2:minutes"
                "Cloud CLIs:3:minutes"
                "Infrastructure tools:2:minutes"
                "Project setup:1:minute"
            )
            ;;
        5)  # Basic Setup
            TOTAL_STEPS=3
            ESTIMATED_TIMES=(
                "Basic tools:3:minutes"
                "Shell setup:1:minute"
                "Project setup:1:minute"
            )
            ;;
        6)  # Custom
            TOTAL_STEPS=3
            ESTIMATED_TIMES=(
                "Basic tools:3:minutes"
                "Shell setup:1:minute"
                "Project setup:1:minute"
            )
            ;;
    esac
    
    # Add common steps
    ((TOTAL_STEPS += 3))  # Prerequisites, Git config, Shell setup
}

# Start a new step
start_step() {
    local step_name=$1
    ((CURRENT_STEP++))
    STEP_START_TIME=$(date +%s)
    
    # Clear previous line and show new progress
    echo -ne "\033[2K\r"
    show_progress "$step_name"
    
    log INFO "Started step $CURRENT_STEP/$TOTAL_STEPS: $step_name"
}

# Complete current step
complete_step() {
    local step_name=$1
    local step_end_time=$(date +%s)
    local step_duration=$((step_end_time - STEP_START_TIME))
    
    # Update progress with completion
    echo -ne "\033[2K\r"
    show_progress "$step_name" "completed"
    echo  # New line after completion
    
    log SUCCESS "Completed step $CURRENT_STEP/$TOTAL_STEPS: $step_name (${step_duration}s)"
}

# Show progress bar
show_progress() {
    local step_name=$1
    local step_status=${2:-"in_progress"}
    
    # Calculate percentage
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    # Calculate filled length
    local filled_length=$((PROGRESS_BAR_WIDTH * CURRENT_STEP / TOTAL_STEPS))
    
    # Create progress bar
    local bar=""
    for ((i=0; i<filled_length; i++)); do
        bar+="█"
    done
    for ((i=filled_length; i<PROGRESS_BAR_WIDTH; i++)); do
        bar+="░"
    done
    
    # Calculate time estimate
    local time_estimate=$(calculate_time_remaining)
    
    # Color based on step_status
    local color=""
    local status_icon=""
    case $step_status in
        in_progress)
            color=$YELLOW
            status_icon="⏳"
            ;;
        completed)
            color=$GREEN
            status_icon="✓"
            ;;
        error)
            color=$RED
            status_icon="✗"
            ;;
    esac
    
    # Print progress bar
    printf "\r${color}[${bar}] ${percentage}%% ${status_icon} Step ${CURRENT_STEP}/${TOTAL_STEPS}: ${step_name}${NC}"
    
    # Add time estimate if in progress
    if [[ "$step_status" == "in_progress" ]] && [[ -n "$time_estimate" ]]; then
        printf " (est. ${time_estimate} remaining)"
    fi
}

# Calculate remaining time
calculate_time_remaining() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - INSTALLATION_START_TIME))
    
    if [[ $CURRENT_STEP -gt 0 ]]; then
        # Calculate average time per step
        local avg_time_per_step=$((elapsed / CURRENT_STEP))
        local remaining_steps=$((TOTAL_STEPS - CURRENT_STEP))
        local estimated_remaining=$((avg_time_per_step * remaining_steps))
        
        # Format time
        if [[ $estimated_remaining -lt 60 ]]; then
            echo "${estimated_remaining}s"
        elif [[ $estimated_remaining -lt 3600 ]]; then
            echo "$((estimated_remaining / 60))m $((estimated_remaining % 60))s"
        else
            echo "$((estimated_remaining / 3600))h $((estimated_remaining % 3600 / 60))m"
        fi
    else
        # Use pre-calculated estimates
        local total_estimate=0
        for estimate in "${ESTIMATED_TIMES[@]}"; do
            if [[ "$estimate" =~ "minute" ]]; then
                local minutes=$(echo "$estimate" | grep -o '[0-9]\+' | head -1)
                ((total_estimate += minutes * 60))
            fi
        done
        echo "$((total_estimate / 60))m"
    fi
}

# Show installation summary
show_installation_summary() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - INSTALLATION_START_TIME))
    
    echo
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${GREEN}                         Installation Summary${NC}"
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    # Format duration
    local hours=$((total_duration / 3600))
    local minutes=$((total_duration % 3600 / 60))
    local seconds=$((total_duration % 60))
    
    echo "${CYAN}Total Installation Time:${NC}"
    if [[ $hours -gt 0 ]]; then
        echo "  ${hours}h ${minutes}m ${seconds}s"
    elif [[ $minutes -gt 0 ]]; then
        echo "  ${minutes}m ${seconds}s"
    else
        echo "  ${seconds}s"
    fi
    
    echo
    echo "${CYAN}Installed Components:${NC}"
    echo "  • Basic tools: $(count_installed_tools brew) packages"
    echo "  • VS Code extensions: $(count_vscode_extensions) extensions"
    
    if [[ ${#INSTALLED_TOOLS[@]} -gt 0 ]]; then
        echo
        echo "${CYAN}Complete list saved to:${NC}"
        echo "  $INSTALLATION_LOG"
    fi
}

# Count installed tools by type
count_installed_tools() {
    local tool_type=$1
    local count=0
    
    for tool in "${INSTALLED_TOOLS[@]}"; do
        if [[ "$tool" == "$tool_type:"* ]]; then
            ((count++))
        fi
    done
    
    echo $count
}

# Count VS Code extensions (placeholder)
count_vscode_extensions() {
    # This would check installed VS Code extensions
    echo "0"
}

# Spinner for long-running operations
show_spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${YELLOW}%c${NC} %s" "$spinstr" "$message"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    
    printf "\r${GREEN}✓${NC} %s\n" "$message"
}