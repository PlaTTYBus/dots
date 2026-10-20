{
  hosts = [ "desktop" ];

  config = _: {
    custom = {
      hardware = {
        monitors = [
          {
            name = "DP-1";
            width = 2560;
            height = 1440;
            refreshRate = "360.000";
            x = 1440;
            y = 560;
            vrr = true;
            workspaces = [
              1
              2
              3
              4
              5
            ];
            hdr = true;
          }
          {
            name = "DP-2";
            width = 2560;
            height = 1440;
            refreshRate = "75.000";
            x = 4000;
            y = 560;
            workspaces = [
              6
              7
            ];
            defaultWorkspace = 6;
          }
          {
            name = "DP-3";
            width = 2560;
            height = 1440;
            refreshRate = "60.000";
            x = 0;
            y = 0;
            workspaces = [
              8
              9
            ];
            defaultWorkspace = 8;
            transform = 1;
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

    services = {
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
