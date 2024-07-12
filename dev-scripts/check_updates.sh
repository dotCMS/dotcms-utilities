#!/bin/bash

# Color definitions
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub repository information
REPO_OWNER="dotcms"
REPO_NAME="dotcms-utilities"
BRANCH="main"

# Cache file for the latest commit hash
CACHE_FILE="$HOME/.dotcms/dev-scripts/.dotcms_latest_hash"
CACHE_DURATION=7200 # 2 hours in seconds
# Function to log messages
log() {
    echo "$1"
}

# Function to handle errors silently
error_silent() {
    return 1
}

# Function to get the latest commit hash from the GitHub repository
get_latest_commit_hash() {
    local api_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/$BRANCH"
    local commit_hash=$(curl -s "$api_url" | grep -m 1 '"sha":' | cut -d '"' -f 4)
    echo "$commit_hash"
}

# Function to check for updates
check_for_updates() {
    local installed_hash
    local latest_hash
    # Read the installed version hash
    if [[ -f "$BIN_DIR/.version" ]]; then
        installed_hash=$(cat "$BIN_DIR/.version")
    else
        installed_hash=""
    fi

    # Check cache for the latest commit hash
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_mod_time=$(stat -f %m "$CACHE_FILE")
        local current_time=$(date +%s)
        local time_diff=$((current_time - cache_mod_time))

        if [[ $time_diff -lt $CACHE_DURATION ]]; then
            latest_hash=$(cat "$CACHE_FILE")
        else
            latest_hash=$(get_latest_commit_hash) || error_silent
            if [[ -n "$latest_hash" ]]; then
                echo "$latest_hash" > "$CACHE_FILE"
            fi
        fi

    else
        latest_hash=$(get_latest_commit_hash) || error_silent
        if [[ -n "$latest_hash" ]]; then
            echo "$latest_hash" > "$CACHE_FILE"
        fi
    fi

    if [[ -z "$latest_hash" ]]; then
        return 1
    fi

    if [[ -z "$installed_hash" || "$installed_hash" != "$latest_hash" ]]; then
        return 0  # Update is available
    else
        return 1  # No update needed
    fi
}

# Function to show update warning
show_update_warning() {
    if check_for_updates; then
        echo -e "${YELLOW}An update is available${NC}"
        echo -e "${YELLOW}To update, run:  ${NC}bash <(curl -fsSL https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/install-dev-scripts.sh)"
    fi
}

# Main function to execute the update check
main() {
    # Determine the directory of the calling script
    BIN_DIR="$HOME/.dotcms/dev-scripts"

    show_update_warning
}

# Run the main function
main