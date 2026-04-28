# macOS App Recommendations

Curated reference of macOS applications worth considering for a power-user dev / AI engineering setup.

- **Installed** apps (✓) are already declared in `nix-config/modules/darwin/homebrew.nix` and provisioned automatically by `nix-rebuild`.
- **★ New** marks picks from the 2026 multi-source curation (gemini + codex + web research) that are *not yet* in the system.

Replaces the previous interactive `scripts/app-catalog/` system (decommissioned 2026-04). Source-of-truth for actually-installed apps remains `nix-config/modules/darwin/homebrew.nix`.

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
| `pieces` | Pieces for Developers | AI copilot with long-term memory, multi-LLM support, runs locally | freemium, recommended | |
| `gpt4all` | GPT4All | Privacy-focused local chatbot with multiple models | free, optional | |
| `whisper-flow` | Wispr Flow | Fastest AI dictation tool | freemium, recommended | |
| `superwhisper` ★ | Superwhisper | System-wide voice-to-text dictation, local Whisper | freemium | |
| `boltai` ★ | BoltAI | Native Mac AI chat with prompt libraries, BYO key, model switching | paid | |
| `mindmac` ★ | MindMac | Native LLM client supporting 50+ providers | freemium | |

## AI Coding Assistants (ai_coding)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `cursor` | Cursor | AI-first code editor (Claude/GPT integration) | freemium, essential | ✓ |
| `claude-code@latest` | Claude Code | Anthropic's official CLI for terminal AI coding | free, essential | ✓ |
| `codex` | Codex CLI | OpenAI's terminal coding agent | freemium | ✓ |
| `codex-app` | Codex App | OpenAI Codex GUI (separate from CLI) | freemium | ✓ |
| `conductor` | Conductor | Runs/organizes parallel Claude Code sessions for agentic work | freemium | ✓ |
| `continue` | Continue | Open-source AI coding assistant for VS Code (any LLM) | free, recommended | |
| `antigravity` | Antigravity | Agent-first AI development platform | freemium | |
| `windsurf` ★ | Windsurf | Cascade-agent IDE (ex-Codeium); Cursor competitor for autonomous edits | freemium | |
| `trae` ★ | Trae | Adaptive AI IDE with strong code-gen and agent workflows | free | |

## Local LLM Tools (local_llm)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `ollama-app` | Ollama App | Official GUI wrapper for Ollama with model management | free | ✓ |
| `jan` | Jan | 100% offline ChatGPT alternative with local models | free, recommended | ✓ |
| `lm-studio` | LM Studio | Best GUI for local LLMs with model search & perf testing | free, essential | |
| `anythingllm` ★ | AnythingLLM | All-in-one desktop app for local RAG, agents, model experimentation | freemium | |
| `enchanted` ★ | Enchanted | Elegant native macOS client for Ollama and local backends | free | |
| `draw-things` ★ | Draw Things | Mac-native Stable Diffusion client, practical on Apple Silicon | freemium | |

## AI Browsers (ai_browsers)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `arc` | Arc | Workspace-based browser, spaces, split view, sidebar | free | |
| `brave-browser` | Brave with Leo AI | Privacy browser with built-in AI | free, recommended | |
| `sigmaos` ★ | SigmaOS | Workspace browser with split-views and AI tab management | freemium | |

## Browsers (browsers)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `firefox` | Firefox | Privacy-focused browser from Mozilla | free, recommended | ✓ |
| `google-chrome` | Google Chrome | Fast browser with vast extensions ecosystem | free | ✓ |
| `orion` | Orion | WebKit-based privacy browser, ad blocking, zero telemetry | free | ✓ |
| `zen` ★ | Zen Browser | Firefox-based with Arc-style sidebar/workspaces; leading Arc successor | free | |
| `mullvad-browser` ★ | Mullvad Browser | Tor-Project privacy-hardened browser without the Tor network | free | |

## Task Management (task_management)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `things` | Things | Award-winning task manager with beautiful macOS design | paid, essential | |
| `omnifocus` | OmniFocus | GTD power-user task management | paid, recommended | |
| `todoist` | Todoist | Cross-platform task manager with NL input | freemium | |
| `ticktick` | TickTick | Task manager with Pomodoro timer & calendar | freemium | |
| `linear-linear` ★ | Linear | Native Mac client for Linear (eng project management) | free | |

