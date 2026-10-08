{
  hosts = [ "desktop" ];

  config =
    {
      lib,
      pkgs,
      tags,
      user,
      ...
    }:
    let
      projects = "/persist/home/${user}/projects";
      # fetch wallpapers from pixiv for user
      pixiv = pkgs.writeShellApplication {
        name = "pixiv";
        runtimeInputs = [ pkgs.custom.direnv-cargo-run ];
        text = /* sh */ ''
          pushd ${projects}/pixiv > /dev/null
          direnv-cargo-run "${projects}/pixiv" "$@"
          popd > /dev/null
        '';
      };
    in
    {
      custom = {
        hardware = {
          monitors = [
            {
              name = "DP-1";
              width = 2560;
              height = 1440;
              refreshRate = "360.000";
              vrr = false;
              x = 1440;
              y = 1080;
              workspaces = [
                1
                2
                3
                4
                5
              ];
              hdr = true; # toggle to use hdr
            }
          ];
        };
        lock.enable = false;

        programs = {
          btop.settings = {
            custom_gpu_name0 = "AMD Radeon RX 9070XT";
          };

          noctalia.settings = {
            control_center.hidden_tabs = [
              "monitor"
              "network"
              "bluetooth"
              "power"
            ];
          };
        };
      };

      boot.zfs.requestEncryptionCredentials = lib.mkForce false;

      services = {
        displayManager.defaultSession = "umbriel";
/*
        pipewire = {
          wireplumber.extraConfig = {
            "99-disable-devices" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    { "device.name" = "alsa_card.pci-0000_03_00.1"; }
                    { "device.name" = "alsa_card.usb-Generic_USB_Audio-00"; }
                    { "device.name" = "alsa_card.pci-0000_0f_00.1"; }
                  ];
                  actions = {
                    update-props = {
                      "device.disabled" = true;
                    };
                  };
                }
              ];
            };
          };
        };
        */
      };

      networking.hostId = "9ea0e958";
    };
}