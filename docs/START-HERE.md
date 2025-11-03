# Nix Darwin - Start Here

**Welcome!** This is your entry point to understanding and using your declarative macOS configuration system.

---

## What You Need to Know (5 minutes)

Your entire Mac is configured by code in `~/nix-darwin/`.

**Core Concept:** Edit config → Run `nix-rebuild` → Changes applied

**One command rebuilds everything:** `darwin-rebuild switch --flake .`

---

## Why This Exists

**Without nix-darwin:**

- Manual installs (brew, pip, npm, etc.)
- Scattered config files (~/.zshrc, ~/.gitconfig)
- Difficult to reproduce on new machine
- No rollback if something breaks

**With nix-darwin:**

- Everything in one place (version controlled)
- One command rebuilds entire system
- New machine = clone repo + rebuild
- Instant rollback if issues

---

## Most Common Tasks

### Daily Use

```bash
# Edit configuration
nixconf                          # Opens config in VS Code

# Apply changes
nix-rebuild                      # Rebuild system

# Undo changes
nix-rollback                     # Rollback to previous state

# Restart shell
exec zsh                         # Load new config
```

### Quick Commands

Print this and keep visible: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)

---

## Common Scenarios

### "I want to add a package"

**Example: Add `htop`**

1. Edit packages file:

```bash
nixconf
# Opens ~/nix-darwin in VS Code
```

2. Go to `modules/shared/packages.nix`

3. Add to list:

```nix
environment.systemPackages = with pkgs; [
  # ... existing packages
  htop     # Add this
];
```

4. Apply:

```bash
nix-rebuild
```

5. Use it:

```bash
htop
```

