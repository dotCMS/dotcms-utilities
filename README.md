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

### Install from Source

If you're working with the source code directly, you can install the current version of the scripts by running:

```bash
./install-dev-scripts.sh
```

## Git Extensions

### Git Smart-Switch

The `git smart-switch` extension enhances branch switching and creation with features like:
- Interactive branch selection
- WIP commit management
- Optional remote branch pushing

#### Usage

```bash
git smart-switch [<new-branch-name>] [-p|--push]
```

### Git Issue Branch

The `git issue-branch` extension helps you:
- Select an issue from your assigned issues list
- Create a new branch automatically prefixed with the issue ID
- Generate a branch name suffix based on the issue title
- Optionally specify a custom suffix
- Switch to an existing branch if one exists for the issue

#### Usage

```bash
git issue-branch
```

### Git New Issue Branch

The `git new-issue-branch` extension helps you:
- Create a new GitHub issue with a title and description
- Automatically create a branch for the new issue
- Generate a branch name suffix based on the issue title
- Optionally specify a custom suffix

#### Usage

```bash
git new-issue-branch
```

### Git Issue PR

The `git issue-pr` extension streamlines PR creation by:
- Creating a new PR from the command line
- Automatically linking it to the issue ID defined in your current branch name
- Simplifying the PR creation workflow

#### Usage

```bash
git issue-pr
```

## Contributing

Feel free to submit issues and enhancement requests!
