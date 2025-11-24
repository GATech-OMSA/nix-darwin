# Quick Reference: Secrets, Environment, Hot Reloading, and AWS

This guide covers common day-to-day tasks for managing your configuration.

## Secrets Management (`sops-nix`)

All secrets are encrypted using `sops` and `age`. They are decrypted at runtime and typically exposed as environment variables or files.

### 1. Adding/Editing Secrets
**Command:** `just secrets-edit` (or `edit-secrets`)

This opens your encrypted secrets file (e.g., `nix-config/hosts/macbook-pro-m1/secrets.yaml`) in your default editor.

*   **Structure:**
    ```yaml
    # Define secrets here
    openai_api_key: "sk-..."
    
    # Zsh secrets are automatically sourced in your shell
    zsh_secrets: |
      export OPENAI_API_KEY="sk-..."
      export ANTHROPIC_API_KEY="sk-..."
    ```

### 2. Applying Changes
After editing, simply rebuild the system:
`just switch`

### 3. Where Secrets Live
*   **Source:** `nix-config/hosts/<machine-id>/secrets.yaml` (Encrypted, safe to commit)
*   **Runtime:** `/run/secrets/` (Decrypted, root-only access)
*   **Shell Access:** `~/.zsh_secrets` (Sourced by Zsh)

---

## Environment Variables

### 1. Public Variables (Non-Secret)
Add these to `nix-config/home/_profiles/<profile>/default.nix` (e.g., `personal/default.nix`).

```nix
home.sessionVariables = {
  EDITOR = "nvim";
  PROJECT_DIR = "$HOME/Dev";
  MY_PUBLIC_VAR = "some_value";
};
```

### 2. Secret Variables
Add these to the `zsh_secrets` block in your `secrets.yaml` (see above).

### 3. Local / Untracked Variables
For variables that are highly local, not managed by Nix, and you prefer not to commit (even encrypted), you can use:

*   **`~/.zshrc.local`**: Sourced by `~/.zshrc`. Ideal for local aliases, PATH adjustments, or temporary variables.
    ```bash
    # ~/.zshrc.local
    export LOCAL_DEV_DIR="/Users/jimmy/local_projects"
    alias lproj="cd $LOCAL_DEV_DIR"
    ```
*   **`$HOME/.config/secrets/local.env`**: A dedicated file for local, untracked environment variables. You would typically source this from your `~/.zshrc` or `.zshrc.local`.
    ```bash
    # $HOME/.config/secrets/local.env
    export MY_API_KEY_TEMP="sk_test_..."
    export DEBUG_MODE="true"
    ```
    **Note:** Ensure this file (and any containing sensitive data) is explicitly excluded from Git via `.gitignore`. You may need to add `/home/<user>/.config/secrets/local.env` to `.gitignore`.

---

## Hot Reloading & Updates

### 1. Applying Configuration Changes
Run this command after editing any `.nix` file:
`just switch`

*   **Fast:** Updates aliases, shell functions, and environment variables almost instantly.
*   **Safety:** If the build fails, your system is left untouched.

### 2. Updating Software
*   **System & Nix:** `just update` (Updates Nix inputs and Homebrew)
*   **Just Nix:** `just update-nix`

### 3. Testing Without Switching
To verify your config compiles without applying it:
`just build`

---

## AWS Configuration: Work vs. Personal

Your AWS setup automatically adapts based on your machine's **Profile** (`personal` vs. `work`).

### Personal Profile
*   **Config:** Uses standard `~/.aws/credentials` or `sso` helper.
*   **Helpers:** `aws-sso-login` maps to your personal start URL.
*   **Default Region:** Configured in `nix-config/home/_profiles/personal/default.nix`.

### Work Profile
*   **Config:** Enforces SSO and typically manages multiple accounts.
*   **Account Mapping:** Checks `~/.aws/accounts.json` or secrets to alias account IDs to names (e.g., `123456789` -> `production`).
*   **Helpers:**
    *   `aws-login <account-alias> <role>`: seamless SSO login.
    *   `aws-console <account-alias>`: Open AWS Console in browser.

### Switching Profiles
The active profile is defined in `config/machine-config.nix`. To change it:
1.  Edit `config/machine-config.nix`:
    ```nix
    profileName = "work"; # or "personal"
    ```
2.  `just switch`

This will reload your shell environment, swap your Git identity (email), and adjust your AWS tools.
