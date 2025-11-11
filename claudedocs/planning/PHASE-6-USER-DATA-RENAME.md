# Phase 6: User-Data Directory Renaming Design

## Current State

**Directory**: `user-data/` (hardcoded name)

**References** (4 files):
- `home/jimmy/default.nix` - Git hooks reference secrets
- `home/jimmy/shell/zsh.nix` - Shell integration
- `home/jimmy/programs/karabiner.nix` - Keyboard config
- `home/jimmy/programs/vscode.nix` - VS Code settings

**Structure**:
```
user-data/
├── app-configs/           # Application configs (Claude, etc.)
├── user-content/          # User-specific content (VS Code settings)
├── secrets/               # Not yet used, planned for future
├── backup.sh              # Backup script
├── restore.sh             # Restore script
├── README.md
├── .gitignore
├── ssh_known_hosts
└── zoxide_database
```

## Objective

Rename `user-data/` → `user-data-${username}/` to support multiple users on same repo.

## Design Decisions

### Option 1: Simple Rename (Selected)
**Approach**: Keep single directory, rename to include username

```
Before:
  user-data/

After:
  user-data-jimmy/
```

**Pros**:
- Simple, straightforward
- No multi-user complexity
- Backward compatible with single-user setup

**Cons**:
- Still one directory per repo copy

### Option 2: Multi-User Support (Rejected for Phase 6)
**Approach**: Support multiple user-data directories

```
user-data/
├── jimmy/
├── alice/
└── .gitignore
```

**Rejected because**:
- Overly complex for current use case
- Each user will have their own repo copy anyway
- Can be added later if needed

## Implementation Design

### 1. Directory Naming Convention

**Pattern**: `user-data-${username}`

**Examples**:
- User "jimmy" → `user-data-jimmy/`
- User "alice" → `user-data-alice/`
- User "john-doe" → `user-data-john-doe/`

### 2. Variable-Based References

**OLD** (hardcoded):
```nix
# home/jimmy/default.nix
SECRETS_PATHS=(
  "$HOME/nix-darwin/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/user-data/secrets/*.yaml"
)
```

**NEW** (variable-based):
```nix
{ config, username, ... }:

let
  userDataDir = "${config.home.homeDirectory}/nix-darwin/user-data-${username}";
in
{
  # Git hooks
  programs.git.extraConfig = {
    core.hooksPath = "${config.home.homeDirectory}/nix-darwin/.git/hooks";
  };

  home.file.".git/hooks/pre-commit".text = ''
    #!/usr/bin/env bash

    SECRETS_PATHS=(
      "$HOME/nix-darwin/hosts/*/secrets.yaml"
      "$HOME/nix-darwin/user-data-${username}/secrets/*.yaml"
    )
  '';
}
```

### 3. Backup/Restore Script Updates

**Scripts to update**:
- `user-data-${username}/backup.sh`
- `user-data-${username}/restore.sh`

**Detection logic** (auto-detect username):
```bash
#!/usr/bin/env bash
# backup.sh - Auto-detect username

# Get username from parent directory name
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_NAME="$(basename "$SCRIPT_DIR")"

# Extract username from "user-data-{username}"
USERNAME="${DIR_NAME#user-data-}"

if [ "$USERNAME" = "$DIR_NAME" ]; then
  # Fallback if pattern doesn't match
  USERNAME="$USER"
fi

echo "Backing up user data for: $USERNAME"

# Rest of backup logic...
```

### 4. .gitignore Updates

**Pattern-based ignore**:
```gitignore
# .gitignore (root)

# User-data directories (all users)
user-data-*/

# But keep template
!user-data-template/

# User configs
config/user-config.nix
config/machine-config.nix
```

**Template directory**:
```
user-data-template/           # Committed (reference structure)
├── app-configs/
│   └── .gitkeep
├── user-content/
│   └── .gitkeep
├── secrets/
│   └── .gitkeep
├── backup.sh
├── restore.sh
├── README.md
└── .gitignore
```

### 5. Migration Flow

**During setup wizard**:
```bash
./setup.sh --migrate

# Step 1: Detect username
Username: jimmy

# Step 2: Check for existing user-data/
Found: user-data/

# Step 3: Rename directory
Renaming: user-data/ → user-data-jimmy/

# Step 4: Update all references
✅ Updated home/jimmy/default.nix
✅ Updated home/jimmy/shell/zsh.nix
✅ Updated home/jimmy/programs/karabiner.nix
✅ Updated home/jimmy/programs/vscode.nix
✅ Updated backup.sh
✅ Updated restore.sh

# Step 5: Git tracking
✅ Added user-data-*/ to .gitignore
✅ Untracked user-data-jimmy/
✅ Keeping user-data-template/ for reference

Migration complete!
```

