{
  config,
  lib,
  user,
  ...
}:
{
  config =
  {
      users = {
        mutableUsers = true;
        # create a password with for root and $user with:
        # mkpasswd -m sha-512 'PASSWORD' and place in secrets.json under the appropriate key
        users = {
          root.hashedPasswordFile = lib.mkForce config.sops.secrets.rp.path;
          ${user} = {
            isNormalUser = true;
            hashedPasswordFile = lib.mkForce config.sops.secrets.up.path;
            extraGroups = [
              "networkmanager"
              "wheel"
            ];
            openssh.authorizedKeys.keys = [
              (lib.mkForce config.sops.secrets.ssh_github.path)
              (lib.mkForce config.sops.secrets.ssh_ustp.path)
            ];
          };
        };
      };
      

      sops.secrets = {
        rp.neededForUsers = true;
        up.neededForUsers = true;
      };
  };
}