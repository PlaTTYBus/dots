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
        
        gnupg.sshKeyPaths = [ ];
        age = {
          # sshKeyPaths = [ "/home/${user}/.ssh/id_ed25519" ];
          keyFile = "/home/pviel/.config/sops/age/keys.txt";
          # This will generate a new key if the key specified above does not exist
          generateKey = false;
        };
      };

      users.users.${user}.extraGroups = [ config.users.groups.keys.name ];
    };
}