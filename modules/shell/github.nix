{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}:
let
  # wrap gh to set GITHUB_TOKEN
  gh = inputs.wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.gh;
    env.GH_CONFIG_DIR = pkgs.writeTextDir "/config.yml" (lib.strings.toJSON { version = 1; });
    runShell = [
      /* sh */ ''
        GITHUB_TOKEN=$(cat "${config.sops.secrets.github_token.path}")
        export GITHUB_TOKEN
      ''
    ];
  };
in
{
  # setup auth token for gh
  sops.secrets.github_token.owner = user;


  # needed for github authentication for private repos
  # adapted from home-manager:
  # https://github.com/nix-community/home-manager/blob/142acd7a7d9eb7f0bb647f053b4ddfd01fdfbf1d/modules/programs/gh.nix#L191
  programs.git.config = {
    # use https with the token above for all github remotes, so the passphrase protected ssh key is never needed
    url."https://github.com/".insteadOf = [
      "git@github.com:"
      "ssh://git@github.com/"
    ];

    credential =
      [
        "https://github.com"
        "https://gist.github.com"
      ]
      |> map (
        host:
        lib.nameValuePair host {
          helper = [
            ""
            "${lib.getExe gh} auth git-credential"
          ];
        }
      )
      |> lib.listToAttrs;
  };

  environment.systemPackages = [ gh ];
}
