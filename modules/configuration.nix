# leftovers from initial configuration.nix
{
  host,
  lib,
  pkgs,
  ...
}:
{
  networking.hostName = host;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  console = {
    useXkbConfig = true; # use xkb.options in tty.
  };

  i18n = {
        defaultLocale = "en_GB.UTF-8";
        extraLocaleSettings = {
          LC_ADDRESS = "de_AT.UTF-8";
          LC_IDENTIFICATION = "de_AT.UTF-8";
            LC_MEASUREMENT = "de_AT.UTF-8";
            LC_MONETARY = "de_AT.UTF-8";
            LC_NAME = "de_AT.UTF-8";
            LC_NUMERIC = "de_AT.UTF-8";
            LC_PAPER = "de_AT.UTF-8";
            LC_TELEPHONE = "de_AT.UTF-8";
            LC_TIME = "de_AT.UTF-8";
        };
      };

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "de";
      variant = "";
    };
    # bye bye xterm
    excludePackages = [ pkgs.xterm ];
  };

  # bye bye nano
  programs.nano.enable = lib.mkForce false;

  # enable sysrq in case for kernel panic
  # boot.kernel.sysctl."kernel.sysrq" = 1;

  # enable opengl
  hardware.graphics.enable = true;

  # zram
  zramSwap.enable = true;

  # do not change this value
  system.stateVersion = "23.05";
}