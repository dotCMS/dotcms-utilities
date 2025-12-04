# Git Worktree Workflow Guide

## Overview

This guide documents a comprehensive git worktree-based workflow that allows you to work on multiple issues/branches simultaneously without switching contexts. Each branch gets its own isolated working directory.

## Benefits

✅ **No more branch switching** - Each branch has its own directory
✅ **Parallel development** - Work on multiple issues simultaneously
✅ **Clean separation** - No accidental commits to wrong branch
✅ **IDE friendly** - Open multiple IDEs, each on different branch
✅ **AI agent friendly** - Perfect for running multiple AI coding agents
✅ **Fast context switching** - Just switch IDE windows, not branches

## Directory Structure

**Note:** This example uses `~/git/` as the repository root, but this structure works **anywhere you clone repositories** - your home directory, `/projects/`, `/workspace/`, etc. The key is that all worktrees are contained **within the repository directory**, keeping everything self-contained and portable.

```
~/git/                              # Example location (use any directory you prefer)
├── dotcms-core/                    # Main repository (completely self-contained)
│   ├── .git/                       # All git metadata here
│   ├── worktrees/                  # All working trees live INSIDE the repo
│   │   ├── main/                   # Main branch worktree
│   │   ├── issue-123-add-feature/  # Issue #123 worktree
│   │   └── issue-456-fix-bug/      # Issue #456 worktree
│   ├── docs/                       # Optional: docs in base directory
│   └── README.md
│
└── dotcms-utilities/               # Another repo (regular clone, no worktrees)
    └── dev-scripts/
```

**Self-Contained Structure:**
- All worktrees are subdirectories within the repository
- Moving the repository directory moves all worktrees together
- No worktrees scattered across different filesystem locations
- Everything related to `dotcms-core` stays inside `dotcms-core/`

## Scripts

### 1. `git-migrate-to-worktrees`

Converts an existing repository to use the worktree workflow.

**Usage:**
```bash
# Preview migration
git migrate-to-worktrees --dry-run

# Perform migration
git migrate-to-worktrees
```

**What it does:**
1. Creates `worktrees/` directory
2. Moves current branch to `worktrees/<branch-name>/`
3. Preserves all uncommitted changes using git stash
4. Optionally creates worktree for main branch

**Safety features:**
- Detects and preserves uncommitted changes
- Confirms before making changes
- Dry-run mode to preview
- Handles existing worktrees gracefully

### 2. `git-issue-branch` (Unified Command)

Creates branches OR worktrees from GitHub issues - automatically adapts to repository structure!

**Usage:**
```bash
# Interactive issue selection - NO ISSUE NUMBER NEEDED!
git issue-branch
# → Shows searchable list of your assigned and recently created issues
# → Select with arrow keys or type to filter
# → Works in both traditional and worktree repos

# Direct issue number (if you already know it)
git issue-branch --issue 123

# Interactive selection with IDE launch (worktree repos)
git issue-branch --open-ide cursor
# → Select issue from list, then IDE opens automatically

# List all available issues
git issue-branch --list

# Preview what would happen (dry run)
git issue-branch --issue 123 --dry-run

# Automation mode (skip confirmations)
git issue-branch --issue 123 --yes
```

**No Issue Number Required:**
- Just run `git issue-branch` without any arguments
- Get an interactive, searchable list of issues
- Filter by typing (fuzzy search)
- Select with arrow keys or number
- Perfect when you don't remember the exact issue number!

**Adaptive Behavior:**
- **Traditional repos:** Creates/switches branches (classic workflow)
- **Worktree repos:** Creates isolated worktree directories (parallel workflow)
- Automatically detects repository structure
- No need to remember separate commands!

**Features:**
- **Interactive issue selection** - searchable list with fuzzy filtering
- Shows your assigned and recently created issues
- In worktree repos: Creates worktree in `worktrees/issue-{number}-{title}/`
- In traditional repos: Creates/switches to branch `issue-{number}-{title}`
- Automatically links branch to GitHub issue
- Optional custom branch suffix
- Handles naming conflicts with numbered suffixes
- Optional IDE launcher integration (worktree mode)

