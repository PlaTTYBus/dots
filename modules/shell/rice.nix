{
  inputs,
  pkgs,
  system,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      fastfetch
      nitch
      pipes-rs
      scope-tui
      tenki
    ];

    shellAliases = {
      neofetch = "fastfetch --config neofetch";
      wwfetch = "wfetch --wallpaper --image-size 270";
    };
  };
}