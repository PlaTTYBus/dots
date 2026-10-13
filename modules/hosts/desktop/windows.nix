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
            search --fs-uuid --set=root {TODO: replace with actual UUID}
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
      };
    };
  };
}