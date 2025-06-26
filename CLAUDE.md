# dotCMS Utilities - Claude Code Context

This repository contains development utilities and Git extensions for enhancing dotCMS development workflows, particularly around GitHub issue management and branch creation.

## Repository Overview

### Core Purpose
Streamline GitHub issue creation and branch management for dotCMS development teams by providing command-line tools that eliminate friction from the traditional GitHub web interface workflow.

### Key Technologies
- **GitHub CLI (`gh`)**: Core integration for issue and project management
- **Git Extensions**: Custom scripts that extend Git functionality via `git-*` naming convention
- **Bash/Shell Scripting**: Primary implementation language for all utilities
- **fzf**: Interactive fuzzy finder for user selections
- **jq**: JSON processing for configuration management
- **ProjectV2 GraphQL APIs**: Integration with GitHub's modern project management

## Architecture

### Installation System
- **`install-dev-scripts.sh`**: Central installation script that handles dependencies, downloads, and PATH setup
- **Local Development**: Scripts can be installed from local source or remote GitHub repository
- **Dependency Management**: Automatically installs required tools (fzf, gh, just, etc.)
- **Version Control**: Tracks installed versions and provides update notifications

### Git Extensions Pattern
All user-facing scripts follow the `git-*` naming convention, allowing them to be called as Git subcommands:
```bash
git issue-create    # calls git-issue-create
git issue-branch    # calls git-issue-branch
git issue-pr        # calls git-issue-pr
git smart-switch    # calls git-smart-switch
```

**Important Naming Convention**: 
- **File names**: Use hyphens throughout (e.g., `git-issue-create`)
- **Command usage**: Replace hyphens with spaces when calling (e.g., `git issue-create`)
- This follows standard Git extension patterns where `git-foo-bar` becomes `git foo-bar`

Scripts are installed to `~/.dotcms/dev-scripts/` and added to PATH.

## Core Workflow Tools

### Issue Creation Ecosystem

#### Primary Tool: `git-issue-create`
**Location**: `/dev-scripts/git-issue-create`
**Purpose**: Comprehensive GitHub issue creation with team-specific configurations

**Architecture**:
- 8-step interactive wizard for full customization
- **Dry-run mode (`--dry-run`)**: Preview issue creation without actually creating
- Command-line argument support for automation
- Smart label matching with fuzzy search algorithms
- **Enhanced fzf integration**: All selectable fields support fuzzy search/filtering with default pre-selection
- **Performance caching**: 24-hour cache for labels and issue types
- Cross-repository support (dotCMS/core, dotCMS/dotcms-utilities, etc.)
- ProjectV2 integration for dotCMS - Product Planning project

**Key Functions**:
- `find_label()`: Fuzzy matching for repository labels (exact → case-insensitive → partial)
- `sanitize_title()`: Branch name normalization following dotCMS conventions
- `save_config()`/`load_config()`: User preference persistence via JSON

**Team Configurations**:
```bash
TEAM_LABELS[Platform]="Team : Platform"
TEAM_LABELS[CloudEng]="Team : Cloud Eng"
TEAM_OKRS[Platform]="OKR : Evergreen"
```

**Enhanced Features**:
- **Generic label selection system**: Dynamic prefix-based label selection supports any repository structure
- **Intelligent label filtering**: Excludes system labels (Release:, Doc:, QA:) from optional selections  
- **Comprehensive validation**: CLI parameters validated against actual repository labels/types
- **Multi-step wizard**: Guides users through team, type, priority, dotCMS area, OKR, and optional label selection
- **Smart defaults**: Pre-selects saved preferences with easy override capability

### Branch Management Tools

#### Enhanced Issue-Branch Integration: `git-issue-branch`
**Location**: `/dev-scripts/git-issue-branch`
**Purpose**: Work with existing issues and create/switch branches

**Enhanced Features**:
- Shows both assigned and recently created issues with visual indicators
- Smart deduplication (`[assigned]` takes precedence over `[created]`)
- Branch renaming for non-standard branch names
- Automatic issue-branch linking via `gh issue develop`

**Branch Renaming Logic**:
```bash
if [[ ! "$CURRENT_BRANCH" =~ ^issue-[0-9]+ ]]; then
    # Offer to rename to issue-{number}-{suffix} format
    # Handle conflicts with existing branch names
    # Link renamed branch to GitHub issue
fi
```

#### Other Git Extensions
- **`git-smart-switch`**: Enhanced branch switching with WIP management
- **`git-issue-pr`**: PR creation with automatic issue linking

