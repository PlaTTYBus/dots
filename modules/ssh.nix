{
  config = { config, user, ... }:
  {
    programs.ssh = {
      extraConfig = ''
        Host github.com
            User git
            IdentityFile /home/${user}/.ssh/keys/github
        Host git.nwt.fhstp.ac.at
            HostName git.nwt.fhstp.ac.at
            IdentitiesOnly yes
            Preferredauthentications publickey
            IdentityFile /home/${user}/.ssh/keys/ustp
      '';
    };
    # Public Keys
    hj.files = {
      ".ssh/keys/github.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlLpDO8rUBx/fcnOXU3btUz/1vb8LoTYNPBe2wYcx6p pviel@vmware";
      ".ssh/keys/ustp.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUI0Xc9C4tNTzHSMwxm00SipqwPi+Pvxi/ZLUKK3c5d pviel@vmware";
    };

    # Private Keys
    sops.secrets = {
      ssh_github = {
        owner = user;
        path = "/home/${user}/.ssh/keys/github";
      };
      ssh_ustp = {
        owner = user;
        path = "/home/${user}/.ssh/keys/ustp";
      };
    };
  };
}