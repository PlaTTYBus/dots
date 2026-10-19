{
  tags = [ "gui" ];

  config =
    { pkgs, user, ... }:
    {
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
      users.users.${user}.packages = with pkgs; [
        vesktop
        obsidian
        stable.zotero
        spotify
        super-productivity
        stable.nomachine-client
      ];
    };
}
