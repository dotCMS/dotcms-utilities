#!/bin/bash

# install-dev-scripts.sh - Install dotCMS development Git extensions
# 
# This script will:
# 1. Install Git extension scripts to ~/.dotcms/dev-scripts/
# 2. Add installation directory to your PATH (with permission)
# 3. Install optional development tools (fzf, gh, just)
# 4. Verify SDKMAN! is available for Java/JBang development
#
# Usage: ./install-dev-scripts.sh [--force] [--ref REF] [--branch BRANCH] [--directory DIR] [--uninstall] [--help]
# 
# NOTE: When downloaded via curl from a specific branch, this script should automatically
# detect and use that branch. For manual override, use --ref parameter.

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub repository information
REPO_OWNER="dotcms"
REPO_NAME="dotcms-utilities"

# Try to detect REF from the script source, with manual override capability
detect_or_prompt_ref() {
    # Method 1: Check if ref was set via environment variable (for curl piping)
    if [[ -n "$DOTCMS_INSTALL_REF" ]]; then
        echo "$DOTCMS_INSTALL_REF"
        return
    fi
    
    # If already set via command line args, use that
    if [[ -n "$EXPLICIT_REF" ]]; then
        echo "$EXPLICIT_REF"
        return
    fi
    
    # Method 2: Try to detect from BASH_SOURCE if available (works for direct execution from GitHub)
    if [[ -n "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" =~ raw\.githubusercontent\.com/.*/.*/(.*)/install-dev-scripts\.sh ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    
    # Method 3: If running from local source, detect current Git branch
    local script_dir
    script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")")"
    if [[ -d "$script_dir/.git" || -f "$script_dir/../.git" ]]; then
        local git_dir="$script_dir"
        [[ -f "$script_dir/../.git" ]] && git_dir="$script_dir/.."
        
        if command -v git >/dev/null 2>&1; then
            local current_branch
            current_branch=$(cd "$git_dir" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if [[ -n "$current_branch" && "$current_branch" != "HEAD" ]]; then
                echo "$current_branch"
                return
            fi
        fi
    fi
    
    # Default to main
    echo "main"
}

# Initial detection (will be re-run after argument parsing)
REF="main"
BRANCH="main"
VERSION="1.0.3"
CHECK_UPDATES=true
FORCE=false
QUIET=false

CACHE_FILE="$HOME/.dotcms/dev-scripts/.dotcms_latest_hash"

# List of scripts to install (add your script names here)
SCRIPTS=(
    "git-issue-branch"
    "git-issue-pr"
    "git-smart-switch"
    "git-issue-create"
    "check_updates"
)

# Logging functions
log() {
    [[ "$QUIET" != "true" ]] && echo "$1"
}

log_info() {
    [[ "$QUIET" != "true" ]] && echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_task() {
    echo -e "${BLUE}●${NC} $1"
}

log_check() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Error handling function
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

get_latest_commit_hash() {
    local api_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/$REF"
    local commit_hash
    commit_hash=$(curl -s "$api_url" | grep -m 1 '"sha":' | cut -d '"' -f 4)
    echo "$commit_hash"
}

# Validate that the ref exists in the repository
validate_ref() {
    local ref="$1"
    log_task "Validating reference: $ref"
    
    # Try to get commit info for the ref
    local api_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/$ref"
    local http_code
    http_code=$(curl -s -w "%{http_code}" -o /dev/null "$api_url")
    
    if [[ "$http_code" == "200" ]]; then
        log_check "Reference '$ref' found"
        return 0
    elif [[ "$http_code" == "404" ]]; then
        log_error "Reference '$ref' not found in repository $REPO_OWNER/$REPO_NAME"
        echo
        echo -e "${YELLOW}Available references:${NC}"
        echo "  • Branches: Check github.com/$REPO_OWNER/$REPO_NAME/branches"
        echo "  • Tags: Check github.com/$REPO_OWNER/$REPO_NAME/tags"
        echo "  • Example: --ref main, --ref v1.2.0, --ref feature-branch"
        return 1
    else
        log_warning "Unable to validate reference (HTTP $http_code). Proceeding anyway..."
        return 0
    fi
}

check_for_updates() {
    local installed_hash
    local latest_hash
    
    # Show what ref we're checking
    if [[ "$REF" != "main" ]]; then
        log_task "Checking for updates from ref: $REF"
        log_warning "You are installing from '$REF' instead of the default 'main' branch"
        log_info "To return to default behavior, run: bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)"
        echo
    else
        log_task "Checking for updates..."
    fi
    # Read the installed version hash
    if [[ -f "$BIN_DIR/.version" ]]; then
        installed_hash=$(cat "$BIN_DIR/.version")
    else
        log_warning "No version information found. This might be an older installation."
        installed_hash=""
    fi

    # Get the latest commit hash
    latest_hash=$(get_latest_commit_hash)

    if [[ -z "$latest_hash" ]]; then
        log_error "Failed to fetch the latest version information."
        return 1
    fi

    echo "${latest_hash}" > "$CACHE_FILE"

    if [[ -z "$installed_hash" || "$installed_hash" != "$latest_hash" ]]; then
        log_task "Update available"
        if [[ -n "$installed_hash" ]]; then
            log_warning "Installed version: $installed_hash"
        else
            log_warning "Installed version: Unknown (older installation)"
        fi
        log_success "Latest version: $latest_hash"
        log_info "Changes:"

        # Fetch the commit messages along with short commit id and date
        if [[ -n "$installed_hash" && "$REF" == "main" ]]; then
            curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/compare/$installed_hash...$latest_hash" | \
                jq -r '.commits[] | "Commit: \(.sha[0:7]) Date: \(.commit.committer.date) Message: \(.commit.message)"' | \
                sed 's/^/  /'
        else
            if [[ "$REF" != "main" ]]; then
                echo "  Installing from ref: $REF"
                echo "  Change comparison only available for main branch installations"
            else
                echo "  Unable to show detailed changes (no previous version found)"
                echo "  It's recommended to update to get the latest features and improvements."
            fi
        fi

        return 0  # Update is available
    else
        log_check "You have the latest version installed."
        return 1  # No update needed
    fi
}

# Check for required tools
check_dependencies() {
    local missing_core=()
    local missing_optional=()
    
    # Check core requirements
    for cmd in git curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_core+=("$cmd")
        fi
    done
    
    if [[ ${#missing_core[@]} -gt 0 ]]; then
        error_exit "Missing required dependencies: ${missing_core[*]}. Please install them first."
    fi
    
    # Check optional tools (only show if verbose)
    for cmd in fzf gh just; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_optional+=("$cmd")
        fi
    done
    
    if [[ ${#missing_optional[@]} -gt 0 && "$QUIET" != "true" ]]; then
        echo
        echo -e "${BLUE}🛠️  Optional Enhancement Tools:${NC}"
        for cmd in "${missing_optional[@]}"; do
            case "$cmd" in
                fzf) echo -e "  ${YELLOW}◦${NC} fzf - Interactive fuzzy finder for better selection menus" ;;
                gh) echo -e "  ${YELLOW}◦${NC} gh - GitHub CLI for issue and PR management" ;;
                just) echo -e "  ${YELLOW}◦${NC} just - Command runner for project automation" ;;
            esac
        done
        echo
        echo -e "${YELLOW}Install these tools now? (y/n) [n]:${NC} "
        read -r REPLY
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for cmd in "${missing_optional[@]}"; do
                install_dependency "$cmd"
            done
        else
            echo -e "${BLUE}💡 Note:${NC} You can install these tools later using Homebrew or package manager"
        fi
    fi
}

# Install a missing dependency
install_dependency() {
    local cmd="$1"
    if [[ "$cmd" == "fzf" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}Installing $cmd using Homebrew...${NC}"
            if ! brew install fzf; then
                echo -e "${RED}WARNING: Failed to install $cmd using Homebrew.${NC}"
            fi
        else
            echo -e "${YELLOW}Installing $cmd using GitHub release...${NC}"
            if ! git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || ! ~/.fzf/install; then
                echo -e "${RED}WARNING: Failed to install $cmd.${NC}"
            fi
        fi
        log_success "$cmd installed successfully"
    elif [[ "$cmd" == "gh" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}Installing $cmd using Homebrew...${NC}"
            if ! brew install gh; then
                echo -e "${RED}WARNING: Failed to install $cmd using Homebrew.${NC}"
            fi
        else
            echo -e "${YELLOW}Installing $cmd using GitHub release...${NC}"
            if ! curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_$(uname -s)_$(uname -m).tar.gz" | tar -xz -C /usr/local/bin; then
                echo -e "${RED}WARNING: Failed to install $cmd.${NC}"
            fi
        fi
        log_success "$cmd installed successfully"
    elif [[ "$cmd" == "just" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}Installing $cmd using Homebrew...${NC}"
            if ! brew install just; then
                echo -e "${RED}WARNING: Failed to install $cmd using Homebrew.${NC}"
            fi
        else
            echo -e "${YELLOW}Installing $cmd using GitHub release...${NC}"
            if ! curl -fsSL "https://github.com/casey/just/releases/latest/download/just-$(uname -s)-$(uname -m).tar.gz" | tar -xz -C /usr/local/bin; then
                echo -e "${RED}WARNING: Failed to install $cmd.${NC}"
            fi
        fi
        log_success "$cmd installed successfully"
    else
        error_exit "$cmd is not installed. Please install $cmd and try again."
    fi
}

# Check for SDKMAN! and source it if available
check_sdkman() {
    SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
    if [[ -s "$SDKMAN_INIT" ]]; then
        # shellcheck source=/dev/null
        source "$SDKMAN_INIT"
        log_check "SDKMAN! available for Java development"
    else
        echo
        echo -e "${RED}SDKMAN! not found${NC}"
        echo -e "${YELLOW}SDKMAN! is required for dotCMS Java development tools.${NC}"
        echo
        echo -e "${BLUE}To install SDKMAN!:${NC}"
        echo -e "${GREEN}curl -s https://get.sdkman.io | bash${NC}"
        echo
        echo -e "${YELLOW}Then restart your terminal and run this script again.${NC}"
        exit 1
    fi
}

# Install JBang using SDKMAN
install_jbang() {
    if command -v sdk >/dev/null 2>&1; then
        if ! command -v jbang >/dev/null 2>&1; then
            log_task "Installing JBang using SDKMAN..."
            if sdk install jbang; then
                log_success "JBang installed"
            else
                log_warning "Failed to install JBang using SDKMAN"
            fi
        else
            log_check "JBang already available"
        fi
    else
        log_warning "SDKMAN not available for JBang installation"
    fi
}

# Install NVM (Node Version Manager)
install_nvm() {
    # Check if nvm is available (it's a shell function)
    if ! type nvm >/dev/null 2>&1 && [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
        log_task "Installing NVM (Node Version Manager)..."
        if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash >/dev/null 2>&1; then
            log_success "NVM installed"
        else
            log_warning "Failed to install NVM"
        fi
    else
        log_check "NVM already available"
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -r|--ref) EXPLICIT_REF="$2"; REF="$2"; BRANCH="$2"; shift ;;  # Override auto-detected ref
            -b|--branch) EXPLICIT_REF="$2"; REF="$2"; BRANCH="$2"; shift ;;  # Backward compatibility
            -d|--directory) CUSTOM_DIR="$2"; shift ;;
            -u|--uninstall) UNINSTALL=true ;;
            -f|--force) FORCE=true ;;
            -q|--quiet) QUIET=true ;;
            -h|--help) show_help; exit 0 ;;
            *) error_exit "Unknown parameter passed: $1" ;;
        esac
        shift
    done
}

show_help() {
    echo -e "${BLUE}install-dev-scripts.sh - Install dotCMS development Git extensions${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 [options]"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "  -r, --ref <ref>          Install from specific branch, tag, or commit (default: main)"
    echo "  -b, --branch <branch>    Install from specific branch (legacy, use --ref instead)"
    echo "  -d, --directory <dir>    Custom installation directory (default: ~/.dotcms/dev-scripts)"
    echo "  -f, --force              Force reinstallation even if up to date"
    echo "  -q, --quiet              Minimal output"
    echo "  -u, --uninstall          Uninstall all Git extensions"
    echo "  -h, --help               Show this help message"
    echo
    echo -e "${YELLOW}What this script does:${NC}"
    echo "  • Installs Git extensions to ~/.dotcms/dev-scripts/"
    echo "  • Adds installation directory to your PATH (with permission)"
    echo "  • Checks/installs development tools (fzf, gh, just)"
    echo "  • Verifies SDKMAN! availability for Java development"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo "  # Auto-detects ref from URL:"
    echo "  curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh | bash"
    echo "  curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/dev-branch/install-dev-scripts.sh | bash"
    echo "  curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/v1.2.0/install-dev-scripts.sh | bash"
    echo
    echo "  # Local execution:"
    echo "  $0                       # Install/update with defaults"
    echo "  $0 --force               # Force reinstall all scripts"
    echo "  $0 --ref dev             # Override to install from dev branch"
    echo "  $0 --quiet               # Install with minimal output"
    echo
    echo -e "${YELLOW}Git Extensions Installed:${NC}"
    for script in "${SCRIPTS[@]}"; do
        if [[ "$script" == git-* ]]; then
            echo "  ${script/git-/git } (calls $script)"
        fi
    done
}

# Determine installation directory
set_install_dir() {
    if [ -n "$CUSTOM_DIR" ]; then
        BIN_DIR="$CUSTOM_DIR"
    else
        BIN_DIR="$HOME/.dotcms/dev-scripts"
    fi

# Ensure the bin directory exists
    mkdir -p "$BIN_DIR"

    # Determine the current shell and update only its RC file
    update_shell_rc
}

# Update the appropriate shell RC file
update_shell_rc() {
    local path_entry

    case "$SHELL" in
        */bash) rc_file="$HOME/.bashrc" ;;
        */zsh)  rc_file="$HOME/.zshrc" ;;
        *)      echo "Unsupported shell: $SHELL. Please add $BIN_DIR to your PATH manually."; return ;;
    esac

    # Replace full path with $HOME if applicable
    if [[ "$BIN_DIR" == "$HOME"* ]]; then
        path_entry="\$HOME${BIN_DIR#"$HOME"}"
    else
        path_entry="$BIN_DIR"
    fi

    # Check if the path is already in the rc file
    if ! grep -q "export PATH=.*$path_entry" "$rc_file" 2>/dev/null; then
        if [[ "$FORCE" == "true" || "$QUIET" == "true" ]]; then
            # Auto-add in force/quiet mode with clear messaging
            echo
            echo -e "${BLUE}🔐 SECURITY: Adding to PATH${NC}"
            log_task "Adding $BIN_DIR to PATH in $rc_file"
            echo "export PATH=\"\$PATH:$path_entry\"" >> "$rc_file"
            log_success "Added to PATH in $rc_file"
            echo -e "${BLUE}💡 Note:${NC} Restart terminal or run: source $rc_file"
        else
            echo
            echo -e "${BLUE}SECURITY NOTICE:${NC}"
            echo -e "${YELLOW}This script needs to add $BIN_DIR to your PATH.${NC}"
            echo -e "${YELLOW}This will modify your $rc_file file.${NC}"
            echo
            echo -e "${BLUE}What this enables:${NC}"
            echo "  • Run git extensions: git issue-create, git issue-branch, etc."
            echo "  • Access dotCMS development tools from anywhere"
            echo
            echo -e "${BLUE}The line added will be:${NC}"
            echo -e "${GREEN}export PATH=\"\$PATH:$path_entry\"${NC}"
            echo
            echo -e "${YELLOW}Add $BIN_DIR to your PATH? (y/n) [y]:${NC} "
            read -r REPLY
            if [[ $REPLY =~ ^[Yy]$ || -z "$REPLY" ]]; then
                echo "export PATH=\"\$PATH:$path_entry\"" >> "$rc_file"
                log_success "Added to PATH in $rc_file"
                echo -e "${BLUE}💡 Note:${NC} Restart terminal or run: source $rc_file"
            else
                echo
                log_warning "PATH not modified. Add manually to use git extensions:"
                echo -e "${BLUE}export PATH=\"\$PATH:$path_entry\"${NC}"
            fi
        fi
    else
        log_check "$BIN_DIR already in PATH"
    fi
}

