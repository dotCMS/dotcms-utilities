# Git Extension Script Abstractions for Worktree Compatibility

## Overview

The dotCMS development scripts have been architected with **intelligent detection and delegation** to work seamlessly with both **traditional single-directory repositories** and **worktree-based multi-directory repositories**. This allows developers to use the same familiar commands regardless of repository structure, with minimal learning curve.

## Design Philosophy

**Core Principle:** Same commands, adaptive behavior.

Users shouldn't need to learn new commands or workflows when switching between repository patterns. The scripts automatically detect the repository structure and adapt their behavior accordingly.

## Key Abstraction Patterns

### 1. Repository Pattern Detection

All worktree-aware scripts implement two detection functions:

#### `is_worktree_repo()` - Detects New Worktree Structure
```bash
is_worktree_repo() {
    local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    local base_repo_root=$(dirname "$git_common_dir")

    # Check if worktrees/ directory exists with actual worktrees
    if [[ -d "$base_repo_root/worktrees" ]]; then
        if [ -n "$(find "$base_repo_root/worktrees" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ]; then
            return 0  # New worktree structure detected
        fi
    fi
    return 1
}
```

**Purpose:** Identifies repositories using the recommended `repo/worktrees/` structure.

#### `is_old_worktree()` - Detects Legacy Worktree Pattern
```bash
is_old_worktree() {
    local git_dir=$(git rev-parse --git-dir 2>/dev/null)

    # Check if we're in a worktree (git-dir points to .git/worktrees/*)
    if [[ "$git_dir" == *".git/worktrees/"* ]]; then
        # NOT part of new pattern (no worktrees/ subdirectory)
        if [[ ! -d "$repo_root/../worktrees" ]] && [[ "$(basename "$(dirname "$repo_root")")" != "worktrees" ]]; then
            return 0  # Old worktree pattern (separate directory)
        fi
    fi
    return 1
}
```

**Purpose:** Identifies repositories using the old scattered worktree pattern (e.g., `../repo-feature-branch/`).

**Why Both?** Graceful migration path. Old pattern gets warnings and migration prompts, new pattern gets full functionality.

---

### 2. Behavioral Delegation Pattern

Scripts use **early detection + delegation** to route to the appropriate implementation:

#### Example: `git-issue-branch` → `git-issue-worktree`

```bash
# Early in git-issue-branch execution:

# Detect NEW worktree structure and delegate
if is_worktree_repo; then
    echo "Worktree structure detected - delegating to git-issue-worktree"

    # Map options appropriately
    WORKTREE_ARGS=()
    for arg in "${ORIGINAL_ARGS[@]}"; do
        case "$arg" in
            --from-current)
                # Skip: doesn't make sense in worktree mode (isolated dirs)
                ;;
            *)
                WORKTREE_ARGS+=("$arg")  # Pass through
                ;;
        esac
    done

    # Delegate with exec (replace current process)
    exec "$script_dir/git-issue-worktree" "${WORKTREE_ARGS[@]}"
    exit $?
fi

# Continue with traditional branch workflow for non-worktree repos...
```

**Benefits:**
- **Single entry point:** Users always run `git issue-branch`
- **Transparent delegation:** Script automatically routes to appropriate implementation
- **Argument mapping:** Options are translated to equivalent worktree operations
- **Exec replacement:** No performance overhead, direct process replacement

---

### 3. Option Compatibility Translation

Some options don't make sense in worktree mode and are handled gracefully:

| Traditional Option | Worktree Behavior | Reason |
|-------------------|-------------------|---------|
| `--from-current` | Ignored/Transformed | Each worktree is isolated; state copying handled differently |
| `--yes` | Passed through | Still useful for automation |
| `--dry-run` | Passed through | Preview works in both modes |
| `--issue NUMBER` | Passed through | Core functionality, works everywhere |

**Example Transformation:**
```bash
case "$arg" in
    --from-current)
        # In worktree mode, this becomes part of create_worktree options
        # Rather than branch switching context
        ;;
    *)
        WORKTREE_ARGS+=("$arg")
        ;;
esac
```

---

