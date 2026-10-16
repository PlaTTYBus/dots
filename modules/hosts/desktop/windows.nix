{
  hosts = [ "desktop" ];

  config = {
    # dual boot
    boot = {
      loader.grub = {
        extraEntries = ''
          menuentry "Windows 11" {
            insmod part_gpt
            insmod fat
            insmod search_fs_uuid
            insmod chain
            # find the windows efi partition by its bootloader, no hardcoded uuid needed
            search --no-floppy --file --set=root /EFI/Microsoft/Boot/bootmgfw.efi
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
      };
    };
  };
}