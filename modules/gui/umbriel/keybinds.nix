{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      user,
      ...
    }:
    {
      custom.programs = {
        umbriel.settings = {
          keybinds =
            let
              # ghostty rejects positional args
              termExec = cmd: "spawn ghostty -e ${cmd}";
            in
            {
              "Mod+Return" = "spawn ghostty +new-window";
              "Mod+Shift+Return" = "spawn noctalia msg panel-toggle launcher";

              "Mod+E" = "spawn nemo /home/${user}/Downloads";
              "Mod+Shift+E" = termExec "yazi /home/${user}/Downloads";

              "Mod+W" = "spawn helium --profile-directory=Default";
              "Mod+Shift+W" = "spawn helium --profile-directory=Default --incognito";

              "Mod+V" = termExec "nvim";

              "Ctrl+Alt+Delete" = "spawn noctalia msg panel-toggle session";

              "Mod+A" = "spawn noctalia msg bar-toggle";

              "Mod+Shift+A" = "spawn noctalia-reload";

              "Mod+Ctrl+V" = "spawn noctalia msg panel-toggle clipboard";

              "Mod+N" = "spawn noctalia msg panel-toggle control-center notifications";

              "Mod+I" = "spawn noctalia msg panel-toggle wallpaper";
              "Mod+Shift+I" = "spawn noctalia msg wallpaper-random";
              "Mod+Ctrl+I" = "spawn noctalia msg wallpaper-previous";
              "Mod+B" = "spawn noctalia msg panel-toggle noctalia/wallhaven:browser";

              "XF86AudioLowerVolume" = {
                action = "spawn pamixer -d 5";
                allow_when_locked = true;
              };
              "XF86AudioRaiseVolume" = {
                action = "spawn pamixer -i 5";
                allow_when_locked = true;
              };
              "XF86AudioMute" = {
                action = "spawn pamixer -t";
                allow_when_locked = true;
              };
            }
            // {
              "Mod+BackSpace" = {
                action = "window-close";
                repeat = false;
              };

              "Alt+F4" = "session-quit";

              "Mod+O" = "overview-toggle";

              "Mod+Shift+O" = {
                action = "cheatsheet-toggle";
                repeat = false;
              };

              "Mod+H" = "window-focus-or-output-left";
              "Mod+J" = "window-focus-or-workspace-down";
              "Mod+K" = "window-focus-or-workspace-up";
              "Mod+L" = "window-focus-or-output-right";

              "Mod+Shift+H" = "window-move-or-output-left";
              "Mod+Shift+J" = "window-move-or-workspace-down";
              "Mod+Shift+K" = "window-move-or-workspace-up";
              "Mod+Shift+L" = "window-move-or-output-right";

              "Mod+Home" = "column-focus-first";
              "Mod+End" = "column-focus-last";
              "Mod+Shift+Home" = "column-move-to-first";
              "Mod+Shift+End" = "column-move-to-last";

              "Mod+Left" = "output-focus-left";
              "Mod+Down" = "output-focus-down";
              "Mod+Up" = "output-focus-up";
              "Mod+Right" = "output-focus-right";

              "Mod+Shift+Left" = "column-move-to-output-left";
              "Mod+Shift+Down" = "column-move-to-output-down";
              "Mod+Shift+Up" = "column-move-to-output-up";
              "Mod+Shift+Right" = "column-move-to-output-right";

              "Mod+Shift+Tab" = "window-focus-last";

              "Alt+Tab" = "window-focus-next";
              "Alt+SHIFT+Tab" = "window-focus-last";

              "Mod+Tab" = "workspace-focus-last";

              "Mod+Comma" = "window-consume-or-expel-left";
              "Mod+Period" = "window-consume-or-expel-right";

              "Mod+R" = "window-cycle-primary-extent";
              "Mod+Shift+R" = "window-cycle-secondary-extent";

              "Mod+Z" = "window-toggle-maximize";
              "Mod+F" = "window-toggle-fullscreen";
              "Mod+G" = "window-toggle-floating";

              "Mod+S" = "window-toggle-pinned";

              "Mod+C" = "window-center";
              "Mod+Ctrl+C" = "column-center";

              "Mod+WheelDown" = "window-focus-or-workspace-down";
              "Mod+WheelUp" = "window-focus-or-workspace-up";
            }
            //
              (
                config.custom.hardware.monitors
                |> lib.custom.mapWorkspaces (
                  { workspace, key, ... }:
                  [
                    {
                      "Mod+${key}" = "workspace-switch --name ${toString workspace}";
                      "Mod+Shift+${key}" = "window-move-to-workspace --name ${toString workspace}";
                    }
                  ]
                )
                |> lib.flatten
                |> lib.mergeAttrsList
              );
        };
      };
    };
}
