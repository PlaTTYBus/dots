{
  config = 
  { inputs, system, user, ... }:
  {
    programs.tack = {
      enable = true;
      package = inputs.tack.packages.${system}.default;
      nixConfTokens = true; # use GITHUB_TOKEN
    };
    environment.sessionVariables = {
      GITHUB_TOKEN = config.sops.secrets.github_token.value;
    };
    sops.secrets = {
      github_token = {
        owner = user;
      };
    };
  };
}