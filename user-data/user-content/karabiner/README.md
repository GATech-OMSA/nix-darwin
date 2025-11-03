# Karabiner-Elements Configuration

**Custom keyboard shortcuts and remapping for maximum productivity**

---

## Overview

This directory contains Karabiner-Elements configuration for custom keybindings managed by nix-darwin. All configurations are declaratively managed and synced via activation scripts.

**Key Features:**
- 🔑 **Hyper Key** - Caps Lock → Cmd+Opt+Ctrl+Shift (tap for Escape)
- 🪟 **Window Management** - Snap windows with Hyper + arrows/numbers
- 🚀 **App Launching** - Quick access to apps with Hyper + letter
- 💻 **Developer Shortcuts** - Reload, DevTools, Force Quit, Command Palette

---

## Quick Start

### First Time Setup

1. **Enable keybindings** (if not already enabled):
   ```nix
   # In home/jimmy/programs/karabiner.nix, line 7:
   enableKeybindings = true;  # Set to false to disable
   ```

2. **Rebuild system:**
   ```bash
   nix-rebuild
   ```

3. **Grant permissions:**
   - Karabiner-Elements will launch
   - System Settings → Privacy & Security → Input Monitoring
   - Enable "karabiner_grabber" and "karabiner_observer"

4. **Test Hyper key:**
   - Press Caps Lock alone → Should do nothing (or Escape if tapped quickly)
   - Press Caps Lock + Left Arrow → Window should snap left

### Daily Use

```bash
# Sync config after making changes
sync-user-data

# Restart Karabiner if needed
killall karabiner_console_user_server
```

---

## Hyper Key Foundation

**What is the Hyper Key?**

The Hyper key is Caps Lock remapped to Cmd+Opt+Ctrl+Shift - a super modifier that no existing shortcuts use.

**Benefits:**
- 🔓 Opens entire layer of custom shortcuts
- ✅ Zero conflicts with existing shortcuts
- 🎯 Single key access (no stretching for multi-modifier combos)
- 🔄 Tap for Escape (bonus!)

**How it works:**
- **Hold** Caps Lock → Acts as Hyper key (Cmd+Opt+Ctrl+Shift)
- **Tap** Caps Lock → Sends Escape key
- **Never** sends actual Caps Lock (disabled)

---

## Available Shortcuts

### Window Management (Hyper + Arrow Keys / Numbers)

**Snap to Halves:**
- `Hyper + Left Arrow` → Snap window to left half
- `Hyper + Right Arrow` → Snap window to right half
- `Hyper + Up Arrow` → Snap window to top half
- `Hyper + Down Arrow` → Snap window to bottom half

**Snap to Quarters:**
- `Hyper + 1` → Top-left quarter
- `Hyper + 2` → Top-right quarter
- `Hyper + 3` → Bottom-left quarter
- `Hyper + 4` → Bottom-right quarter

**Window Control:**
- `Hyper + F` → Fullscreen/Maximize
- `Hyper + C` → Center window

**Note:** Window management uses Rectangle app URL scheme. Rectangle must be installed (already in homebrew.nix).

### App Launching (Hyper + Letter)

**Quick Access:**
- `Hyper + T` → Terminal (iTerm2)
- `Hyper + B` → Browser (Safari)
- `Hyper + V` → Visual Studio Code
- `Hyper + M` → Mail
- `Hyper + N` → Notes
- `Hyper + S` → Messages
- `Hyper + O` → Obsidian

**How it works:** Opens app if not running, focuses if already running.

### Developer Shortcuts (Hyper + Letter)

**Development Tools:**
- `Hyper + R` → Reload/Refresh (sends Cmd+R)
- `Hyper + D` → Developer Tools (sends Cmd+Opt+I)
- `Hyper + K` → Force Quit dialog (sends Cmd+Opt+Esc)
- `Hyper + P` → VS Code Command Palette (sends Cmd+Shift+P)

---

## Configuration Structure

