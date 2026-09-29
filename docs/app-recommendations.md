# macOS App Recommendations

Curated reference of macOS applications worth considering for a power-user dev / AI engineering setup.

- ✓ — declared in `nix-config/modules/darwin/homebrew.nix` and provisioned by `nix-rebuild`.
- (blank) — research candidate worth considering, not currently installed.
- (disabled) — intentionally turned off; see comment in `homebrew.nix`.

Replaces the previous interactive `scripts/app-catalog/` system (decommissioned 2026-04). Source-of-truth for actually-installed apps remains `nix-config/modules/darwin/homebrew.nix` — sync this doc against it when reality drifts (`brew list --cask` to compare).

## Install workflow

One-off:
```bash
brew install --cask <cask-name>
```

Declarative (preferred — survives reinstall):
```bash
# Add <cask-name> to the casks list in nix-config/modules/darwin/homebrew.nix
nix-rebuild
```

---

## AI & LLM Clients (ai_llm)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `chatgpt` | ChatGPT Desktop | Official ChatGPT with Advanced Voice Mode & plugins | freemium, recommended | ✓ |
| `claude` | Claude Desktop | Anthropic's Claude with desktop integration & MCP support | freemium, recommended | ✓ |
| `perplexity` | Perplexity | AI search with citations & research mode | freemium, recommended | |
| `whisper-flow` | Wispr Flow | Fastest AI dictation tool | freemium, recommended | |

## AI Coding Assistants (ai_coding)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `cursor` | Cursor | AI-first code editor (Claude/GPT integration) | freemium, essential | ✓ |
| `claude-code@latest` | Claude Code | Anthropic's official CLI for terminal AI coding | free, essential | ✓ |
| `codex` | Codex CLI | OpenAI's terminal coding agent | freemium | ✓ |
| `codex-app` | Codex App | OpenAI Codex GUI (separate from CLI) | freemium | ✓ |
| `conductor` | Conductor | Runs/organizes parallel Claude Code sessions for agentic work | freemium | ✓ |
| `windsurf` | Windsurf | Cascade-agent IDE (ex-Codeium); Cursor competitor for autonomous edits | freemium | |

## Local LLM Tools (local_llm)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `ollama-app` | Ollama App | Official GUI wrapper for Ollama with model management | free | ✓ |
| `jan` | Jan | 100% offline ChatGPT alternative with local models | free, recommended | ✓ |
| `lm-studio` | LM Studio | Best GUI for local LLMs with model search & perf testing | free, essential | |
| `draw-things` | Draw Things | Mac-native Stable Diffusion client, practical on Apple Silicon | freemium | |

## AI Browsers (ai_browsers)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `arc` | Arc | Workspace-based browser, spaces, split view, sidebar | free | |
| `brave-browser` | Brave with Leo AI | Privacy browser with built-in AI | free, recommended | |

## Browsers (browsers)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `firefox` | Firefox | Privacy-focused browser from Mozilla | free, recommended | ✓ |
| `google-chrome` | Google Chrome | Fast browser with vast extensions ecosystem | free | ✓ |
| `orion` | Orion | WebKit-based privacy browser, ad blocking, zero telemetry | free | ✓ |
| `zen` | Zen Browser | Firefox-based with Arc-style sidebar/workspaces; leading Arc successor | free | |

## Task Management (task_management)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `things` | Things | Award-winning task manager with beautiful macOS design | paid, essential | |
| `todoist` | Todoist | Cross-platform task manager with NL input | freemium | |
| `linear-linear` | Linear | Native Mac client for Linear (eng project management) | free | |

