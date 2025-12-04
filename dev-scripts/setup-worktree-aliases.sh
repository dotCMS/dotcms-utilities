#!/bin/bash

# setup-worktree-aliases.sh - Configure git aliases for worktree workflow
# Makes worktree commands shorter and integrates with existing workflow

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up git aliases for worktree workflow...${NC}"
echo ""

# Determine script directory (where the actual scripts are)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add aliases to git config
echo -e "${BLUE}Configuring git aliases...${NC}"

# Core worktree aliases
git config --global alias.wt-clone "!f() { '$SCRIPT_DIR/git-clone-worktree' \"\$@\"; }; f"
git config --global alias.wt-migrate "!f() { '$SCRIPT_DIR/git-migrate-to-worktrees' \"\$@\"; }; f"
git config --global alias.wt-issue "!f() { '$SCRIPT_DIR/git-issue-worktree' \"\$@\"; }; f"
git config --global alias.wt-ide "!f() { '$SCRIPT_DIR/git-worktree-ide' \"\$@\"; }; f"
git config --global alias.wt-cleanup "!f() { '$SCRIPT_DIR/git-worktree-cleanup' \"\$@\"; }; f"

# Short aliases
git config --global alias.wti "!f() { '$SCRIPT_DIR/git-issue-worktree' \"\$@\"; }; f"  # wt-issue
git config --global alias.wtc "!f() { '$SCRIPT_DIR/git-worktree-cleanup' \"\$@\"; }; f"  # wt-cleanup

# Note: git-smart-switch is already available as 'git smart-switch' - no alias needed

# Convenience aliases
git config --global alias.wt-list "worktree list"
git config --global alias.wt-remove "worktree remove"
git config --global alias.wt-prune "worktree prune"

echo -e "${GREEN}✓ Git aliases configured${NC}"
echo ""

# Show configured aliases
echo -e "${BLUE}Configured aliases:${NC}"
echo ""
echo -e "${YELLOW}Core Commands:${NC}"
echo "  git wt-clone <url> [dir]      - Clone with worktree structure"
echo "  git wt-migrate                - Migrate existing repo to worktrees"
echo "  git wt-issue [--issue N]      - Create worktree from GitHub issue"
echo "  git wt-ide [worktree]         - Open IDE for worktree"
echo "  git smart-switch <branch>     - Safe branch switching (worktree-aware)"
echo "  git wt-cleanup                - Clean up merged worktrees"
echo ""
echo -e "${YELLOW}Short Aliases:${NC}"
echo "  git wti                       - Same as wt-issue"
echo "  git wtc                       - Same as wt-cleanup"
echo ""
echo -e "${YELLOW}Built-in Git:${NC}"
echo "  git wt-list                   - List all worktrees"
echo "  git wt-remove <path>          - Remove a worktree"
echo "  git wt-prune                  - Clean up worktree info"
echo ""

# Check if PATH includes script directory
if [[ ":$PATH:" != *":$SCRIPT_DIR:"* ]]; then
    echo -e "${YELLOW}Note: For direct command access (without 'git' prefix), add to PATH:${NC}"
    echo ""
    echo "  export PATH=\"\$PATH:$SCRIPT_DIR\""
    echo ""
    echo "Add to your ~/.bashrc or ~/.zshrc for permanent access"
    echo ""
fi

# Setup git-smart-switch shell function for automatic cd
echo -e "${BLUE}Setting up git-smart-switch wrapper...${NC}"

SHELL_RC=""
if [[ -n "$ZSH_VERSION" ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q "git-smart-switch.sh" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Git smart-switch wrapper for automatic directory navigation" >> "$SHELL_RC"
        echo "source $SCRIPT_DIR/git-smart-switch.sh" >> "$SHELL_RC"
        echo -e "${GREEN}✓ Added git-smart-switch wrapper to $SHELL_RC${NC}"
        echo -e "${YELLOW}Note: Run 'source $SHELL_RC' or restart your shell to activate${NC}"
    else
        echo -e "${GREEN}✓ git-smart-switch wrapper already configured${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not detect shell type. Manually add to your shell RC:${NC}"
    echo "  source $SCRIPT_DIR/git-smart-switch.sh"
fi
echo ""

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo "  git wt-clone git@github.com:dotCMS/core.git    # Clone new repo"
echo "  git wt-migrate                                  # Or migrate existing"
echo "  git wti --issue 123                             # Create worktree for issue"
echo "  git smart-switch feature-branch                 # Switch safely"
echo ""