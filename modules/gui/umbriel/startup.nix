{
  tags = [ "wm" ];

  config =
    {
      config,
      host,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      startup = [
        {
          match.app_id = "helium";
          spawn = "helium --profile-directory=Default";
          workspace = 1;
        }
        # neovim, needs a terminal to show a window
        # ghostty only accepts a --class containing a dot
        rec {
          match.app_id = "dev.${user}.nvim";
          spawn = "ghostty --class=${match.app_id} -e nvim";
          workspace = 2;
        }
        # file manager
        {
          match.app_id = "nemo";
          spawn = "nemo";
          workspace = 4;
        }

        # terminal
        {
          match.app_id = config.custom.programs.terminal.app_id;
          spawn = "ghostty";
          workspace = 3;
        }
      ];
    in
    {
      custom.programs = {
        umbriel.settings = lib.mkMerge (
          (
            startup
            |> map (s: {
              general.autostart = [ s.spawn ];
              window_rule = [
                {
                  match = s.match // {
                    at_startup = true;
                  };
                  default_workspace = toString s.workspace;
                }
              ];
            })
          )
          ++ [
            {
              # focus default workspace for each monitor
              general.autostart =
                config.custom.hardware.monitors
                |> lib.reverseList
                |> map (mon: ''umbriel msg workspace-switch:"${toString mon.defaultWorkspace}"'');
            }
          ]
        );
      };
    };
}