## Productivity (productivity)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `raycast` | Raycast | Supercharged Spotlight with AI, extensions, clipboard history | freemium, essential | ✓ |
| `alfred` | Alfred | Productivity workflows & clipboard history | freemium, recommended | ✓ |
| `obsidian` | Obsidian | Knowledge base using local markdown files | freemium, essential | ✓ |
| `rectangle` | Rectangle | Window management with keyboard shortcuts | free, essential | |
| `cleanshot` | CleanShot X | Professional screenshot and screen recording | paid | |
| `1password` | 1Password | Password manager with secure vault & SSH keys | paid, essential | |
| `screen-studio` | Screen Studio | Pro screen recordings with auto-zoom & effects | paid | |
| `bartender` | Bartender | Organize and hide menu bar icons | paid | |
| `maccy` | Maccy | Lightweight open-source clipboard manager, keyboard-driven | free | |
| `hazel` | Hazel | Rule-based file automation (clean, route, tag, archive) | paid | |
| `alt-tab` | AltTab | Fast window switcher for keyboard-heavy users | free | |
| `popclip` | PopClip | iOS-style selection popup for instant text actions (200+ extensions) | paid | |

## Development Tools (development)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `visual-studio-code` | VS Code | Most popular code editor, vast extensions | free, essential | ✓ |
| `ghostty` | Ghostty | Mitchell Hashimoto's GPU-accelerated, native, zero-config terminal | free | ✓ |
| `iterm2` | iTerm2 | Terminal with advanced features | free | ✓ |
| `warp` | Warp | Modern terminal with AI command search & autocomplete | freemium | ✓ |
| `fork` | Fork | Fast and friendly Git client | freemium | ✓ |
| `orbstack` | OrbStack | Fast, light Docker & Linux alternative (better than Docker Desktop) | freemium, essential | ✓ |
| `microsoft-word` | Microsoft Word | Word processor | paid | ✓ |
| `microsoft-excel` | Microsoft Excel | Spreadsheet | paid | ✓ |
| `microsoft-powerpoint` | Microsoft PowerPoint | Presentations | paid | ✓ |
| `bruno` | Bruno | Git-friendly local API client (modern Postman replacement) | freemium | ✓ |
| `proxyman` | Proxyman | Native HTTP/HTTPS debugging proxy with SSL inspection | freemium | ✓ |
| `kaleidoscope` | Kaleidoscope | Best-in-class visual diff/merge for code, folders, images | paid | ✓ |
| `zed` | Zed | Lightning-fast collaborative code editor (Rust-based) | free | |
| `jetbrains-toolbox` | JetBrains Toolbox | Manage all JetBrains IDEs | freemium | |
| `tableplus` | TablePlus | Modern database management (SQL, NoSQL, Redis) | freemium | |
| `dbeaver-community` | DBeaver | Universal database tool (free, open-source) | free | |
| `redis-insight` | Redis Insight | Official Redis GUI for keys, profiling, debugging | free | |
| `devutils` | DevUtils | Native dev toolbox (JSON, JWT, regex, base64, time, diff) — no telemetry | paid | |
| `wezterm` | WezTerm | Cross-platform GPU terminal with multiplexing, Lua config, SSH domains | free | |

## Creative & Design (creative)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `figma` | Figma | Collaborative design and prototyping | freemium, essential | |
| `gimp` | GIMP | Free, open-source image editor | free | |
| `davinci-resolve` | DaVinci Resolve | Pro video editing & color grading | freemium | |
| `capcut` | CapCut | Free video editor with AI features | free | |
| `gifski` | Gifski | Convert video files into high-quality, efficient GIFs | free | |

## Communication (communication)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `slack` | Slack | Team collaboration and messaging | freemium, essential | ✓ |
| `whatsapp` | WhatsApp | Cross-platform messaging with E2E encryption | free | ✓ |
| `zoom` | Zoom | Video conferencing | freemium, essential | ✓ |
| `microsoft-teams` | Microsoft Teams | Workplace chat and collaboration | freemium | |
| `telegram` | Telegram | Fast, secure messaging with cloud sync | free | |
| `signal` | Signal | Industry-standard private messaging with E2E encryption | free | |

## Finance (finance)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `tradingview` | TradingView | Charting + market data for stocks/crypto/forex with built-in scripting | freemium | ✓ |

## Security & Privacy (security_privacy)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `protonvpn` | ProtonVPN | Secure VPN with strong privacy (Swiss-based, no logs) | freemium | ✓ |
| `little-snitch` | Little Snitch | Definitive macOS outbound firewall (per-app network monitoring) | paid | ✓ |
| `tailscale-app` | Tailscale | WireGuard-based mesh VPN for private dev/homelab/SSH access | freemium | |