# Function to download and install a script
install_script() {
    local script_name="$1"

    # Base path and URL
    local base_path="./dev-scripts/"
    local base_url="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$REF/dev-scripts/"

    # Determine the script file extension based on naming convention

    local script_name_ext="${script_name}"
    if [[ "$script_name" != git-* ]]; then
        script_name_ext="${script_name}.sh"
    fi

    local local_script_path="${base_path}${script_name_ext}"
    local script_url="${base_url}${script_name_ext}"


    # Check if local script is available
    if [[ -f "$local_script_path" ]]; then
        log_task "Installing $script_name (local)"
        cp "$local_script_path" "$BIN_DIR/$script_name_ext"
        log_success "$script_name_ext installed"
    else
        log_task "Downloading $script_name from ref $REF"
        tmp_file=$(mktemp)
        if curl -sL -w "%{http_code}" "$script_url" -o "$tmp_file" | grep -q "200"; then
            mv "$tmp_file" "$BIN_DIR/$script_name_ext"
            log_success "$script_name_ext downloaded"
        else
            rm "$tmp_file" 2>/dev/null || true
            error_exit "Failed to download $script_name_ext from $script_url"
        fi
    fi

    chmod +x "$BIN_DIR/$script_name_ext"

    # Convert line endings to Unix format
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/\r$//' "$BIN_DIR/$script_name_ext"
    else
        sed -i 's/\r$//' "$BIN_DIR/$script_name_ext"
    fi
}

