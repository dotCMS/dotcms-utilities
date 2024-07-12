Public Repo

# dotcms-utilities

## Dev Scripts & Custom Git Extensions

This project includes several custom scripts andGit extensions to enhance your workflow.

This will check for the existence of and attempt to install the following

* HomeBrew (for mac)
* sdkman (for java and jbang multi versions and .sdkmanrc support)
* nvm (for nodejs multi versions and .nvmrc support)
* curl (for downloading files)
* fzf (for interactive selection, used in git- scripts)
* gh (for github cli support used in git- scripts)
* just (for justfile alias support)

### Installation

To install or update all the Git extensions and required executables from the main branch, run:


```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dotcms/dotcms-utilities/main/install-dev-scripts.sh)
```

If running from source code, you can install the current version scripts by running:

```bash
./install-dev-scripts.sh
```

### Git Smart-Switch Extension

This Git extension script, `git smart-switch`, enhances branch switching and creation by providing additional features like interactive branch selection, WIP commit management, and optional remote branch pushing.

#### Usage

```bash
git smart-switch [<new-branch-name>] [-p|--push]
```

### Git Issue Branch Extension

This Git extension script, `git issue-branch`, helps select an issue from the list assigned to the current user and creates a new branch for that issue.  The branch will be prefixed automatically with the issue id
and a default suffix will be created based upon the issue title.   The user can specify their own suffix also



#### Usage

```bash
git issue-branch 
```

### Git Issue PR Extension

This Git extension script, `git issue-pr`, helps to create a new PR from the command line and relate it to the issue id defined on the current branch.



#### Usage

```bash
git issue-pr 
```