### 3. `git-worktree-ide`

Opens IDEs for specific worktrees.

**Usage:**
```bash
# Interactive selection
git worktree-ide

# Open specific worktree
git worktree-ide worktrees/issue-123-feature

# Specify IDE
git worktree-ide worktrees/main --ide cursor
git worktree-ide worktrees/issue-123 --ide code
git worktree-ide worktrees/issue-456 --ide idea

# List worktrees
git worktree-ide --list
```

**Supported IDEs:**
- `cursor` - Cursor IDE
- `code` - Visual Studio Code
- `idea` - IntelliJ IDEA
- `fleet` - JetBrains Fleet

**Configuration:**
```bash
# Set default IDE
git config --global worktree.defaultIde cursor
git config --global worktree.defaultIde code
git config --global worktree.defaultIde idea
```

### 4. `git-worktree-cleanup`

Cleans up merged and stale worktrees.

**Usage:**
```bash
# Interactive cleanup
git worktree-cleanup

# List worktrees with status
git worktree-cleanup --list

# Dry run
git worktree-cleanup --dry-run

# Auto-confirm (careful!)
git worktree-cleanup --yes

# Remove all non-main worktrees
git worktree-cleanup --all
```

**Features:**
- Identifies merged branches
- Detects uncommitted changes
- Never removes main/master worktree
- Confirms before deletion
- Preserves git history (only removes worktrees)

## Workflow Examples

### Starting Fresh (New Repository)

```bash
# 1. Clone repository normally
cd ~/git
git clone git@github.com:dotCMS/core.git dotcms-core
cd dotcms-core

# 2. Migrate to worktrees
git migrate-to-worktrees

# 3. Set default IDE (optional)
git config --global worktree.defaultIde cursor

# 4. Done! Start working
```

### Daily Development Workflow

```bash
# Start working on an issue (same command works for traditional or worktree repos!)
git issue-branch --issue 123 --open-ide cursor

# In worktree repo: IDE opens at worktrees/issue-123-feature/
# In traditional repo: Creates branch and switches to it

# Start another task (in parallel in worktree repos!)
git issue-branch --issue 456 --open-ide cursor

# In worktree repos, you now have TWO IDE windows:
# - Window 1: issue-123-feature
# - Window 2: issue-456-fix-bug

# Switch between them by switching IDE windows
# No git checkout needed!
```

### Multiple AI Agents Workflow

```bash
# Agent 1: Start working on backend feature
git issue-branch --issue 100 --yes
cd worktrees/issue-100-backend-api
cursor .  # AI agent 1 works here

# Agent 2: Start working on frontend feature
git issue-branch --issue 101 --yes
cd worktrees/issue-101-frontend-ui
cursor .  # AI agent 2 works here

# Both agents work in complete isolation
# No conflicts, no branch switching
```

### Cleanup After Merge

```bash
# After merging a PR on GitHub

# Option 1: Clean up specific worktree manually
git worktree remove worktrees/issue-123-feature

# Option 2: Auto-cleanup all merged worktrees
git worktree-cleanup

# Option 3: Just see what would be cleaned
git worktree-cleanup --list
```

## Migrating Existing Setup

If you already have `~/git/core2` worktree:

```bash
# Current state:
# ~/git/core-baseline/    (original)
# ~/git/core2/            (worktree)

# Option 1: Keep core-baseline as main, remove core2
cd ~/git/core-baseline
git migrate-to-worktrees
# Then delete ~/git/core2

# Option 2: Fresh start with worktrees
cd ~/git
mv core-baseline core-baseline.old
git clone git@github.com:dotCMS/core.git dotcms-core
cd dotcms-core
git migrate-to-worktrees
# Copy any uncommitted work from core-baseline.old
```

## Unified Command Works Everywhere

The `git-issue-branch` command automatically adapts to your repository structure:

- **Traditional repos** - Creates/switches branches (classic workflow)
- **Worktree repos** - Creates isolated worktree directories (parallel workflow)

You use the SAME command everywhere! Example:

