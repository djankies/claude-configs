# Git Research

## Overview
- **Version**: 2.52.0 (Latest stable release as of November 17, 2025)
- **Purpose**: Distributed version control system for tracking changes in source code during software development
- **Official Documentation**: https://git-scm.com/doc
- **Pro Git Book**: https://git-scm.com/book
- **Command Reference**: https://git-scm.com/docs
- **Last Updated**: November 20, 2025

## Installation

### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install git
```

### macOS
```bash
brew install git
```

Or download from https://git-scm.com/download/mac

### Windows
Download installer from https://git-scm.com/download/win

### Verify Installation
```bash
git --version
```

## Core Concepts

### The Three Trees

Git manages three distinct collections of files during normal operation:

1. **HEAD** - The snapshot of your last commit on that branch, representing the parent of the next commit
2. **Index** - Your proposed next commit, also called the staging area
3. **Working Directory** - Your sandbox for making changes before committing

### How Branches Work

Git branches are lightweight pointers to commits. Rather than copying entire directories like older VCS tools, Git stores branches as simple files containing a 40-character SHA-1 checksum. This design makes branching operations nearly instantaneous.

**Data Structure**: When you commit, Git creates a commit object containing:
- A pointer to the snapshot of staged content
- Author information and commit message
- Pointers to parent commit(s)

**HEAD Pointer**: In Git, this is a pointer to the local branch you're currently on. HEAD tracks which branch you're actively working on.

### Distributed Architecture

Git is a distributed version control system, meaning every developer has a complete copy of the repository history. This enables:
- Working offline
- Fast operations (most operations are local)
- Multiple backup locations
- Flexible workflows

## Configuration and Setup

### Configuration Levels

The `git config` command manages Git settings across three hierarchy levels:

1. **System**: `[path]/etc/gitconfig` - applies to all users (use `--system`)
2. **Global**: `~/.gitconfig` or `~/.config/git/config` - user-specific (use `--global`)
3. **Local**: `.git/config` - repository-specific (use `--local`, default)

Lower levels override higher ones, so local settings trump global settings.

### First-Time Setup

#### Setting Up Your Identity
```bash
git config --global user.name "Your Name"
git config --global user.email your.email@example.com
```

This information becomes permanently embedded in every commit you create.

#### Selecting a Default Editor
```bash
git config --global core.editor vim
git config --global core.editor "code --wait"
git config --global core.editor emacs
```

#### Configuring Default Branch Name
Starting with Git 2.28, customize the initial branch name:
```bash
git config --global init.defaultBranch main
```

#### Verifying Configuration
```bash
git config --list
git config user.name
git config user.email
```

### Essential Configuration Options

#### Editor & Templates
```bash
git config --global core.editor vim
git config --global commit.template ~/.gitmessage.txt
```

#### Output Control
```bash
git config --global core.pager less
git config --global color.ui auto
```

#### Workflow Preferences
```bash
git config --global help.autocorrect 10
git config --global user.signingkey YOUR_GPG_KEY_ID
```

#### Cross-Platform Compatibility
```bash
git config --global core.autocrlf true
git config --global core.autocrlf input
git config --global core.excludesfile ~/.gitignore_global
```

## Core Commands and Workflows

### Getting and Creating Projects

#### Initialize a Repository
```bash
git init
git init project-name
```

#### Clone an Existing Repository
```bash
git clone https://github.com/user/repo.git
git clone https://github.com/user/repo.git custom-name
git clone --recurse-submodules https://github.com/user/repo.git
```

### Basic Snapshotting

#### Check Status
```bash
git status
git status -s
```

#### Stage Changes
```bash
git add file.txt
git add .
git add *.js
git add --patch
```

The `--patch` option allows interactive selection of changes to stage.

#### Commit Changes
```bash
git commit -m "Commit message"
git commit -a -m "Stage and commit tracked files"
git commit --amend
git commit --amend -m "New message"
```

**Important**: Only amend commits that haven't been pushed, as amending pushed commits causes collaboration problems.

#### View Differences
```bash
git diff
git diff --staged
git diff --cached
git diff HEAD
git diff branch1..branch2
git diff --check
```

Run `git diff --check` before committing to catch whitespace errors.

#### Unstage Files

With git reset (older approach):
```bash
git reset HEAD file.txt
```

With git restore (Git 2.23.0+):
```bash
git restore --staged file.txt
```

#### Discard Changes

With git checkout:
```bash
git checkout -- file.txt
```

With git restore:
```bash
git restore file.txt
```

Both commands are dangerous - any local changes are permanently lost.

### Branching and Merging

#### Create Branches
```bash
git branch feature-branch
git branch -a
git branch -r
```

#### Switch Branches
```bash
git checkout feature-branch
git switch feature-branch
git checkout -b new-feature
git switch -c new-feature
```

`git switch` was introduced in Git 2.23+ as a clearer alternative to `git checkout`.

#### Merge Branches
```bash
git checkout main
git merge feature-branch
git merge --no-ff feature-branch
git merge --squash feature-branch
```

The `--no-ff` flag creates an explicit merge commit, preserving branch history and simplifying future reverts.

#### Delete Branches
```bash
git branch -d feature-branch
git branch -D feature-branch
git push origin --delete feature-branch
```

### Working with Remotes

#### Add Remotes
```bash
git remote add origin https://github.com/user/repo.git
git remote add upstream https://github.com/original/repo.git
```

#### View Remotes
```bash
git remote
git remote -v
git remote show origin
```

#### Fetch from Remotes
```bash
git fetch origin
git fetch --all
```

`git fetch` retrieves data that you don't yet have locally but doesn't automatically merge it.

#### Pull from Remotes
```bash
git pull origin main
git pull --rebase origin main
```

`git pull` combines fetching and merging in one operation.

#### Push to Remotes
```bash
git push origin main
git push -u origin feature-branch
git push --all
git push --tags
git push --force
git push --force-with-lease
```

Use `--force-with-lease` instead of `--force` for safer force pushes that won't overwrite others' work.

#### Rename and Remove Remotes
```bash
git remote rename old-name new-name
git remote remove remote-name
git remote rm remote-name
```

### Viewing Commit History

#### Basic Log Commands
```bash
git log
git log -3
git log --oneline
git log --graph
git log --all --decorate --oneline --graph
```

#### Formatting Output
```bash
git log --pretty=oneline
git log --pretty=format:"%h - %an, %ar : %s"
git log --pretty=format:"%h %an %ad %s" --date=short
```

Common format specifiers:
- `%h` - Abbreviated commit hash
- `%an` - Author name
- `%ad` - Author date
- `%ar` - Author date, relative
- `%s` - Subject (commit message)
- `%cn` - Committer name
- `%cd` - Committer date

#### Filtering Commits
```bash
git log --since=2.weeks
git log --since="2025-01-01"
git log --until="2025-12-31"
git log --author="John Doe"
git log --grep="fix"
git log -S "function_name"
git log --no-merges
git log -- path/to/file
git log --follow file.txt
```

#### Graph Visualization
```bash
git log --graph --oneline --all
git log --graph --pretty=format:"%h %s" --abbrev-commit
```

### Viewing Changes
```bash
git show HEAD
git show commit-hash
git show v1.0.0
git show HEAD~3
git show branch-name:path/to/file
```

## Advanced Features

### Git Stash

#### Save Changes
```bash
git stash
git stash push
git stash push -m "description"
git stash --keep-index
git stash --include-untracked
git stash -u
git stash --all
git stash -a
git stash --patch
```

Stashing takes the dirty state of your working directory - modified tracked files and staged changes - and saves it on a stack of unfinished changes that you can reapply at any time.

#### List Stashes
```bash
git stash list
```

#### Apply Stashes
```bash
git stash apply
git stash apply stash@{2}
git stash apply --index
git stash pop
```

`git stash pop` applies and removes the stash immediately.

#### Remove Stashes
```bash
git stash drop stash@{1}
git stash clear
```

#### Create Branch from Stash
```bash
git stash branch new-branch-name
```

### Git Rebase

#### Basic Rebase
```bash
git checkout feature
git rebase main
git rebase main feature
```

Rebasing replays commits from one branch onto another, creating a linear history.

#### Interactive Rebase
```bash
git rebase -i HEAD~3
git rebase -i main
```

Interactive rebase allows you to:
- Reorder commits
- Squash commits together
- Edit commit messages
- Split commits
- Remove commits

#### Selective Rebasing
```bash
git rebase --onto main server client
```

#### Continue/Abort Rebase
```bash
git rebase --continue
git rebase --skip
git rebase --abort
```

#### Critical Warning

**"Do not rebase commits that exist outside your repository and that people may have based work on."**

When you rebase, you're rewriting history. If others have based work on your commits, rebasing creates duplicate work and confusion.

#### Best Practice

You can get the best of both worlds: rebase local changes before pushing to clean up your work, but never rebase anything that you've pushed somewhere.

### Git Cherry-Pick

#### Basic Cherry-Pick
```bash
git cherry-pick commit-hash
git cherry-pick commit-hash1 commit-hash2
git cherry-pick start-commit^..end-commit
```

Cherry-pick applies specific commits from one branch to another.

#### Options
```bash
git cherry-pick -x commit-hash
git cherry-pick --edit commit-hash
git cherry-pick -n commit-hash
git cherry-pick --no-commit commit-hash
```

#### Continue/Abort Cherry-Pick
```bash
git cherry-pick --continue
git cherry-pick --abort
```

#### Best Practice

Use cherry-pick as rarely as possible. It easily creates duplicate commits. Whenever you can use a traditional merge or rebase to integrate, you should do so. Cherry-pick should be reserved for cases where this is not possible, such as creating hotfixes or salvaging commits from abandoned branches.

### Git Bisect

Git bisect performs automated binary search through commit history to pinpoint which commit introduced a bug.

#### Manual Bisect Workflow
```bash
git bisect start
git bisect bad
git bisect good commit-hash
git bisect good
git bisect bad
git bisect reset
```

#### Automated Bisect
```bash
git bisect start HEAD v1.0
git bisect run test-script.sh
git bisect reset
```

The test script should exit 0 for working code and non-zero for broken code.

### Git Reflog

Reflog tracks changes to HEAD and branch references over time.

#### View Reflog
```bash
git reflog
git reflog show branch-name
git reflog show HEAD@{2.days.ago}
```

#### Recover Lost Commits
```bash
git reflog
git checkout commit-hash
git branch recovery-branch commit-hash
```

Reflog data is strictly local and only persists for a few months.

### Git Reset

#### Reset Modes

**Soft Reset** (moves HEAD, keeps staging and working directory):
```bash
git reset --soft HEAD~1
git reset --soft commit-hash
```

**Mixed Reset** (default, moves HEAD and unstages):
```bash
git reset HEAD~1
git reset --mixed commit-hash
```

**Hard Reset** (moves HEAD, unstages, and discards changes):
```bash
git reset --hard HEAD~1
git reset --hard origin/main
```

Hard reset is dangerous - it forcibly overwrites files in the working directory and data loss can occur.

#### Reset with Paths
```bash
git reset HEAD file.txt
git reset commit-hash -- file.txt
```

When you specify a file path, reset only affects the index and working directory.

### Git Revert

Revert creates new commits that undo previous commits without rewriting history.

```bash
git revert HEAD
git revert commit-hash
git revert -m 1 merge-commit-hash
git revert --no-commit HEAD~3..HEAD
```

Use revert for shared repositories instead of reset, as it doesn't rewrite history.

## Commit Reference Methods

### RefLog Shortnames
```bash
HEAD@{0}
HEAD@{5}
main@{yesterday}
main@{2.days.ago}
```

### Ancestry References

**Caret (^)**: Points to a commit's parent
```bash
HEAD^
HEAD^^
d921970^2
```

**Tilde (~)**: Traverses first parents
```bash
HEAD~3
HEAD~
main~5
```

**Combined**:
```bash
HEAD~3^2
main~2^
```

### Commit Ranges

**Double dot (..)**: Shows commits reachable from one ref but not another
```bash
git log main..feature
git log origin/main..HEAD
```

**Triple dot (...)**: Displays commits in either reference but not both
```bash
git log main...feature
git log --left-right main...feature
```

**Multiple points**:
```bash
git log refA refB ^refC
git log refA refB --not refC
```

## Branching Strategies and Best Practices

### Long-Running Branches

Maintain multiple persistent branches at different stability levels:

- **Main/Master branch**: Contains only production-ready, stable code
- **Develop branch**: Integration branch for testing features before release
- **Topic branches**: Short-lived branches merged into develop when ready

### Topic Branches

Short-lived branches that isolate individual features or fixes. In Git it's common to create, work on, merge, and delete branches several times a day.

**Key benefits**:
- Enable rapid context-switching between features
- Simplify code review by grouping related changes
- Allow flexible merging order regardless of creation sequence
- Support experimentation without affecting main development

### Git Flow Branching Model

#### Main Branches

**Master**: Every commit represents a new production release. The source code of HEAD always reflects a production-ready state.

**Develop**: Integration branch with the latest delivered development changes for the next release.

#### Supporting Branches

**Feature Branches**:
- Origin: Branch from `develop`
- Merge back to: `develop`
- Naming: Anything except `master`, `develop`, `release-*`, or `hotfix-*`

**Release Branches**:
- Origin: Branch from `develop`
- Merge back to: Both `develop` and `master`
- Naming: `release-*`
- Purpose: Prepare production releases with final adjustments

**Hotfix Branches**:
- Origin: Branch from `master`
- Merge back to: Both `master` and `develop`
- Naming: `hotfix-*`
- Purpose: Address critical production bugs immediately

#### Critical Workflow Rule

Use `--no-ff` flags during merges to preserve feature branch history and simplify future reverts.

```bash
git merge --no-ff feature-branch
```

### Pull Request Workflow

For public projects using fork-based contributions:

1. Clone the main repository
2. Create a feature branch
3. Make changes and commit
4. Fork the project on the hosting platform
5. Push your feature branch to your fork
6. Submit a pull request to the original repository

#### Best Practices for Contributions

**Whitespace**: Run `git diff --check` before committing to catch whitespace errors.

**Logical changesets**: Make each commit represent a single, digestible change. Use `git add --patch` to split changes.

**Commit messages**:
- 50-character summary line
- Blank line
- Detailed explanation in imperative voice ("Fix bug" not "Fixed bug")

**Handling feedback**:
```bash
git rebase origin/master
git merge --squash feature
git push origin featureBv2
```

## Tags

### Creating Tags

**Lightweight tags**:
```bash
git tag v1.4-lw
git tag v1.0.0
```

**Annotated tags**:
```bash
git tag -a v1.4 -m "my version 1.4"
git tag -a v1.0.0 -m "Release version 1.0.0"
```

### Listing Tags
```bash
git tag
git tag -l "v1.8*"
git tag -l "pattern*"
```

### Viewing Tag Details
```bash
git show v1.4
```

### Tagging Past Commits
```bash
git tag -a v1.2 9fceb02
```

### Pushing Tags
```bash
git push origin v1.5
git push origin --tags
git push origin --follow-tags
```

### Deleting Tags

**Locally**:
```bash
git tag -d v1.4-lw
```

**Remotely**:
```bash
git push origin --delete v1.4-lw
git push origin :refs/tags/v1.4-lw
```

### Checking Out Tags
```bash
git checkout v2.0.0
git checkout -b version2 v2.0.0
```

Checking out a tag enters "detached HEAD" state. Create a branch if you need to make modifications.

## .gitignore Patterns and Best Practices

### Pattern Syntax

#### Basic Elements
- Blank lines and comments (lines starting with `#`) are ignored
- Backslash escapes special characters, including `#` and `!`
- Trailing spaces are preserved only if escaped with backslash

