{
  config =
    { config, pkgs, ... }:
    {
      programs = {
        git = {
          enable = true;
        };
      };
/*
      custom.persist = {
        home.directories = [
          ".config/lazygit"
          ".config/gitbutler"
        ];
      };
    */
    };
}