```bash
# Worktree repo - creates worktree
cd ~/git/dotcms-core
git issue-branch --issue 123
# → Creates worktrees/issue-123-*/

# Traditional repo - creates branch
cd ~/git/dotcms-utilities
git issue-branch --issue 456
# → Creates and switches to branch issue-456-*

# Same command, adaptive behavior!
```

## Native Git Commands vs. Helper Scripts

**You have complete freedom to choose your workflow!** The helper scripts (`git issue-branch`, `git smart-switch`) are entirely optional. You can manage worktrees using standard git commands if you prefer.

### Option A: Native Git Commands (More Work, Full Control)

```bash
# Create a new worktree manually
git worktree add worktrees/issue-123-feature issue-123-feature

# Navigate to it
cd worktrees/issue-123-feature

# Link to GitHub issue (optional)
gh issue develop 123 --checkout

# Open your IDE
cursor .

# List all worktrees
git worktree list

# Remove a worktree when done
git worktree remove worktrees/issue-123-feature

# Clean up orphaned worktree metadata
git worktree prune
```

**When to use native commands:**
- You prefer manual control over every step
- You're comfortable with git worktree syntax
- You want to use custom naming conventions
- You're scripting your own workflows
- You don't need GitHub issue integration

### Option B: Helper Scripts (Less Work, Convenience Features)

```bash
# Create worktree with one command (interactive or direct)
git issue-branch                    # Interactive issue selection
git issue-branch --issue 123        # Direct issue number
git issue-branch --open-ide cursor  # Create + open IDE

# Navigate between worktrees safely
git smart-switch main               # Creates/navigates to main worktree
git smart-switch issue-456          # Creates/navigates to issue-456 worktree

# Clean up merged worktrees automatically
git worktree-cleanup
```

**What helper scripts provide:**

1. **Consistency** - Standardized naming (`worktrees/issue-123-title/`)
2. **Safety** - Prevents common mistakes (wrong directory, naming conflicts)
3. **GitHub Integration** - Automatic issue linking, searches your assigned issues
4. **Time Savings** - One command instead of multiple steps
5. **Error Prevention** - Validates branch names, handles edge cases
6. **IDE Integration** - Automatically launches your preferred IDE
7. **Interactive Selection** - Searchable issue list when you don't know the number

### Full Comparison: Native vs. Helper Scripts

**Creating a worktree from GitHub issue #123:**

```bash
# Native Git Way (5 steps, more typing)
git fetch origin
git worktree add worktrees/issue-123-add-dark-mode issue-123-add-dark-mode
cd worktrees/issue-123-add-dark-mode
gh issue develop 123 --checkout  # Link to GitHub issue
cursor .                          # Open IDE

# Helper Script Way (1 command)
git issue-branch --issue 123 --open-ide cursor
# ✅ Creates worktree with standard naming
# ✅ Links to GitHub issue automatically
# ✅ Opens IDE in one command
# ✅ Handles errors gracefully
```

**Switching to work on a different branch:**

```bash
# Native Git Way
cd ~/git/dotcms-core/worktrees/main
# Or create new worktree if it doesn't exist:
git worktree add worktrees/main main
cd worktrees/main

# Helper Script Way (from anywhere in the repo)
git smart-switch main
# ✅ Detects worktree structure
# ✅ Creates worktree if needed
# ✅ Shows you the path to navigate to
```

**Cleaning up merged worktrees:**

```bash
# Native Git Way (manual for each worktree)
git worktree list  # See all worktrees
git branch -d issue-123-feature  # Delete branch
git worktree remove worktrees/issue-123-feature
# Repeat for each merged worktree...

# Helper Script Way (automated)
git worktree-cleanup
# ✅ Detects merged branches automatically
# ✅ Shows which worktrees will be removed
# ✅ Confirms before deletion
# ✅ Preserves uncommitted changes
```

### Bottom Line: Your Choice!

**Both approaches work perfectly!** Choose based on your preferences:

- **Use native commands** if you want full manual control and don't need GitHub integration
- **Use helper scripts** if you want convenience, safety features, and time savings
- **Mix both** - use native commands for some tasks, helper scripts for others