### 4. Graceful Fallback for Old Patterns

When old worktree patterns are detected, scripts provide **warnings + guidance**, not errors:

```bash
if is_old_worktree; then
    echo "⚠️ Old worktree pattern detected!"
    echo "You're in a separate worktree folder (not using worktrees/ subdirectory)"
    echo ""
    echo "Recommendation: Migrate to new structure for better organization"
    echo ""
    echo "To migrate:"
    echo "  1. cd to the base repository"
    echo "  2. Run: git migrate-to-worktrees"
    echo ""
    echo "Continuing with traditional branch workflow for now..."
    echo ""
fi
```

**Key Points:**
- **Non-blocking:** Users can continue working
- **Educational:** Clear explanation of what's detected
- **Actionable:** Specific migration steps provided
- **Fallback:** Traditional workflow continues to work

---

### 5. Path Resolution Abstraction

Scripts intelligently resolve repository paths regardless of where they're executed:

```bash
# Get base repository root (works from any worktree or base repo)
local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
local repo_root=$(dirname "$git_common_dir")
local worktrees_dir="$repo_root/worktrees"
```

**Why This Matters:**
- Works when run from base repository
- Works when run from any worktree subdirectory
- Consistently finds the canonical worktree storage location
- Prevents path confusion and wrong-directory operations

---

### 6. Contextual Behavior in `git-smart-switch`

`git-smart-switch` demonstrates the most sophisticated abstraction - it changes behavior based on **current context**:

#### When run from Base Repository:
```bash
# User is in /repo/ (base directory)
if is_worktree_repo; then
    echo "Creating/navigating to worktree for branch: $new_branch"
    # Creates worktree at worktrees/branch-name/
    # Outputs path for wrapper function to cd to
fi
```

#### When run from Inside a Worktree:
```bash
# User is in /repo/worktrees/feature-123/
if [[ "$CURRENT_DIR" == "$REPO_ROOT/worktrees/"* ]]; then
    echo "You're in a worktree - creating new worktree instead of switching"
    # Creates ANOTHER worktree (parallel work)
    # Does NOT modify current directory
fi
```

#### When run from Traditional Repo:
```bash
# User is in regular single-directory repo
# Standard branch switching with WIP management
git checkout "$new_branch"
restore_wip
```

**Result:** Same command (`git smart-switch feature`), three different contextual behaviors, all appropriate to the situation.

---

## Benefits to User Experience

### 1. Zero Learning Curve
Users don't need to memorize new commands:
- `git issue-branch` works everywhere
- `git smart-switch` works everywhere
- `git issue-pr` works everywhere

### 2. Progressive Enhancement
- Traditional repos: Full functionality as before
- Worktree repos: Enhanced with parallel work capability
- Migration: Smooth transition with clear guidance

### 3. Safety Through Detection
Scripts prevent dangerous operations:
- Won't migrate from within a worktree (would corrupt structure)
- Won't create conflicting worktrees
- Won't lose uncommitted changes during transitions

### 4. Consistent Developer Experience
Whether working on:
- Personal projects (traditional repos)
- Team projects migrated to worktrees
- Mixed environments (some repos migrated, some not)

**Same muscle memory, same commands, appropriate behavior.**

---

## Implementation Details

### Shared Helper Functions

All worktree-aware scripts source common detection logic:

```bash
# Defined in git-issue-branch, git-smart-switch, etc.
is_worktree_repo() { ... }  # Detects new structure
is_old_worktree() { ... }   # Detects legacy pattern
find_worktree_for_branch() { ... }  # Locates existing worktrees
```

### Consistent User Messaging

All scripts use unified color-coded output:
- 🔵 **Blue:** Informational messages (structure detected, actions taken)
- 🟡 **Yellow:** Warnings (old patterns, migration suggestions)
- 🟢 **Green:** Success confirmations
- 🔴 **Red:** Errors (operation blocked, manual action needed)

### Dry-Run Support Everywhere

Both traditional and worktree modes support `--dry-run`:
```bash
git issue-branch --issue 123 --dry-run  # Works in both modes
git smart-switch feature --dry-run      # Shows what would happen
```

