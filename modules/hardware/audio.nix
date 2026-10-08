{
  config,
  host,
  lib,
  pkgs,
  user,
  ...
}:{
  # setup pipewire for audio
  security.rtkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    pamixer
    pavucontrol
  ];

  custom.persist = {
    home.directories = [
      ".local/state/wireplumber"
    ];
  };
}