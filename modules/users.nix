{
  config,
  user,
  ...
}:
{
  users = {
    mutableUsers = false;
    # passwords come only from sops, there is no fallback: if a secret cannot be decrypted the account is locked
    # create a password for root and $user with:
    # mkpasswd -m sha-512 'PASSWORD' and place in secrets.json under the appropriate key
    users = {
      root.hashedPasswordFile = config.sops.secrets.rp.path;
      ${user} = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.up.path;
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
}
