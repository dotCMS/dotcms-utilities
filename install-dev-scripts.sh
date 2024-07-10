#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub repository information
REPO_OWNER="dotcms"
REPO_NAME="dotcms-utilities"
BRANCH="main"
VERSION="1.0.2"
CHECK_UPDATES=true
FORCE=false

# List of scripts to install (add your script names here)
SCRIPTS=(
    "git-issue-branch"
    "git-issue-pr"
    "git-smart-switch"
    "check_updates"
)

# Logging function
log() {
    echo "$1"
}

# Error handling function
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

get_latest_commit_hash() {
    local api_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/$BRANCH"
    local commit_hash=$(curl -s "$api_url" | grep -m 1 '"sha":' | cut -d '"' -f 4)
    echo "$commit_hash"
}

check_for_updates() {
    local installed_hash
    local latest_hash
    echo -e "Checking $BIN_DIR/.version for installed version..."
    # Read the installed version hash
    if [[ -f "$BIN_DIR/.version" ]]; then
        installed_hash=$(cat "$BIN_DIR/.version")
    else
        echo -e "${YELLOW}No version information found. This might be an older installation.${NC}"
        installed_hash=""
    fi

    # Get the latest commit hash
    latest_hash=$(get_latest_commit_hash)

    if [[ -z "$latest_hash" ]]; then
        echo -e "${RED}Failed to fetch the latest version information.${NC}"
        return 1
    fi

    if [[ -z "$installed_hash" || "$installed_hash" != "$latest_hash" ]]; then
        echo -e "${GREEN}An update is available.${NC}"
        if [[ -n "$installed_hash" ]]; then
            echo -e "Installed version: ${YELLOW}$installed_hash${NC}"
        else
            echo -e "Installed version: ${YELLOW}Unknown (older installation)${NC}"
        fi
        echo -e "Latest version: ${GREEN}$latest_hash${NC}"
        echo -e "${BLUE}Changes:${NC}"

        # Fetch the commit messages along with short commit id and date
        if [[ -n "$installed_hash" ]]; then
            curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/compare/$installed_hash...$latest_hash" | \
                jq -r '.commits[] | "Commit: \(.sha[0:7]) Date: \(.commit.committer.date) Message: \(.commit.message)"' | \
                sed 's/^/  /'
        else
            echo "  Unable to show detailed changes (no previous version found)"
            echo "  It's recommended to update to get the latest features and improvements."
        fi

        return 0  # Update is available
    else
        echo -e "${GREEN}You have the latest version installed.${NC}"
        return 1  # No update needed
    fi
}

# Check for required tools
check_dependencies() {
    for cmd in git curl fzf gh just; do
        echo -e "${BLUE}Checking for $cmd...${NC}"
        command -v "$cmd" >/dev/null 2>&1 || install_dependency "$cmd"
    done
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
        echo -e "${GREEN}$cmd installed successfully.${NC}"
    elif [[ "$cmd" == "gh" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}Installing $cmd using Homebrew...${NC}"
            if ! brew install gh; then
                echo -e "${RED}WARNING: Failed to install $cmd using Homebrew.${NC}"
            fi
        else
            echo -e "${YELLOW}Installing $cmd using GitHub release...${NC}"
            if ! curl -fsSL https://github.com/cli/cli/releases/latest/download/gh_$(uname -s)_$(uname -m).tar.gz | tar -xz -C /usr/local/bin; then
                echo -e "${RED}WARNING: Failed to install $cmd.${NC}"
            fi
        fi
        echo -e "${GREEN}$cmd installed successfully.${NC}"
    elif [[ "$cmd" == "just" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}Installing $cmd using Homebrew...${NC}"
            if ! brew install just; then
                echo -e "${RED}WARNING: Failed to install $cmd using Homebrew.${NC}"
            fi
        else
            echo -e "${YELLOW}Installing $cmd using GitHub release...${NC}"
            if ! curl -fsSL https://github.com/casey/just/releases/latest/download/just-$(uname -s)-$(uname -m).tar.gz | tar -xz -C /usr/local/bin; then
                echo -e "${RED}WARNING: Failed to install $cmd.${NC}"
            fi
        fi
        echo -e "${GREEN}$cmd installed successfully.${NC}"
    else
        error_exit "$cmd is not installed. Please install $cmd and try again."
    fi
}

# Check for SDKMAN! and source it if available
check_sdkman() {
    SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
    if [[ -s "$SDKMAN_INIT" ]]; then
        source "$SDKMAN_INIT"
        echo -e "${GREEN}SDKMAN! sourced from $SDKMAN_INIT${NC}"
    else
        echo -e "${RED}SDKMAN! not found at $SDKMAN_INIT. Please install SDKMAN! first.${NC}"
        exit 1
    fi
}

# Install JBang using SDKMAN
install_jbang() {
    if command -v sdk >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing JBang using SDKMAN...${NC}"
        if sdk install jbang; then
            echo -e "${GREEN}JBang installed successfully.${NC}"
        else
            echo -e "${RED}WARNING: Failed to install JBang using SDKMAN.${NC}"
        fi
    else
        error_exit "SDKMAN is not installed. Please install SDKMAN and try again."
    fi
}

# Install NVM (Node Version Manager)
install_nvm() {
    if ! command -v nvm >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing NVM (Node Version Manager)...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
        echo -e "${GREEN}NVM installed successfully.${NC}"
    else
        echo -e "${GREEN}NVM is already installed.${NC}"
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -b|--branch) BRANCH="$2"; shift ;;
            -d|--directory) CUSTOM_DIR="$2"; shift ;;
            -u|--uninstall) UNINSTALL=true ;;
            -f|--force) FORCE=true ;;
            -h|--help) show_help; exit 0 ;;
            *) error_exit "Unknown parameter passed: $1" ;;
        esac
        shift
    done
}

