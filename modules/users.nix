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
          root = {
            initialPassword = "password";
            hashedPasswordFile = lib.mkForce config.sops.secrets.rp.path;
          };
          ${user} = {
            isNormalUser = true;
            initialPassword = "password";
            hashedPasswordFile = lib.mkForce config.sops.secrets.up.path;
            extraGroups = [
              "networkmanager"
              "wheel"
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