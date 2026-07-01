# _template/profile-base.nix
#
# Shared scaffolding for the full profiles (personal, work): standard imports
# + starship-from-toml wiring. The minimal profile deliberately bypasses this
# (no _template/programs, no starship) — see minimal/default.nix.
#
# `profileDir` is the importing profile's directory (a path, e.g. ../personal),
# passed by the profile's default.nix so this module can reach that profile's
# packages.nix / aliases.nix / starship.toml. `extras` (optional) is a path to a
# profile-specific starship-extras.toml; passing it (a pure path literal) instead
# of probing with builtins.pathExists keeps the flake pure (no --impure).
{ profileDir, extras ? null, ... }:

{
  imports = [
    ./programs                 # _template/programs
    ./shell/zsh.nix            # _template/shell/zsh.nix
    ../../_template/development
    (profileDir + "/packages.nix")
    (profileDir + "/aliases.nix")
  ];

  programs.starship = {
    enable = true;
    settings =
      let
        base = builtins.fromTOML (builtins.readFile ./starship/base.toml);
      in
        # Shallow // is sufficient: extras only adds new top-level module keys
        # (kubernetes/nodejs/…) and overrides the `format` string. Shared
        # modules + palettes stay from base.
        if extras != null
        then base // (builtins.fromTOML (builtins.readFile extras))
        else base;
  };
}