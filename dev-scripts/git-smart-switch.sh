#!/bin/bash
# Shell function wrapper for git-smart-switch that enables automatic directory navigation
# Source this in your .zshrc or .bashrc

# Override git-smart-switch function (takes priority over PATH executables in zsh)
function git-smart-switch() {
    # Run the actual git-smart-switch command and capture output
    local temp_file=$(mktemp)
    /Users/stevebolton/.dotcms/dev-scripts/git-smart-switch "$@" 2>&1 | tee "$temp_file"
    local exit_code=${PIPESTATUS[0]}
    
    # Get the last line (potential worktree path)
    local last_line=$(tail -n 1 "$temp_file")
    rm -f "$temp_file"
    
    # Check if last line is a valid directory path
    if [[ -d "$last_line" ]]; then
        echo ""
        echo "Changing directory to worktree..."
        cd "$last_line" || return 1
    fi
    
    return $exit_code
}

# Override git smart-switch as well (for when called via git)
function git() {
    if [[ "$1" == "smart-switch" ]]; then
        shift
        git-smart-switch "$@"
    else
        command git "$@"
    fi
}

# Short alias
alias gss='git-smart-switch'
