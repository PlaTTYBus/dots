{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      focus-default-workspaces = pkgs.writeShellApplication {
        name = "umbriel-focus-default-workspaces";
        runtimeInputs = [ pkgs.jq ];
        text =
          config.custom.hardware.monitors
          |> lib.reverseList
          |> map (
            mon:
            let
              ws = toString mon.defaultWorkspace;
            in
            /* sh */ ''
              if ! umbriel workspaces --json | jq -e --arg o "${mon.name}" --arg w "${ws}" 'any(.[]; .output == $o and .name == $w and .active)' >/dev/null; then
                umbriel msg 'workspace-switch:"${ws}"/${mon.name}'
              fi
            ''
          )
          |> lib.concatStrings;
      };

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
          workspace = 3;
        }
        # file manager
        {
          match.app_id = "nemo";
          spawn = "nemo";
          workspace = 4;
        }

        # terminal, opens a window in the ghostty background service (started via dbus if not running yet)
        {
          match.app_id = config.custom.programs.terminal.app_id;
          spawn = "ghostty +new-window";
          workspace = 2;
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
                (
                  {
                    match = s.match // {
                      at_startup = true;
                    };
                    default_workspace = toString s.workspace;
                  }
                  // lib.optionalAttrs (s.workspace != (lib.head config.custom.hardware.monitors).defaultWorkspace) {
                    default_focused = false;
                    focus_on_activate = false;
                  }
                )
              ];
            })
          )
          ++ [
            {
              # focus default workspace for each monitor
              general.autostart = [ (lib.getExe focus-default-workspaces) ];
            }
          ]
        );
      };
    };
}
