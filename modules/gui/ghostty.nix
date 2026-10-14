{
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
                desktop = "ghostty.desktop";
              };
      };
  };
}