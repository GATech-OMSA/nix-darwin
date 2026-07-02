# Host Configurations

Machine-specific configuration: one directory per machine (keyed by
`machineId`, not hostname), holding host settings and that machine's
SOPS-encrypted secrets.

## How a machine is selected

The machine registry lives in `flake.nix` (`machineDefaults`): each entry
defines `machineId`, `profileName`, `system`, `expectedHostname`,
`enableHomeManager`, and `skipGoPackages`. The active machine is chosen by
`config/machine-config.nix` (`machineId = "..."`), whose values override the
registry entry for that machine (e.g. `profileName` written by
`scripts/profiles/switch-profile.sh`).

Only the active machine is exported as a `darwinConfiguration` — building the
other machine locally requires switching `config/machine-config.nix` first.
CI covers both machines via its matrix (`.github/workflows/ci.yml`).

Behavior (packages, aliases, session vars) is driven by the machine's
**profile** — see `nix-config/home/_profiles/` and CLAUDE.md rule 6. Host
directories here only hold what is truly per-machine: identity, secrets, and
hardware/OS specifics.

## Directory structure

```
hosts/
├── README.md                    # This file
├── _template/                   # Copy to create a new machine (see its README)
│   ├── default.nix
│   ├── secrets-personal.nix     # sops-nix wiring (personal profile)
│   ├── secrets-work.nix         # sops-nix wiring (work profile)
│   └── secrets.yaml.template
├── macbook-pro-m1-personal/     # Personal MacBook
│   ├── default.nix              # networking, user, homebrew toggle
│   ├── secrets-personal.nix     # age key path + defaultSopsFile
│   └── secrets.yaml             # SOPS-encrypted (never plaintext in git)
└── macbook-pro-m3-work/         # Work MacBook (same shape)
```

Each host `default.nix` receives `profileName` and imports its
`secrets-<profile>.nix` conditionally:

```nix
imports = lib.optional (profileName == "personal") ./secrets-personal.nix;
```

## Adding a new machine

The setup scripts do most of this (`docs/installation.md`); the manual steps:

1. Copy the template: `cp -r nix-config/hosts/_template nix-config/hosts/<machineId>`
   and customize `default.nix` (computerName, homebrew.enable).
2. Add a registry entry to `machineDefaults` in `flake.nix`.
3. Point `config/machine-config.nix` at the new `machineId`.
4. Set up secrets: age key in `~/.config/sops/age/keys.txt`, public key added
   to `.sops.yaml` (repo root; creation rules match `*-personal` / `*-work`
   machineId suffixes), then `secrets-edit` to populate
   `hosts/<machineId>/secrets.yaml`.
5. First build: `sudo nix run nix-darwin -- switch --flake .#<machineId>`;
   thereafter `nix-rebuild`.

## Secrets

- `secrets.yaml` is SOPS/age-encrypted; git hooks block committing it
  plaintext.
- Deployment to target paths (`~/.zsh_secrets`, `~/.ssh/*`, `~/.tokens/*`, …)
  is handled by `scripts/secrets/deploy-secrets.sh` (mappings = single source
  of truth), not by sops-nix templates. Day-to-day: `secrets-edit`,
  `secrets-deploy`, `respin`. See `docs/secrets.md`.

## See also

- `_template/README.md` — step-by-step new-machine walkthrough
- `docs/installation.md` — full three-script setup flow
- `docs/secrets.md` — SOPS encryption details
- `nix-config/home/_profiles/` — profile system (behavior per machine class)
