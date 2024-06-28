#!/bin/bash

# GitHub repository information
REPO_OWNER="dotcms"
REPO_NAME="dotcms-utilities"
BRANCH="master"
VERSION="1.0.2"

# List of scripts to install (add your script names here)
SCRIPTS=(
    "git-issue-branch"
    "git-issue-pr"
    "git-smart-switch"
)

# Logging function
log() {
    echo "$1"
}

# Error handling function
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check for required tools
check_dependencies() {
    for cmd in git curl fzf gh just; do
        echo "Checking for $cmd..."
        command -v "$cmd" >/dev/null 2>&1 || install_dependency "$cmd"
    done
}

# Install a missing dependency
install_dependency() {
    local cmd="$1"
    if [[ "$cmd" == "fzf" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Installing $cmd using Homebrew..."
            if ! brew install fzf; then
                echo "WARNING: Failed to install $cmd using Homebrew."
            fi
        else
            echo "Installing $cmd using GitHub release..."
            if ! git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || ! ~/.fzf/install; then
                echo "WARNING: Failed to install $cmd."
            fi
        fi
        echo "$cmd installed successfully."
    elif [[ "$cmd" == "gh" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Installing $cmd using Homebrew..."
            if ! brew install gh; then
                echo "WARNING: Failed to install $cmd using Homebrew."
            fi
        else
            echo "Installing $cmd using GitHub CLI release..."
            if ! curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
               sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
               echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
               sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null &&
               sudo apt update &&
               sudo apt install gh; then
                echo "WARNING: Failed to install $cmd."
            fi
        fi
        echo "$cmd installed successfully."
    elif [[ "$cmd" == "just" ]]; then
        echo "Installing $cmd..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if ! brew install just; then
                echo "WARNING: Failed to install $cmd using Homebrew."
            fi
        else
            if ! curl -fsSL https://just.systems/install.sh | bash -s -- --to /usr/local/bin; then
                echo "WARNING: Failed to install $cmd."
            fi
        fi
        echo "$cmd installed successfully."
    else
        error_exit "$cmd is not installed. Please install $cmd and try again."
    fi
}

# Check for SDKMAN! and source it if available
check_sdkman() {
    SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
    if [[ -s "$SDKMAN_INIT" ]]; then
        source "$SDKMAN_INIT"
        echo "SDKMAN! sourced from $SDKMAN_INIT"
    else
        echo "SDKMAN! not found at $SDKMAN_INIT. Please install SDKMAN! first."
        exit 1
    fi
}

# Install JBang using SDKMAN
install_jbang() {
    if command -v sdk >/dev/null 2>&1; then
        echo "Installing JBang using SDKMAN..."
        if sdk install jbang; then
            echo "JBang installed successfully."
        else
            echo "WARNING: Failed to install JBang using SDKMAN."
        fi
    else
        error_exit "SDKMAN is not installed. Please install SDKMAN and try again."
    fi
}

# Install NVM (Node Version Manager)
install_nvm() {
    if ! command -v nvm >/dev/null 2>&1; then
        echo "Installing NVM (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
        echo "NVM installed successfully."
    else
        echo "NVM is already installed."
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -b|--branch) BRANCH="$2"; shift ;;
            -d|--directory) CUSTOM_DIR="$2"; shift ;;
            -u|--uninstall) UNINSTALL=true ;;
            -h|--help) show_help; exit 0 ;;
            *) error_exit "Unknown parameter passed: $1" ;;
        esac
        shift
    done
}

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -b, --branch <branch>    Specify the branch to install from (default: master)"
    echo "  -d, --directory <dir>    Specify a custom installation directory"
    echo "  -u, --uninstall          Uninstall the Git extensions"
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
        # Ask the user if they want to automatically add the path
        read -p "Do you want to automatically add $BIN_DIR to your PATH in $rc_file? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "export PATH=\"\$PATH:$path_entry\"" >> "$rc_file"
            echo "Added $BIN_DIR to PATH in $rc_file. Please restart your terminal or run 'source $rc_file'."
        else
            echo "Please add $BIN_DIR to your PATH manually by adding the following line to your $rc_file:"
            echo "export PATH=\"\$PATH:$path_entry\""
        fi
    else
        echo "$BIN_DIR is already in PATH in $rc_file."
    fi
}

# Function to download and install a script
install_script() {
    local script_name="$1"

    # Determine the script file extension based on naming convention
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
        echo "Using local version of $script_name..."
        cp "$local_script_path" "$BIN_DIR/$script_name"
    else
        echo "Downloading $script_name from branch $BRANCH..."
        tmp_file=$(mktemp)
        if curl -sL -w "%{http_code}" "$script_url" -o "$tmp_file" | grep -q "200"; then
            mv "$tmp_file" "$BIN_DIR/$script_name"
            echo "$script_name has been installed to $BIN_DIR"
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
            echo "Uninstalled $script"
        else
            echo "$script was not found in $BIN_DIR"
        fi
    done
    echo "Uninstallation complete. You may want to remove $BIN_DIR from your PATH if it's no longer needed."
}

# Function to check and install Homebrew on macOS
install_homebrew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ $? -eq 0 ]; then
                echo "Homebrew installed successfully."
            else
                error_exit "Failed to install Homebrew."
            fi
        else
            echo "Homebrew is already installed."
        fi
    else
        echo "Not on macOS. Skipping Homebrew installation."
    fi
}

# Main execution
main() {
    echo "Starting installation script v$VERSION"
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
        for script in "${SCRIPTS[@]}"; do
            install_script "$script"
        done
        echo "Installation complete. Installed dev-scripts from branch $BRANCH: ${SCRIPTS[*]}"
        echo
        echo "Scripts starting git- are available as git extensions and can be run"
        echo "with 'git <script>' e.g. git-smart-switch can be run as 'git smart-switch'"
    fi
}

# Run the main function
main "$@"