```
user-data/user-content/karabiner/
├── karabiner.json                     # Main config (synced from ~/.config/karabiner/)
├── assets/
│   └── complex_modifications/
│       ├── hyper-key.json            # Caps Lock → Hyper key setup
│       ├── window-management.json    # Window snapping shortcuts
│       ├── app-launching.json        # App quick launch shortcuts
│       └── developer-shortcuts.json  # Developer productivity shortcuts
└── README.md                          # This file
```

### How Configuration Syncs

**From user-data → Home (on rebuild):**
- `home/jimmy/programs/karabiner.nix` activation script
- Copies configs from `user-data/user-content/karabiner/`
- To `~/.config/karabiner/`
- Happens automatically on `nix-rebuild`

**From Home → user-data (manual backup):**
- Run `sync-user-data` command
- Copies configs from `~/.config/karabiner/`
- To `user-data/user-content/karabiner/`
- Commit changes to git

---

## Customization

### Adding New Shortcuts

1. **Edit complex modification JSON files:**
   ```bash
   code ~/nix-darwin/user-data/user-content/karabiner/assets/complex_modifications/
   ```

2. **Add new rule:**
   ```json
   {
     "description": "Hyper + X → Your action",
     "manipulators": [
       {
         "type": "basic",
         "from": {
           "key_code": "x",
           "modifiers": {
             "mandatory": ["command", "option", "control", "shift"]
           }
         },
         "to": [
           {
             "shell_command": "your-command-here"
           }
         ]
       }
     ]
   }
   ```

3. **Rebuild to apply:**
   ```bash
   nix-rebuild
   ```

### Changing App Launch Targets

Edit `app-launching.json` and change the app name:

```json
{
  "shell_command": "open -a 'Your App Name'"
}
```

### Disabling Specific Shortcuts

Remove or comment out the rule in the JSON file, then rebuild.

### Disabling All Keybindings

Set `enableKeybindings = false` in `home/jimmy/programs/karabiner.nix` line 7, then rebuild.

---

## Troubleshooting

### Shortcuts Not Working

**1. Check Karabiner is running:**
```bash
ps aux | grep karabiner
```

**2. Check Input Monitoring permissions:**
- System Settings → Privacy & Security → Input Monitoring
- Ensure "karabiner_grabber" and "karabiner_observer" are enabled

**3. Restart Karabiner:**
```bash
killall karabiner_console_user_server
```

**4. Check config is synced:**
```bash
ls -la ~/.config/karabiner/
cat ~/.config/karabiner/karabiner.json | grep caps_lock
```

### Window Management Not Working

**Check Rectangle is running:**
```bash
ps aux | grep -i rectangle
```

**Test Rectangle URL scheme:**
```bash
open -g rectangle://left-half
```

If this doesn't work, restart Rectangle from Applications.

### Hyper Key Not Responding

**1. Check caps lock is mapped:**
- Open Karabiner-Elements app
- Go to "Complex Modifications" tab
- Verify "Caps Lock → Hyper Key" rule is enabled

**2. Test individual modifiers:**
- Try Caps Lock + T (should launch iTerm)
- Try Caps Lock + Left Arrow (should snap window)

**3. Check for conflicts:**
- Disable other keyboard customization tools
- Check System Settings → Keyboard → Keyboard Shortcuts

### Config Changes Not Applying

**Rebuild system:**
```bash
nix-rebuild
exec zsh  # Reload shell
```

**Force sync:**
```bash
cp -r ~/nix-darwin/user-data/user-content/karabiner/* ~/.config/karabiner/
```

---

## Tips & Best Practices

### Learning the Shortcuts

**Week 1 - Master Hyper Key:**
- Focus on using Caps Lock as Hyper
- Practice one shortcut: Hyper + Left (window snap)
- Build muscle memory

**Week 2 - Add Window Management:**
- Practice all arrow key window snaps
- Add quarter snapping (1, 2, 3, 4)
- Remove mouse from window management workflow

**Week 3 - App Launching:**
- Pick 3 most-used apps
- Use Hyper + letter instead of Cmd+Tab
- Gradually add more apps

**Week 4 - Developer Shortcuts:**
- Integrate Hyper + R (reload) into workflow
- Use Hyper + D for DevTools
- Practice Hyper + K for force quit

### Muscle Memory Building

