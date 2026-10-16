{
  hosts = [ "vmware" ];

  config = { lib, pkgs, ... }:
  {
    custom = {
      hardware = {
          monitors = [
              {
                  name = "Virtual-1";
                  width = 1920;
                  height = 1080;
                  workspaces = [
                      1
                      2
                      3
                      4
                      5
                      6
                      7
                      8
                      9
                  ];
              }
          ];
      };
    };
    boot.zfs.requestEncryptionCredentials = lib.mkForce false; # VM is not encrypted
    networking.hostId = "2b859231";
    virtualisation.vmware.guest.enable = true;
  };
}
