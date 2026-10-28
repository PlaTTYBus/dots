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

            # each app is autostarted and always opens on its own workspace
            startup = [
                {
                    app_id = "helium";
                    spawn = "helium --profile-directory=Default";
                    workspace = 1;
                }
                # neovim, needs a terminal to show a window
                # ghostty only accepts a --class containing a dot
                rec {
                    app_id = "dev.${user}.nvim";
                    spawn = "ghostty --class=${app_id} -e nvim";
                    workspace = 3;
                }
                # file manager
                {
                    app_id = "nemo";
                    spawn = "nemo";
                    workspace = 4;
                }

                # terminal, opens a window in the ghostty background service (started via dbus if not running yet)
                {
                    inherit (config.custom.programs.terminal) app_id;
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
                                {
                                    match = {
                                        app_id = "^${lib.escapeRegex s.app_id}$";
                                        # dialogs open floating and stay with their parent
                                        is_floating = false;
                                    };
                                    default_workspace = toString s.workspace;
                                }
                            ];
                        })
                    )
                    ++ [
                        {
                            # focus default workspace for each monitor
                            general.autostart = [ (lib.getExe focus-default-workspaces) ];

                            # 1-4 belong to the apps above, everything else opens on 5. no window steals focus,
                            # neither when it opens nor through activation. the later rule wins, so this comes first
                            window_rule = lib.mkBefore [
                                {
                                    match.is_floating = false;
                                    default_workspace = "5";
                                    default_focused = false;
                                }
                            ];
                        }
                    ]
                );
            };
        };
}
