Public Repo

# dotcms-utilities

A collection of development utilities and Git extensions to enhance your workflow when working with dotCMS.

## Prerequisites

The installation script will check for and attempt to install the following dependencies:

* HomeBrew (for macOS)
* SDKMAN (for Java and JBang multi-version support and .sdkmanrc)
* NVM (for Node.js multi-version support and .nvmrc)
* curl (for downloading files)
* fzf (for interactive selection, used in git scripts)
* gh (GitHub CLI, used in git scripts)
* just (for justfile alias support)

## Installation

### Quick Install

To install or update all Git extensions and required executables from the main branch, run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)
```

### Install from Specific Branch or Tag

To install from a specific branch, tag, or commit (useful for testing PRs), use the environment variable approach:

```bash
# Install from a specific branch
DOTCMS_INSTALL_REF="dev-branch" bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/dev-branch/install-dev-scripts.sh)

# Install from a specific tag
DOTCMS_INSTALL_REF="v1.2.0" bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/v1.2.0/install-dev-scripts.sh)

# Install from a PR branch for testing
DOTCMS_INSTALL_REF="feature-pr-123" bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/feature-pr-123/install-dev-scripts.sh)

# Return to default main branch
bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)
```

**How it works:** The `DOTCMS_INSTALL_REF` environment variable tells the installer which branch/tag you're installing from. This ensures proper tracking and update notifications.

**Note:** When installing from non-default branches, the update checker will clearly indicate which ref you're using and provide the correct commands to update or switch back to the default.

### Install from Source

If you're working with the source code directly, you can install the current version of the scripts by running:

```bash
./install-dev-scripts.sh
```

**Branch Detection:** When running from local source, the script automatically detects and uses your current Git branch. If you're on a feature branch, it will show a warning and provide guidance on how to install from main:

```bash
# On feature branch - shows warning and guidance
./install-dev-scripts.sh

# To switch to default main installation, use the remote installer
bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)

# Or override to install main branch behavior locally  
./install-dev-scripts.sh --ref main
```

## Git Extensions

### Issue Creation and Management

#### Git Issue Create

The `git issue-create` extension provides a comprehensive GitHub issue creation workflow with:

**Key Features:**
- **🧙‍♂️ Interactive Wizard**: 8-step guided wizard for complete customization
- **👁️ Dry Run Preview**: Preview issue creation with `--dry-run` before actually creating
- **🎯 Smart Labels**: Auto-applies appropriate labels based on repository with intelligent filtering
- **👥 Team Support**: Configurable for Platform, CloudEng, QA, Frontend, Backend teams
- **💾 Persistent Defaults**: Saves your preferences for future use
- **🌐 Cross-Repository**: Create issues in any repository (dotCMS/core, dotCMS/utilities, etc.)
- **🔗 Branch Integration**: Optionally create and switch to working branch
- **📋 Project Support**: Integration with dotCMS - Product Planning project
- **⚡ Performance**: 24-hour caching for labels and issue types

**Usage:**

```bash
# Full wizard mode
git issue-create

# Direct creation with options
git issue-create "Fix login timeout bug" --type Defect --priority "2 High" --branch

# Cross-repository issue creation
git issue-create "Update API docs" --repo dotCMS/core --team Platform

# Preview before creating
git issue-create "Add new feature" --dry-run --team Platform
```

**Command Options:**
- `--team TEAM` - Set team (Platform, CloudEng, QA, Frontend, Backend)
- `--type TYPE` - Set issue type (Enhancement, Defect, Task)
- `--priority PRIORITY` - Set priority (1 Critical, 2 High, 3 Medium, 4 Low)
- `--repo REPO` - Target repository (owner/repo format)
- `--branch, -b` - Create and switch to branch after issue creation
- `--assignee USER` - Assign issue to specific user
- `--project ID` - Add to specified project
- `--dry-run` - Preview what would be created without actually creating the issue
- `--refresh` - Force refresh of cached labels and types

#### Git Issue Branch

The `git issue-branch` extension helps you work with existing issues:

**Enhanced Features:**
- **📋 Combined Issue Lists**: Shows both assigned and recently created issues
- **🏷️ Visual Indicators**: Clear `[assigned]` vs `[created]` tags  
- **🔍 Smart Deduplication**: Issues that are both assigned and created show as `[assigned]`
- **⏱️ Recent Focus**: Shows your 20 most recent created issues
- **🔗 Branch Linking**: Integrates with `gh issue develop` for proper issue-branch linking
- **🏷️ Smart Branch Renaming**: Detects non-standard branch names and offers to rename them to proper `issue-{number}-{suffix}` format

**Branch Renaming Feature:**
When you're on a branch that doesn't follow the `issue-{number}-` naming convention, the tool will:
1. **Detect** the non-standard branch name
2. **Offer to rename** it to match the selected issue  
3. **Handle conflicts** if the target name already exists
4. **Link to issue** automatically after renaming
5. **Continue working** seamlessly with proper issue tracking

**Usage:**

```bash
git issue-branch
```

**Example Workflow:**
```bash
# You're on branch 'feature-login-fix'
git issue-branch
# → Selects issue #123 "Fix login timeout"
# → Offers: "Rename 'feature-login-fix' to 'issue-123-fix-login-timeout'?"
# → After rename: Branch is properly linked to issue #123
```


### Branch and PR Management

#### Git Smart-Switch

The `git smart-switch` extension enhances branch switching and creation with features like:
- Interactive branch selection
- WIP commit management
- Optional remote branch pushing

**Usage:**

```bash
git smart-switch [<new-branch-name>] [-p|--push]
```

#### Git Issue PR

The `git issue-pr` extension streamlines PR creation by:
- Creating a new PR from the command line
- Automatically linking it to the issue ID defined in your current branch name
- Simplifying the PR creation workflow

**Usage:**

```bash
git issue-pr
```

## Workflow Examples

### Streamlined Development Workflow

```bash
# 1. Create an issue with branch creation
git issue-create "Fix user authentication timeout" --branch

