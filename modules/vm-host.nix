{
  hosts = [
    "desktop"
    "tuxedo"
  ];

  config =
    { pkgs, user, ... }:
    {
      virtualisation = {
        libvirtd.enable = true;
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
      # https://discourse.nixos.org/t/virt-manager-cannot-find-virtiofsd/26752/2
      # add virtiofsd to filesystem xml
      # <binary path="/run/current-system/sw/bin/virtiofsd"/>
      environment.systemPackages = with pkgs; [ virtiofsd ];

      users.users.${user}.extraGroups = [ "libvirtd" ];
    };
}
