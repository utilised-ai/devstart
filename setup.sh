#!/bin/zsh

# DevStart - macOS Development Environment Setup Script
# A friendly wizard to help you set up your development environment

# Get the directory where this script is located
SCRIPT_DIR="${0:A:h}"

# Parse command line arguments (before set -e to check for dry run)
export DRY_RUN=false
export UNINSTALL=false
export CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-d)
            export DRY_RUN=true
            shift
            ;;
        --uninstall|-u)
            UNINSTALL=true
            shift
            ;;
        --config|-c)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
            exit 0
            ;;
            exit 0
            ;;
            exit 0
            ;;
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Enable strict error handling (except in dry run mode)
if [[ "$DRY_RUN" != "true" ]]; then
    set -e
fi

# Show help message
show_help() {
    cat << EOF
DevStart - macOS Development Environment Setup

Usage: ./setup.sh [OPTIONS]

Options:
    -d, --dry-run             Preview what would be installed without making changes
    -u, --uninstall           Remove DevStart installed tools
    -c, --config FILE         Use configuration file for automated setup
    -h, --help                Show this help message

Pro Features:

Examples:
    ./setup.sh                    # Interactive installation
    ./setup.sh --dry-run          # Preview installation
    ./setup.sh --uninstall        # Remove installed tools
    ./setup.sh --config my.conf   # Automated installation

For more information, see README.md
EOF
}

# Source version configuration
if [[ -f "$SCRIPT_DIR/config/versions.conf" ]]; then
    source "$SCRIPT_DIR/config/versions.conf"
else
    echo "Error: versions.conf not found. Please ensure config/versions.conf exists."
    exit 1
fi

# Validate that essential versions are loaded
if ! check_versions; then
    echo "Error: Required version variables are not set. Check config/versions.conf"
    exit 1
fi

# Source libraries
for lib in error_handler.sh progress_tracker.sh uninstaller.sh config_loader.sh platform_detector.sh parallel_installer.sh; do
    if [[ -f "$SCRIPT_DIR/lib/$lib" ]]; then
        source "$SCRIPT_DIR/lib/$lib"
    else
        echo "Error: $lib not found. Please ensure lib/$lib exists."
        exit 1
    fi
done

# Initialize error handling and logging
init_logs
setup_error_trap
setup_cleanup_trap

# Load configuration file if provided
if [[ -n "$CONFIG_FILE" ]]; then
    load_config_file "$CONFIG_FILE"
    override_prompts
fi