This helps users understand what the script will do **before** committing to an action.

---

## Migration Path Considerations

### Phase 1: Traditional Repositories
- All scripts work as they always have
- No worktree detection needed
- Full backward compatibility

### Phase 2: Post-Migration (Worktree Structure)
- Scripts auto-detect new structure
- Delegate to worktree-optimized implementations
- Enhanced parallel work capabilities

### Phase 3: Hybrid Environments
- Some repos migrated, some not
- Scripts adapt per-repository
- No mental overhead for developers
- Same commands everywhere

---

## Example: Command Equivalence Table

| Command | Traditional Repo Behavior | Worktree Repo Behavior |
|---------|--------------------------|------------------------|
| `git issue-branch` | Creates/switches local branch | Creates new worktree directory |
| `git issue-branch --from-current` | Branches from current state | Maps to state-copying option |
| `git smart-switch main` | Switches branch (WIP commits) | Navigates to main worktree directory |
| `git smart-switch new-feature` | Creates branch from main | Creates worktree from main |
| `git issue-pr` | Creates PR from current branch | Creates PR from current worktree's branch |

**User perspective:** "I just run the same commands I always have."

---

## Advanced: Argument Pass-Through Logic

Scripts implement intelligent argument filtering and transformation:

```bash
# Original args from user
ORIGINAL_ARGS=("$@")

# Parse and potentially transform
for arg in "${ORIGINAL_ARGS[@]}"; do
    case "$arg" in
        --from-current)
            # In worktree context, this becomes:
            # "copy state from current worktree to new worktree"
            # Not: "branch from current commit"
            if is_worktree_repo; then
                WORKTREE_ARGS+=("--copy-state")
            else
                TRAD_ARGS+=("--from-current")
            fi
            ;;
        --issue)
            # Universal - works same in both modes
            WORKTREE_ARGS+=("$arg")
            TRAD_ARGS+=("$arg")
            ;;
    esac
done
```

This ensures **semantic preservation** - the *intent* of the option is maintained, even if the implementation differs.

---

## Testing Strategy

Scripts are designed to be testable in both modes:

```bash
# Test traditional mode
cd ~/test-repo-traditional/
git issue-branch --issue 123 --dry-run

# Test worktree mode
cd ~/test-repo-worktree/
git issue-branch --issue 123 --dry-run

# Same command, different preview output, both valid
```

---

## Summary: Why This Design Works

1. **Single Source of Truth:** Core business logic (issue creation, PR creation) is shared
2. **Behavioral Polymorphism:** Implementation adapts to detected environment
3. **Progressive Disclosure:** Users only see complexity when needed (migration warnings)
4. **Fail-Safe Defaults:** When in doubt, scripts explain and prompt rather than error
5. **Idempotent Operations:** Running commands multiple times is safe
6. **Context-Aware Help:** Help text adapts to show relevant options for detected mode

**Result:** Developers experience a **unified, intuitive workflow** that "just works" regardless of repository structure, with clear guidance when transitioning between patterns.

---

## Comparison: Before vs After Abstraction

### Before (Separate Commands, User Confusion)
```bash
# Traditional repo
git issue-branch --issue 123  # Works

# After migration
git issue-branch --issue 123  # Error: not compatible with worktrees!
                              # Must use git issue-worktree instead!

# User: "Wait, which command do I use where?"
```

### After (Unified Interface, Adaptive)
```bash
# Traditional repo
git issue-branch --issue 123  # Creates branch

# After migration
git issue-branch --issue 123  # Auto-detects, delegates to worktree creation

# User: "Same command, just works."
```

---

## Future Extensibility

This abstraction pattern allows future enhancements without breaking changes:

- **New repository patterns** (e.g., sparse checkouts): Add detection + delegation
- **Cloud-based workflows**: Abstract to support remote worktree creation
- **IDE integrations**: Scripts already output paths for wrapper functions
- **Multi-repo coordination**: Detection logic can expand to parent/child relationships

The architecture is **open-closed principle compliant**: Open for extension (new patterns), closed for modification (existing behavior preserved).