**Do's:**
- ✅ Start with 3-5 shortcuts, add more weekly
- ✅ Practice new shortcuts for 3 days before adding more
- ✅ Use shortcuts exclusively (avoid mouse) for practice
- ✅ Create visual reminder (sticky note on keyboard)

**Don'ts:**
- ❌ Don't add 30 shortcuts at once
- ❌ Don't give up after 1-2 days (takes 2 weeks for habits)
- ❌ Don't mix old and new methods (commit to shortcuts)

### Performance Tips

- Keep complex_modifications JSON files under 100 rules each
- Disable unused rules to reduce Karabiner CPU usage
- Use specific modifiers (don't use "any") for faster processing

### Backup Strategy

**Before making changes:**
```bash
sync-user-data
cd ~/nix-darwin
git add user-data/user-content/karabiner
git commit -m "Backup Karabiner config before changes"
```

**After changes:**
```bash
nix-rebuild  # Test changes
sync-user-data  # Save if working
git add user-data && git commit -m "Update Karabiner shortcuts"
```

---

## Advanced Configuration

### Creating Custom Layers

You can create multiple "layers" by using different modifier combinations:

**Layer 1 - Window Management:** Hyper + arrows/numbers
**Layer 2 - App Launching:** Hyper + letters (T, B, V, M, N, S, O)
**Layer 3 - Developer Tools:** Hyper + letters (R, D, K, P)

### Adding Vim-Style Navigation

Add to a new JSON file for home-row arrow keys:

```json
{
  "description": "Hyper + H/J/K/L → Left/Down/Up/Right",
  "manipulators": [
    {
      "from": { "key_code": "h", "modifiers": { "mandatory": ["command", "option", "control", "shift"] } },
      "to": [{ "key_code": "left_arrow" }]
    }
    // Add j, k, l similarly
  ]
}
```

### Conditional Rules (Per-App Shortcuts)

Use `conditions` to enable shortcuts only in specific apps:

```json
{
  "conditions": [
    {
      "type": "frontmost_application_if",
      "bundle_identifiers": ["^com\\.microsoft\\.VSCode$"]
    }
  ]
}
```

---

## Reference

### Modifier Keys in Karabiner

| Name | Symbol | Karabiner Name |
|------|--------|---------------|
| Command | ⌘ | `command` |
| Option | ⌥ | `option` |
| Control | ⌃ | `control` |
| Shift | ⇧ | `shift` |
| Hyper | ⌘⌥⌃⇧ | All four together |

### Shell Command Actions

Execute macOS commands from keybindings:

```json
{
  "to": [
    { "shell_command": "open -a 'App Name'" },           // Launch app
    { "shell_command": "open -g rectangle://action" },   // Rectangle action
    { "shell_command": "osascript -e 'script'" }        // AppleScript
  ]
}
```

### Key Code Reference

Common key codes:
- Letters: `a`, `b`, `c`, etc.
- Numbers: `1`, `2`, `3`, etc.
- Arrows: `left_arrow`, `right_arrow`, `up_arrow`, `down_arrow`
- Special: `escape`, `return_or_enter`, `delete_or_backspace`, `tab`, `spacebar`

Full list: https://github.com/pqrs-org/Karabiner-Elements/blob/main/src/apps/SettingsWindow/Resources/simple_modifications.json

---

## Resources

**Official Documentation:**
- Karabiner-Elements: https://karabiner-elements.pqrs.org/
- Complex Modifications: https://ke-complex-modifications.pqrs.org/
- Rectangle: https://rectangleapp.com/

**Community Resources:**
- Karabiner Examples: https://pqrs.org/osx/karabiner/complex_modifications/
- Reddit r/Karabiner: https://reddit.com/r/Karabiner

**Nix-Darwin:**
- Home configuration: `home/jimmy/programs/karabiner.nix`
- Homebrew install: `modules/darwin/homebrew.nix`

---

**Version**: 1.0.0
**Last Updated**: 2025-11-03
**Status**: Production Ready ✅

For questions or issues, see [docs/guides/troubleshooting.md](../../../docs/guides/troubleshooting.md)
