{ 
  hosts = [ "tuxedo" ];
  
  config =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.tuxedo-pulse-14-gen3 ];

      boot = {
        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "usb_storage"
          "sd_mod"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];
      };

      services.displayManager.defaultSession = "umbriel";
      services.upower.enable = true;

      networking.useDHCP = lib.mkDefault true;
      hardware.enableRedistributableFirmware = true;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      
    };
}