#### Negation
```
*.log
!important.log
```

The `!` prefix reverses exclusion. However, you cannot re-include files whose parent directory is already excluded.

#### Wildcard Matching
- `*` matches anything except `/`
- `?` matches any single character except `/`
- `[a-z]` character ranges are supported

#### Directory Separators
- Leading or middle `/`: pattern is relative to the `.gitignore` file location
- No `/`: pattern matches at any depth
- Trailing `/`: matches only directories

#### Double Asterisk (`**`)
- `**/foo` matches "foo" at any directory level
- `abc/**` matches everything inside the `abc` directory recursively
- `a/**/b` matches `a/b`, `a/x/b`, `a/x/y/b`, etc.

### Precedence and File Locations

Git checks patterns in this order (highest to lowest priority):

1. Command-line patterns
2. `.gitignore` files (from root down to target directory)
3. `$GIT_DIR/info/exclude`
4. `core.excludesFile` configuration file

**Where to place patterns**:
- **`.gitignore`**: Share across developers (version-controlled)
- **`.git/info/exclude`**: Repository-specific, user-only patterns
- **`core.excludesFile`**: Personal, system-wide exclusions

### Practical Examples

```
*.log
*.tmp
node_modules/
.env
.DS_Store
Thumbs.db
*.swp
*~
build/
dist/
```

