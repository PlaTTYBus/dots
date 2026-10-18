{
  config,
  pkgs,
  user,
  ...
}:
{
  config = {
    services.openssh = {
      enable = true;
      # disable password auth
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    # keyring settings
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;

    sops.secrets.keyring_password.owner = user;

    systemd.user.services.gnome-keyring-unlock = {
      wantedBy = [ "graphical-session-pre.target" ];
      before = [ "graphical-session-pre.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.secrets";
        ExecStart = pkgs.writeShellScript "gnome-keyring-unlock" ''
          exec ${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --replace --unlock --foreground \
            --components=pkcs11,secrets --control-directory="$XDG_RUNTIME_DIR/keyring" \
            < <(${pkgs.coreutils}/bin/tr -d '\n' < ${config.sops.secrets.keyring_password.path})
        '';
        Restart = "on-failure";
      };
    };

    systemd.tmpfiles.rules = [
      "d /home/${user}/.local/share/keyrings 0700 ${user} users -"
      "f+ /home/${user}/.local/share/keyrings/default 0644 ${user} users - login"
    ];

    security = {
      sudo = {
        enable = true;
        extraConfig = ''
          Defaults passwd_tries=5
          Defaults lecture=never
        '';
      };
    };

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    environment.variables = {
      GNUPGHOME = "/home/${user}/.local/share/.gnupg";
    };

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
