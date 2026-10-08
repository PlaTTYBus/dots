{
  config,
  inputs,
  pkgs,
  user,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  config = {
      sops = {
        # to edit secrets file, run "sops modules/hosts/secrets.json"
        defaultSopsFile = ./hosts/secrets.json;
        useSystemdActivation = true;

        # use full path to persist as the secrets activation script runs at the start
        # of stage 2 boot before impermanence
        gnupg.sshKeyPaths = [ ];
        age = {
          # NOTE: paths from persist are used so they exist before impermanence kicks in
          # sshKeyPaths = [ "/persist/home/${user}/.ssh/id_ed25519" ];
          keyFile = "/persist/home/${user}/.config/sops/age/keys.txt";
          # This will generate a new key if the key specified above does not exist
          generateKey = false;
        };
      };

      users.users.${user}.extraGroups = [ config.users.groups.keys.name ];

      custom.persist.home = {
        directories = [ ".config/sops" ];
      };
    };
}