## Productivity (productivity)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `raycast` | Raycast | Supercharged Spotlight with AI, extensions, clipboard history | freemium, essential | ✓ |
| `alfred` | Alfred | Productivity workflows & clipboard history | freemium, recommended | ✓ |
| `obsidian` | Obsidian | Knowledge base using local markdown files | freemium, essential | ✓ |
| `rectangle` | Rectangle | Window management with keyboard shortcuts | free, essential | |
| `craft` | Craft | Beautiful note-taking & document editor with publishing | freemium | |
| `notion` | Notion | All-in-one workspace for notes, docs, databases | freemium | |
| `cleanshot` | CleanShot X | Professional screenshot and screen recording | paid | |
| `1password` | 1Password | Password manager with secure vault & SSH keys | paid, essential | |
| `bitwarden` | Bitwarden | Open-source password manager | freemium | |
| `tella` | Tella | Screen recording with AI enhancements | freemium | |
| `screen-studio` | Screen Studio | Pro screen recordings with auto-zoom & effects | paid | |
| `superhuman` | Superhuman | Blazingly fast email client with AI features | paid | |
| `bartender` | Bartender | Organize and hide menu bar icons | paid | |
| `hiddenbar` | Hidden Bar | Free menu bar icon hider (Bartender alternative) | free | |
| `bettertouchtool` | BetterTouchTool | Advanced gestures, window snapping, automation | paid | |
| `iclip` | iClip | Advanced clipboard manager with history & snippets | paid | |
| `maccy` ★ | Maccy | Lightweight open-source clipboard manager, keyboard-driven | free | |
| `keyboard-maestro` ★ | Keyboard Maestro | Most powerful Mac automation/macro engine | paid | |
| `hazel` ★ | Hazel | Rule-based file automation (clean, route, tag, archive) | paid | |
| `swish` ★ | Swish | Trackpad-gesture window management (snap, tab, hide) | paid | |
| `homerow` ★ | Homerow | Vimium-for-macOS: keyboard-driven click anywhere | paid | |
| `alt-tab` ★ | AltTab | Fast window switcher for keyboard-heavy users | free | |
| `popclip` ★ | PopClip | iOS-style selection popup for instant text actions (200+ extensions) | paid | |
| `notchnook` ★ | NotchNook | MacBook notch becomes a dock for AirDrop, clipboard, music | paid | |

## Development Tools (development)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `visual-studio-code` | VS Code | Most popular code editor, vast extensions | free, essential | ✓ |
| `cursor` | Cursor | (see ai_coding) | freemium | ✓ |
| `ghostty` | Ghostty | Mitchell Hashimoto's GPU-accelerated, native, zero-config terminal | free | ✓ |
| `iterm2` | iTerm2 | Terminal with advanced features | free | ✓ |
| `warp` | Warp | Modern terminal with AI command search & autocomplete | freemium | ✓ |
| `fork` | Fork | Fast and friendly Git client | freemium | ✓ |
| `orbstack` | OrbStack | Fast, light Docker & Linux alternative (better than Docker Desktop) | freemium, essential | ✓ |
| `microsoft-word` | Microsoft Word | Word processor | paid | ✓ |
| `microsoft-excel` | Microsoft Excel | Spreadsheet | paid | ✓ |
| `microsoft-powerpoint` | Microsoft PowerPoint | Presentations | paid | ✓ |
| `zed` | Zed | Lightning-fast collaborative code editor (Rust-based) | free | |
| `sublime-text` | Sublime Text | Lightning-fast text editor with multi-cursor | freemium | |
| `jetbrains-toolbox` | JetBrains Toolbox | Manage all JetBrains IDEs | freemium | |
| `docker` | Docker Desktop | Containerization platform | free | |
| `postman` | Postman | API development and testing | freemium | |
| `insomnia` | Insomnia | Simple, beautiful API client | freemium | |
| `tableplus` | TablePlus | Modern database management (SQL, NoSQL, Redis) | freemium | |
| `dbeaver-community` | DBeaver | Universal database tool (free, open-source) | free | |
| `gitkraken` | GitKraken | Git GUI client | freemium | |
| `sublime-merge` | Sublime Merge | Git client from makers of Sublime Text | freemium | |
| `framer` | Framer | Interactive design and prototyping | freemium | |
| `bruno` ★ | Bruno | Git-friendly local API client (modern Postman replacement) | freemium | |
| `proxyman` ★ | Proxyman | Native HTTP/HTTPS debugging proxy with SSL inspection | freemium | |
| `kaleidoscope` ★ | Kaleidoscope | Best-in-class visual diff/merge for code, folders, images | paid | |
| `devutils` ★ | DevUtils | Native dev toolbox (JSON, JWT, regex, base64, time, diff) — no telemetry | paid | |
| `tower` ★ | Tower | Premium Git GUI for complex branch/history/merge workflows | paid | |
| `wezterm` ★ | WezTerm | Cross-platform GPU terminal with multiplexing, Lua config, SSH domains | free | |
| `nova` ★ | Nova | Panic's native Mac-first code editor with great remote/SFTP workflows | paid | |
| `sequel-ace` ★ | Sequel Ace | Fast, lightweight native MySQL/MariaDB management | free | |
| `beekeeper-studio` ★ | Beekeeper Studio | Clean SQL client (Postgres, MySQL, SQLite, SQL Server) | freemium | |
| `postico` ★ | Postico 2 | Modern, native PostgreSQL client | freemium | |
| `redis-insight` ★ | Redis Insight | Official Redis GUI for keys, profiling, debugging | free | |
| `mongodb-compass` ★ | MongoDB Compass | Official MongoDB desktop client | free | |
| `yaak` ★ | Yaak | Lightweight REST/GraphQL/gRPC client | freemium | |

