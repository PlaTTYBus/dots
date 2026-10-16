# NOTE: zfs datasets are created via install.sh
{
  pkgs,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    zfs = {
      devNodes = "/dev/disk/by-partuuid";

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
    "/" = {
      device = "zroot/root";
      fsType = "zfs";
    };

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

    # cache are files that should not be snapshotted,
    # e.g. npm, cargo cache etc, that could always be redownloaded
    "/cache" = {
      device = "zroot/cache";
      fsType = "zfs";
      neededForBoot = true;
    };

    "/tank" = {
      device = "zroot/tank";
      fsType = "zfs";
    };
    "/home" = {
      device = "zroot/home";
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
      data = {
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
      "zroot/home" = {
        useTemplate = [ "data" ];
      };
      "zroot/tank" = {
        useTemplate = [ "media" ];
      };
    };
  };

  # show compress ratio in zfs list output
  environment.shellAliases = {
    zls = "zfs list -o name,lused,used,avail,compressratio";
  };
}