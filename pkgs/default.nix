# Custom Packages
#
# Purpose: Define custom packages not available in nixpkgs
# Usage: Import in your configuration to use custom packages
#
# Structure:
#   pkgs/
#   ├── default.nix (this file)
#   ├── my-tool/
#   │   └── default.nix
#   └── custom-script/
#       └── default.nix

{ pkgs ? import <nixpkgs> {} }:

{
  # Example: Custom shell script as a package
  # my-helper = pkgs.writeShellScriptBin "my-helper" ''
  #   echo "Hello from custom package!"
  # '';

  # Example: Build from GitHub
  # my-tool = pkgs.stdenv.mkDerivation {
  #   pname = "my-tool";
  #   version = "1.0.0";
  #
  #   src = pkgs.fetchFromGitHub {
  #     owner = "username";
  #     repo = "my-tool";
  #     rev = "v1.0.0";
  #     sha256 = "0000000000000000000000000000000000000000000000000000";
  #   };
  #
  #   buildPhase = ''
  #     make
  #   '';
  #
  #   installPhase = ''
  #     mkdir -p $out/bin
  #     cp my-tool $out/bin/
  #   '';
  # };

  # Example: Python package not in nixpkgs
  # my-python-lib = pkgs.python311Packages.buildPythonPackage {
  #   pname = "my-python-lib";
  #   version = "1.0.0";
  #   src = ./path/to/source;
  #   propagatedBuildInputs = with pkgs.python311Packages; [
  #     requests
  #     numpy
  #   ];
  # };
}
