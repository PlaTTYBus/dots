{
  hosts = [ "qemu" ];

  config =
    { modulesPath, ... }:
    {
      imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

      boot = {
        initrd.availableKernelModules = [
          "ahci"
          "xhci_pci"
          "sr_mod"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ ];
        extraModulePackages = [ ];
      };

      # firmware for usb devices passed into the vm
      hardware.enableRedistributableFirmware = true;
    };
}
