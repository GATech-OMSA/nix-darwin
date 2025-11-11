# Quick Start Checklist - Day 1

**Your first day with nix-darwin - complete this in 30-45 minutes**

[← Back to Index](index.md)

---

## Pre-Installation

- [ ] **Nix installed** - Run `nix --version`
  ```bash
  # If not installed:
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```

- [ ] **Homebrew installed** (optional) - Run `brew --version`
  ```bash
  # If not installed:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

---

## Clone & Setup (5 minutes)

- [ ] **Set hostname**
  ```bash
  sudo scutil --set HostName mbp-jimmy  # or mbp-work
  hostname  # Verify
  ```

- [ ] **Clone repository**
  ```bash
  git clone https://github.com/YOUR-USERNAME/nix-darwin.git ~/nix-darwin
  cd ~/nix-darwin
  ```

- [ ] **Initial build** (takes 15-30 min on first run)
  ```bash
  sudo nix run nix-darwin -- switch --flake .#mbp-jimmy
  # Or for work Mac:
  sudo nix run nix-darwin -- switch --flake .#mbp-work
  ```

---

## Post-Build Setup (10 minutes)

- [ ] **Install Oh-My-Zsh** (cannot be installed via Nix)
  ```bash
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  # Say YES to make zsh default, NO to changing .zshrc
  ```

- [ ] **Install Zsh plugins**
  ```bash
  cd ~/nix-darwin
  ./scripts/install-zsh-plugins.sh
  ```

- [ ] **Restart terminal**
  ```bash
  exec zsh
  ```

---

## Verify Installation (5 minutes)

- [ ] **Check environment**
  ```bash
  nix --version              # Nix package manager
  darwin-rebuild --version   # nix-darwin
  echo $MACHINE_MODE        # Should show "home" or "work"
  hostname                  # Should match what you set
  ```

- [ ] **Test commands**
  ```bash
  g s                       # Git status (should work)
  ll                        # Better ls with icons
  bat README.md             # Syntax highlighted view
  python --version          # Should show Python 3.13
  ```

- [ ] **Check prompt** - Should show:
  ```
  home | Python: 3.13.8
  ~/nix-darwin on master
  ➜
  ```

---

## First Customizations (10 minutes)

### Add a Package

- [ ] **Add your first package**
  ```bash
  nixconf  # Opens config in VS Code
  # Navigate to: modules/shared/packages.nix
  # Add package to list, e.g., htop
  nix-rebuild
  htop  # Test it works
  ```

### Add a Shell Alias

- [ ] **Add your first alias**
  ```bash
  zshconf  # Opens shell config
  # Add to shellAliases section:
  # myproject = "cd ~/Dev/my-main-project";
  nix-rebuild && exec zsh
  myproject  # Test it works
  ```

### Set Up Dev Directory

- [ ] **Create development structure**
  ```bash
  mkdir -p ~/Dev/{algorithms,learning,ai-ml,courses,experiments}
  cd ~/Dev
  ll  # Verify structure
  ```

---

## Essential Configuration (10 minutes)

### Git Setup

- [ ] **Generate SSH key**
  ```bash
  ssh-keygen -t ed25519 -C "your@email.com"
  ssh-add ~/.ssh/id_ed25519
  cat ~/.ssh/id_ed25519.pub | pbcopy
  # Add to GitHub: Settings → SSH Keys → New SSH Key
  ssh -T git@github.com  # Test
  ```

- [ ] **Verify git config**
  ```bash
  g config --list
  # Should show your name and email
  ```

### Secrets Setup

- [ ] **Create secrets file**
  ```bash
  touch ~/.zsh_secrets
  chmod 600 ~/.zsh_secrets
  code ~/.zsh_secrets
  # Add API keys:
  # export OPENAI_API_KEY="sk-..."
  # export ANTHROPIC_API_KEY="sk-ant-..."
  exec zsh  # Reload
  ```

- [ ] **Verify git hooks** (automatically installed)
  ```bash
  secrets-status
  # Should show: ✅ Git hooks installed
  ```

---

## First Commit (5 minutes)

- [ ] **Commit your customizations**
  ```bash
  cd ~/nix-darwin
  g s                           # Check status
  g aa                          # Add all
  g cm "Initial setup for $(hostname)"
  g ps                          # Push to GitHub
  ```

---

## Quick Test Drive (5 minutes)

Try these essential commands:

- [ ] **System management**
  ```bash
  nix-rebuild      # Rebuild system
  nix-rollback     # Undo last rebuild
  health-check     # Check system health
  ```

- [ ] **Configuration shortcuts**
  ```bash
  nixconf          # Open nix-darwin folder
  gitconf          # Edit git config
  zshconf          # Edit shell config
  ```

- [ ] **Modern CLI tools**
  ```bash
  ll               # List files with icons
  bat README.md    # View with syntax highlighting
  rg "pattern"     # Search in files
  z nix            # Jump to directory
  ```

- [ ] **Git with g prefix**
  ```bash
  g s              # Status
  g l              # Log
  g recent         # Recent branches
  ```

---

## Next Steps

You're done with Day 1! 🎉

**Week 1 - Learn the basics:**
- Read [START-HERE.md](START-HERE.md) for detailed overview
- Print [QUICK-REFERENCE.md](QUICK-REFERENCE.md) and keep visible
- Practice: `nixconf` → edit → `nix-rebuild`

**Week 2 - Daily workflows:**
- Read [Usage Guide](guides/usage.md)
- Learn modern CLI: [Learning Guide](guides/learning.md)
- Set up backups: [Backup Guide](guides/backup-and-recovery.md)

**Week 3 - Advanced:**
- Understand architecture: [Architecture Overview](architecture/overview.md)
- Explore all references for your tools
- Set up multi-machine if needed: [Learning Guide](guides/learning.md#multi-machine-setup)

---

## Troubleshooting

**Command not found?**
```bash
exec zsh
```

**Build failed?**
```bash
nix-rollback
```

**Need help?**
- Check [Troubleshooting Guide](guides/troubleshooting.md)
- Check [FAQ](appendix/faq.md)
- Review [Installation Guide](guides/installation.md) for detailed steps

---

## Checklist Summary

Quick count: Did you complete all checkboxes?

**Pre-Installation:** 2 items
**Clone & Setup:** 3 items
**Post-Build Setup:** 3 items
**Verify Installation:** 3 items
**First Customizations:** 3 items
**Essential Configuration:** 4 items
**First Commit:** 1 item
**Quick Test Drive:** 4 items

**Total:** 23 checkboxes

---

**Time:** 30-45 minutes (excluding initial build wait time)
**Status:** Ready to use daily! ✅