### 6. Fresh Install Flow

**New user "alice"**:
```bash
./setup.sh --fresh

Username: alice

# Create user-data directory from template
Creating: user-data-alice/ from user-data-template/

✅ Directory structure created
✅ Scripts configured for user: alice
✅ All references use: user-data-alice/
```

### 7. All File References to Update

**Search pattern**: `user-data/` → `user-data-${username}/`

**Files requiring updates**:

1. **home/jimmy/default.nix** (becomes `home/${username}/default.nix`):
   ```nix
   # Line 67, 155
   "$HOME/nix-darwin/user-data/secrets/*.yaml"
   →
   "$HOME/nix-darwin/user-data-${username}/secrets/*.yaml"
   ```

2. **home/jimmy/shell/zsh.nix**:
   - Check for user-data references
   - Update to variable-based path

3. **home/jimmy/programs/karabiner.nix**:
   - Check for user-data references
   - Update to variable-based path

4. **home/jimmy/programs/vscode.nix**:
   - Comment on line 59: "Settings are backed up via: backup-user-data"
   - Update comments to reference `user-data-${username}/`

5. **Scripts**:
   - `user-data/backup.sh` → Auto-detect username from directory name
   - `user-data/restore.sh` → Auto-detect username from directory name

6. **Documentation**:
   - Update all docs referencing `user-data/`
   - Add note about username-specific directories

### 8. Backward Compatibility

**Graceful handling of old `user-data/` directory**:

```nix
# lib/user-data.nix

{ lib, username, ... }:

let
  # Try new pattern first, fall back to old
  userDataDir =
    if builtins.pathExists ./user-data-${username}
    then "user-data-${username}"
    else if builtins.pathExists ./user-data
    then "user-data"  # Backward compatible
    else throw "No user-data directory found. Run: ./setup.sh --migrate";
in
{
  # Export for use in modules
  _module.args.userDataDir = userDataDir;
}
```

**Migration warning**:
```bash
# During nix-rebuild

⚠️  Warning: Using old 'user-data/' directory
   Recommended: Run './setup.sh --migrate' to rename to 'user-data-jimmy/'
   This will support multi-user setups in the future.
```

### 9. Template Directory Contents

**user-data-template/README.md**:
```markdown
# User Data Directory

This directory will be renamed to `user-data-{username}` during setup.

## Structure

- `app-configs/` - Application-specific configs (Claude, etc.)
- `user-content/` - User-specific content (VS Code settings, etc.)
- `secrets/` - Future: encrypted secrets (not yet implemented)
- `backup.sh` - Backup user data to this directory
- `restore.sh` - Restore user data from this directory

## Usage

During setup:
1. Directory is renamed to `user-data-{username}/`
2. Scripts auto-detect username from directory name
3. All nix configs reference `user-data-${username}/`

## Gitignore

This directory is gitignored by pattern: `user-data-*/`

Only `user-data-template/` is committed for reference.
```

## Implementation Checklist

- [ ] Create `user-data-template/` from current `user-data/`
- [ ] Update `home/jimmy/default.nix` to use `${username}` variable
- [ ] Update `home/jimmy/shell/zsh.nix` to use variable
- [ ] Update `home/jimmy/programs/karabiner.nix` to use variable
- [ ] Update `home/jimmy/programs/vscode.nix` comments
- [ ] Update `backup.sh` to auto-detect username
- [ ] Update `restore.sh` to auto-detect username
- [ ] Add backward compatibility check in lib/
- [ ] Update .gitignore for pattern-based ignore
- [ ] Create migration logic in setup wizard
- [ ] Update all documentation references

## Benefits

1. ✅ **Multi-user ready**: Each user has own user-data directory
2. ✅ **Clear ownership**: Directory name shows which user's data
3. ✅ **Gitignore pattern**: Single pattern handles all users
4. ✅ **Template-based**: New users get clean template structure
5. ✅ **Auto-detection**: Scripts detect username from directory name
6. ✅ **Backward compatible**: Falls back to old `user-data/` if exists

## Edge Cases

**Q: What if user changes username?**
A: Manual rename required: `mv user-data-oldname user-data-newname`

**Q: What if multiple users share same machine?**
A: Each user clones repo separately, gets own `user-data-{username}/`

**Q: What about existing user-data/?**
A: Migration wizard renames it automatically

**Q: Can we support multiple users in same repo?**
A: Not in Phase 6 - deferred to future phase if needed
