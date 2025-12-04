# Git Worktree Quick Start Guide

**Note:** This guide uses `~/git/` as an example location for repositories. The worktree structure works in **any directory** you choose - `/projects/`, `/workspace/`, your home directory, etc. All worktrees stay **inside the repository directory**, keeping everything self-contained and portable.

## TL;DR - Get Started

### Option A: Fresh Clone (Recommended)

```bash
# 1. Clone with worktree structure built-in
git clone-worktree git@github.com:dotCMS/core.git dotcms-core

# 2. Create worktree for an issue (same command as traditional repos!)
cd dotcms-core
git issue-branch --issue 123

# 3. Open in your IDE
cd worktrees/issue-123-feature
cursor .  # or code . or idea .
```

### Option B: Migrate Existing Repository

```bash
# 1. Migrate your repository
cd ~/git/dotcms-core
git migrate-to-worktrees

# 2. Create worktree for an issue (auto-detects worktree structure!)
git issue-branch --issue 123

# 3. Open in your IDE
cd worktrees/issue-123-feature
cursor .  # or code . or idea .
```

Done! Now you can work on multiple issues simultaneously.

## Essential Commands

### Safe Branch Switching (IMPORTANT!)
```bash
git smart-switch feature-branch       # Safe! Navigates to worktree
git checkout feature-branch           # ⚠️ DANGEROUS in worktree!

# The safe way - prevents accidental branch changes
git smart-switch issue-123            # Finds or creates worktree
git smart-switch main                 # Navigates to main worktree
```

### Create Worktree for Issue
```bash
# NO ISSUE NUMBER NEEDED - Interactive selection!
git issue-branch
# → Shows searchable list of your issues
# → Type to filter, arrow keys to select
# → Works in both traditional and worktree repos

git issue-branch --issue 123          # Direct issue number (if you know it)
git issue-branch --open-ide cursor    # Interactive + auto-open IDE
```

### Open IDE for Worktree
```bash
git worktree-ide                      # Interactive selection
git worktree-ide worktrees/issue-123  # Open specific worktree
```

### List Worktrees
```bash
git worktree list                     # Built-in git command
git worktree-cleanup --list           # With merge status
```

### Clean Up Merged Worktrees
```bash
git worktree-cleanup                  # Interactive cleanup
git worktree-cleanup --dry-run        # Preview
```

### Setup Aliases (Optional)
```bash
# Run once to set up short aliases
./setup-worktree-aliases.sh

# Then use shorter commands:
git wti --issue 123                   # wt-issue
git wts feature-branch                # wt-switch
git wtc                               # wt-cleanup
```

## Workflow Comparison

### Old Way (Branch Switching)
```bash
git checkout main
git checkout -b issue-123
# work...
git checkout main              # ❌ Lose context
git checkout -b issue-456
# work...
git checkout issue-123         # ❌ Switch again
```

### New Way (Worktrees)
```bash
git issue-branch --issue 123    # Same command as before!
git issue-branch --issue 456    # Auto-detects worktree structure
# Just switch IDE windows! ✅
# No git checkout needed
```

## Real-World Examples

### Example 1: Multiple AI Agents
```bash
# Terminal 1: Agent working on backend
git issue-branch --issue 100
cd worktrees/issue-100-backend-api
cursor .

# Terminal 2: Agent working on frontend
git issue-branch --issue 101
cd worktrees/issue-101-frontend-ui
cursor .

# Both agents work in complete isolation ✅
```

### Example 2: Emergency Hotfix During Feature Work
```bash
# Currently working on feature in worktrees/issue-123-feature/
cursor .  # IDE open here

# Emergency hotfix needed!
git issue-branch --issue 999 --open-ide cursor
# New Cursor window opens for issue-999
# Fix bug, commit, push

# Close issue-999 window
# Return to issue-123 window - exactly where you left off ✅
```

### Example 3: Code Review While Developing
```bash
# Working on your feature
cd worktrees/issue-123-my-feature

# Colleague asks for code review
git issue-branch --issue 456 --open-ide code
# Review code in VS Code

# Close review window
# Return to your feature window ✅
```