The worktree structure works the same regardless of which commands you use to create and manage worktrees. The scripts simply automate common patterns and add safety guardrails.

## Critical Rules for Working with Worktrees

### Rule 1: Never Work in the Base Repository Directory

**After migration, the top-level directory is metadata only:**

```bash
~/git/dotcms-core/          # ❌ DO NOT open this in your IDE
~/git/dotcms-core/          # ❌ DO NOT commit changes here
~/git/dotcms-core/worktrees/issue-123/  # ✅ ALWAYS work in worktree directories
```

**Why?** The base directory after migration contains only:
- `.git/` - Shared git metadata for all worktrees
- `worktrees/` - Your actual working directories
- Possibly documentation or configuration files

**Important:**
- ❌ **DO NOT** open `~/git/dotcms-core/` in your IDE
- ❌ **DO NOT** commit changes from the base directory
- ✅ **ALWAYS** work inside `~/git/dotcms-core/worktrees/<branch-name>/`

### Rule 2: Keep Worktree Folders and Branches Matched

**Each worktree directory should stay on its corresponding branch:**

```bash
# ✅ CORRECT - Branch matches directory name
~/git/dotcms-core/worktrees/issue-123-feature/  → branch: issue-123-feature

# ❌ WRONG - Branch doesn't match directory
~/git/dotcms-core/worktrees/issue-123-feature/  → branch: main  # CONFUSING!
```

**Why this matters:**

1. **Prevents confusion** - Directory name tells you what branch it contains
2. **Avoids conflicts** - Git prevents checking out the same branch in multiple worktrees
3. **Simplifies workflow** - No mental overhead tracking which directory is on which branch

**What happens if you break this rule:**

```bash
cd ~/git/dotcms-core/worktrees/issue-123-feature/
git checkout main  # ❌ BAD IDEA!

# Now you have:
# - Directory named "issue-123-feature"
# - But it's on the "main" branch
# - Very confusing!

# Worse: Try to create a new worktree for main
git worktree add worktrees/main main
# ERROR: 'main' is already checked out at 'worktrees/issue-123-feature'
```

**The right way to switch work:**

```bash
# Instead of changing branches, create/navigate to worktrees
cd ~/git/dotcms-core/worktrees/issue-123-feature/  # Working on feature

# Need to work on main?
git smart-switch main
# ✅ Creates/navigates to worktrees/main/
# ✅ Keeps issue-123-feature worktree unchanged
```

### Rule 3: Use `git smart-switch` Instead of `git checkout`

**The problem with `git checkout` in worktree repos:**

```bash
# Traditional repo behavior (single directory)
git checkout feature-branch  # Switches branch in current directory

# Worktree repo behavior (should navigate instead!)
git checkout feature-branch  # ❌ Changes branch in worktree directory (confusing!)
```

**The solution: `git smart-switch` adapts to repo structure:**

| Repository Type | `git smart-switch` Behavior |
|----------------|----------------------------|
| **Traditional repo** | Backs up WIP, switches branch in current directory |
| **Worktree repo** | Creates/navigates to worktree for that branch |

**Examples:**

```bash
# Traditional repo
cd ~/git/dotcms-utilities
git smart-switch feature-branch
# ✅ Backs up current work, switches to feature-branch

# Worktree repo
cd ~/git/dotcms-core/worktrees/issue-123/
git smart-switch main
# ✅ Shows you: "Navigate to ~/git/dotcms-core/worktrees/main/"
# ✅ Creates worktree if it doesn't exist
# ✅ Current worktree stays on issue-123 branch
```

**Why `git smart-switch` is safer:**

1. **Context-aware** - Detects worktree structure and adapts behavior
2. **Prevents accidents** - Won't let you change branches in worktree directories
3. **Consistent UX** - Same command works everywhere, does the right thing
4. **Migration-friendly** - Works before and after worktree migration

### Rule 4: One Branch, One Worktree (Maximum)

**Git enforces this rule automatically:**

