{
  config =
    { config, user, ... }:
    {
      # Authorized Keys
      users.users."${user}".openssh.authorizedKeys.keyFiles = [
        ./id_ed25519.pub
      ];

      # Public Keys
      hj.files = {
        # NOTE: private keys are used directly from /run/secrets, a sops secret with a path inside of home
        # makes sops-nix create the missing parent dirs as root, which locks hjem out of ~/.ssh
        ".ssh/config".text = ''
          Host github.com
              User git
              IdentityFile ${config.sops.secrets.ssh_github.path}
              IdentitiesOnly yes

          Host git.nwt.fhstp.ac.at
              HostName git.nwt.fhstp.ac.at
              PreferredAuthentications publickey
              IdentityFile ${config.sops.secrets.ssh_ustp.path}
              IdentitiesOnly yes
        '';
        ".ssh/keys/github.pub".text =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlLpDO8rUBx/fcnOXU3btUz/1vb8LoTYNPBe2wYcx6p pviel@vmware";
        ".ssh/keys/ustp.pub".text =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUI0Xc9C4tNTzHSMwxm00SipqwPi+Pvxi/ZLUKK3c5d pviel@vmware";
      };

      # Private Keys, decrypted to /run/secrets/<name> and readable only by the user (mode 0400)
      sops.secrets = {
        ssh_github.owner = user;
        ssh_ustp.owner = user;
      };
    };
}
