{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      pluginId = "plattybus/vpn-switcher";

      nmcli = lib.getExe' pkgs.networkmanager "nmcli";
      grep = lib.getExe pkgs.gnugrep;
      # run "protonvpn signin <username>" once, the session is kept in gnome-keyring
      protonvpn = lib.getExe pkgs.proton-vpn-cli;

      # proton always brings its tunnel up as proton0, which skips the slow python startup when it is down
      protonActive = "[ -e /sys/class/net/proton0 ]";
      universityActive = "${nmcli} -t -f NAME connection show --active | ${grep} -qx University";
      protonDown = "if ${protonActive}; then ${protonvpn} disconnect; fi";
      universityDown = "if ${universityActive}; then ${nmcli} connection down University; fi";
    in
    {
      environment.systemPackages = [
        pkgs.proton-vpn-cli
      ];

      networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

      sops.secrets.university_vpn = { };

      systemd.services.university-vpn-import = {
        after = [
          "NetworkManager.service"
          "sops-install-secrets.service"
        ];
        wants = [
          "NetworkManager.service"
          "sops-install-secrets.service"
        ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.networkmanager ];
        environment.HOME = "/var/lib/university-vpn";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "university-vpn";
          StateDirectoryMode = "0700";
        };
        script = ''
          install -m 600 ${config.sops.secrets.university_vpn.path} "$STATE_DIRECTORY/University.ovpn"
          nmcli connection delete University >/dev/null 2>&1 || true
          nmcli connection import type openvpn file "$STATE_DIRECTORY/University.ovpn"
          nmcli connection modify University connection.autoconnect no
        '';
      };

      # bar widget to switch between no vpn, university and proton
      custom.programs.noctalia.settings = {
        plugins = {
          enabled = [ pluginId ];
          source = [
            {
              name = "vpn-switcher";
              kind = "path";
              location = "${inputs.vpn-switcher}";
              enabled = true;
            }
          ];
        };

        # each mode takes the other vpn down first, runAsync gives up after 60s so nmcli waits at most 50s
        plugin_settings.${pluginId} = {
          cmd_disabled = "${universityDown} && ${protonDown}";
          cmd_university = "${protonDown} && ${nmcli} --wait 50 connection up University";
          # no server arguments connects to the fastest server
          cmd_proton = "${universityDown} && ${protonvpn} connect";
          cmd_status = "if ${protonActive}; then echo proton; elif ${universityActive}; then echo university; else echo disabled; fi";
        };

        widget.vpn-switcher.type = "${pluginId}:bar";
      };
    };
}
