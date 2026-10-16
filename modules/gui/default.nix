{
  tags = [ "gui" ];

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.custom = {
        nixJson = lib.mkOption {
          type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
          default = { };
          description = "Data to be written to nix.json for use in other programs at runtime.";
        };
      };

      config = {
        environment = {
          sessionVariables = {
            NIXOS_OZONE_WL = "1";
            # fall back to xwayland for qt apps without the wayland plugin
            QT_QPA_PLATFORM = "wayland;xcb";
          };

          systemPackages = [
            # run gparted with all the permissions crap fixed, I don't want it permanently installed
            (pkgs.writeShellApplication {
              name = "gparted";
              # gparted runs as root, so allow only root to connect to xwayland while it runs,
              # xhost +local: would open xwayland to every local process
              text = /* sh */ ''
                nix-shell -p xhost gparted --command "xhost si:localuser:root && sudo gparted; xhost -si:localuser:root"
              '';
            })
          ];
        };

        hj.xdg.state.files = {
          # misc information for nix
          "nix.json" = {
            generator = lib.strings.toJSON;
            value = {
              fallbackWallpaper = "${../wallpaper-default.jpg}";
              inherit (config.custom.hardware) monitors;
            }
            // config.custom.nixJson;
          };
        };
      };
    };
}
