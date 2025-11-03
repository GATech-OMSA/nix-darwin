{ config, pkgs, lib, ... }:

{
  # VS Code configuration - Fully declarative
  # Settings + Extensions managed by Nix
  # Using Home Manager vscode structure

  programs.vscode = {
    enable = true;

    # Use profiles (modern syntax)
    profiles.default = {
      # Extensions - using only well-tested packages from nixpkgs
      # More extensions can be added after verifying they exist
      extensions = with pkgs.vscode-extensions; [
        # Themes & Icons
        pkief.material-icon-theme

        # Git
        eamodio.gitlens

        # Python Development
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy

        # GitHub Copilot
        github.copilot
        github.copilot-chat

        # Formatters & Linting
        esbenp.prettier-vscode
        charliermarsh.ruff

        # Documentation & Markdown
        yzhang.markdown-all-in-one
        bierner.markdown-mermaid

        # Code Quality
        usernamehw.errorlens
        streetsidesoftware.code-spell-checker

        # Jupyter & Data Science
        ms-toolsai.jupyter
        ms-toolsai.vscode-jupyter-cell-tags
        ms-toolsai.vscode-jupyter-slideshow

        # Other utilities
        tamasfe.even-better-toml
      ];

      # Note: Install these manually via VS Code UI (not in nixpkgs):
      # - Vitesse theme (antfu.theme-vitesse)
      # - LeetCode (LeetCode.vscode-leetcode) - for interview prep
      # - Better Comments (aaron-bond.better-comments) - document thinking
      # - Draw.io Integration (hediet.vscode-drawio) - system design diagrams

      # User settings
      userSettings = {
      # ========== Visuals ==========
      "window.autoDetectColorScheme" = true;
      "window.dialogStyle" = "custom";
      "window.nativeTabs" = true;
      "window.title" = "\${rootName}";
      "window.titleBarStyle" = "custom";
      "workbench.colorTheme" = "Vitesse Dark";  # Will need to install theme manually
      "workbench.editor.tabActionLocation" = "left";
      "workbench.fontAliasing" = "antialiased";
      "workbench.activityBar.location" = "top";
      "explorer.autoReveal" = true;
      "workbench.editor.showIcons" = true;
      "workbench.editor.labelFormat" = "short";
      "workbench.list.smoothScrolling" = true;
      "workbench.startupEditor" = "newUntitledFile";
      "workbench.tree.expandMode" = "singleClick";
      "workbench.tree.indent" = 10;
      "workbench.preferredLightColorTheme" = "GitHub Plus";

      # ========== Editor ==========
      "editor.cursorSmoothCaretAnimation" = "on";
      "editor.guides.bracketPairs" = "active";
      "editor.lineNumbers" = "interval";
      "editor.renderWhitespace" = "selection";
      "editor.wordSeparators" = "`~!@#%^&*()=+[{]}\\|;:'\",.<>/?";
      "editor.find.addExtraSpaceOnTop" = false;
      "editor.inlineSuggest.enabled" = true;
      "editor.multiCursorModifier" = "ctrlCmd";
      "editor.suggestSelection" = "first";
      "editor.tabSize" = 4;
      "editor.unicodeHighlight.invisibleCharacters" = true;
      "editor.stickyScroll.enabled" = true;
      "editor.hover.sticky" = true;
      "editor.minimap.autohide" = "mouseover";
      "editor.fontFamily" = "MesloLGM Nerd Font, Fira Code, Menlo, Monaco, 'Courier New', monospace";
      "editor.fontSize" = 14;
      "editor.fontLigatures" = false;
      "editor.formatOnSave" = true;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";

      # Code actions
      "editor.codeActionsOnSave" = {
        "source.fixAll" = "never";
        "source.fixAll.eslint" = "explicit";
        "source.organizeImports" = "never";
      };

      # ========== Terminal ==========
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.cursorStyle" = "line";
      "terminal.integrated.fontFamily" = "MesloLGM Nerd Font";
      "terminal.integrated.fontSize" = 13;
      "terminal.integrated.fontWeight" = "300";
      "terminal.integrated.persistentSessionReviveProcess" = "never";
      "terminal.integrated.tabs.enabled" = true;

      # ========== Files ==========
      "files.autoSave" = "afterDelay";
      "files.dialog.defaultPath" = "/Users/jimmy/Dev";
      "files.eol" = "\\n";
      "files.insertFinalNewline" = true;
      "files.trimTrailingWhitespace" = true;
      "files.watcherExclude" = {
        "**/.git/objects/**" = true;
        "**/node_modules/**" = true;
      };

      # ========== Explorer ==========
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;
      "explorer.excludeGitIgnore" = true;
      "explorer.openEditors.minVisible" = 1;
      "explorer.sortOrder" = "foldersNestsFiles";
      "explorer.openEditors.visible" = 5;
      "explorer.openEditors.sortOrder" = "alphabetical";

      # ========== Git ==========
      "git.autofetch" = true;
      "git.confirmSync" = false;
      "git.enableSmartCommit" = true;
      "git.untrackedChanges" = "separate";

      # ========== SCM ==========
      "scm.diffDecorationsGutterWidth" = 2;

      # ========== Python ==========
      "python.defaultInterpreterPath" = "\${workspaceFolder}/.venv/bin/python";
      "python.analysis.typeCheckingMode" = "basic";
      "python.analysis.autoImportCompletions" = true;
      "[python]" = {
        "editor.defaultFormatter" = "charliermarsh.ruff";
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
          "source.fixAll" = "explicit";
        };
      };

      # ========== JavaScript/TypeScript ==========
      "[javascript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescript]" = {
        "editor.defaultFormatter" = "vscode.typescript-language-features";
      };
      "[javascriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      # ========== JSON/YAML/Markdown ==========
      "[json]" = {
        "editor.defaultFormatter" = "vscode.json-language-features";
      };
      "[jsonc]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[markdown]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      # ========== Copilot ==========
      "github.copilot.enable" = {
        "*" = true;
        "yaml" = true;
        "plaintext" = true;
        "markdown" = true;
        "scminput" = false;
      };

      # ========== Workbench ==========
      "workbench.editor.closeOnFileDelete" = true;
      "workbench.sideBar.location" = "right";
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.restoreWindows" = "preserve";

      # ========== Search ==========
      "search.exclude" = {
        "**/*.snap" = true;
        "**/*.svg" = true;
        "**/.git" = true;
        "**/.github" = false;
        "**/.ipynb" = true;
        "**/.output" = true;
        "**/.pnpm" = true;
        "**/.vscode" = true;
        "**/.yarn" = true;
        "**/__pycache__" = true;
        "**/.ipynb_checkpoints" = true;
        "**/bower_components" = true;
        "**/dist/**" = true;
        "**/logs" = true;
        "**/node_modules" = true;
        "**/out/**" = true;
        "**/package-lock.json" = true;
        "**/pnpm-lock.yaml" = true;
        "**/temp" = true;
        "**/yarn.lock" = true;
        "**/CHANGELOG*" = true;
        "**/LICENSE*" = true;
        "**/*.log" = true;
        "**/.terraform" = true;
        "**/.aws" = true;
        "**/*.tfstate" = true;
        "**/*.tfstate.backup" = true;
        "**/.pytest_cache" = true;
        "**/.mypy_cache" = true;
        "**/venv" = true;
        "**/.venv" = true;
        "**/.env" = true;
        "**/env" = true;
        "**/coverage" = true;
        "**/terraform.tfstate.d" = true;
        "**/.DS_Store" = true;
      };

      # ========== Extensions Config ==========
      "extensions.autoUpdate" = "onlyEnabledExtensions";

      # ========== Emmet ==========
      "emmet.showAbbreviationSuggestions" = true;
      "emmet.showSuggestionsAsSnippets" = true;
      "emmet.triggerExpansionOnTab" = true;
      "emmet.excludeLanguages" = [ "markdown" ];
      "emmet.includeLanguages" = {
        "javascript" = "javascriptreact";
        "vue-html" = "html";
        "plaintext" = "html";
      };

      # ========== ESLint ==========
      "eslint.codeAction.showDocumentation" = {
        "enable" = true;
      };

      # ========== cSpell ==========
      "cSpell.showAutocompleteSuggestions" = true;
      "cSpell.allowCompoundWords" = true;
      "cSpell.language" = "en,en-US";
      "cSpell.minWordLength" = 4;
      "cSpell.customDictionaries" = {
        "custom" = {
          "name" = "cspell-dictionary";
          "path" = "/Users/jimmy/.vscode/spell-dictionary.txt";
          "addWords" = true;
        };
      };
      "cSpell.dictionaries" = [
        "aws" "dict-sql" "sql" "python" "dict-python" "typescript"
        "typescriptreact" "javascript" "javascriptreact" "html" "css"
        "json" "yaml" "yml" "markdown" "go" "git" "dockerfile"
        "dict-data-science"
      ];

      # ========== CodeSnap ==========
      "codesnap.backgroundColor" = "#000000";
      "codesnap.containerPadding" = "0px";
      "codesnap.showWindowControls" = false;
      "codesnap.transparentBackground" = true;

      # ========== CSS ==========
      "css.lint.hexColorLength" = "ignore";

      # ========== Debug ==========
      "debug.onTaskErrors" = "debugAnyway";

      # ========== DiffEditor ==========
      "diffEditor.ignoreTrimWhitespace" = true;
      "diffEditor.hideUnchangedRegions.enabled" = true;

      # ========== ErrorLens ==========
      "errorLens.codeLensTemplate" = "$severity $message $source";

      # ========== Excalidraw ==========
      "excalidraw.theme" = "auto";
      "excalidraw.workspaceLibraryPath" = "/Users/jimmy/Dev/Excalidraw/";

      # ========== Jupyter ==========
      "jupyter.experiments.enabled" = true;

      # ========== Markdown ==========
      "markdown.updateLinksOnFileMove.enabled" = "always";

      # ========== JavaScript/TypeScript ==========
      "javascript.updateImportsOnFileMove.enabled" = "always";

      # ========== Poetry Monorepo ==========
      "poetryMonorepo.appendExtraPaths" = false;

      # ========== VS Icons ==========
      "vsicons.dontShowNewVersionMessage" = true;

      # ========== Performance ==========
      "files.exclude" = {
        "**/.git" = true;
        "**/.DS_Store" = true;
        "**/__pycache__" = true;
        "**/.pytest_cache" = true;
        "**/.mypy_cache" = true;
        "**/.ipynb_checkpoints" = true;
        "**/node_modules" = true;
      };

      # ========== Breadcrumbs ==========
      "breadcrumbs.enabled" = true;
      "breadcrumbs.filePath" = "on";
      "breadcrumbs.symbolPath" = "on";

      # ========== Zen Mode ==========
      "zenMode.centerLayout" = true;
      "zenMode.fullScreen" = false;
      "zenMode.hideLineNumbers" = false;

      # ========== Notebook ==========
      "notebook.cellToolbarLocation" = {
        "default" = "right";
        "jupyter-notebook" = "left";
      };
      "notebook.lineNumbers" = "on";
      "notebook.output.textLineLimit" = 50;

      # ========== Misc ==========
      "security.workspace.trust.untrustedFiles" = "open";
      "update.mode" = "none";  # Nix manages updates
      "telemetry.telemetryLevel" = "off";
      "workbench.enableExperiments" = false;
      "workbench.settings.enableNaturalLanguageSearch" = false;
      };

      # Keybindings (can be customized)
      keybindings = [];
    };
  };
}