#### Exclude Everything Except Specific Files
```
/*
!/foo
/foo/*
!/foo/bar
```

### Common Patterns

#### Node.js
```
node_modules/
npm-debug.log
.env
dist/
build/
```

#### Python
```
__pycache__/
*.py[cod]
*$py.class
.Python
venv/
env/
.venv
*.egg-info/
.pytest_cache/
```

#### Java
```
*.class
*.jar
*.war
target/
.gradle/
build/
```

#### IDE Files
```
.vscode/
.idea/
*.sublime-project
*.sublime-workspace
```

### Important Considerations

Already-tracked files remain tracked unless removed with `git rm --cached`. Git does not follow symbolic links in `.gitignore` files.

## Git Hooks and Automation

### What Are Git Hooks?

Git hooks are custom scripts that execute automatically when specific Git operations occur. They enable policy enforcement and integration with external systems.

### Installation

Hooks are stored in `.git/hooks`. To activate a hook, place an executable file with the appropriate name (no extension) in the hooks subdirectory.

Client-side hooks are not copied when you clone a repository, so enforcement typically requires server-side implementation.

### Common Client-Side Hooks

**pre-commit**: Inspects snapshots before committing
```bash
#!/bin/sh
npm test
```

**prepare-commit-msg**: Edits default messages before the editor opens