## Configuration Management

### User Preferences
**File**: `~/.dotcms/issue-config.json`
**Purpose**: Store personalized defaults to reduce repetitive input

**Schema**:
```json
{
    "default_team": "Platform",
    "default_type": "Enhancement", 
    "default_priority": "3 Medium",
    "default_project_id": "product-planning",
    "last_updated": "2024-01-15T10:30:00Z"
}
```

**Key Design Decision**: Effort estimation is intentionally NOT saved as default - it must be considered per-issue.

### Label Mapping Strategy
**Problem**: Different repositories have different label schemes
**Solution**: Smart label matching with fallbacks

**Algorithm**:
1. **Exact Match**: `"Team : Platform"` → `"Team : Platform"`
2. **Case Insensitive**: `"team : platform"` → `"Team : Platform"`  
3. **Fuzzy Match**: `"platform"` → `"Team : Platform"`
4. **Fallback**: `"Enhancement"` → `"Type : Defect"` (if Enhancement doesn't exist)

### Repository-Specific Handling
- **dotCMS/core**: Uses `"Type : Defect"`, `"Priority : 4 Low"`, etc.
- **dotCMS/dotcms-utilities**: Uses `"Team : Platform"`, `"OKR : Evergreen"`, etc.
- **Cross-repository workflows**: Auto-detects and adapts to available labels

## Project Integration (ProjectV2)

### dotCMS - Product Planning Project
**Integration**: GraphQL-based ProjectV2 APIs
**Default Settings**:
- Status: `New` (for all new issues)
- Effort: Prompted each time (XS, S, M, L, XL)

**Implementation Notes**:
- Requires `read:project` and `write:project` GitHub CLI scopes
- Uses GraphQL mutations for project item creation and field updates
- Provides manual commands for project integration (automation requires additional API work)

## Branch Naming Conventions

### Standard Format
`issue-{number}-{sanitized-suffix}`

**Examples**:
- `issue-123-fix-login-timeout`
- `issue-456-add-user-dashboard`
- `issue-789-update-api-docs`

### Sanitization Rules
```bash
sanitize_title() {
    # Convert to lowercase
    # Replace spaces with dashes
    # Remove non-alphanumeric characters (except dashes)
    # Collapse multiple dashes
    # Truncate to 50 characters on word boundaries
    # Remove trailing dashes
}
```

## Development Patterns

### Error Handling
- Comprehensive validation for repository formats (`owner/repo`)
- GitHub CLI authentication checking
- Graceful fallbacks when tools are unavailable (fzf → select menu)

### User Experience
- Color-coded output for better CLI readability
- Interactive wizards with sensible defaults
- Confirmation steps for destructive operations
- Clipboard integration (macOS pbcopy support)

### Code Organization
- Modular functions for reusability
- Consistent parameter passing
- Configuration separation from business logic
- DRY principle enforcement with modular design

## Multi-Language Projects

### Python Projects
- **`mysql_to_postgres/`**: Poetry-based database migration utility
- Uses `pyproject.toml` for dependency management
- Supports Python 3.8-3.12

### Node.js Integration
- NVM support for multi-version Node.js management
- Automatic `.nvmrc` file detection

### Java Integration  
- SDKMAN integration for JVM toolchain management
- JBang support for script execution

## Installation & Updates

### Quick Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)
```

### Update Checking
- Automatic version checking via GitHub API
- Commit-based versioning for precise update tracking
- Cache system to avoid excessive API calls

### Dependencies
- **Required**: git, curl, gh (GitHub CLI)
- **Enhanced UX**: fzf (interactive selection)
- **Platform-specific**: Homebrew (macOS), SDKMAN (Java)

## Performance & Caching

### Caching Strategy
**Cache Location**: `~/.dotcms/cache/`
**Cache Duration**: 24 hours
**Cache Types**:
- **Labels**: `labels-{owner}-{repo}` - Repository label data
- **Issue Types**: `types-{org}-types` - Organization issue type metadata

**Benefits**:
- **First API call**: Fetches and caches data (normal response time)
- **Subsequent calls**: Instant response from cache
- **Automatic refresh**: Cache expires after 24 hours or can be force-refreshed with `--refresh`

### Cache Management
```bash
# Force refresh all cached data
git issue-create --refresh

# Clear all cache files manually
rm ~/.dotcms/cache/*
```

## Testing & Quality

### Validation Points
- Repository format validation
- GitHub authentication verification
- Label existence checking
- Branch name collision handling

### Cross-Platform Support
- macOS primary target (Homebrew integration)
- Linux secondary support
- Clipboard integration where available
- **Bash 3.x Compatibility**: Uses functions instead of associative arrays for macOS compatibility

## Common Issues & Solutions

### Label Compatibility
- **Problem**: Repository labels don't match user selections
- **Solution**: Fuzzy matching with graceful fallbacks

### Cross-Repository Workflows
- **Problem**: Can't create branches in different repositories
- **Solution**: Clear warnings + suggested workflow (`git issue-branch` in target repo)

### Project Integration Complexity
- **Problem**: ProjectV2 APIs require complex GraphQL
- **Solution**: Provide manual commands with clear instructions

## Documentation Maintenance

### Critical Documentation Synchronization
**IMPORTANT**: When making changes to any git extension scripts, the following documentation MUST be updated simultaneously to prevent user confusion and maintain accuracy:

#### Primary Documentation Files
1. **`README.md`** (User-facing documentation)
   - **Command options**: Update all `--option` lists when adding/removing parameters
   - **Usage examples**: Reflect actual command syntax and current workflow patterns
   - **Feature descriptions**: Match actual implementation capabilities
   - **Help text**: Keep consistent with script's `--help` output

2. **`CLAUDE.md`** (Development context)
   - **Architecture section**: Update when adding new modes or major features
   - **Usage patterns**: Reflect modern workflow recommendations
   - **Key Functions**: Document new utility functions or significant changes

#### Synchronization Checklist
When modifying git extension scripts, verify these elements are consistent across all documentation:

**Command Line Interface:**
- [ ] All `--parameter` options match between script help text and README
- [ ] Example commands use valid syntax and current parameter names
- [ ] Default values match between code and documentation
- [ ] Required vs optional parameters are correctly documented

**Feature Descriptions:**
- [ ] README key features match actual implementation
- [ ] Workflow examples demonstrate current best practices
- [ ] Performance claims (caching, speed) reflect actual behavior
- [ ] Cross-repository behavior is accurately described

**Code Organization:**
- [ ] Function names in CLAUDE.md match actual implementation
- [ ] Architecture descriptions reflect current code structure
- [ ] Dependencies and requirements are up-to-date

#### Common Documentation Debt Patterns
Watch for these frequent inconsistencies:

1. **Removed Features**: Old documentation referencing deleted functionality
2. **Parameter Changes**: Help examples using outdated flag names
3. **Workflow Evolution**: Examples showing deprecated usage patterns
4. **Performance Updates**: Stale claims about speed or caching behavior
5. **Cross-References**: Links between scripts that become invalid after refactoring

#### Documentation Update Process
1. **During Development**: Update docs alongside code changes
2. **Before Commit**: Run `git-issue-create --help` and verify README examples match
3. **Testing**: Validate all documented examples actually work
4. **Review**: Check that CLAUDE.md reflects the architectural reality

This ensures users have accurate information and future developers understand current capabilities.

## Future Enhancement Areas

1. **Automated ProjectV2 Integration**: Full automation of project board updates
2. **Template System**: Issue templates for different types (bug, feature, etc.)
3. **Bulk Operations**: Multiple issue creation/management
4. **Integration Testing**: Automated testing of GitHub CLI interactions
5. **Configuration UI**: Web-based configuration management
6. **Documentation Validation**: Automated testing of README examples against actual script behavior

## Usage Patterns

### Streamlined Development Workflow
```bash
# Create issue with branch in one step
git issue-create "Fix user authentication timeout" --branch
# Work on changes...
git issue-pr      # Create PR linked to issue
```

### Preview and Validation Workflow
```bash
# Preview issue before creation
git issue-create "Add new feature" --dry-run --team Platform --type Enhancement
# Review the preview, then create for real
git issue-create "Add new feature" --team Platform --type Enhancement
```

### Team-Specific Workflows
```bash
# Platform Team
git issue-create "Optimize database queries" --team Platform --type Enhancement

# QA Team  
git issue-create "Add integration tests" --team QA --type Task --priority "2 High"
```

### Cross-Repository Collaboration
```bash
git issue-create "Update integration docs" --repo dotCMS/core --team Platform
```

This comprehensive context should enable future Claude instances to effectively work with and enhance the dotCMS utilities repository while understanding the sophisticated issue-to-branch workflow patterns that have been established.