# Function to uninstall scripts
uninstall_scripts() {
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$BIN_DIR/$script" ]; then
            rm "$BIN_DIR/$script"
            echo -e "${GREEN}Uninstalled $script${NC}"
        else
            echo -e "${YELLOW}$script was not found in $BIN_DIR${NC}"
        fi
    done
    echo -e "${BLUE}Uninstallation complete. You may want to remove $BIN_DIR from your PATH if it's no longer needed.${NC}"
}

# Function to check and install Homebrew on macOS
install_homebrew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            log_task "Installing Homebrew..."
            if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1; then
                log_success "Homebrew installed"
            else
                log_warning "Failed to install Homebrew. Manual installation may be needed."
            fi
        else
            log_check "Homebrew available"
        fi
    else
        log_check "Not on macOS, skipping Homebrew"
    fi
}

# Main execution
main() {
    # First detect ref from environment or other sources
    if [[ -z "$REF" || "$REF" == "main" ]]; then
        REF=$(detect_or_prompt_ref)
        BRANCH="$REF"
    fi
    
    # Then parse arguments (which might override the detected ref)
    parse_arguments "$@"
    if [[ "$QUIET" != "true" ]]; then
        echo
        echo -e "${BLUE}🔧 dotCMS Development Tools Installer v$VERSION${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Determine the source of installation
        local install_source="remote"
        local script_dir
        script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")")"
        if [[ -d "$script_dir/.git" || -f "$script_dir/../.git" ]] && [[ -f "$script_dir/dev-scripts/git-issue-create" || -f "dev-scripts/git-issue-create" ]]; then
            install_source="local"
        fi
        
        if [[ "$install_source" == "local" ]]; then
            echo -e "${BLUE}📍 Installing from local source (branch: $REF)${NC}"
            if [[ "$REF" != "main" ]]; then
                echo -e "${YELLOW}⚠️  Using local branch '$REF'. To install from main: bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)${NC}"
            fi
        else
            echo -e "${BLUE}📍 Installing from remote ref: $REF${NC}"
            if [[ "$REF" != "main" ]]; then
                echo -e "${YELLOW}⚠️  Using non-default ref. To return to main: bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)${NC}"
            elif [[ -z "$EXPLICIT_REF" && "$REF" == "main" ]]; then
                echo -e "${BLUE}💡 To install from a different branch: add --ref <branch-name> or use that branch in the URL${NC}"
            fi
        fi
        echo
    fi
    
    # Quick exit for uninstall
    if [[ "$UNINSTALL" == "true" ]]; then
        set_install_dir
        uninstall_scripts
        return 0
    fi
    
    # Set up installation directory first
    set_install_dir
    
    # Validate the ref if it's not main and not a force/quiet install
    if [[ "$REF" != "main" && "$FORCE" != "true" && "$QUIET" != "true" ]]; then
        if ! validate_ref "$REF"; then
            exit 1
        fi
    fi
    
    # Check dependencies and tools
    check_dependencies
    check_sdkman  
    install_homebrew
    install_jbang
    install_nvm

    # Main installation/update logic
    local update_needed=false
    local first_install=false
        
        if [[ ! -f "$BIN_DIR/.version" ]]; then
            first_install=true
            update_needed=true
            log_task "First installation detected"
        elif [[ "$CHECK_UPDATES" == "true" ]]; then
            if check_for_updates; then
                update_needed=true
                if [[ "$FORCE" != "true" && "$QUIET" != "true" ]]; then
                    echo -e "${YELLOW}Update available. Install? (y/n) [y]:${NC} "
                    read -r REPLY
                    if [[ ! $REPLY =~ ^[Yy]$ && -n "$REPLY" ]]; then
                        log_warning "Update cancelled"
                        exit 0
                    fi
                fi
            fi
        fi
        
        if [[ "$FORCE" == "true" ]]; then
            update_needed=true
            log_task "Force installation requested"
        fi

        if [[ "$update_needed" == "true" ]]; then
            echo
            echo -e "${BLUE}📥 Installing Git extensions to:${NC} $BIN_DIR"
            log_task "Downloading from github.com/dotcms/dotcms-utilities"
            
            for script in "${SCRIPTS[@]}"; do
                install_script "$script"
            done
            
            # Save the new version hash and ref information
            if ! get_latest_commit_hash > "$BIN_DIR/.version" 2>/dev/null; then
                log_warning "Could not save version information"
            fi
            
            # Save the ref that was used for installation
            echo "$REF" > "$BIN_DIR/.ref" 2>/dev/null || true
            
            # Save installation source information
            local install_source="remote"
            local script_dir
            script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")")"
            if [[ -d "$script_dir/.git" || -f "$script_dir/../.git" ]] && [[ -f "$script_dir/dev-scripts/git-issue-create" || -f "dev-scripts/git-issue-create" ]]; then
                install_source="local"
            fi
            echo "$install_source" > "$BIN_DIR/.source" 2>/dev/null || true
            
            echo
            if [[ "$first_install" == "true" ]]; then
                echo
                echo -e "${GREEN}🎉 Installation Complete!${NC}"
            else
                echo
                echo -e "${GREEN}🎉 Update Complete!${NC}"
            fi
        else
            log_success "All Git extensions up to date"
            if [[ "$QUIET" != "true" ]]; then
                echo -e "${BLUE}💡 Tip:${NC} Use --force to reinstall"
            fi
        fi

        if [[ "$QUIET" != "true" ]]; then
            echo
            echo -e "${BLUE}📦 Available Git Extensions:${NC}"
            echo -e "${GREEN}  ▶ git issue-create${NC} 'Fix login bug' --type Defect --branch"
            echo -e "${GREEN}  ▶ git issue-branch${NC}  # Select issue and create/switch branch"
            echo -e "${GREEN}  ▶ git issue-pr${NC}      # Create PR linked to current issue"
            echo -e "${GREEN}  ▶ git smart-switch${NC}  # Enhanced branch switching"
            echo
            echo -e "${BLUE}💡 Getting Help:${NC}"
            echo -e "  • Help available: ${GREEN}git-issue-create --help${NC} (with hyphen)"
            echo -e "  • Interactive mode: ${GREEN}git issue-create${NC} (launches wizard)"
            echo -e "  • Quick commands: ${GREEN}git issue-branch${NC}, ${GREEN}git issue-pr${NC}, ${GREEN}git smart-switch${NC}"
            echo -e "  • ${YELLOW}Note:${NC} 'git [command] --help' may show man page errors"
            echo
        fi
}

# Run the main function
main "$@"