**commit-msg**: Validates commit messages
```bash
#!/bin/sh
if ! grep -qE "^(feat|fix|docs|style|refactor|test|chore):" "$1"; then
    echo "Invalid commit message format"
    exit 1
fi
```

**post-commit**: Runs after commits complete; useful for notifications

**pre-push**: Validates refs before transferring objects
```bash
#!/bin/sh
npm run lint && npm test
```

**post-checkout/post-merge**: Sets up working directory after operations

### Server-Side Hooks

**pre-receive**: Validates all pushed references; rejects entire push if needed

**update**: Evaluates individual branch updates; can selectively reject branches

**post-receive**: Notifies services or users after successful pushes
```bash
#!/bin/sh
curl -X POST https://example.com/webhook
```

### Hook Examples

#### Prevent Force Push
```bash
#!/bin/sh
while read oldrev newrev refname; do
    if [ "$oldrev" != "0000000000000000000000000000000000000000" ]; then
        if ! git merge-base --is-ancestor "$oldrev" "$newrev"; then
            echo "Force push detected and rejected"
            exit 1
        fi
    fi
done
```

#### Enforce Tests Before Commit
```bash
#!/bin/sh
npm test
if [ $? -ne 0 ]; then
    echo "Tests must pass before commit"
    exit 1
fi
```

