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

```
~/git/
├── dotcms-core/                    # Main repository
│   ├── .git/                       # All git metadata here
│   ├── worktrees/                  # All working trees
│   │   ├── main/                   # Main branch
│   │   ├── issue-123-add-feature/  # Issue #123
│   │   └── issue-456-fix-bug/      # Issue #456
│   ├── docs/                       # Optional: docs in main
│   └── README.md
│
└── dotcms-utilities/               # Regular clone (no worktrees)
    └── dev-scripts/
```

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
# Interactive issue selection (works in both traditional and worktree repos)
git issue-branch

# Specific issue
git issue-branch --issue 123

# Create and open in IDE (worktree repos only)
git issue-branch --issue 123 --open-ide cursor

# List issues
git issue-branch --list

# Dry run
git issue-branch --issue 123 --dry-run

# Automation mode
git issue-branch --issue 123 --yes
```

**Adaptive Behavior:**
- **Traditional repos:** Creates/switches branches (classic workflow)
- **Worktree repos:** Creates isolated worktree directories (parallel workflow)
- Automatically detects repository structure
- No need to remember separate commands!

**Features:**
- Lists your assigned and recently created issues
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

**Important:** Once migrated to worktrees, you can use standard git commands to manage worktrees:

```bash
# Native git worktree commands (always work)
git worktree add worktrees/feature-branch feature-branch
git worktree list
git worktree remove worktrees/feature-branch
git worktree prune
```

**However, the helper scripts provide:**

1. **Consistency** - Standardized naming conventions (`worktrees/issue-123-title/`)
2. **Safety** - Prevents common mistakes (wrong directory, naming conflicts)
3. **Convenience** - GitHub issue integration, IDE launching, automatic linking
4. **Time savings** - Less typing, fewer commands to remember
5. **Error prevention** - Validates branch names, handles edge cases

### Comparison: Native vs. Helper Scripts

```bash
# Native Git Way (more manual)
git worktree add worktrees/my-feature feature-branch
cd worktrees/my-feature
gh issue develop 123 --checkout
cursor .

# Helper Script Way (integrated workflow)
git issue-branch --issue 123 --open-ide cursor
# ✅ Creates worktree with standard naming
# ✅ Links to GitHub issue automatically
# ✅ Opens IDE in one command
```

**Bottom Line:** The scripts are **optional conveniences**, not requirements. Use native git commands if you prefer, or use the scripts for a smoother workflow. Both approaches work perfectly!

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

### Shell prompt integration

Add to `.bashrc` or `.zshrc`:

```bash
# Show current worktree in prompt
worktree_prompt() {
    local wt=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ "$wt" =~ /worktrees/([^/]+)$ ]]; then
        echo "[${BASH_REMATCH[1]}]"
    fi
}

PS1='$(worktree_prompt) $ '
```

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

## Resources

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [dotcms-utilities Scripts](https://github.com/dotCMS/dotcms-utilities)
- Related scripts: `git-smart-switch`, `git-issue-branch`, `git-issue-create`