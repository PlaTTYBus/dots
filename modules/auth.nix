{
  lib,
  user,
  ...
}:
{
  config = lib.mkMerge [
    # ssh settings
    {
      services.openssh = {
        enable = true;
        # disable password auth
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      users.users."${user}".openssh.authorizedKeys.keyFiles = [
            ./id_ed25519.pub
      ];
    }

    # keyring settings
    {
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.login.enableGnomeKeyring = true;
    }

    # use run0 for sudo
    {
      security = {
        sudo.enable = false;
        run0 = {
          enable = true;
          sudo-shim.enable = true;
          persistentAuth.enable = true;
        };
      };
    }

    {
      security = {
        polkit.enable = true;
        sudo.extraConfig = "Defaults passwd_tries=5";
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

      # persist keyring and misc other secrets
      custom.persist = {
        root = {
          directories = [
            "/etc/ssh"
          ];
        };
        home = {
          directories = [
            # ".pki" # chromium recreates this directory, so it can't be moved to $XDG_DATA_HOME/.pki
            ".ssh"
            ".local/share/.gnupg"
            ".local/share/keyrings"
          ];
        };
      };
    }
  ];
}