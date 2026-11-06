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
                    app_id = "helium";
                    spawn = "helium --profile-directory=Default";
                    workspace = 1;
                }
                # ghostty only accepts a --class containing a dot
                rec {
                    app_id = "dev.${user}.nvim";
                    spawn = "ghostty --class=${app_id} -e nvim";
                    workspace = 3;
                }
                {
                    app_id = "nemo";
                    spawn = "nemo";
                    workspace = 4;
                }
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
                                        is_floating = false;
                                    };
                                    default_workspace = toString s.workspace;
                                }
                            ];
                        })
                    )
                    ++ [
                        {
                            general.autostart = [ (lib.getExe focus-default-workspaces) ];

                            # the later rule wins, so this comes first
                            window_rule = lib.mkBefore [
                                {
                                    match.is_floating = false;
                                    default_workspace = "5";
                                }
                            ];
                        }
                    ]
                );
            };
        };
}
