# nix-darwin Documentation

**Complete user guides for nix-darwin v2.0.0 profile-based architecture**

---

## 📖 Essential Guides

**New to nix-darwin? Start here:**

1. **[Installation Guide](INSTALLATION.md)** - Complete setup from scratch
   - Three-script workflow (bootstrap → configure → activate)
   - Profile selection (personal/work/minimal)
   - First-time configuration

2. **[Secrets Management](SECRETS.md)** - Secure your credentials
   - SOPS age encryption setup
   - Profile-specific secrets
   - API keys, SSH keys, AWS credentials

3. **[Troubleshooting](TROUBLESHOOTING.md)** - Fix common issues
   - Profile system debugging
   - Build errors and recovery
   - Configuration problems

4. **[Backup & Recovery](backup-and-recovery.md)** - Protect your setup
   - Age key backups (critical!)
   - Disaster recovery procedures
   - Gitignored config backups

---

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone <repo> ~/nix-darwin
cd ~/nix-darwin

# 2. Install dependencies (Nix, nix-darwin, SOPS, age)
./scripts/bootstrap.sh

# 3. Configure (generates age keys, scans secrets, creates configs)
./scripts/configure.sh

# 4. Activate (encrypt secrets, build system, deploy)
./scripts/activate.sh

# 5. Restart shell
exec zsh

# 6. Verify
echo $ACTIVE_PROFILE
secrets-status
```

---

## 🏗️ Architecture Overview

**v2.0.0 Profile-Based System:**

- **Profiles**: personal, work, minimal
- **Configuration**: Gitignored machine-specific configs
- **Secrets**: SOPS age encryption with profile templates
- **Workflow**: Three-script setup (bootstrap → configure → activate)

**Key Concepts:**

- `config/user-config.nix` - Your username, email, fullName (gitignored)
- `config/machine-config.nix` - Machine ID, profile selection (gitignored)
- `hosts/$(hostname)/secrets.yaml` - Encrypted secrets (binary format)
- `~/.config/sops/age/keys.txt` - Age private key (backup critical!)

---

## 📂 Documentation Structure

```
docs/
├── README.md                 # This file
├── INSTALLATION.md          # Setup guide
├── TROUBLESHOOTING.md       # Debugging guide
├── BACKUP-AND-RECOVERY.md   # Disaster recovery
└── SECRETS.md               # SOPS encryption
```

---

## 🔗 Additional Resources

**Main Configuration File**:
- `CLAUDE.md` - AI assistant instructions and critical rules

**AWS Configuration** (work profile only):
- AWS Multi-Role Guide - Multi-account AWS SSO configuration
- AWS Quick Reference - Daily AWS commands and workflows

---

## ⚡ Essential Commands

| Task | Command | Notes |
|------|---------|-------|
| Rebuild system | `nix-rebuild` | After ANY config change |
| Restart shell | `exec zsh` | After rebuild |
| Rollback | `nix-rollback` | If build breaks |
| Health check | `health-check` | System diagnostics |
| Edit secrets | `edit-secrets` | Encrypt/decrypt secrets |
| Check secrets | `secrets-status` | Verify encryption |

---

## 🆘 Getting Help

**Common Issues:**

1. **Build fails** → Run `nix-rollback` then `exec zsh`
2. **Command not found** → Run `exec zsh` to reload shell
3. **Wrong profile active** → Edit `config/machine-config.nix` → Change `profileName`
4. **Secrets not decrypting** → Check `~/.config/sops/age/keys.txt` exists
5. **Config changes not applied** → Run `nix-rebuild && exec zsh`

**Detailed troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📋 Support

**Issues & Questions:**
- GitHub Issues: [Report bugs or ask questions]
- Documentation: All guides in `docs/`

**Contributing:**
- Follow DEVELOPMENT-WORKFLOW.md (see repository)
- Use DOCUMENTATION-CHANGELOG-GUIDE.md (see repository)

---

**Version**: v2.0.0
**Last Updated**: 2025-11-10
**Architecture**: Profile-based configuration with SOPS age encryption
