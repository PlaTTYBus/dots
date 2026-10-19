{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      pluginId = "plattybus/vpn-switcher";
      unit = "openvpn-university.service";

      systemctl = lib.getExe' config.systemd.package "systemctl";
      # run "protonvpn signin <username>" once, the session is kept in gnome-keyring
      protonvpn = lib.getExe pkgs.proton-vpn-cli;

      # proton always brings its tunnel up as proton0, which skips the slow python startup when it is down
      protonActive = "[ -e /sys/class/net/proton0 ]";
      universityActive = "${systemctl} is-active --quiet ${unit}";
      protonDown = "if ${protonActive}; then ${protonvpn} disconnect; fi";
      universityDown = "if ${universityActive}; then ${systemctl} stop ${unit}; fi";
    in
    {
      environment.systemPackages = [
        pkgs.proton-vpn-cli
      ];

      sops.secrets.university_vpn = { };

      # the ovpn file is self-contained, so openvpn runs it as is
      services.openvpn.servers.university = {
        config = "config ${config.sops.secrets.university_vpn.path}";
        autoStart = false;
        updateResolvConf = true;
      };

      systemd.services.openvpn-university.serviceConfig = {
        # Type=notify, so "systemctl start" waits for the tunnel; runAsync gives up after 60s
        TimeoutStartSec = 50;
        # openvpn exits 0 on AUTH_FAILED, so this avoids hammering the server with bad credentials
        Restart = lib.mkForce "on-failure";
      };

      # lets the bar widget switch the tunnel without a password prompt
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "${unit}" &&
              subject.user == "${user}") {
            return polkit.Result.YES;
          }
        });
      '';

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

        # each mode takes the other vpn down first
        plugin_settings.${pluginId} = {
          cmd_disabled = "${universityDown} && ${protonDown}";
          cmd_university = "${protonDown} && ${systemctl} start ${unit}";
          # no server arguments connects to the fastest server
          cmd_proton = "${universityDown} && ${protonvpn} connect";
          cmd_status = "if ${protonActive}; then echo proton; elif ${universityActive}; then echo university; else echo disabled; fi";
        };

        # icon only, the minibar has no room for the label next to the centered workspaces
        widget.vpn-switcher = {
          type = "${pluginId}:bar";
          show_label = false;
        };
      };
    };
}
