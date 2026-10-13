{
  hosts = [
    "desktop"
    "tuxedo"
  ];

  config =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        rocmPackages.rocm-smi
        rocmPackages.rocminfo
      ];
    };
}