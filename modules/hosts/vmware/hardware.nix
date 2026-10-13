{
  hosts = [ "vmware" ];
  
  config =
    {
      config,
      lib,
      ...
    }:
    {
      boot = {
        initrd.availableKernelModules = [
          "ata_piix"
          "mptspi"
          "uhci_hcd"
          "ehci_pci"
          "ahci"
          "sd_mod"
          "sr_mod"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ ];
        extraModulePackages = [ ];
      };

      hardware.enableRedistributableFirmware = true;
    };
}