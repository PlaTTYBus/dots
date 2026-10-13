{
  lib,
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

    # use run0 for sudo
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