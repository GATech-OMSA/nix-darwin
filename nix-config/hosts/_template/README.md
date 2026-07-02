# Host Configuration Template

Template for creating a new machine configuration. Normally
`scripts/setup/configure.sh` does this for you (it copies the template,
creates config files, and scaffolds secrets) — the steps below are the manual
equivalent.

## Quick Start

### 1. Copy the template

```bash
# machineId convention: <model>-<profile suffix>, e.g. macbook-air-m2-personal
cp -r nix-config/hosts/_template nix-config/hosts/NEW-MACHINE-ID
```

The `-personal` / `-work` machineId suffix matters: `.sops.yaml` creation
rules select the age key by that suffix.

### 2. Customize `default.nix`

```nix
networking.computerName = "Alice's MacBook Pro";   # display name
homebrew.enable = true;                             # false on corporate MDM
```

Keep the conditional secrets import as-is — it picks
`secrets-personal.nix` / `secrets-work.nix` by the active profile.

### 3. Register the machine in `flake.nix`

Add an entry to `machineDefaults`:

```nix
{
  machineId = "NEW-MACHINE-ID";
  profileName = "personal";          # or "work" / "minimal"
  system = "aarch64-darwin";
  expectedHostname = "mbp-alice";
  enableHomeManager = true;
  skipGoPackages = false;
}
```

### 4. Activate it locally

Point `config/machine-config.nix` at the new machine:

```nix
machineId = "NEW-MACHINE-ID";
profileName = "personal";
```

Only the active machineId is exported by the flake, so this step is what
makes the new machine buildable on this checkout.

### 5. Set up secrets

```bash
# Generate age key (bootstrap.sh does this on a fresh machine)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
grep "public key:" ~/.config/sops/age/keys.txt

# Add the public key to .sops.yaml (repo root), then create the secrets file
cp nix-config/hosts/NEW-MACHINE-ID/secrets.yaml.template \
   nix-config/hosts/NEW-MACHINE-ID/secrets.yaml
sops nix-config/hosts/NEW-MACHINE-ID/secrets.yaml   # or: secrets-edit

# Verify it's encrypted before committing
head -5 nix-config/hosts/NEW-MACHINE-ID/secrets.yaml   # expect ENC[AES256_GCM,...]
```

Secret → target-path mappings live in `scripts/secrets/deploy-secrets.sh`;
deploy with `secrets-deploy`, apply to the current shell with `respin`.

### 6. Build

```bash
# First time
sudo nix run nix-darwin -- switch --flake .#NEW-MACHINE-ID

# Subsequent rebuilds
nix-rebuild
```

## Files in this template

```
_template/
├── default.nix            # Host config (networking, user, homebrew toggle)
├── secrets-personal.nix   # sops-nix wiring for personal profile
├── secrets-work.nix       # sops-nix wiring for work profile
├── secrets.yaml.template  # Starting point for the encrypted secrets file
└── README.md              # This file
```

## Profile choice

Machine behavior (packages, aliases, session vars) comes from the profile,
not from this host directory:

- `personal` — full setup, Homebrew enabled, personal AWS profile
- `work` — corporate variant (proxy support, work AWS, Homebrew usually off)
- `minimal` — bare-bones troubleshooting profile

Set it in the flake registry entry and `config/machine-config.nix`; switch
later with `scripts/profiles/switch-profile.sh`.

## Corporate environment notes

- Homebrew: `homebrew.enable = false;` when MDM manages apps.
- Blocked Go module downloads (sops-nix builds): enable the Go proxy in
  `config/user-config.nix` (`proxies.go.enabled = true`) — see CLAUDE.md
  "Proxy Configuration".

## See also

- `../README.md` — how machine selection works
- `docs/installation.md` — complete three-script setup
- `docs/secrets.md` — SOPS encryption guide