# Source installer modules
for installer in "$SCRIPT_DIR"/installers/*.sh; do
    if [[ -f "$installer" ]]; then
        source "$installer"
    fi
done

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# ASCII Art Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║    ██████╗ ███████╗██╗   ██╗███████╗████████╗ █████╗   ║"
    echo "║    ██╔══██╗██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔══██╗  ║"
    echo "║    ██║  ██║█████╗  ██║   ██║███████╗   ██║   ███████║  ║"
    echo "║    ██║  ██║██╔══╝  ╚██╗ ██╔╝╚════██║   ██║   ██╔══██║  ║"
    echo "║    ██████╔╝███████╗ ╚████╔╝ ███████║   ██║   ██║  ██║  ║"
    echo "║    ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝   ╚═╝   ╚═╝  ╚═╝  ║"
    echo "║                                                          ║"
    echo "║       macOS Development Environment Setup Wizard         ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print colored messages
print_info() { echo -e "${BLUE}ℹ ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_question() { echo -e "${PURPLE}?${NC} $1"; }


# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if not present
install_homebrew() {
    if ! command_exists brew; then
        print_info "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed successfully!"
    else
        print_success "Homebrew is already installed"
        brew update
    fi
}

# Install Xcode Command Line Tools
install_xcode_cli() {
    if ! xcode-select -p &> /dev/null; then
        print_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        # Wait for installation
        until xcode-select -p &> /dev/null; do
            sleep 5
        done
        print_success "Xcode Command Line Tools installed!"
    else
        print_success "Xcode Command Line Tools are already installed"
    fi
}

# Show beginner introduction
show_beginner_intro() {
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${CYAN}                           🎉 Welcome to Coding! 🎉${NC}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "${GREEN}What is a development environment?${NC}"
    echo "Think of it like setting up a kitchen before cooking. You need:"
    echo "  📝 A text editor (like VS Code) - where you write code"
    echo "  🔧 Programming languages (like JavaScript or Python) - the 'ingredients'"
    echo "  📦 Package managers - tools to download code libraries others have made"
    echo "  💾 Databases - where your apps can store information"
    echo "  🎨 Frameworks - pre-made templates to build apps faster"
    echo
    echo "${GREEN}What will this do to my Mac?${NC}"
    echo "  ✓ Install developer tools in standard locations"
    echo "  ✓ Everything can be uninstalled later if needed"
    echo "  ✓ Won't affect your regular apps or files"
    echo "  ✓ Uses official sources (like the App Store for developers)"
    echo
    echo "${GREEN}How long will this take?${NC}"
    echo "  ⏱️  About 10-20 minutes depending on your choice"
    echo "  ☕ Perfect time for a coffee break!"
    echo
    echo "${YELLOW}💡 Tip: We recommend Option 1 for beginners - it has everything you need!${NC}"
    echo
    echo -n "Press Enter to continue..."
    read
    echo
}

# Show detailed information for each option
show_option_details() {
    local option=$1
    
    case $option in
        1)
            echo "${CYAN}=== 🌟 Web Development (Recommended for Beginners) ===${NC}"
            echo
            echo "${GREEN}Perfect for building:${NC}"
            echo "  • Personal websites and portfolios"
            echo "  • Web applications like social media clones"
            echo "  • Online stores and marketplaces"
            echo "  • APIs and backend services"
            echo
            echo "${GREEN}What you'll get:${NC}"
            echo
            echo "  ${BLUE}📝 Code Editors:${NC}"
            echo "    • Visual Studio Code - Traditional code editor"
            echo "    • Cursor - AI-powered editor with built-in assistant"
            echo "      (Perfect for coding with AI help!)"
            echo
            echo "  ${BLUE}🔧 Programming Languages:${NC}"
            echo "    • JavaScript/Node.js $NODE_VERSION - For web development"
            echo "      (The language that powers the web)"
            echo "    • Python $PYTHON_VERSION - For backend and data tasks"
            echo "      (Easy to learn, very powerful)"
            echo
            echo "  ${BLUE}📦 Helper Tools:${NC}"
            echo "    • npm, yarn, pnpm - Install pre-made code packages"
            echo "      (Like an app store for code libraries)"
            echo "    • Git - Save and track your code changes"
            echo "      (Like 'Track Changes' in Word, but better)"
            echo
            echo "  ${BLUE}💾 Databases:${NC}"
            echo "    • PostgreSQL, MySQL - Store user data"
            echo "    • MongoDB - Store flexible data"
            echo "    • Redis - Super-fast temporary storage"
            echo "      (Where your apps keep user info, posts, etc.)"
            echo
            echo "  ${BLUE}🎨 Frameworks:${NC}"
            echo "    • React, Next.js, Vue - Build modern web apps"
            echo "      (Pre-made templates to build faster)"
            echo
            echo "${YELLOW}⏱️  Installation time:${NC} 15-20 minutes"
            echo "${YELLOW}💾 Disk space needed:${NC} About 3GB (like 2-3 movies)"
            echo
            echo "${PURPLE}After installation, you'll be ready to:${NC}"
            echo "  ✓ Build your first website"
            echo "  ✓ Create interactive web apps"
            echo "  ✓ Follow any web development tutorial"
            echo "  ✓ Start your coding journey!"
            ;;
        2)
            echo "${CYAN}=== Python Development ===${NC}"
            echo
            echo "${GREEN}What will be installed:${NC}"
            echo "  ${BLUE}Python Environment:${NC}"
            echo "    • Python $PYTHON_VERSION via pyenv"
            echo "    • pip (package installer)"
            echo "    • Poetry $POETRY_VERSION (dependency management)"
            echo "    • pipx (install Python applications)"
            echo
            echo "  ${BLUE}Development Tools:${NC}"
            echo "    • black (code formatter)"
            echo "    • flake8 (linter)"
            echo "    • mypy (type checker)"
            echo "    • pytest (testing framework)"
            echo "    • ipython (enhanced REPL)"
            echo "    • jupyter (notebooks)"
            echo
            echo "  ${BLUE}Databases:${NC}"
            echo "    • PostgreSQL $POSTGRESQL_VERSION"
            echo "    • Redis $REDIS_VERSION"
            echo
            echo "${YELLOW}Disk space required:${NC} ~2GB"
            echo "${YELLOW}Installation time:${NC} 10-15 minutes"
            ;;
        3)
            echo "${CYAN}=== Mobile Development ===${NC}"
            echo
            echo "${GREEN}What will be installed:${NC}"
            echo "  ${BLUE}iOS Development:${NC}"
            echo "    • CocoaPods (dependency manager)"
            echo "    • Fastlane (deployment automation)"
            echo
            echo "  ${BLUE}Cross-Platform:${NC}"
            echo "    • Flutter SDK"
            echo "    • Android Studio"
            echo
            echo "  ${BLUE}Required:${NC}"
            echo "    • Xcode (install from App Store)"
            echo "    • Java $JAVA_VERSION (for Android)"
            echo
            echo "${YELLOW}Disk space required:${NC} ~5GB"
            echo "${YELLOW}Installation time:${NC} 20-30 minutes"
            echo "${YELLOW}Note:${NC} Android Studio requires additional setup"
            ;;
        4)
            echo "${CYAN}=== DevOps & Cloud ===${NC}"
            echo
            echo "${GREEN}What will be installed:${NC}"
            echo "  ${BLUE}Containerization:${NC}"
            echo "    • Docker Desktop"
            echo "    • docker-compose"
            echo
            echo "  ${BLUE}Kubernetes:${NC}"
            echo "    • kubectl (CLI)"
            echo "    • helm (package manager)"
            echo "    • k9s (terminal UI)"
            echo "    • kubectx (context switching)"
            echo
            echo "  ${BLUE}Cloud Providers:${NC}"
            echo "    • AWS CLI v2"
            echo "    • Google Cloud SDK"
            echo "    • Azure CLI"
            echo
            echo "  ${BLUE}Infrastructure:${NC}"
            echo "    • Terraform"
            echo "    • Ansible"
            echo "    • Vagrant"
            echo "    • VirtualBox"
            echo
            echo "${YELLOW}Disk space required:${NC} ~4GB"
            echo "${YELLOW}Installation time:${NC} 15-25 minutes"
            echo "${YELLOW}Note:${NC} Docker Desktop requires restart"
            ;;
        5)
            echo "${CYAN}=== Basic Setup ===${NC}"
            echo
            echo "${GREEN}What will be installed:${NC}"
            echo "  ${BLUE}Version Control:${NC}"
            echo "    • Git (latest)"
            echo "    • GitHub CLI"
            echo
            echo "  ${BLUE}Editor:${NC}"
            echo "    • Visual Studio Code"
            echo
            echo "  ${BLUE}Terminal Tools:${NC}"
            echo "    • ripgrep (better grep)"
            echo "    • fd (better find)"
            echo "    • bat (better cat)"
            echo "    • exa (better ls)"
            echo "    • fzf (fuzzy finder)"
            echo "    • tldr (simple man pages)"
            echo "    • htop (process viewer)"
            echo
            echo "  ${BLUE}Shell:${NC}"
            echo "    • Oh My Zsh"
            echo "    • Starship prompt"
            echo "    • Zsh plugins"
            echo
            echo "${YELLOW}Disk space required:${NC} ~500MB"
            echo "${YELLOW}Installation time:${NC} 5-10 minutes"
            ;;
        6)
            echo "${CYAN}=== Custom Installation ===${NC}"
            echo
            echo "This option will install only the basic tools,"
            echo "then exit so you can manually install what you need."
            echo
            echo "${GREEN}Basic tools included:${NC}"
            echo "  • Git, VS Code, terminal utilities"
            echo "  • Oh My Zsh with enhancements"
            echo
            echo "After setup, use Homebrew to install additional tools:"
            echo "  ${BLUE}brew search <tool>${NC} - Find packages"
            echo "  ${BLUE}brew install <tool>${NC} - Install packages"
            echo "  ${BLUE}brew install --cask <app>${NC} - Install applications"
            ;;
    esac
    
    echo
}

# Show menu and get selection
show_menu() {
    echo
    print_question "What would you like to build?"
    echo
    echo "  ${GREEN}1) 🌟 Web Development - RECOMMENDED FOR BEGINNERS${NC}"
    echo "     Build websites, web apps, and APIs (Instagram, Twitter, etc.)"
    echo
    echo "  2) 🐍 Python Development"
    echo "     Data science, AI/ML, automation, and web backends"
    echo
    echo "  3) 📱 Mobile Development"
    echo "     iPhone and Android apps"
    echo
    echo "  4) ☁️  DevOps & Cloud"
    echo "     Server management, cloud deployment, containers"
    echo
    echo "  5) 🛠️  Just the Basics"
    echo "     Minimal setup - just code editor and essential tools"
    echo
    echo "  6) 🎯 Custom Setup"
    echo "     I know what I want - let me choose"
    echo
    echo -n "Enter your choice (1-6) or 'q' to quit: "
    read choice
    
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
    
    if [[ ! "$choice" =~ ^[1-6]$ ]]; then
        print_error "Invalid choice. Please enter 1-6 or 'q' to quit."
        show_menu
        return
    fi
    
    echo
    show_option_details "$choice"
    
    # Confirm selection
    echo
    print_question "Do you want to proceed with this installation? (y/n)"
    echo -n "Your choice: "
    read confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_info "Let's choose a different option."
        show_menu
        return
    fi
    
    echo
    print_success "Great! Starting installation..."
    echo
}

# Install basic tools
install_basic_tools() {
    print_info "Installing basic development tools..."
    
    # Progress tracking for beginners
    if [[ "$IS_BEGINNER" == "y" || "$IS_BEGINNER" == "Y" ]]; then
        echo
        echo "${YELLOW}This might take a few minutes. Here's what's happening:${NC}"
        echo "  📦 Downloading tools from the internet"
        echo "  🔧 Installing them in the right places"
        echo "  ⚙️  Configuring everything to work together"
        echo
        echo "${GREEN}You'll see progress messages below. Don't worry about understanding them!${NC}"
        echo
    fi
    
    local tools=(
        "git"
        "gh"  # GitHub CLI
        "wget"
        "curl"
        "jq"
        "tree"
        "htop"
        "ripgrep"
        "fd"
        "bat"
        "exa"
        "tldr"
        "fzf"
    )
    
    # Additional tools for AI-assisted development
    if [[ "$IS_BEGINNER" == "y" || "$IS_BEGINNER" == "Y" ]]; then
        tools+=(
            "glow"  # Markdown renderer for terminal
            "httpie"  # User-friendly HTTP client
            "jless"  # JSON viewer
        )
    fi
    
    # Use parallel installation for brew packages if enabled
    if [[ "$PARALLEL_ENABLED" == "true" ]]; then
        local tools_to_install=()
        for tool in "${tools[@]}"; do
            if ! command_exists "$tool"; then
                tools_to_install+=("$tool")
            else
                print_success "$tool is already installed"
            fi
        done
        
        if [[ ${#tools_to_install[@]} -gt 0 ]]; then
            install_brew_packages_parallel "${tools_to_install[@]}"
        fi
    else
        # Sequential installation
        for tool in "${tools[@]}"; do
            if ! command_exists "$tool"; then
                print_info "Installing $tool..."
                safe_execute "Install $tool" "brew install $tool"
                track_installation "brew:$tool"
            else
                print_success "$tool is already installed"
            fi
        done
    fi
    
    # Install VS Code
    if ! command_exists code; then
        print_info "Installing Visual Studio Code..."
        safe_execute "Install VS Code" "brew install --cask visual-studio-code"
        track_installation "cask:visual-studio-code"
    else
        print_success "VS Code is already installed"
    fi
    
    # Install Cursor (AI-first code editor) for beginners
    if [[ "$IS_BEGINNER" == "y" || "$IS_BEGINNER" == "Y" ]]; then
        if ! command_exists cursor; then
            print_info "Installing Cursor - an AI-powered code editor perfect for beginners..."
            safe_execute "Install Cursor" "brew install --cask cursor"
            track_installation "cask:cursor"
        else
            print_success "Cursor is already installed"
        fi
    fi
}


# Install Docker and Kubernetes tools
install_devops_tools() {
    print_info "Setting up DevOps tools..."
    
    # Docker Desktop
    if ! command_exists docker; then
        print_info "Installing Docker Desktop..."
        brew install --cask docker
        print_warning "Please start Docker Desktop from Applications to complete setup"
    fi
    
    # Kubernetes tools
    brew install kubectl helm k9s kubectx
    
    # Cloud CLI tools
    brew install awscli
    brew install --cask google-cloud-sdk
    brew install azure-cli
    
    # Other DevOps tools
    brew install terraform ansible vagrant
    brew install --cask virtualbox
    
    print_success "DevOps tools setup complete!"
}

# Configure Git
configure_git() {
    print_info "Configuring Git..."
    
    # Use config values if available
    if [[ -n "$CONFIG_GIT_USERNAME" ]] && [[ -n "$CONFIG_GIT_EMAIL" ]]; then
        git_username="$CONFIG_GIT_USERNAME"
        git_email="$CONFIG_GIT_EMAIL"
        print_info "Using Git config from file: $git_username <$git_email>"
    else
        echo -n "Enter your Git username: "
        read git_username
        echo -n "Enter your Git email: "
        read git_email
    fi
    
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor "code --wait"
    git config --global pull.rebase false
    
    print_success "Git configured successfully!"
}

# Setup shell improvements
setup_shell() {
    print_info "Setting up shell improvements..."
    
    # Install Oh My Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install Starship prompt
    if ! command_exists starship; then
        print_info "Installing Starship prompt..."
        brew install starship
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi
    
    # Install useful Zsh plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
    
    print_success "Shell improvements installed!"
}

# Show beginner completion guide
show_beginner_completion_guide() {
    local env_choice=$1
    
    echo
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${GREEN}                    🎉 Congratulations! You're Ready to Code! 🎉${NC}"
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo "${CYAN}📋 What Just Happened:${NC}"
    echo "  ✅ Installed all your development tools"
    echo "  ✅ Created your project folders at ~/Dev"
    echo "  ✅ Set up your code editor (VS Code)"
    echo "  ✅ Configured your terminal for coding"
    echo
    
    echo "${CYAN}🚀 Your First Steps:${NC}"
    echo
    echo "  ${YELLOW}1. Close and reopen your Terminal${NC}"
    echo "     (Or type: source ~/.zshrc)"
    echo
    echo "  ${YELLOW}2. Open Your Code Editor${NC}"
    echo "     • ${BLUE}Cursor${NC} (Recommended for AI coding):"
    echo "       - Find it in Applications or type 'cursor' in Terminal"
    echo "       - Has AI built-in - just press Cmd+K to ask questions!"
    echo "     • ${BLUE}VS Code${NC} (Traditional editor):"
    echo "       - Find it in Applications or type 'code' in Terminal"
    echo
    
    if [[ "$env_choice" == "1" ]]; then
        echo "  ${YELLOW}3. Try Your First AI-Powered Project!${NC}"
        echo
        echo "     ${GREEN}Option A: Use the AI Starter Project${NC}"
        echo "     In Terminal, type:"
        echo "       cd ~/Dev/projects/ai-starter-project"
        echo "       npm install"
        echo "       npm run dev"
        echo "       cursor ."
        echo "     Then ask AI: \"Add a route that returns a random joke\""
        echo
        echo "     ${GREEN}Option B: Start from scratch with AI${NC}"
        echo "     In Terminal, type:"
        echo "       cd ~/Dev/projects"
        echo "       mkdir my-ai-project"
        echo "       cd my-ai-project"
        echo "       cursor ."
        echo "     Then ask AI: \"Create a simple Express server with a home page\""
        echo
        echo "${CYAN}📚 Recommended Learning Resources:${NC}"
        echo "  • ${BLUE}freeCodeCamp${NC} - Free interactive coding lessons"
        echo "  • ${BLUE}MDN Web Docs${NC} - Excellent web development reference"
        echo "  • ${BLUE}JavaScript.info${NC} - Modern JavaScript tutorial"
        echo "  • ${BLUE}The Odin Project${NC} - Full stack curriculum"
    fi
    
    echo
    echo "${CYAN}💡 Pro Tips for Beginners:${NC}"
    echo "  • Don't worry about understanding everything at once"
    echo "  • Start with HTML/CSS before JavaScript"
    echo "  • Build small projects to learn"
    echo "  • Google errors - every developer does it!"
    echo "  • Join communities like Reddit's r/learnprogramming"
    echo
    echo "${PURPLE}🆘 If Something Goes Wrong:${NC}"
    echo "  • Most errors can be fixed by restarting Terminal"
    echo "  • Your code projects are in: ~/Dev/projects"
    echo "  • You can always re-run this installer"
    echo
    echo "${GREEN}You're all set! Welcome to the world of coding! 🎊${NC}"
    echo
    echo "${CYAN}📖 We've created helpful guides in this folder:${NC}"
    echo
    echo "  ${BLUE}GETTING_STARTED.md${NC}"
    echo "  • Step-by-step first projects"
    echo "  • Answers to common questions"
    echo "  • Troubleshooting tips"
    echo
    echo "  ${BLUE}AI_CODING_GUIDE.md${NC} 🤖"
    echo "  • How to code with AI assistants"
    echo "  • Prompting tips and tricks"
    echo "  • Vibe coding workflow"
    echo "  • Quick challenges to try"
    echo
    echo -n "Press Enter to finish..."
    read
}

# Create project structure
create_project_structure() {
    print_info "Creating recommended project structure..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "${BLUE}[DRY RUN]${NC} Would create directories: ~/Dev/{projects,sandbox,learning,tools}"
    else
        mkdir -p ~/Dev/{projects,sandbox,learning,tools}
    fi
    
    # Copy starter templates and AI configs for beginners
    if [[ "$IS_BEGINNER" == "y" || "$IS_BEGINNER" == "Y" ]]; then
        # Copy the first website template
        if [[ -f "${0%/*}/templates/first-website.html" ]]; then
            cp "${0%/*}/templates/first-website.html" ~/Dev/learning/
            print_success "Added a starter website template to ~/Dev/learning/"
        fi
        
        # Copy AI context files
        if [[ -f "${0%/*}/templates/CLAUDE.md" ]]; then
            cp "${0%/*}/templates/CLAUDE.md" ~/Dev/
            print_success "Added CLAUDE.md for AI context to ~/Dev/"
        fi
        
        if [[ -f "${0%/*}/templates/.cursorrules" ]]; then
            cp "${0%/*}/templates/.cursorrules" ~/Dev/
            print_success "Added .cursorrules for Cursor AI to ~/Dev/"
        fi
        
        # Copy AI starter project
        if [[ -d "${0%/*}/templates/ai-starter-project" ]]; then
            cp -r "${0%/*}/templates/ai-starter-project" ~/Dev/projects/
            print_success "Added AI-optimized starter project to ~/Dev/projects/"
        fi
    fi
    
    # Create a sample .gitignore
    cat > ~/Dev/.gitignore << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride

# IDE
.idea/
.vscode/
*.swp
*.swo

# Dependencies
node_modules/
venv/
__pycache__/

# Environment variables
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.egg-info/
EOF
    
    print_success "Project structure created at ~/Dev"
}

# Main installation flow
main() {
    # Handle special modes
    if [[ "$UNINSTALL" == "true" ]]; then
        run_uninstall_mode
        return
    fi
    
    clear
    print_banner
    
    # Show Pro status if available
        if is_pro_version 2>/dev/null; then
            echo
        fi
    fi
    
    # Show dry run notice
    if [[ "$DRY_RUN" == "true" ]]; then
        echo
        echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "${YELLOW}                              DRY RUN MODE${NC}"
        echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo
        echo "This will preview what would be installed without making any changes."
        echo
    fi
    
    print_info "Welcome to DevStart! This wizard will help you set up your macOS development environment."
    echo
    
    # Check if user is new to development
    print_question "Is this your first time setting up a development environment? (y/n)"
    echo -n "Your answer: "
    read is_beginner
    echo
    
    # Export for use in other functions
    export IS_BEGINNER="$is_beginner"
    
    if [[ "$is_beginner" == "y" || "$is_beginner" == "Y" ]]; then
        show_beginner_intro
    fi
    
    # Initialize platform detection
    init_platform_detection
    
    # Initialize parallel installation settings
    init_parallel_settings
    
    # Check prerequisites
    install_xcode_cli
    install_homebrew
    
    # Show menu and get user choice
    show_menu
    
    # Initialize progress tracking for selected environment
    init_progress "$choice"
    
    # Check if resuming from previous installation
    if ! load_progress; then
        echo
        print_info "Starting fresh installation..."
    fi
    
    # Always install basic tools
    start_step "Installing basic development tools"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "${BLUE}[DRY RUN]${NC} Would install basic development tools"
    fi
    install_basic_tools
    complete_step "Basic tools installed"
    
    # Install based on user choice
    case $choice in
        1)
            start_step "Setting up Node.js environment"
            install_nodejs_env
            complete_step "Node.js environment ready"
            
            start_step "Setting up Python environment"
            install_python_env
            complete_step "Python environment ready"
            
            start_step "Installing databases"
            install_databases "web"
            complete_step "Databases installed"
            ;;
        2)
            start_step "Setting up Python environment"
            install_python_env
            complete_step "Python environment ready"
            
            start_step "Installing databases"
            install_databases "python"
            complete_step "Databases installed"
            ;;
        3)
            print_info "Installing mobile development tools..."
            brew install cocoapods fastlane
            brew install --cask android-studio flutter
            ;;
        4)
            install_devops_tools
            ;;
        5)
            # Basic tools already installed
            ;;
        6)
            print_info "Custom installation selected. Basic tools have been installed."
            print_info "You can now manually install additional tools using Homebrew."
            ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    # Common setup tasks
    start_step "Configuring Git"
    configure_git
    complete_step "Git configured"
    
    start_step "Setting up shell enhancements"
    setup_shell
    complete_step "Shell enhanced"
    
    start_step "Creating project structure"
    create_project_structure
    complete_step "Project structure created"
    
    # Show installation summary
    show_installation_summary
    
    # Show appropriate completion guide
    if [[ "$IS_BEGINNER" == "y" || "$IS_BEGINNER" == "Y" ]]; then
        show_beginner_completion_guide "$choice"
    else
        # Standard completion message
        echo
        print_success "🎉 Installation complete!"
        echo
        print_info "Next steps:"
        echo "  1. Restart your terminal or run: source ~/.zshrc"
        echo "  2. Your development projects should go in: ~/Dev/projects"
        echo "  3. Check out the README.md for more information"
        echo
        print_info "Happy coding! 🚀"
    fi
    
    # Show Pro upsell for community users
        if ! is_pro_version 2>/dev/null; then
            echo
            echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "${CYAN}💡 Did you know? DevStart Pro can save you hours of setup time!${NC}"
            echo
            echo "  • AI-powered project analyzer"
            echo "  • 70% faster installations"  
            echo "  • Cloud configuration sync"
            echo "  • Priority support"
            echo
            echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        fi
    fi
}

# Run main function
main "$@"