show_help() {
    echo -e "${BLUE}Usage: $0 [options]${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo "  -b, --branch <branch>    Specify the branch to install from (default: main)"
    echo "  -d, --directory <dir>    Specify a custom installation directory"
    echo "  -u, --uninstall          Uninstall the Git extensions"
    echo "  -f, --force              Force installation even if the version hasn't changed"
    echo "  -h, --help               Show this help message"
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
        path_entry="\$HOME${BIN_DIR#$HOME}"
    else
        path_entry="$BIN_DIR"
    fi

    # Check if the path is already in the rc file
    if ! grep -q "export PATH=.*$path_entry" "$rc_file"; then
        echo -e "${YELLOW}=======================================${NC}"
        echo -e "${YELLOW}Do you want to automatically add $BIN_DIR to your PATH in $rc_file? (y/n)${NC}"
        echo -e "${YELLOW}=======================================${NC}"

        read -p "Enter your choice: " REPLY
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "export PATH=\"\$PATH:$path_entry\"" >> "$rc_file"
            echo -e "${GREEN}Added $BIN_DIR to PATH in $rc_file. Please restart your terminal or run 'source $rc_file'.${NC}"
        else
            echo -e "${YELLOW}Please add $BIN_DIR to your PATH manually by adding the following line to your $rc_file:${NC}"
            echo -e "${BLUE}export PATH=\"\$PATH:$path_entry\"${NC}"
        fi
    else
        echo -e "${GREEN}$BIN_DIR is already in PATH in $rc_file.${NC}"
    fi
}

# Function to download and install a script
install_script() {
    local script_name="$1"

    # Base path and URL
    local base_path="./dev-scripts/"
    local base_url="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/dev-scripts/"

    # Determine the script file extension based on naming convention
    local local_script_path="${base_path}${script_name}"
    local script_url="${base_url}${script_name}"

    if [[ "$script_name" != git-* ]]; then
        local_script_path="${local_script_path}.sh"
        script_url="${script_url}.sh"
    fi

    # Check if local script is available
    if [[ -f "$local_script_path" ]]; then
        echo -e "${BLUE}Using local version of $script_name...${NC}"
        cp "$local_script_path" "$BIN_DIR"
    else
        echo -e "${YELLOW}Downloading $script_name from branch $BRANCH...${NC}"
        tmp_file=$(mktemp)
        if curl -sL -w "%{http_code}" "$script_url" -o "$tmp_file" | grep -q "200"; then
            mv "$tmp_file" "$BIN_DIR"
            echo -e "${GREEN}$script_name has been installed to $BIN_DIR${NC}"
        else
            rm "$tmp_file"
            error_exit "Failed to download $script_name from $script_url"
        fi
    fi

    chmod +x "$BIN_DIR/$script_name"

    # Convert line endings to Unix format
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/\r$//' "$BIN_DIR/$script_name"
    else
        sed -i 's/\r$//' "$BIN_DIR/$script_name"
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
            echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Homebrew installed successfully.${NC}"
            else
                error_exit "Failed to install Homebrew."
            fi
        else
            echo -e "${GREEN}Homebrew is already installed.${NC}"
        fi
    else
        echo -e "${BLUE}Not on macOS. Skipping Homebrew installation.${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Starting installation script v$VERSION${NC}"
    parse_arguments "$@"
    check_dependencies
    check_sdkman
    install_homebrew
    install_jbang
    install_nvm
    set_install_dir

    if [ "$UNINSTALL" = true ]; then
        uninstall_scripts
    else
        local update_needed=false
        if [ ! -f "$BIN_DIR/.version" ] || [ "$CHECK_UPDATES" = true ]; then
            if check_for_updates || [ "$FORCE" = true ]; then
                update_needed=true
                echo
                echo -e "${YELLOW}=======================================${NC}"
                echo -e "${YELLOW}  Do you want to update? (y/n)${NC}"
                echo -e "${YELLOW}=======================================${NC}"
                read -p "Enter your choice: " REPLY
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${RED}Update cancelled.${NC}"
                    exit 0
                fi
            fi
        fi

        if [ "$update_needed" = true ] || [ ! -f "$BIN_DIR/.version" ]; then
            for script in "${SCRIPTS[@]}"; do
                install_script "$script"
            done
            # Save the new version hash
            get_latest_commit_hash > "$BIN_DIR/.version"
            echo -e "${GREEN}Update/Installation complete.${NC}"
        else
            echo -e "${GREEN}No updates available. Current installation is up to date. use --force to reapply${NC}"
        fi

        echo
        echo -e "${BLUE}Installed dev-scripts from branch $BRANCH: ${SCRIPTS[*]}${NC}"
        echo
        echo -e "${YELLOW}Scripts starting git- are available as git extensions and can be run"
        echo -e "with 'git <script>' e.g. git-smart-switch can be run as 'git smart-switch'${NC}"
    fi
}

# Run the main function
main "$@"