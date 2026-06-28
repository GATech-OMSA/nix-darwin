# Custom Packages

This directory contains custom Nix package definitions that aren't available in nixpkgs.

## When to Use

- Building packages from source
- Packaging proprietary software
- Custom scripts packaged as Nix derivations
- Packages not yet in nixpkgs

## Structure

```
pkgs/
├── default.nix          # Main entry point
├── README.md            # This file
├── my-custom-tool/      # Example package
│   └── default.nix
└── company-app/         # Another example
    └── default.nix
```

## Usage

### 1. Define Package

Create a directory for your package:

```nix
# pkgs/my-tool/default.nix
{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "my-tool";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "username";
    repo = "my-tool";
    rev = "v1.0.0";
    sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
  };

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp my-tool $out/bin/
  '';
}
```

### 2. Import in default.nix

```nix
# pkgs/default.nix
{ pkgs }:

{
  my-tool = pkgs.callPackage ./my-tool {};
}
```

### 3. Expose via the overlay (how this repo wires it)

Custom packages are injected into `pkgs` through an overlay, so they're
available as `pkgs.<name>` anywhere (modules, profiles) with no per-call-site
`import`. The wiring already exists in [`../overlays/default.nix`](../overlays/default.nix):

```nix
# Last entry in the overlay list:
(final: _prev: import ../pkgs { pkgs = final; })
```

Then reference the package like any other:

```nix
# nix-config/modules/darwin/packages.nix
environment.systemPackages = with pkgs; [
  security-scan   # resolved from nix-config/pkgs via the overlay
];
```

> **Flake gotcha:** flakes only see **git-tracked** files. After adding a new
> `pkgs/<tool>/default.nix` (or any file a derivation `readFile`s), `git add` it
> before `nix build` — an untracked file yields
> `error: path '…/pkgs/<tool>/default.nix' does not exist`.

## Examples

### Shell Script Package

```nix
{ pkgs }:

pkgs.writeShellScriptBin "my-helper" ''
  #!${pkgs.bash}/bin/bash
  echo "Hello from custom package!"
  ${pkgs.cowsay}/bin/cowsay "Nix is awesome!"
''
```

### Python Package

```nix
{ pkgs }:

pkgs.python311Packages.buildPythonPackage {
  pname = "my-python-lib";
  version = "1.0.0";

  src = ./src;

  propagatedBuildInputs = with pkgs.python311Packages; [
    requests
    numpy
  ];

  checkPhase = ''
    pytest
  '';
}
```

## Packaging repo shell scripts (`writeShellApplication`)

The real reason to package a maintenance script: the tool then **carries its own
closure** via `runtimeInputs` instead of depending on whatever is on `PATH` at
the call site (a launchd job, an activation hook, a bare login shell). This is
the structural version of the per-call-site `PATH=…` injection fixes scattered
through the modules.

`security-scan/` is the worked example:

```nix
# pkgs/security-scan/default.nix
{ writeShellApplication, vulnix, jq, gnused, gawk, coreutils }:

writeShellApplication {
  name = "security-scan";
  runtimeInputs = [ vulnix jq gnused gawk coreutils ];   # bundled closure
  text = builtins.readFile ../../../scripts/validation/scan-vulnerabilities.sh;
}
```

The source script stays in `scripts/validation/` (editable, directly runnable,
covered by the test suite); the derivation just wraps it. One source of truth.

Things to know about `writeShellApplication`:

- It runs **shellcheck at build time** and fails the build on any finding. Keep
  the script shellcheck-clean (or set `excludeShellChecks = [ "SCxxxx" ];`).
- It prepends `set -euo pipefail`. The script must be safe under it — capture
  expected non-zero exits (`cmd || rc=$?`) rather than letting them abort.
- `runtimeInputs` is **prepended** to `PATH`, not a sandbox — ambient tools are
  still reachable. List every dependency anyway so the tool is hermetic. Verify
  by running it under `PATH=/usr/bin:/bin` and confirming it still resolves its
  tools.
- Deliberately *unbundled* deps are fine when they live outside Nix: `security-scan`
  calls `brew` via a `command -v brew` guard and does **not** put it in
  `runtimeInputs`.

### Caveat: repo-rooted scripts don't package naively

A packaged script lives in `/nix/store`, so `BASH_SOURCE`-relative or
`REPO_ROOT`-from-location lookups resolve into the store, **not** the working
tree. `security-scan` packages cleanly only because it's closure-only — it reads
`/run/current-system` and an *absolute* whitelist path, with no working-tree
dependency.

Scripts like `scripts/secrets/deploy-secrets.sh` derive `REPO_ROOT` from their
own location and read the live `config/` and `hosts/*/secrets.yaml` trees. A
naive `writeShellApplication` wrap would break them. Packaging those requires
splitting **tool logic** (hermetic) from **repo-path inputs** (passed as
args/env) — deferred until there's a concrete need. Package the genuinely
standalone tools first.

## See Also

- [Nixpkgs Manual - Creating Packages](https://nixos.org/manual/nixpkgs/stable/#chap-stdenv)
- [`writeShellApplication`](https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeShellApplication)
- [Nix Pills - Developing with nix-shell](https://nixos.org/guides/nix-pills/developing-with-nix-shell.html)
