# NOTE: zfs datasets are created via install.sh
{
  config,
  pkgs,
  tags,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    zfs = {
      devNodes =
        if builtins.elem "vm" tags then
          "/dev/disk/by-partuuid"
        # use by-id for intel mobo when not in a vm
        else if config.hardware.cpu.intel.updateMicrocode then
          "/dev/disk/by-id"
        else
          "/dev/disk/by-partuuid";

      package = pkgs.zfs_unstable;

      forceImportRoot = false;
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # 16GB swap
  swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];

  # standardized filesystem layout
  fileSystems = {
    # NOTE: root and home are on tmpfs
    # root partition, exists only as a fallback, actual root is a tmpfs
    "/" = {
      device = "zroot/root";
      fsType = "zfs";
    };

    # boot partition
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };

    "/nix" = {
      device = "zroot/nix";
      fsType = "zfs";
    };

    # create a 5GB tmpfs for /tmp, separate from "/" to keep root small
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "defaults"
        # NOTE: this is the max, it is not pre-allocated
        "size=5G"
        "mode=755"
      ];
    };

    "/persist" = {
      device = "zroot/persist";
      fsType = "zfs";
      neededForBoot = true;
    };

    # cache are files that should be persisted, but not to snapshot
    # e.g. npm, cargo cache etc, that could always be redownloaded
    "/cache" = {
      device = "zroot/cache";
      fsType = "zfs";
      neededForBoot = true;
    };
  };

  systemd.services = {
    # https://github.com/openzfs/zfs/issues/10891
    systemd-udev-settle.enable = false;
  };

  services.sanoid = {
    enable = true;

    templates = {
      persist = {
        hourly = 50;
        daily = 15;
        weekly = 3;
        monthly = 1;
      };

      media = {
        hourly = 3;
        daily = 10;
        weekly = 2;
        monthly = 0;
      };
    };

    datasets = {
      "zroot/persist" = {
        useTemplate = [ "persist" ];
      };
    };
  };

  # show compress ratio in zfs list output
  environment.shellAliases = {
    zls = "zfs list -o name,lused,used,avail,compressratio";
  };
}