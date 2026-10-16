{
  config,
  lib,
  user,
  ...
}:
{
  # silence warning about setting multiple user password options
  # https://github.com/NixOS/nixpkgs/pull/287506#issuecomment-1950958990
  options = {
    warnings = lib.mkOption {
      apply = lib.filter (
        w: !(lib.hasInfix "If multiple of these password options are set at the same time" w)
      );
    };
  };

  config = {
    users = {
      mutableUsers = false;
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
