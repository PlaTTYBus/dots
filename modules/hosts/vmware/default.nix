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
    services.xserver.videoDrivers = [ "vmware" ];
    virtualisation.vmware.guest.enable = true;
    services = {
        spice-vdagentd.enable = true;
        spice-webdavd.enable = true;
    };
      
    # fix for spice-vdagentd not starting in wms
    systemd.user.services.spice-agent = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.spice-vdagent "spice-vdagent"} -x";
      };
      unitConfig = {
        ConditionVirtualization = "vm";
        Description = "Spice guest session agent";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
    };
  };
}