```bash
# Create first worktree for feature-branch
git worktree add worktrees/issue-123-feature issue-123-feature
# ✅ Success

# Try to create another worktree for the same branch
git worktree add worktrees/issue-123-copy issue-123-feature
# ❌ ERROR: 'issue-123-feature' is already checked out
```

**Why this exists:**
- Prevents simultaneous edits to the same branch from different directories
- Avoids confusion about which worktree has the "real" state
- Ensures clean git history

**What to do if you need to work on the same code in two places:**

```bash
# Option 1: Use the existing worktree
cd worktrees/issue-123-feature/

# Option 2: Create a new branch
git worktree add worktrees/issue-123-variant issue-123-variant
# Base it on issue-123-feature or merge later

# Option 3: Remove the old worktree first
git worktree remove worktrees/issue-123-feature
git worktree add worktrees/issue-123-feature issue-123-feature
```

### Summary: Worktree Best Practices

| ✅ DO | ❌ DON'T |
|-------|---------|
| Open worktree directories in IDE | Open base repository directory |
| Commit from worktree directories | Commit from base directory |
| Keep branch matched to directory name | Change branches within worktrees |
| Use `git smart-switch` to navigate | Use `git checkout` to switch branches |
| Create one worktree per branch | Try to checkout same branch twice |
| Use `git issue-branch` for new issues | Manually manage worktree naming |

**Golden Rule:** Treat each worktree directory as if it were a separate clone of the repository. Each one has its own branch, its own working state, and should be opened in its own IDE window.

## Troubleshooting

### Worktree is locked

```bash
# Remove lock file
rm .git/worktrees/<branch-name>/locked

# Or force remove
git worktree remove --force worktrees/<branch-name>
```

### Uncommitted changes in old location

After migration, if you left uncommitted changes:

```bash
# Check stash
git stash list

# Apply stash to worktree
cd worktrees/<branch-name>
git stash pop
```

### IDE doesn't recognize worktree

Worktrees are full git repositories, just open the directory:

```bash
# ✅ Correct
cursor worktrees/issue-123-feature/

# ❌ Wrong
cursor .  # (from main repo directory)
```

### Disk space concerns

Each worktree is a checkout, but they share `.git`:

```bash
# Check worktree sizes
du -sh worktrees/*

# Worktrees are lightweight (~same size as one checkout)
# .git directory is shared (no duplication)
```

## Advanced Usage

### Custom worktree locations

By default, worktrees go in `repo/worktrees/`. You can put them anywhere:

```bash
# Worktrees outside repo (not recommended)
git worktree add ~/my-worktrees/issue-123 issue-123-feature

# But then tools may not find them automatically
```

### Sharing worktrees with smart-switch

The `git-smart-switch` script can detect and switch to existing worktrees:

```bash
# If worktree exists, switches to it
# If not, creates branch normally
git smart-switch issue-123-feature
```

**Note:** Your shell prompt should already display the current branch name through standard git integration. Each worktree directory is a full git repository with its own branch, so existing git prompt configurations work automatically without additional setup.

## Best Practices

1. **Main branch worktree** - Always keep a main branch worktree for quick reference
2. **Regular cleanup** - Run `git worktree-cleanup` weekly to remove merged branches
3. **IDE windows** - Name your IDE windows by branch (Cursor/Code support this)
4. **Terminal tabs** - Use separate terminal tabs per worktree
5. **One worktree per issue** - Don't share worktrees between multiple issues

## Comparison: Traditional vs Worktree Workflow

### Traditional (Branch Switching)

```bash
git checkout main
git pull
git checkout -b issue-123-feature
# ... work on feature ...

git checkout main          # ❌ Slow, loses IDE state
git checkout -b issue-456-bug
# ... work on bug ...

git checkout issue-123-feature  # ❌ More switching
# ... continue feature ...
```

### Worktree Workflow

```bash
# One-time setup (same command as traditional, just detects worktree structure!)
git issue-branch --issue 123
git issue-branch --issue 456

# Then just switch IDE windows!
# IDE 1: ~/git/dotcms-core/worktrees/issue-123-feature/
# IDE 2: ~/git/dotcms-core/worktrees/issue-456-bug/

# ✅ No git checkout
# ✅ Instant context switching
# ✅ Independent IDE states
```

