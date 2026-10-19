# NOTE: zfs datasets are created via install.sh, the tank datasets through custom.zfs.tank.createScript
{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  cfg = config.custom.zfs.tank;

  # parent of all tank datasets, the whole pool when it lives on its own disk
  tankRoot = if cfg.pool == "zroot" then "zroot/tank" else cfg.pool;

  # each group holds the settings for its folders, a group with several folders gets one child dataset per
  # folder, so every folder is mounted directly into the home directory
  groups = {
    documents = {
      snapshots = "data";
      folders = {
        documents = "Documents";
        desktop = "Desktop";
        templates = "Templates";
        public = "Public";
      };
    };
    pictures = {
      snapshots = "media";
      folder = "Pictures";
    };
    media = {
      snapshots = "media";
      # large sequential files
      recordsize = "1M";
      folders = {
        music = "Music";
        videos = "Videos";
      };
    };
    # downloads and isos can be downloaded again, so no snapshots
    downloads.folder = "Downloads";
    isos = {
      recordsize = "1M";
      folder = "ISOs";
    };
  };

  mounts = lib.concatLists (
    lib.mapAttrsToList (
      name: group:
      if group ? folder then
        [
          {
            dataset = "${tankRoot}/${name}";
            dir = group.folder;
          }
        ]
      else
        lib.mapAttrsToList (child: dir: {
          dataset = "${tankRoot}/${name}/${child}";
          inherit dir;
        }) group.folders
    ) groups
  );

  # idempotent, so it also creates datasets added later on an installed system
  create = dataset: options: ''
    zfs list -H -o name ${dataset} >/dev/null 2>&1 || zfs create ${lib.concatStringsSep " " options} ${dataset}
  '';
  recordsize = group: lib.optional (group ? recordsize) "-o recordsize=${group.recordsize}";
in
{
  options.custom.zfs.tank = {
    pool = lib.mkOption {
      type = lib.types.str;
      default = "zroot";
      description = "Pool for the media datasets, any other pool than zroot lives on its own disk (see install.sh)";
    };

    createScript = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      internal = true;
      description = "Commands that create the tank datasets, run by install.sh";
    };
  };

  config = {
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

      "/home" = {
        device = "zroot/home";
        fsType = "zfs";
        neededForBoot = true;
      };
    }
    // lib.listToAttrs (
      map (
        m:
        lib.nameValuePair "/home/${user}/${m.dir}" {
          device = m.dataset;
          fsType = "zfs";
          # keep file managers from listing every folder as a drive
          options = [ "x-gvfs-hide" ];
        }
      ) mounts
    );

    # a freshly mounted dataset belongs to root
    systemd.tmpfiles.rules = map (m: "d /home/${user}/${m.dir} 0755 ${user} users -") mounts;

    custom.zfs.tank.createScript =
      lib.optionalString (tankRoot != cfg.pool) (create tankRoot [ "-o canmount=off" ])
      + lib.concatStrings (
        lib.mapAttrsToList (
          name: group:
          if group ? folder then
            create "${tankRoot}/${name}" ([ "-o mountpoint=legacy" ] ++ recordsize group)
          else
            create "${tankRoot}/${name}" ([ "-o canmount=off" ] ++ recordsize group)
            + lib.concatMapStrings (child: create "${tankRoot}/${name}/${child}" [ "-o mountpoint=legacy" ]) (
              lib.attrNames group.folders
            )
        ) groups
      );

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
      }
      // lib.mapAttrs' (
        name: group:
        lib.nameValuePair "${tankRoot}/${name}" {
          useTemplate = [ group.snapshots ];
          recursive = true;
        }
      ) (lib.filterAttrs (_: group: group ? snapshots) groups);
    };

    # show compress ratio in zfs list output
    environment.shellAliases = {
      zls = "zfs list -o name,lused,used,avail,compressratio";
    };
  };
}
