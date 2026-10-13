{
  packages =
    { inputs, pkgs, ... }:
    {
      neovim-plattybus = pkgs.callPackage (
        {
          dots ? null,
          host ? "desktop",
        }:
        (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [
            ./_settings.nix
            ./_keymaps.nix
          ];
          extraSpecialArgs = { inherit dots host; };
        }).neovim
      ) { };
    };

  config =
    {
      host,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      customNeovim = pkgs.custom.neovim-plattybus.override {
        inherit host;
        dots = "/home/${user}/projects/dots";
      };
    in
    {
      environment = {
        systemPackages = [
          customNeovim
        ];
      };

      xdg = {
        mime = {
          defaultApplications = {
            "text/plain" = "nvim.desktop";
            "text/markdown" = "nvim.desktop";
            "text/x-nix" = "nvim.desktop";
            "application/x-shellscript" = "nvim.desktop";
            "application/xml" = "nvim.desktop";
          };
          addedAssociations = {
            "text/csv" = "nvim.desktop";
          };
        };
      };

      custom.programs.print-config = rec {
        neovim = /* sh */ "nvf-print-config | ${lib.getExe pkgs.stylua} --indent-type Spaces --indent-width 2 - | moor --lang lua";
        nvf = neovim;
        nvim = neovim;
      };
    };
}