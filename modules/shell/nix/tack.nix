{
  config = 
  { inputs, system, user, config, ... }:
  {
    programs.tack = {
      enable = true;
      package = inputs.tack.packages.${system}.default;
      nixConfTokens = true; # use GITHUB_TOKEN
    };
  };
}