## Troubleshooting Common Issues

### 1. Fixing Commit Message Typos

```bash
git commit --amend
git commit --amend -m "New message"
```

Avoid using `--amend` for commits already pushed to a central repository.

### 2. Merge Conflicts

When conflicts occur:

1. Open conflicting files
2. Locate conflict markers: `<<<<<<<`, `=======`, `>>>>>>>`
3. Resolve conflicts manually
4. Stage resolved files: `git add file.txt`
5. Complete the merge: `git commit`

#### Abort Merge
```bash
git merge --abort
```

#### Merge Tools
```bash
git mergetool
git mergetool --tool=vimdiff
```

### 3. Failed Push: Diverged Branches

```bash
git pull --rebase origin main
git push origin main
```

Rebasing gives a cleaner commit history compared to merging.

### 4. Accidentally Added Files

```bash
git reset HEAD file.txt
git rm --cached file.txt
echo "file.txt" >> .gitignore
```

### 5. Recovering Lost Commits

```bash
git reflog
git checkout commit-hash
git branch recovery-branch commit-hash
```

40% of developers lose track of significant commits at crucial development stages.

### 6. Repository Not Found Error

Ensure correct repository URL:
```bash
git remote -v
git remote set-url origin https://github.com/user/repo.git
```

### 7. SSL Certificate Issues

```bash
git config --global http.sslVerify false
```

Or add the certificate to your trusted certificate store.

### 8. Undoing Commits

Keep changes:
```bash
git reset HEAD~2
```

Discard changes:
```bash
git reset --hard HEAD~2
```

### 9. Restoring Deleted Files

```bash
git log -- path/to/file
git checkout commit-hash^ -- path/to/file
```

### 10. Finding Bad Commits

```bash
git bisect start
git bisect bad
git bisect good v1.0
git bisect run test.sh
git bisect reset
```

### 11. Detached HEAD State

```bash
git checkout -b temp-branch
git checkout main
git merge temp-branch
```

### 12. Large File Issues

```bash
git filter-branch --tree-filter 'rm -f large-file' HEAD
git push --force
```

Better alternative: Use git-filter-repo or BFG Repo-Cleaner.

### 13. Rebase Conflicts

```bash
git rebase --continue
git rebase --skip
git rebase --abort
```

## Advanced Merging

### Merge Strategies

**Recursive Strategy Options**:
```bash
git merge -Xignore-all-space feature
git merge -Xignore-space-change feature
git merge -Xours feature
git merge -Xtheirs feature
```

**Ours Strategy**:
```bash
git merge -s ours feature
```

Creates a merge commit while completely ignoring changes from the incoming branch.

### Conflict Resolution Tools

Extract file versions during merge:
```bash
git show :1:file.txt > file.common.txt
git show :2:file.txt > file.ours.txt
git show :3:file.txt > file.theirs.txt
```

Use diff3 format:
```bash
git checkout --conflict=diff3 file.txt
git merge --conflict=diff3 feature
```

View conflicting commits:
```bash
git log --oneline --left-right --merge
```

### Undoing Merges

**Local repositories only**:
```bash
git reset --hard HEAD~
```

**Shared repositories**:
```bash
git revert -m 1 HEAD
```

### Subtree Merging

```bash
git remote add external-project https://github.com/user/project.git
git fetch external-project
git read-tree --prefix=vendor/project/ -u external-project/main
git commit -m "Add external project as subtree"
git merge --squash -Xsubtree=vendor/project external-project/main
```

## Rewriting History

### Interactive Rebase

```bash
git rebase -i HEAD~3
git rebase -i main
```

Available commands:
- `pick` - Use commit
- `reword` - Use commit, but edit message
- `edit` - Use commit, but stop for amending
- `squash` - Use commit, but meld into previous commit
- `fixup` - Like squash, but discard message
- `drop` - Remove commit

