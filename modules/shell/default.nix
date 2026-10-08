{
  config =
    {
      config,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      homeDir = "/persist/home/${user}";
      xdg-user-dirs = {
        # xdg user dirs
        XDG_DESKTOP_DIR = "${homeDir}/Desktop";
        XDG_DOCUMENTS_DIR = "${homeDir}/Documents";
        XDG_DOWNLOAD_DIR = "${homeDir}/Downloads";
        XDG_MUSIC_DIR = "${homeDir}/Music";
        XDG_PICTURES_DIR = "${homeDir}/Pictures";
        XDG_PROJECTS_DIR = "/persist${homeDir}/projects";
        XDG_PUBLICSHARE_DIR = "${homeDir}/Public";
        XDG_TEMPLATES_DIR = "${homeDir}/Templates";
        XDG_VIDEOS_DIR = "${homeDir}/Videos";
      };
      # mkdir then change to directory
      md = pkgs.writeShellApplication {
        name = "md";
        text = /* sh */ ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
      };
    in
    {
      environment = {
        shellAliases = {
          dots = "cd /persist/home/${user}/projects/dotfiles";
        };

        systemPackages =
          (with pkgs; [
            bonk # mkdir and touch in one
            curl
            # dysk # better disk info
            ets # add timestamp to beginning of each line
            fd # better find
            fx # terminal json viewer and processor
            gzip
            htop
            jq
            killall
            procs # better ps
            (lib.hiPrio procps) # for uptime
            sd # better sed
            trash-cli
            xdg-utils
            tree
          ])
          ++ [
            md
          ];

        variables = {
          TERMINAL = "kitty";
          EDITOR = "nvim";
          VISUAL = "nvim";
          NIXPKGS_ALLOW_UNFREE = "1";
          # xdg
          XDG_CACHE_HOME = config.hj.xdg.cache.directory;
          XDG_CONFIG_HOME = config.hj.xdg.config.directory;
          XDG_DATA_HOME = config.hj.xdg.data.directory;
          XDG_STATE_HOME = config.hj.xdg.state.directory;

          # stop libX11 from polluting $HOME with .compose-cache
          XCOMPOSECACHE = "/home/${user}/.cache/xcompose";
        }
        // xdg-user-dirs;
      };

      # follow xdg user dirs spec, see hm for original implementation
      # https://github.com/nix-community/home-manager/blob/master/modules/misc/xdg-user-dirs.nix
      hj.xdg.config.files = {
        "user-dirs.conf".text = "enabled=False";
        "user-dirs.dirs" = {
          generator = lib.generators.toKeyValue { };
          # For some reason, these need to be wrapped with quotes to be valid.
          value = lib.mapAttrs (_: value: ''"${value}"'') xdg-user-dirs;
        };
      };
    };
}