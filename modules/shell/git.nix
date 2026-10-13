{
  config =
    { config, pkgs, ... }:
    {
      programs = {
        git = {
          enable = true;
        };
      };
    };
}