### Squashing Commits

In interactive rebase, change `pick` to `squash`:
```
pick abc123 First commit
squash def456 Second commit
squash ghi789 Third commit
```

### Splitting Commits

1. Mark commit as `edit` in rebase script
2. When Git stops: `git reset HEAD^`
3. Stage and commit portions separately
4. Continue: `git rebase --continue`

### Filter-Branch (Legacy)

```bash
git filter-branch --tree-filter 'rm -f passwords.txt' HEAD
git filter-branch --subdirectory-filter trunk HEAD
git filter-branch --commit-filter 'GIT_AUTHOR_EMAIL="new@email.com"' HEAD
```

Use git-filter-repo as a superior alternative.

### Amending Author Information

```bash
git commit --amend --author="Name <email@example.com>"
```

For multiple commits:
```bash
git rebase -i HEAD~5
```

Mark commits as `edit`, then amend each one.

## Security Best Practices

### Signing Commits and Tags with GPG

#### Initial GPG Setup

Check for existing keys:
```bash
gpg --list-keys
```

Generate a new key:
```bash
gpg --gen-key
```

Configure Git:
```bash
git config --global user.signingkey YOUR_KEY_ID
```

#### Signing Tags

```bash
git tag -s v1.5 -m 'my signed 1.5 tag'
git show v1.5
```

#### Verifying Tags

```bash
git tag -v v1.4.2.1
```

Requires the signer's public key in your keyring.

#### Signing Commits

```bash
git commit -a -S -m 'Signed commit'
git log --show-signature
git log --pretty="format:%h %G? %aN %s"
```

Signature status codes:
- `G` - Good signature
- `B` - Bad signature
- `U` - Good signature, unknown validity
- `N` - No signature

#### Always Sign Commits

```bash
git config --global commit.gpgsign true
git config --local commit.gpgsign true
```

#### Enforcing Signatures in Merges

```bash
git merge --verify-signatures feature
git merge --verify-signatures --no-ff feature
```

### Credential Storage

#### Available Credential Helpers

**Default**: Prompts for username and password every connection

**Cache mode**: Keeps credentials in memory for 15 minutes
```bash
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=3600'
```

**Store mode**: Saves credentials in plain-text file (insecure)
```bash
git config --global credential.helper store
git config --global credential.helper 'store --file ~/.git-credentials'
```

**macOS (osxkeychain)**: Caches credentials in secure keychain
```bash
git config --global credential.helper osxkeychain
```

**Windows (Git Credential Manager)**: Uses Windows Credential Store
```bash
git config --global credential.helper manager
```

#### Multiple Helpers

```bash
git config --global credential.helper store
git config --global --add credential.helper cache
```

Git queries them sequentially and stops after the first answer.

#### Security Considerations

- Avoid plain-text store for sensitive repositories
- Use encrypted system vaults when possible
- Consider custom helpers for enterprise scenarios
- Rotate credentials regularly
- Use SSH keys instead of HTTPS passwords

### SSH Authentication

#### Generate SSH Key

ED25519 keys (recommended):
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

RSA keys (legacy):
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

#### Add SSH Key to Agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

#### Add Public Key to GitHub/GitLab

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy output and add to GitHub/GitLab SSH keys settings.

#### Test Connection

```bash
ssh -T git@github.com
ssh -T git@gitlab.com
```

#### Use SSH URLs

```bash
git clone git@github.com:user/repo.git
git remote set-url origin git@github.com:user/repo.git
```

#### SSH Config

Create `~/.ssh/config`:
```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
```

## Integration with GitHub/GitLab

### GitHub-Specific Features

#### GitHub CLI
```bash
gh repo clone user/repo
gh pr create
gh pr list
gh pr checkout 123
gh issue create
gh workflow run
```

#### GitHub Actions Integration
```bash
git commit -m "feat: add feature"
git push origin main
```

#### Protected Branches
- Configure in repository settings
- Require pull request reviews
- Require status checks
- Enforce linear history

### GitLab-Specific Features

#### GitLab CI/CD
```bash
git push origin main
```

Triggers pipelines defined in `.gitlab-ci.yml`.

#### Merge Request Workflows
```bash
git push -o merge_request.create origin feature-branch
git push -o merge_request.target=main origin feature-branch
```

#### Protected Branches
- Configure in Settings > Repository > Protected branches
- Set allowed to merge/push
- Require code owner approval

### Best Practices for Platform Integration

#### Two-Factor Authentication
Enable 2FA for all users, especially those with elevated permissions.

#### Access Control
Grant users minimum permissions necessary. Assign minimum roles at the top-level, then grant higher permissions in specific subgroups.

#### Branch Protection
- Require pull/merge requests
- Require code reviews
- Require passing CI/CD pipelines
- Prevent force pushes
- Prevent deletion

