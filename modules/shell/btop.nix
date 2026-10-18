let
  baseBtopConf = {
    color_theme = "TTY";
    theme_background = false;
    cpu_single_graph = true;
    # base_10_sizes = true;
    show_gpu_info = "Off"; # don't show gpu info in cpu box
    show_disks = true;
    show_swap = true;
    swap_disk = false;
    use_fstab = false;
    only_physical = false;
    zfs_arc_cached = true;
    shown_boxes = "cpu mem net proc gpu0";
    gpu_mirror_graph = false;
  };
in
{
  packages =
    { inputs, pkgs, ... }:
    {
      # expose generic btop package without disks set
      btop = inputs.wrappers.wrappers.btop.wrap {
        inherit pkgs;
        settings = baseBtopConf;
      };
    };

  config =
    {
      config,
      host,
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      options.custom = {
        programs.btop = {
          inherit (inputs.wrappers.wrappers.btop.wrapperOptions) settings;
        };
      };

      config = {
        nixpkgs.overlays = [
          (_: prev: {
            btop = pkgs.custom.btop.wrap {
              package = prev.btop.override {
                rocmSupport = host == "desktop" || host == "tuxedo";
              };
              settings = lib.mkForce (
                baseBtopConf
                // {
                  color_theme = "noctalia";
                  disks_filter = lib.concatStringsSep " " [
                    "/"
                    "/boot"
                    "/home"
                  ];
                }
                // config.custom.programs.btop.settings
              );
            };
          })
        ];

        environment.systemPackages = [
          pkgs.btop # overlay-ed above
        ];

        custom.programs.print-config = {
          btop = /* sh */ ''moor --lang ini "${pkgs.btop.configuration.constructFiles.generatedConfig.outPath}"'';
        };
      };
    };
}