## FAQ

**Q: Does this duplicate my repository?**
A: No! The `.git` directory is shared. Worktrees are just checkouts, similar to having multiple clones but more efficient.

**Q: Do I need to learn new commands for worktrees?**
A: No! `git issue-branch` automatically detects worktree structure and adapts. Same command, everywhere!

**Q: What happens to my existing branches?**
A: Nothing! Your branches stay intact. Worktrees are just another way to check them out.

**Q: Can I commit/push from worktrees?**
A: Absolutely! Worktrees are full-featured git working directories.

**Q: Do I need to migrate my entire repo?**
A: No! You can create worktrees manually with `git worktree add` or use `git issue-branch` (it will detect and create worktrees automatically in migrated repos).

**Q: What about disk space?**
A: Worktrees use similar disk space to a single checkout (not per worktree). The `.git` directory is shared.

## Git Worktree Command Reference

For those who prefer using native git commands, here's a complete reference of standard git worktree operations:

### Creating Worktrees

```bash
# Create a new worktree from an existing branch
git worktree add <path> <branch>
git worktree add worktrees/feature-branch feature-branch

# Create a new worktree and new branch from current HEAD
git worktree add -b <new-branch> <path>
git worktree add -b issue-123-fix worktrees/issue-123-fix

# Create a new worktree and new branch from a specific commit/branch
git worktree add -b <new-branch> <path> <commit-ish>
git worktree add -b hotfix worktrees/hotfix-123 main

# Create worktree without checking out files (bare worktree)
git worktree add --no-checkout <path> <branch>

# Create detached HEAD worktree at specific commit
git worktree add --detach <path> <commit>
git worktree add --detach worktrees/test-commit abc123
```

### Listing Worktrees

```bash
# List all worktrees
git worktree list

# List worktrees with detailed information (porcelain format)
git worktree list --porcelain

# Example output:
# worktree /Users/user/git/dotcms-core
# HEAD 1234567890abcdef
# branch refs/heads/main
#
# worktree /Users/user/git/dotcms-core/worktrees/issue-123
# HEAD abcdef1234567890
# branch refs/heads/issue-123-feature
```

### Removing Worktrees

```bash
# Remove a worktree (must have no uncommitted changes)
git worktree remove <path>
git worktree remove worktrees/issue-123-feature

# Force remove a worktree (even with uncommitted changes)
git worktree remove --force <path>
git worktree remove -f worktrees/issue-123-feature
```

### Moving Worktrees

```bash
# Move/rename a worktree to a new location
git worktree move <source> <destination>
git worktree move worktrees/old-name worktrees/new-name
```

### Pruning Worktrees

```bash
# Remove worktree information for deleted worktrees
git worktree prune

# Dry run - show what would be pruned
git worktree prune --dry-run

# Verbose output
git worktree prune --verbose
```

### Locking/Unlocking Worktrees

**What are locked worktrees?**

Locking a worktree prevents `git worktree prune` from automatically removing its administrative data, even if the worktree directory has been deleted or moved. This is useful when:

- Working on a network drive that may be temporarily unavailable
- Moving worktrees to different locations (external drives, NAS, etc.)
- Protecting important long-running work from accidental cleanup
- Working on removable media (USB drives)

**When Git locks worktrees automatically:**
- Worktrees on removable media are automatically locked
- When Git detects a worktree is on a different filesystem than the main repo

```bash
# Lock a worktree (prevents automatic pruning)
git worktree lock <path>
git worktree lock worktrees/important-feature

# Optional: provide a reason (recommended for team repos)
git worktree lock worktrees/important-feature --reason "Work in progress, do not remove"

# Unlock a worktree
git worktree unlock <path>
git worktree unlock worktrees/important-feature

# Check if a worktree is locked (shows in list output)
git worktree list
# Output shows: worktree /path/to/worktree  locked
```

**Common scenarios:**

