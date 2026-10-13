{ inputs, self, ... }:
let
  # access to nixpkgs-stable
  nixpkgsStable = _: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (prev.pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # add flake.packages as pkgs.custom
  pkgsCustom = _: prev: {
    custom = self.packages.${prev.stdenv.hostPlatform.system};
  };
in
{
  nixpkgs.overlays = [
    nixpkgsStable
    pkgsCustom
  ];
}