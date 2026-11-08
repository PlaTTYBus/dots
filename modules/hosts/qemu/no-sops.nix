# the dev vm never decrypts secrets, it has no age key and logs in with a test password
# the shared modules still declare their sops secrets, this only stops sops-nix from installing them
{
  hosts = [ "qemu" ];

  config =
    {
      config,
      lib,
      user,
      ...
    }:
    let
      password = "test";
    in
    {
      users.users = {
        root = {
          hashedPasswordFile = lib.mkForce null;
          inherit password;
        };
        ${user} = {
          hashedPasswordFile = lib.mkForce null;
          inherit password;
        };
      };

      # secrets for users are installed by an activation script, as regular secrets they fall under the unit below
      sops.secrets = {
        rp.neededForUsers = lib.mkForce false;
        up.neededForUsers = lib.mkForce false;
      };
      systemd.services.sops-install-secrets.enable = false;

      # placeholders where the shared modules read their secrets, missing files are skipped by nix !include,
      # openvpn and ssh, so only the ones that would otherwise error are created
      systemd.tmpfiles.rules = [
        # gnome-keyring-unlock creates and unlocks the login keyring with the same password
        "f ${config.sops.secrets.keyring_password.path} 0400 ${user} users - ${password}"
        # gh runs unauthenticated, run "gh auth login" if needed
        "f ${config.sops.secrets.github_token.path} 0400 ${user} users -"
      ];
    };
}
