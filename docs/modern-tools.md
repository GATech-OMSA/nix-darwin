# Modern CLI Tools Guide

This configuration replaces legacy Unix tools with modern, faster, and smarter alternatives.

## 🚀 Zoxide (Smarter `cd`)
Replaces: `cd` aliases

Zoxide remembers which directories you use most frequently, so you can "jump" to them in just a few keystrokes.

| Command | Description | Example |
| :--- | :--- | :--- |
| `z <name>` | Jump to a directory that matches `<name>` | `z tri` (jumps to `~/Dev/tririga`) |
| `z <name> <name>` | Jump to a directory matching multiple terms | `z dev scst` |
| `zi` | Interactive selection (requires fzf) | `zi` |
| `z -` | Go back to the previous directory | `z -` |

> [!TIP]
> You no longer need aliases like `fti`, `fscst`, or `learning`. Just type `z tri` or `z learn`.

## 📂 Eza (Better `ls`)
Replaces: `ls`

A modern replacement for `ls` that is faster, more colorful, and git-aware.

| Command | Description |
| :--- | :--- |
| `ls` | List files (aliased to `eza`) |
| `ll` | List with details, git status, and icons |
| `la` | List all (including hidden) |
| `lt` | List as a tree |

## 🦇 Bat (Better `cat`)
Replaces: `cat`

A `cat` clone with syntax highlighting and git integration.

| Command | Description |
| :--- | :--- |
| `cat <file>` | Print file content (aliased to `bat`) |
| `bat <file>` | Print file content with syntax highlighting |

## 🤖 Just (Command Runner)
Replaces: `make` (for non-build tasks)

`just` is a handy command runner for saving and running project-specific commands. It looks for a `Justfile` in your project root.

| Command | Description |
| :--- | :--- |
| `just` | List available commands in the current project |
| `just <command>` | Run a specific command |

## ⚡ Fastfetch (System Info)
Replaces: `neofetch`

A much faster system information tool.

| Command | Description |
| :--- | :--- |
| `fastfetch` | Show system information |
