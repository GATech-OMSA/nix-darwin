{ config, pkgs, lib, hostname, myLib, ... }:

let
  # Conditional email based on machine type
  gitEmail = myLib.selectByMachine hostname {
    personal = "jimmy-jain@users.noreply.github.com";
    work = "first.last@work-domain.com";
  };
in
{
  # Git configuration - migrated from ConfigHub
  # Using new Home Manager git options format
  programs.git = {
    enable = true;

    # Git LFS
    lfs.enable = true;

    settings = {
      # User info
      user = {
        name = "Jimmy Jain";
        email = gitEmail;
      };
      # Core settings
      core = {
        editor = "code --wait";
        autocrlf = "input";
        # pager is set by programs.delta module
      };

      # Colors
      color = {
        diff = "auto";
        ui = "auto";
        status = "auto";
        branch = "auto";
      };

      # Delta configuration is handled by programs.delta module

      # Merge settings
      merge = {
        tool = "vscode";
        conflictstyle = "diff3";
      };

      # Diff settings
      diff = {
        tool = "vscode";
        colorMoved = "default";
        algorithm = "histogram";
      };

      # Rebase settings
      rebase = {
        autoStash = true;
      };

      # Pull settings
      pull = {
        rebase = true;
        ff = "only";
      };

      # Push settings
      push = {
        default = "current";
        autoSetupRemote = true;
      };

      # Fetch settings
      fetch = {
        prune = true;
      };

      # Credential helper
      credential = {
        helper = "osxkeychain";
      };

      # Init settings
      init = {
        defaultBranch = "main";
      };

      # Git aliases - migrated from ConfigHub .gitconfig
      alias = {
      # Status
      s = "status -s";
      st = "status";

      # Commit
      ci = "commit -m";
      cm = "commit";
      cam = "commit -am";
      amend = "commit --amend";

      # Checkout
      co = "checkout";
      cod = "checkout . --";

      # Reset
      rh = "reset HEAD";
      unstage = "reset HEAD --";
      undo = "reset HEAD~1 --mixed";
      undo-commit = "reset --soft HEAD^";

      # Add
      a = "add";
      aa = "add -A";
      ap = "add -p";

      # Clean
      cdf = "clean -df";

      # Branch
      b = "branch";
      ba = "branch -a";

      # Pull and Push
      pl = "pull";
      pr = "pull --rebase";
      ps = "push";

      # Log
      l = "log";
      last = "log -1 HEAD";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      lo = "log --oneline --graph --decorate";
      ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate";
      ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --numstat";

      # Diff
      d = "diff";
      ds = "diff --staged";

      # Stash
      pop = "stash pop";
      stp = "stash pop";

      # Miscellaneous
      changes = "log -p --follow --";
      blame = "blame -c";
      fp = "fetch --all --prune";
      remotes = "remote -v";
      aliases = "config --get-regexp alias";
      m = "merge --no-ff";
      rb = "rebase";
      rbi = "rebase -i";
      cp = "cherry-pick";
      wip = "commit -am \"WIP\"";

      # Find commands (Search & Discovery)
      fb = "!f() { git branch -a --contains $1; }; f";  # Find branches containing commit
      ft = "!f() { git describe --always --contains $1; }; f";  # Find tags containing commit
      fc = "!f() { git log --pretty=format:'%C(yellow)%h %Cblue%ad %Creset%s%Cgreen [%cn] %Cred%d' --decorate --date=short -S$1; }; f";  # Find commits by code
      fm = "!f() { git log --pretty=format:'%C(yellow)%h %Cblue%ad %Creset%s%Cgreen [%cn] %Cred%d' --decorate --date=short --grep=$1; }; f";  # Find commits by message

      # ==================================================
      # MODERN WORKFLOW ENHANCEMENTS (2025 Best Practices)
      # ==================================================

      # Recent work tracking
      recent = "for-each-ref --sort=-committerdate --format='%(color:yellow)%(refname:short)%(color:reset) - %(color:green)%(committerdate:relative)%(color:reset) - %(color:blue)%(authorname)%(color:reset)' refs/heads/ --count=10";
      today = "!git log --since='midnight' --author=\"$(git config user.name)\" --oneline";
      yesterday = "!git log --since='yesterday.midnight' --until='midnight' --author=\"$(git config user.name)\" --oneline";
      week = "!git log --since='1 week ago' --author=\"$(git config user.name)\" --oneline --no-merges";

      # Team insights
      contributors = "shortlog -sn --no-merges";
      who = "!git shortlog -sn --all --no-merges | head -20";
      activity = "!git log --all --oneline --no-merges --shortstat --since='2 weeks ago'";

      # Quick status checks
      stat = "status -sb";  # Short branch status
      ahead = "log @{u}..HEAD --oneline";  # Commits ahead of upstream
      behind = "log HEAD..@{u} --oneline";  # Commits behind upstream
      diverged = "log --left-right --graph --oneline @{u}...HEAD";  # Show divergence

      # Branch management
      bclean = "!f() { git branch --merged \${1-main} | grep -v \" \${1-main}$\" | xargs git branch -d; }; f";  # Delete merged branches
      bdone = "!git checkout \${1-main} && git pull && git bclean \${1-main}";  # Finish branch workflow
      branches = "branch -vv";  # Verbose branch list
      gone = "!git fetch -p && git for-each-ref --format '%(refname:short) %(upstream:track)' | awk '$2 == \"[gone]\" {print $1}' | xargs -r git branch -D";  # Delete gone branches

      # Quick commits
      save = "!git add -A && git commit -m 'SAVEPOINT'";  # Quick savepoint
      wipe = "!git add -A && git commit -qm 'WIPE SAVEPOINT' && git reset HEAD~1 --hard";  # Wipe to last commit
      uncommit = "reset --soft HEAD~1";  # Undo last commit, keep changes
      recommit = "commit --amend --no-edit";  # Amend without changing message

      # Stash management
      stashes = "stash list --pretty=format:'%C(yellow)%gd%Creset %C(green)(%cr)%Creset - %s'";  # Pretty stash list
      snapshot = "!git stash push -u -m \"snapshot: $(date)\"";  # Quick snapshot

      # Diff helpers
      changed = "diff --name-only";  # List changed files
      unstaged = "diff --name-only";  # Unstaged files
      staged = "diff --cached --name-only";  # Staged files
      untracked = "ls-files --others --exclude-standard";  # Untracked files
      ignored = "ls-files --ignored --exclude-standard --others";  # Ignored files

      # Review helpers (Code Review Workflow)
      review = "log --reverse --no-merges --stat @{u}..HEAD";  # Review your changes
      files = "diff --name-status";  # Files changed in diff
      filehistory = "log --follow -p --";  # Full history of a file

      # Sync helpers
      sync = "!git fetch --all --prune && git pull --rebase";  # Full sync
      update = "!git fetch --all --prune && git merge --ff-only @{u}";  # Fast-forward only
      catchup = "!git fetch && git log ..@{u} --oneline";  # See what's new upstream

      # Aliases for typos (common mistakes)
      stauts = "status";
      stats = "status";
      pul = "pull";
      psuh = "push";
      };
    };
  };
}
