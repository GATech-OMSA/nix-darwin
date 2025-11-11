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

### 3. Use in Configuration

```nix
# In your module or configuration
{ pkgs, ... }:

let
  customPkgs = import ../pkgs { inherit pkgs; };
in
{
  home.packages = [
    customPkgs.my-tool
  ];
}
```

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

## See Also

- [Nixpkgs Manual - Creating Packages](https://nixos.org/manual/nixpkgs/stable/#chap-stdenv)
- [Nix Pills - Developing with nix-shell](https://nixos.org/guides/nix-pills/developing-with-nix-shell.html)