#### Code Review Guidelines
- Review changes line by line
- Test changes locally
- Provide constructive feedback
- Approve only when confident

## Git Submodules

### Adding Submodules

```bash
git submodule add https://github.com/user/repo.git path/to/submodule
git commit -m "Add submodule"
```

### Cloning with Submodules

```bash
git clone --recurse-submodules https://github.com/user/repo.git
```

Or after cloning:
```bash
git submodule init
git submodule update
```

### Updating Submodules

```bash
git submodule update --remote
git submodule update --remote --merge
git submodule update --remote --rebase
```

### Removing Submodules

```bash
git submodule deinit path/to/submodule
git rm path/to/submodule
rm -rf .git/modules/path/to/submodule
```

### Submodule Best Practices

1. **Point to specific commits or tags**, not branches
2. **Document usage clearly** in README
3. **Regularly update** but test thoroughly
4. **Avoid nested submodules** when possible
5. **Create setup scripts** for initialization
6. **Coordinate in teams** to avoid confusion
7. **Use for strict version management** over dependencies

### When to Use Submodules

- External components changing too fast
- Upcoming changes will break API
- Need to lock code to specific commit
- Shared libraries across multiple projects

### Submodule Alternatives

- Git subtree
- Package managers (npm, pip, maven)
- Monorepos
- Build tools with dependency management

## Code Examples

### Basic Workflow

```bash
cd /path/to/project
git init

git add .
git commit -m "Initial commit"

git remote add origin https://github.com/user/repo.git
git push -u origin main
```

### Feature Branch Workflow

```bash
git checkout main
git pull origin main

git checkout -b feature/user-authentication
git add src/auth.js
git commit -m "Add user authentication"

git push -u origin feature/user-authentication

git checkout main
git merge feature/user-authentication
git push origin main

git branch -d feature/user-authentication
git push origin --delete feature/user-authentication
```

### Fixing a Bug

```bash
git checkout main
git pull origin main

git checkout -b fix/login-error

git add src/login.js
git commit -m "Fix login validation error"

git push -u origin fix/login-error
```

### Rebasing Feature Branch

```bash
git checkout feature-branch
git fetch origin
git rebase origin/main

git push --force-with-lease origin feature-branch
```

### Squashing Commits Before Merge

```bash
git checkout feature-branch
git rebase -i HEAD~5

git checkout main
git merge --no-ff feature-branch
git push origin main
```

### Creating a Release

```bash
git checkout main
git pull origin main

git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

git checkout -b release/1.0.0
git push -u origin release/1.0.0
```

### Hotfix Workflow

```bash
git checkout main
git checkout -b hotfix/security-patch

git add src/security.js
git commit -m "Fix security vulnerability"

git checkout main
git merge --no-ff hotfix/security-patch
git tag -a v1.0.1 -m "Hotfix v1.0.1"

git checkout develop
git merge --no-ff hotfix/security-patch

git branch -d hotfix/security-patch
git push origin main develop --tags
```

### Recovering from Mistakes

```bash
git reflog
git checkout commit-hash
git checkout -b recovery-branch

git checkout main
git merge recovery-branch
```

### Cleaning Up History

```bash
git checkout feature
git rebase -i main
```

In editor, squash or reword commits, then:
```bash
git push --force-with-lease origin feature
```

### Searching Commit History

```bash
git log --all --grep="authentication"
git log -S "function_name" --source --all
git log --since="2 weeks ago" --author="John"
git log --oneline --graph --all --decorate
```

### Blame and Debugging

```bash
git blame -L 10,20 src/app.js
git blame -C src/app.js

git bisect start
git bisect bad
git bisect good v1.0
```

Test each midpoint, then:
```bash
git bisect good
git bisect bad
git bisect reset
```

## Version-Specific Notes

### Git 2.52.0 (November 2025)
- Latest stable release
- Performance improvements
- Bug fixes and security updates

### Git 2.49.0 (March 2025)
- Enhanced merge conflict resolution
- Improved submodule handling

### Git 2.28.0 (July 2020)
- Introduced `init.defaultBranch` configuration
- Allows customization of default branch name

### Git 2.23.0 (August 2019)
- Introduced `git switch` and `git restore`
- Clearer alternatives to `git checkout`

### Breaking Changes to Watch

- Older Git versions may not support newer features
- SSH key algorithms (DSA deprecated, ED25519 preferred)
- Default branch naming conventions (master vs main)

## Common Gotchas

1. **Forgetting to pull before pushing** - Always pull before pushing to avoid conflicts

2. **Working on the wrong branch** - Check current branch with `git branch` before committing

3. **Committing sensitive data** - Use `.gitignore` and never commit passwords, API keys, or credentials