## Directory Structure Visual

```
~/git/dotcms-core/
├── .git/                          # Shared git metadata
├── worktrees/                     # All your work happens here
│   ├── main/                      # ← Always available
│   ├── issue-123-add-auth/        # ← Current feature
│   ├── issue-456-fix-cache/       # ← Parallel work
│   └── issue-789-update-docs/     # ← Another task
├── docs/                          # Optional: keep in main
└── README.md
```

## Common Scenarios

### Migrating from ~/git/core2
```bash
# If you have:
# ~/git/core-baseline/  (main clone)
# ~/git/core2/          (existing worktree)

cd ~/git/core-baseline
git migrate-to-worktrees

# Now delete core2:
rm -rf ~/git/core2

# Use worktrees instead (same command as before!):
git issue-branch --issue 123
# Creates: ~/git/core-baseline/worktrees/issue-123-*/
```

### Setting Default IDE
```bash
# Set once, use everywhere
git config --global worktree.defaultIde cursor

# Now this automatically uses cursor:
git issue-worktree --issue 123 --open-ide
```

### Checking Disk Usage
```bash
# Worktrees are lightweight
du -sh .git/           # ~500MB (shared metadata)
du -sh worktrees/*/    # ~200MB each (just files)

# Compare to cloning 3 times:
# 3 clones = 3 × 500MB = 1.5GB
# 3 worktrees = 500MB + 3 × 200MB = 1.1GB
```

## Troubleshooting

### "worktree already exists"
```bash
# Remove existing worktree first
git worktree remove worktrees/issue-123-feature

# Or remove orphaned entry
git worktree prune
```

### Lost uncommitted changes after migration
```bash
# Check stash
git stash list

# Apply to worktree
cd worktrees/<branch-name>
git stash pop
```

### IDE not opening
```bash
# Check IDE is installed and in PATH
which cursor  # or: code, idea
```

## Pro Tips

1. **Keep main worktree** - Always have `worktrees/main/` for quick reference
2. **Name IDE windows** - Cursor/Code let you name windows by branch
3. **Use separate terminals** - One terminal tab per worktree
4. **Weekly cleanup** - Run `git worktree-cleanup` to remove merged branches
5. **IDE bookmarks** - Bookmark `~/git/dotcms-core/worktrees/` for quick access

## Need More Info?

- Full documentation: [WORKTREE_WORKFLOW.md](./WORKTREE_WORKFLOW.md)
- Script source: `/Users/stevebolton/git/dotcms-utilities/dev-scripts/`
- Git documentation: `man git-worktree`

## Safety Features

### Why `git smart-switch`?

**The Problem:**
```bash
cd ~/git/dotcms-core/worktrees/issue-123-feature/
git checkout main  # ⚠️ DANGER! Changes branch in worktree directory
# Now worktree/issue-123-feature contains main branch - CONFUSING!
```

**The Solution:**
```bash
cd ~/git/dotcms-core/worktrees/issue-123-feature/
git smart-switch main  # ✅ SAFE! Shows you main worktree path
# Prevents accidental branch change, guides you to correct worktree
```

### What `git smart-switch` Does:

1. **Detects worktree structure** - Knows when you're in worktrees/
2. **Prevents accidents** - Blocks accidental branch changes in worktrees
3. **Finds correct worktree** - Shows path to target branch's worktree
4. **Creates if missing** - Makes new worktree for existing branches
5. **Migrates old worktrees** - Automatically moves old worktrees to new structure
6. **Preserves safety** - Ensures worktree names match their branches

## Quick Reference Card

| Task | Command |
|------|---------|
| Clone with worktrees | `git clone-worktree <repo-url> [dir]` |
| Migrate repo | `git migrate-to-worktrees` |
| **Create branch/worktree** | **`git issue-branch --issue 123`** (adapts!) |
| **Safe branch switch** | **`git smart-switch <branch>`** |
| Open IDE | `git worktree-ide` |
| List worktrees | `git worktree list` |
| Clean up | `git worktree-cleanup` |
| Remove worktree | `git worktree remove worktrees/branch` |
| Get help | `git issue-branch --help` |