**See complete guide:** [Usage Guide - Adding Packages](guides/usage.md#adding-packages)

---

### "I want to add a shell alias"

**Example: Add `work` alias to jump to work directory**

1. Edit shell config:

```bash
zshconf  # Opens home/jimmy/shell/zsh.nix
```

2. Add alias:

```nix
shellAliases = {
  # ... existing aliases
  work = "cd ~/Work";
};
```

3. Apply:

```bash
nix-rebuild && exec zsh
```

4. Use it:

```bash
work   # Jumps to ~/Work
```

**See complete guide:** [Usage Guide - Adding Aliases](guides/usage.md#adding-aliases)

---

### "I want to add a git alias"

**Example: Add `git undo` to undo last commit**

1. Edit git config:

```bash
gitconf  # Opens home/jimmy/programs/git.nix
```

2. Add alias:

```nix
aliases = {
  # ... existing aliases
  undo = "reset HEAD~1 --mixed";
};
```

3. Apply:

```bash
nix-rebuild && exec zsh
```

4. Use it:

```bash
g undo   # Undoes last commit
```

**See all git aliases:** [Shell Reference - Git](reference/shell.md#git-configuration)

---

### "Something broke!"

**Instant rollback:**

```bash
nix-rollback
```

This reverts to your previous working configuration.

**See complete troubleshooting:** [Troubleshooting Guide](guides/troubleshooting.md)

---

## What's Where - Quick Navigation

### Getting Started

- **Installing on new Mac** → [Installation Guide](guides/installation.md)
- **Daily commands** → [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- **Learning modern CLI tools** → [Learning Guide](guides/learning.md)

### Configuration

- **Adding packages/aliases** → [Usage Guide](guides/usage.md)
- **Managing secrets** → [Secrets Guide](guides/secrets.md)
- **Backup & recovery** → [Backup Guide](guides/backup-and-recovery.md)
- **Multi-machine setup** → [Learning Guide - Multi-Machine](guides/learning.md#multi-machine-setup)

### Reference (Complete Details)

- **System commands** → [System Reference](reference/system.md)
- **Shell & Git** → [Shell Reference](reference/shell.md)
- **Python & Node.js** → [Languages Reference](reference/languages.md)
- **AWS, Docker, K8s, Terraform** → [Infrastructure Reference](reference/infrastructure.md)
- **VS Code, CLI tools** → [Tools Reference](reference/tools.md)

### Understanding the System

- **How it works** → [Architecture Overview](architecture/overview.md)
- **File structure** → [Architecture Reference](architecture/reference.md)

### Help

- **Troubleshooting** → [Troubleshooting Guide](guides/troubleshooting.md)
- **FAQ** → [FAQ & Glossary](appendix/faq.md)
- **Complete index** → [Documentation Index](index.md)

---

## Quick Troubleshooting

### Command not found after rebuild?

```bash
exec zsh
```

### Build failed?

```bash
nix-rollback
```

### Secrets not working?

```bash
secrets-status
```

### Need to recover from disaster?

See: [Backup & Recovery Guide](guides/backup-and-recovery.md)

---

## The Big Picture

### What's Managed

**System Level (Nix-Darwin):**

- System packages (git, python, docker, etc.)
- macOS settings (Dock, Finder, etc.)
- Fonts
- Homebrew apps (GUI applications)

**User Level (Home Manager):**

- Shell config (Zsh, aliases, functions)
- Git configuration
- VS Code settings & extensions
- Application configs

**Secrets (sops-nix):**

- API keys (encrypted)
- SSH keys (encrypted)
- AWS credentials (encrypted)

### What's NOT Managed

**Application data:**

- Browser bookmarks (use browser sync)
- Email (use email provider sync)
- Photos (use iCloud/Photos)
- Documents (use iCloud/Dropbox)

**Why:** Separates system config from user data. Best of both worlds.

---

## Learning Path

### Week 1: Basics

1. Read this guide (you're here!)
2. Print [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
3. Practice: `nixconf` → edit → `nix-rebuild`
4. Add one package
5. Add one alias

### Week 2: Daily Usage

1. Read [Usage Guide](guides/usage.md)
2. Learn modern CLI tools: [Learning Guide](guides/learning.md)
3. Set up backups: [Backup Guide](guides/backup-and-recovery.md)
4. Configure secrets: [Secrets Guide](guides/secrets.md)

### Week 3: Advanced

1. Understand architecture: [Architecture Overview](architecture/overview.md)
2. Learn all shell functions: [System Reference](reference/system.md)
3. Explore reference docs for your tools
4. Set up multi-machine if needed: [Learning Guide](guides/learning.md#multi-machine-setup)

---

## Key Concepts

### Declarative Configuration

**Traditional (Imperative):**

```bash
brew install git
echo "alias ll='ls -la'" >> ~/.zshrc
# Hope you wrote down what you did!
```

**Nix-Darwin (Declarative):**

```nix
# In config file:
environment.systemPackages = [ git ];
shellAliases = { ll = "ls -la"; };
# Config IS the documentation!
```

### Generations

Every rebuild creates a new "generation":

- Generation 1: Initial install
- Generation 2: Added htop
- Generation 3: Added git alias
- etc.

Can rollback to any generation:

```bash
darwin-rebuild --list-generations
darwin-rebuild --rollback
darwin-rebuild --switch-generation 5
```

### Flakes

Your system is a "flake" (modern Nix approach):

- `flake.nix` = entry point
- `flake.lock` = locked versions
- Reproducible across machines

Don't worry about details yet. Just know: it works!

---

## Machine-Specific Behavior

Your system automatically adjusts based on hostname:

**Personal Mac (`mbp-jimmy`):**

- Git email: jimmy-jain@users.noreply.github.com
- AWS profile: personal
- Machine mode: 🏠 PERSONAL
- Homebrew: Enabled

**Work Mac (`mbp-work`):**

- Git email: first.last@work-domain.com
- AWS: SSO with multiple profiles
- Machine mode: 🏢 WORK
- Work-specific shortcuts

See: [Learning Guide - Multi-Machine](guides/learning.md#multi-machine-setup)

---

## Safety First

### Before Every Rebuild

**Pre-rebuild checklist:**

```bash
# 1. Backup user data
backup-user-data

# 2. Commit your changes
cd ~/nix-darwin
g aa && g cm "Description of changes"

# 3. Note current generation (in case rollback needed)
darwin-rebuild --list-generations | tail -1

# 4. Rebuild
nix-rebuild
```

See: [Backup Guide - Pre-Rebuild Safety](guides/backup-and-recovery.md#pre-rebuild-safety)

---

## Next Steps

### First Time Here?

1. Print [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
2. Try adding a package: [Usage Guide](guides/usage.md#adding-packages)
3. Set up backups: [Backup Guide](guides/backup-and-recovery.md)

### Daily User?

- Bookmark [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- Bookmark [Troubleshooting](guides/troubleshooting.md)
- Learn modern CLI: [Learning Guide](guides/learning.md)

### Want Deep Understanding?

- Read [Architecture Overview](architecture/overview.md)
- Explore [Complete Index](index.md)

---

## Get Help

**Something not working?**

1. Check [Troubleshooting Guide](guides/troubleshooting.md)
2. Check [FAQ](appendix/faq.md)
3. Review [CLAUDE.md](../CLAUDE.md) for AI assistant help

**Want to understand better?**

- See [Architecture Overview](architecture/overview.md)
- See [Complete Documentation Index](index.md)

---