# 2. Work on your changes...

# 3. Create a PR
git issue-pr
```

### Alternative: Create Issue Then Branch

```bash
# 1. Create an issue first
git issue-create "Fix user authentication timeout"

# 2. Select the issue and create a branch
git issue-branch

# 3. Work on your changes...

# 4. Create a PR
git issue-pr
```

### Comprehensive Issue Management

```bash
# 1. Create a detailed issue with full wizard
git issue-create
# → Walks through all options: repository, team, labels, project, etc.

# 2. Later, work on any of your issues
git issue-branch
# → Shows both assigned and recently created issues

# 3. Cross-repository collaboration
git issue-create "Update integration docs" --repo dotCMS/core --team Platform
```

### Team-Specific Workflows

```bash
# Platform Team
git issue-create "Optimize database queries" --team Platform --type Enhancement

# QA Team  
git issue-create "Add integration tests" --team QA --type Task --priority "2 High"

# Cloud Engineering Team
git issue-create "Deploy new monitoring" --team CloudEng --type Task --branch
```

## Configuration

### User Preferences

The issue creation tools save your preferences to `~/.dotcms/issue-config.json` for a personalized experience:

```json
{
    "default_team": "Platform",
    "default_type": "Enhancement", 
    "default_priority": "3 Medium",
    "default_project_id": "product-planning",
    "last_updated": "2024-01-15T10:30:00Z"
}
```

**Key Benefits:**
- **🎯 Remembers Your Preferences**: Team, issue type, priority automatically set
- **⚡ Speeds Up Workflow**: Less repetitive input required
- **🔄 Always Customizable**: Can override or update defaults anytime
- **📱 Per-Developer**: Each developer has their own saved preferences
- **📊 Per-Issue Effort**: Effort estimation prompted each time (not saved as default)

### Label Mapping

The tools automatically map your selections to actual repository labels:

**Smart Label Matching:**
- **Exact Match**: `"Team : Platform"` → `"Team : Platform"`
- **Case Insensitive**: `"team : platform"` → `"Team : Platform"`  
- **Fuzzy Match**: `"platform"` → `"Team : Platform"`
- **Fallback**: `"Enhancement"` → `"Type : Defect"` (if Enhancement doesn't exist)

**Repository-Specific Handling:**
- **dotCMS/core**: Uses `"Type : Defect"`, `"Priority : 4 Low"`, etc.
- **dotCMS/dotcms-utilities**: Uses `"Team : Platform"`, `"OKR : Evergreen"`, etc.
- **Other repos**: Adapts to whatever labels exist

### Team Configurations

Built-in team configurations with appropriate labels and OKRs:

| Team | Labels Applied | OKR |
|------|---------------|-----|
| **Platform** | `Team : Platform` | `OKR : Evergreen` |
| **CloudEng** | `Team : Cloud Eng` | `OKR : Evergreen` |  
| **QA** | `Team : QA` | - |
| **Frontend** | `Team : Frontend` | - |
| **Backend** | `Team : Backend` | - |

### Project Integration (ProjectV2)

When adding issues to the dotCMS - Product Planning project, the tools provide comprehensive integration:

**Default Settings Applied:**
- **Status**: `New` (default for all new issues)
- **Effort Estimation**: Prompted each time with standardized options

**Effort Size Options:**
- **XS**: < 1 day
- **S**: 1-2 days  
- **M**: 3-5 days
- **L**: 1-2 weeks
- **XL**: 2+ weeks
- **Skip**: No effort estimation

**ProjectV2 Integration Steps:**
1. **Add to Project**: Issue gets added to the project board
2. **Set Status**: Automatically set to "New" status
3. **Set Effort**: Apply selected effort estimation (if provided)
4. **Ready for Planning**: Issue appears in project backlog for team planning

**Note**: Effort estimation is intentionally prompted for each issue rather than saved as a default, since effort varies per issue and should be carefully considered each time.

## Troubleshooting

### Common Issues

**Labels Not Applied:**
```bash
# Check what labels exist in the repository
gh label list --repo dotCMS/core

# Use manual label selection in wizard
git issue-create
# → Step 7: Choose "Choose specific labels manually"
```

**Project Integration (ProjectV2):**

The tools support dotCMS's ProjectV2 structure. When you select project integration, the issue will be prepared for addition to the dotCMS - Product Planning project:

```bash
# Get project ID for dotCMS - Product Planning
gh api graphql -f query='query{organization(login:"dotCMS"){projectsV2(first:10){nodes{id title}}}}'

# Add issue to project (replace PROJECT_ID and ISSUE_ID)
gh api graphql -f query='mutation{addProjectV2ItemById(input:{projectId:"PROJECT_ID" contentId:"ISSUE_ID"}){item{id}}}'

# Example with actual values:
gh api graphql -f query='mutation{addProjectV2ItemById(input:{projectId:"PVT_kwDOBWK2qs4ATeam" contentId:"I_kwDOBWK2qs6Ah2kG"}){item{id}}}'
```

**Note**: The GitHub CLI requires `read:project` and `write:project` scopes for ProjectV2 operations. You can add these scopes with:
```bash
gh auth refresh -s read:project,write:project
```

**Branch Creation Issues:**
- Branch creation only works when creating issues in the current repository
- Cross-repository issues show a warning and suggest using `git issue-branch` in the target repo

### Reset Configuration

```bash
# Remove saved preferences to start fresh
rm ~/.dotcms/issue-config.json
```

## Contributing

Feel free to submit issues and enhancement requests!
