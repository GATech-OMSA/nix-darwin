# Overlays

This directory contains Nix overlays for modifying existing nixpkgs packages.

## Purpose

Overlays allow you to:
- Override package versions
- Enable/disable package features
- Apply custom patches
- Customize build configurations
- Add new attributes to pkgs

## When to Use

Use overlays when you need to modify existing packages without forking nixpkgs:
- "I need Python 3.11.5 specifically, not the latest 3.11.x"
- "I want to enable a feature that's disabled by default"
- "I need to patch a package for macOS compatibility"
- "I want to add my own package set to pkgs"

## Structure

```
overlays/
├── default.nix          # Main entry point (list of overlays)
├── README.md            # This file
├── python.nix           # Python-specific overrides
└── versions.nix         # Version pinning overlays
```

## Usage

### 1. Define Overlay

Create an overlay file:

```nix
# overlays/python.nix
final: prev: {
  # Pin Python to specific version
  python311 = prev.python311.overrideAttrs (old: {
    version = "3.11.5";
  });

  # Customize Python packages
  python311Packages = prev.python311Packages.override {
    overrides = pyfinal: pyprev: {
      numpy = pyprev.numpy.overrideAttrs (old: {
        # Enable optimizations
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
      });
    };
  };
}
```

### 2. Import in default.nix

```nix
# overlays/default.nix
{ inputs }:

[
  (import ./python.nix)
  (import ./versions.nix)
]
```

### 3. Apply in flake.nix

```nix
# flake.nix
{
  outputs = { self, nixpkgs, ... }: {
    darwinConfigurations."mbp-jimmy" = nix-darwin.lib.darwinSystem {
      modules = [
        {
          nixpkgs.overlays = import ./overlays { inherit inputs; };
        }
        # ... other modules
      ];
    };
  };
}
```

## Examples

### Pin Package Version

```nix
final: prev: {
  nodejs = prev.nodejs-18_x;  # Use Node 18 instead of latest
}
```

### Enable Package Feature

```nix
final: prev: {
  neovim = prev.neovim.override {
    configure = {
      customRC = ''
        set number
        set relativenumber
      '';
      packages.myVimPackage = with prev.vimPlugins; {
        start = [ vim-nix ];
      };
    };
  };
}
```

### Apply Patch

```nix
final: prev: {
  mypackage = prev.mypackage.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./fix-macos-build.patch
    ];
  });
}
```

### Add Custom Package Set

```nix
final: prev: {
  myPackages = {
    tool1 = prev.callPackage ./pkgs/tool1 {};
    tool2 = prev.callPackage ./pkgs/tool2 {};
  };
}
```

## Common Patterns

### Override Build Flags

```nix
final: prev: {
  sqlite = prev.sqlite.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      "--enable-fts5"
      "--enable-json1"
    ];
  });
}
```

### Change Dependencies

```nix
final: prev: {
  myapp = prev.myapp.override {
    # Use different version of dependency
    openssl = prev.openssl_3;
  };
}
```

### Compose Multiple Overlays

```nix
# overlays/default.nix
{ inputs }:

[
  # Apply in order (later overlays see changes from earlier ones)
  (import ./base.nix)
  (import ./python.nix)
  (import ./nodejs.nix)
  (import ./custom.nix)
]
```

## Overlay vs Custom Package

**Use overlay when:**
- Modifying existing nixpkgs package
- Changing versions or build flags
- Applying patches

**Use custom package (pkgs/) when:**
- Package doesn't exist in nixpkgs
- Building completely new software
- Packaging proprietary tools

## See Also

- [Nixpkgs Manual - Overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [FAQ - Override Package](../docs/appendix/faq.md)
- [Custom Packages](../pkgs/README.md)