## Utilities (utilities)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `keka` | Keka | File archiver (7z, RAR, ZIP) | free | ✓ |
| `keyclu` | KeyClu | Keyboard shortcut reference (hold ⌘ to see shortcuts) | free | ✓ |
| `shottr` | Shottr | Fast, feature-rich screenshot tool | free, recommended | ✓ |
| `appcleaner` | AppCleaner | Thoroughly uninstall applications | free | ✓ |
| `karabiner-elements` | Karabiner Elements | Powerful keyboard customizer | free, essential | (disabled) |
| `pdf-expert` | PDF Expert | Fast PDF editor (annotations, forms, signing) | paid | ✓ |
| `hush` | Hush | Block cookie nags & tracking in Safari | free | ✓ |
| `betterdisplay` | BetterDisplay | HiDPI scaling, brightness, virtual displays — essential for external monitors on Apple Silicon | freemium | ✓ |
| `vlc` | VLC | Versatile media player | free, essential | |
| `stats` | Stats | Free system monitor (CPU, memory, network, battery) | free | |
| `daisydisk` | DaisyDisk | Visual disk space analyzer | paid | |
| `aldente` | AlDente | Extends MacBook battery life by limiting max charge percentage | freemium | |
| `localsend` | LocalSend | Open-source AirDrop alternative across macOS, Linux, Windows, iOS, Android | free | |
| `meetingbar` | MeetingBar | Next calendar event and video meeting links in the menu bar | free | |

---

<!-- BEGIN GENERATED:apps -->
## Currently Installed (Generated)

_This section is generated from `nix-config/modules/darwin/homebrew.nix` by_
_`scripts/docs/sync-app-recommendations.sh`. Do not edit by hand —_
_re-run via `just docs-apps` after editing `homebrew.nix`._

### Casks (28)

| Cask | Note |
| --- | --- |
| `alfred` |  |
| `betterdisplay` | HiDPI/brightness for external monitors on Apple Silicon |
| `chatgpt` |  |
| `claude` |  |
| `claude-code@latest` |  |
| `codex` |  |
| `codex-app` | OpenAI Codex GUI (separate from codex CLI) |
| `cursor` |  |
| `fork` |  |
| `ghostty` |  |
| `google-chrome` |  |
| `hush` | migrated from MAS — `mas uninstall 1544743900` first |
| `keka` |  |
| `keyclu` |  |
| `microsoft-excel` | migrated from MAS — `mas uninstall 462058435` first |
| `microsoft-powerpoint` | migrated from MAS — `mas uninstall 462062816` first |
| `microsoft-word` |  |
| `obsidian` |  |
| `orbstack` |  |
| `orion` |  |
| `pdf-expert` |  |
| `pearcleaner` | open-source uninstaller + brew-leftover cleanup (replaced appcleaner 2026-08-22) |
| `protonvpn` |  |
| `proxyman` | Native HTTP/HTTPS debugging proxy with SSL inspection |
| `raycast` |  |
| `shottr` |  |
| `visual-studio-code` |  |
| `zed` | Rust-native editor, built-in multi-provider AI (trial vs VS Code) |

### Mac App Store (6)

| App | App ID | Note |
| --- | --- | --- |
| Capital One Shopping | `1477110326` |  |
| DarkModeSafari | `6755151037` |  |
| Pages | `409201541` |  |
| Rakuten Cash Back | `1451893560` |  |
| uBlock Origin Lite | `6745342698` |  |
| Uplock | `6469049274` | was published as "Access" before rename |

<!-- END GENERATED:apps -->

---

## Curation provenance

The candidate list was assembled 2026-04-28 from parallel queries to `gemini -p`, `codex exec`, and web research (awesome-mac, MacStories, Reddit r/macapps, ProductHunt, Homebrew cask repo). 3-way consensus picks (`bruno`, `proxyman`, `kaleidoscope`, `betterdisplay`, `little-snitch`) were adopted into `homebrew.nix` the same day.

Before adding a new cask: `brew info --cask <name>` to confirm it still exists.
