{ inputs, system, ... }:
{
  programs.tack = {
    enable = true;
    package = inputs.tack.packages.${system}.default;
    nixConfTokens = true; # use GITHUB_TOKEN
  };
  environment.sessionVariables = {
    GITHUB_TOKEN = sops.secrets.github_token.path;
  };
}