{
  config = { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      calibre
    ];

    services.udisks2 = {
      enable = true;
      mountOnMedia = true;
    };
  };
}