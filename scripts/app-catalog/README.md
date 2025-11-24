# App Catalog System

Interactive installer for discovering and installing recommended macOS applications.

## Purpose

This standalone system helps users browse and install curated apps from a catalog of recommendations. It's separate from the core nix-darwin configuration to make app discovery easy and optional.

## Files

- `catalog.yaml` - Curated list of recommended apps organized by category
- `install-apps.sh` - Interactive installer with beautiful terminal UI (powered by gum)

## Usage

```bash
# Run the interactive installer
./scripts/app-catalog/install-apps.sh
```

The installer provides:
- **Category browsing** - Browse apps by category (AI Tools, Development, Productivity, etc.)
- **Multi-select UI** - Select multiple apps at once
- **Dry run mode** - Preview changes before installing
- **Nix integration** - Automatically adds apps to `modules/darwin/homebrew.nix`
- **Auto rebuild** - Runs `darwin-rebuild switch` to install apps

## How It Works

1. User browses categories and selects apps
2. Selected apps are added to the homebrew.nix cask list
3. darwin-rebuild switch installs the apps via Homebrew Casks
4. Apps are managed declaratively from that point on

## Requirements

- `gum` - Beautiful terminal UI tool
  ```bash
  brew install gum
  # Or add to your Nix packages and rebuild
  ```

## Adding New Apps

Edit `catalog.yaml` and add apps in this format:

```yaml
category_name:
  - name: "App Name"
    cask: "homebrew-cask-name"
    description: "Brief description of what this app does"
    tags: [tag1, tag2]
```

## Categories

Current categories:
- AI & LLM Tools
- AI Coding Assistants
- Local LLM Tools
- AI Browsers
- Task Management
- Productivity
- Development Tools
- Browsers
- Creative & Design
- Communication
- Security & Privacy
- Utilities