```bash
# Moving worktree to external drive
git worktree lock worktrees/big-feature --reason "Moved to external SSD"
mv worktrees/big-feature /Volumes/ExternalSSD/
# Later: unlock when back in standard location
git worktree unlock /Volumes/ExternalSSD/big-feature

# Network drive temporarily unavailable
git worktree lock worktrees/shared-work --reason "Network drive may disconnect"
# Prevents pruning when network is down
# Unlock when network is stable
git worktree unlock worktrees/shared-work
```

### Repairing Worktrees

```bash
# Repair worktree administrative files (if moved manually)
git worktree repair

# Repair specific worktree
git worktree repair <path>
```

### Working with Worktree Branches

```bash
# Inside a worktree, all standard git commands work:
cd worktrees/issue-123-feature

# Check current branch
git branch --show-current

# Create a new branch from current worktree
git checkout -b new-branch

# Switch branches (NOT recommended - breaks directory/branch matching)
git checkout other-branch  # ⚠️ Avoid this in worktrees!

# Commit, push, pull - all work normally
git add .
git commit -m "Fix bug"
git push origin issue-123-feature
```

### Checking Worktree Status

```bash
# Check if current directory is a worktree
git rev-parse --git-dir
# Output: /path/to/repo/.git/worktrees/branch-name (if worktree)
# Output: .git (if main working tree)

# Get the common git directory (shared across all worktrees)
git rev-parse --git-common-dir
# Output: /path/to/repo/.git

# Get the root directory of current worktree
git rev-parse --show-toplevel
```

### Advanced Usage

```bash
# Create worktree with specific initial commit
git worktree add <path> <commit-hash>

# Create orphan branch in worktree (no commit history)
git worktree add --orphan <path>

# Create worktree for existing remote branch
git worktree add worktrees/feature origin/feature

# Create worktree tracking a remote branch
git worktree add -b local-feature worktrees/feature origin/feature
```

### Common Workflows with Native Commands

**Parallel Feature Development:**
```bash
# Work on multiple features simultaneously
git worktree add worktrees/feature-a feature-a
git worktree add worktrees/feature-b feature-b
git worktree add worktrees/main main

# Switch between them by changing directories
cd worktrees/feature-a  # Work on feature A
cd worktrees/feature-b  # Work on feature B
cd worktrees/main       # Check main branch
```

**Emergency Hotfix:**
```bash
# Create hotfix worktree from main
git worktree add -b hotfix-urgent worktrees/hotfix-urgent main
cd worktrees/hotfix-urgent
# Fix bug, commit, push
git add .
git commit -m "Fix critical bug"
git push origin hotfix-urgent
# Create PR, get it merged
cd ../..
git worktree remove worktrees/hotfix-urgent
git branch -d hotfix-urgent
```

**Code Review in Separate Worktree:**
```bash
# Create temporary worktree for reviewing a PR
git fetch origin pull/123/head:pr-123
git worktree add worktrees/pr-123-review pr-123
cd worktrees/pr-123-review
# Review code, test locally
cd ../..
git worktree remove worktrees/pr-123-review
git branch -d pr-123
```

### Cleanup After Merging

```bash
# After branch is merged on GitHub
git fetch --prune  # Update remote branch info

# Remove the worktree
git worktree remove worktrees/issue-123-feature

# Delete the local branch
git branch -d issue-123-feature

# If branch wasn't merged (force delete)
git branch -D issue-123-feature
```

### Troubleshooting Commands

```bash
# List locked worktrees
git worktree list | grep locked

# Manually unlock all worktrees
find .git/worktrees -name locked -delete

# Check for corrupted worktrees
git worktree list --porcelain | grep -A 3 "^worktree"

# Repair all worktrees
git worktree repair

# Remove all worktree metadata (nuclear option)
rm -rf .git/worktrees/*
git worktree prune
```

### Configuration Options

```bash
# Set default behavior for worktree creation
git config worktree.guessRemote true  # Auto-track remote branches

# Configure worktree paths
git config extensions.worktreeConfig true
```

## Resources

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [dotcms-utilities Scripts](https://github.com/dotCMS/dotcms-utilities)
- Related scripts: `git-smart-switch`, `git-issue-branch`, `git-issue-create`