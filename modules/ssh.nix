{
  config = { config, ... }:
  {
    hj.files = {
      # Config
      ".ssh/config".text = ''
        Host github.com
            User git
            IdentityFile /home/pviel/.ssh/keys/github
        Host git.nwt.fhstp.ac.at
            HostName git.nwt.fhstp.ac.at
            IdentitiesOnly yes
            Preferredauthentications publickey
            IdentityFile /home/pviel/.ssh/keys/ustp
      '';

       # Public Keys
      ".ssh/keys/github.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOc19UTkQ5O+ky5Wk+NaCPt7nopLUXEKmbbLXhNP1zvW tenno@ordis";
      ".ssh/keys/ustp.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETGCQVu53bLEtLyp3rCIiDMrYOhz8TBvlZuFjmc/xLS tenno@ordis";
    };

    # Private Keys
    sops.secrets = {
      ssh_github = {
        owner = user;
        path = "/persist/${config.hj.directory}/.ssh/keys/github";
      };
      ssh_ustp = {
        owner = user;
        path = "/persist${config.hj.directory}/.ssh/keys/ustp";
      };
    };
  };
}