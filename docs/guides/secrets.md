# Secrets Management Guide

This repository uses two methods for managing secrets:
1.  **Sops-Nix**: For persistent, encrypted system secrets (requires rebuild).
2.  **Local Env**: For ephemeral, local-only secrets (hot reload, no rebuild).

## 🔥 Hot Reload Workflow (Local Env)

For rapid development, you often need to add or change API keys without waiting for a full system rebuild. We use `~/.config/secrets/local.env` for this.

### How it Works
Your Zsh configuration is set up to automatically source `~/.config/secrets/local.env` if it exists. This file is **not managed by Nix** and is **ignored by Git**.

### Usage

1.  **Create/Edit the file**:
    ```bash
    mkdir -p ~/.config/secrets
    nano ~/.config/secrets/local.env
    ```

2.  **Add your secrets**:
    ```bash
    export OPENAI_API_KEY="sk-..."
    export ANTHROPIC_API_KEY="sk-..."
    export DB_PASSWORD="password123"
    ```

3.  **Reload**:
    *   **Option A**: Open a new terminal tab.
    *   **Option B**: Run `source ~/.zshrc` in your current terminal.

### Security Note
*   Ensure this file is **never committed** to version control.
*   Set restrictive permissions:
    ```bash
    chmod 600 ~/.config/secrets/local.env
    ```

## 🔒 Sops-Nix (Persistent Secrets)

For long-term secrets that should be synchronized across machines (encrypted), use `sops`.

### Usage
1.  **Edit secrets**:
    ```bash
    sops hosts/common/secrets.yaml
    ```
2.  **Rebuild system**:
    ```bash
    darwin-rebuild switch --flake .
    ```

## ⚖️ Decision Guide: Sops vs. Local

| Feature | **Sops-Nix** | **Local Env** |
| :--- | :--- | :--- |
| **Use Case** | System-wide, long-term secrets | Development, ephemeral, personal keys |
| **Persistence** | Committed to Git (Encrypted) | **NEVER** committed (Gitignored) |
| **Sync** | Synced across all your machines | Local to *this* machine only |
| **Update Speed** | Slow (Requires Rebuild) | Instant (Hot Reload) |

### ✅ Keep in Sops-Nix
*   **Infrastructure Credentials**: AWS/GCP credentials for system services.
*   **Backup Keys**: Restic/Borg backup passwords.
*   **System Config**: WiFi passwords, VPN keys.
*   **Shared Dev Secrets**: API keys needed on *every* machine you own.

### ✅ Keep in Local Env
*   **Personal API Keys**: OpenAI/Anthropic keys for testing.
*   **Project Secrets**: Database passwords for a specific local project.
*   **Temporary Tokens**: Short-lived access tokens (e.g., GitHub PATs for a script).
*   **Debug Variables**: `DEBUG=1`, `TRACE=true`.
