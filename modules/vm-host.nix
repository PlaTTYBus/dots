{
  hosts = [
    "desktop"
    "tuxedo"
  ];

  config =
    {
      config,
      pkgs,
      user,
      ...
    }:
    let
      vmsDir = "/var/lib/libvirt/vms";
      vmsDataset = "zroot/vms";
    in
    {
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu.vhostUserPackages = [ pkgs.virtiofsd ];
        };
        # following configuration is used only when building VMs with build-vm
        vmVariant = {
          virtualisation = {
            memorySize = 1024 * 16;
            cores = 8;
          };
        };
      };
      programs.virt-manager.enable = true;
      # pass usb devices (e.g. a wifi adapter) into a vm
      virtualisation.spiceUSBRedirection.enable = true;
      # the nixos firewall otherwise drops dhcp and dns from vms on the default nat network
      networking.firewall.trustedInterfaces = [ "virbr0" ];
      # virsh and virt-install use the system vms that virt-manager shows, not a per user session
      environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";

      # 64K records match the qcow2 cluster size, the guest caches its own data
      systemd.services.zfs-create-vms = {
        unitConfig.DefaultDependencies = false;
        after = [ "zfs-import.target" ];
        path = [ config.boot.zfs.package ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          zfs list -H -o name ${vmsDataset} >/dev/null 2>&1 ||
            zfs create -o mountpoint=legacy -o recordsize=64K -o primarycache=metadata ${vmsDataset}
        '';
      };

      fileSystems.${vmsDir} = {
        device = vmsDataset;
        fsType = "zfs";
        options = [
          "nofail"
          "x-systemd.requires=zfs-create-vms.service"
          "x-systemd.after=zfs-create-vms.service"
        ];
      };

      systemd.services.libvirtd.unitConfig.RequiresMountsFor = [ vmsDir ];

      users.users.${user}.extraGroups = [ "libvirtd" ];
    };
}