4. **Force pushing shared branches** - Never force push to shared branches without team coordination

5. **Not understanding detached HEAD** - Create a branch when making changes in detached HEAD state

6. **Merge vs rebase confusion** - Use merge for shared branches, rebase for local cleanup

7. **Ignoring already-tracked files** - Use `git rm --cached` to stop tracking files

8. **Large binary files** - Use Git LFS for large files, not standard Git

9. **Nested repositories** - Use submodules or subtrees instead of nesting `.git` directories

10. **Case-sensitive filenames** - Git is case-sensitive even on case-insensitive filesystems

## Anti-Patterns

### What NOT to Do

1. **Don't commit directly to main/master** - Use feature branches and pull requests

2. **Don't rebase public/shared branches** - Rewrites history and causes conflicts for others

3. **Don't use `git push --force` on shared branches** - Use `--force-with-lease` if absolutely necessary

4. **Don't commit large binary files** - Use Git LFS or external storage

5. **Don't commit generated files** - Add build artifacts to `.gitignore`

6. **Don't use vague commit messages** - "fix stuff" or "updates" provide no context

7. **Don't mix multiple concerns in one commit** - One commit should address one logical change

8. **Don't ignore merge conflicts** - Resolve properly, don't just accept all changes blindly

9. **Don't store credentials in repository** - Use environment variables or secret management

10. **Don't skip code review** - Even senior developers benefit from peer review

## Performance Tips

### 1. Shallow Clones

```bash
git clone --depth 1 https://github.com/user/repo.git
git clone --shallow-since="2024-01-01" https://github.com/user/repo.git
```

### 2. Partial Clones

```bash
git clone --filter=blob:none https://github.com/user/repo.git
git clone --filter=tree:0 https://github.com/user/repo.git
```

### 3. Sparse Checkout

```bash
git clone --filter=blob:none --sparse https://github.com/user/repo.git
cd repo
git sparse-checkout init --cone
git sparse-checkout set path/to/needed/folder
```

### 4. Git Garbage Collection

```bash
git gc
git gc --aggressive
git gc --auto
```

### 5. Optimize Repository

```bash
git repack -a -d --depth=250 --window=250
git prune
```

### 6. Use .gitattributes for Large Repos

```
*.jpg filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
```

### 7. Disable Auto GC for Large Operations

```bash
git config --global gc.auto 0
```

Re-enable after:
```bash
git config --global --unset gc.auto
```

## Error Handling

### Common Errors and Solutions

#### "fatal: not a git repository"
```bash
git init
```

#### "fatal: refusing to merge unrelated histories"
```bash
git pull origin main --allow-unrelated-histories
```

#### "error: failed to push some refs"
```bash
git pull --rebase origin main
git push origin main
```

#### "fatal: remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/user/repo.git
```

#### "Your branch and 'origin/main' have diverged"
```bash
git pull --rebase origin main
```

Or:
```bash
git reset --hard origin/main
```

#### "Updates were rejected because the tip of your current branch is behind"
```bash
git pull origin main
git push origin main
```

#### "fatal: pathspec 'file.txt' did not match any files"

File doesn't exist. Check spelling and path.

#### "error: Your local changes would be overwritten by merge"
```bash
git stash
git pull
git stash pop
```

## References

### Official Documentation
- Git Official Website: https://git-scm.com
- Pro Git Book: https://git-scm.com/book
- Git Reference Manual: https://git-scm.com/docs
- Git Wiki: https://git.wiki.kernel.org

### Tutorials and Guides
- Git Flow: https://nvie.com/posts/a-successful-git-branching-model/
- Atlassian Git Tutorials: https://www.atlassian.com/git/tutorials
- GitHub Guides: https://guides.github.com
- GitLab Documentation: https://docs.gitlab.com

### Tools
- Git GUI Clients: GitKraken, SourceTree, GitHub Desktop, Tower
- Git Extensions: git-lfs, git-filter-repo, BFG Repo-Cleaner
- GitHub CLI: https://cli.github.com
- GitLab CLI: https://gitlab.com/gitlab-org/cli

### Community Resources
- Stack Overflow Git Tag: https://stackoverflow.com/questions/tagged/git
- Git Mailing List: https://git.kernel.org/pub/scm/git/git.git
- GitHub Community: https://github.community
- GitLab Forum: https://forum.gitlab.com

### Books
- Pro Git by Scott Chacon and Ben Straub
- Version Control with Git by Jon Loeliger and Matthew McCullough
- Git Pocket Guide by Richard E. Silverman

### Version History Sources
- Git Release Notes: https://github.com/git/git/tree/master/Documentation/RelNotes
- GitHub Blog: https://github.blog/tag/git/
- GitLab Blog: https://about.gitlab.com/blog/tags.html#git