## Creative & Design (creative)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `figma` | Figma | Collaborative design and prototyping | freemium, essential | |
| `sketch` | Sketch | Vector graphics editor for UI/UX | paid | |
| `adobe-creative-cloud` | Adobe Creative Cloud | Suite of creative apps | paid | |
| `gimp` | GIMP | Free, open-source image editor | free | |
| `blender` | Blender | 3D creation suite | free | |
| `davinci-resolve` | DaVinci Resolve | Pro video editing & color grading | freemium | |
| `capcut` | CapCut | Free video editor with AI features | free | |
| `gifski` ★ | Gifski | Convert video files into high-quality, efficient GIFs | free | |

## Communication (communication)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `slack` | Slack | Team collaboration and messaging | freemium, essential | ✓ |
| `whatsapp` | WhatsApp | Cross-platform messaging with E2E encryption | free | ✓ |
| `zoom` | Zoom | Video conferencing | freemium, essential | ✓ |
| `discord` | Discord | Voice, video, text chat for communities | free | |
| `microsoft-teams` | Microsoft Teams | Workplace chat and collaboration | freemium | |
| `telegram` | Telegram | Fast, secure messaging with cloud sync | free | |
| `signal` ★ | Signal | Industry-standard private messaging with E2E encryption | free | |

## Security & Privacy (security_privacy)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `protonvpn` | ProtonVPN | Secure VPN with strong privacy (Swiss-based, no logs) | freemium | ✓ |
| `little-snitch` ★ | Little Snitch | Definitive macOS outbound firewall (per-app network monitoring) | paid | |
| `lulu` ★ | LuLu | Open-source outbound firewall, minimal setup | free | |
| `tailscale-app` ★ | Tailscale | WireGuard-based mesh VPN for private dev/homelab/SSH access | freemium | |

## Utilities (utilities)

| Cask | App | Description | Tags | Installed |
| --- | --- | --- | --- | --- |
| `keka` | Keka | File archiver (7z, RAR, ZIP) | free | ✓ |
| `keyclu` | KeyClu | Keyboard shortcut reference (hold ⌘ to see shortcuts) | free | ✓ |
| `shottr` | Shottr | Fast, feature-rich screenshot tool | free, recommended | ✓ |
| `appcleaner` | AppCleaner | Thoroughly uninstall applications | free | ✓ |
| `karabiner-elements` | Karabiner Elements | Powerful keyboard customizer | free, essential | ✓ |
| `pdf-expert` | PDF Expert | Fast PDF editor (annotations, forms, signing) | paid | ✓ |
| `hush` | Hush | Block cookie nags & tracking in Safari | free | ✓ |
| `the-unarchiver` | The Unarchiver | Archive extraction utility | free | |
| `transmission` | Transmission | Lightweight BitTorrent client | free | |
| `vlc` | VLC | Versatile media player | free, essential | |
| `spotify` | Spotify | Music streaming | freemium | |
| `monitorcontrol` | MonitorControl | Control external monitor brightness/volume | free | |
| `istat-menus` | iStat Menus | Advanced system monitor in menu bar | paid | |
| `stats` | Stats | Free system monitor (CPU, memory, network, battery) | free | |
| `cleanmymac` | CleanMyMac X | Mac maintenance and cleanup | paid | |
| `daisydisk` | DaisyDisk | Visual disk space analyzer | paid | |
| `timing` | Timing | Automatic time tracking | paid | |
| `betterdisplay` ★ | BetterDisplay | HiDPI scaling, brightness, virtual displays — essential for external monitors on Apple Silicon | freemium | |
| `localsend` ★ | LocalSend | Open-source AirDrop alternative across macOS, Linux, Windows, iOS, Android | free | |
| `pearcleaner` ★ | Pearcleaner | Free, open-source AppCleaner alternative with deeper leftover detection | free | |
| `aldente` ★ | AlDente | Extends MacBook battery life by limiting max charge percentage | freemium | |
| `linearmouse` ★ | LinearMouse | Free per-device mouse customization (acceleration, scroll, buttons) | free | |
| `meetingbar` ★ | MeetingBar | Next calendar event and video meeting links in the menu bar | free | |
| `muzzle` ★ | Muzzle | Auto-enables Do Not Disturb during screen sharing | free | |

---

## Curation provenance

The ★ picks were generated 2026-04-28 by parallel queries to:
- `gemini -p` (Gemini 2.x CLI)
- `codex exec` (OpenAI Codex CLI)
- general-purpose web research (awesome-mac, MacStories, Reddit r/macapps, ProductHunt, Homebrew cask repo)

3-way consensus picks (highest confidence): `bruno`, `proxyman`, `kaleidoscope`, `betterdisplay`, `little-snitch`.

Verify any cask still exists before adding: `brew info --cask <name>`.
