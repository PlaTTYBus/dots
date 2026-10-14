{
  options.custom = {
        # terminal options
        programs.terminal = {
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.ghostty;
            description = "Package to use for the terminal";
          };

          app_id = lib.mkOption {
            type = lib.types.str;
            description = "app_id (wm class) for the terminal";
          };

          desktop = lib.mkOption {
            type = lib.types.str;
            default = "${config.custom.programs.terminal.package.pname}.desktop";
            description = "Name of desktop file for the terminal";
          };
        };
      };

  tags = [ "gui" ];

  config = 
    {
      hjem.users.pviel.rum.programs.ghostty = {
        enable = true;
        settings = {
          font-family = "JetBrainsMono Nerd Font";
          font-size = 10;
          theme = "Catppuccin Mocha";
          keybind = [
            "ctrl+h=goto_split:left"
            "ctrl+l=goto_split:right"
          ];
          alpha-blending = "linear-corrected";
          app-notifications = "no-clipboard-copy";
          background-opacity = 0.85;
          confirm-close-surface = false;
          copy-on-select = "clipboard";
          cursor-style = "bar";
          window-decoration = false;
          font-feature = "zero";
          font-style = "Medium";
        };
      };

      custom.programs = {
        terminal = {
          app_id = "ghostty";
        };
      };
  };
}