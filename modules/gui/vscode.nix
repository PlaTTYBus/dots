{
  tags = [ "gui" ];

  config =
    { pkgs, ... }:
    let
      vscodium' = pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions = with pkgs.vscode-extensions; [
          aaron-bond.better-comments
          dbaeumer.vscode-eslint
          denoland.vscode-deno
          donjayamanne.githistory
          eamodio.gitlens
          enkia.tokyo-night
          esbenp.prettier-vscode
          formulahendry.auto-rename-tag
          gruntfuggly.todo-tree
          jnoortheen.nix-ide
          mhutchie.git-graph
          mkhl.direnv
          ms-python.black-formatter
          ms-python.flake8
          ms-python.python
          ms-python.vscode-pylance
          pkief.material-icon-theme
          tamasfe.even-better-toml
          usernamehw.errorlens
          vscodevim.vim
          yzhang.markdown-all-in-one
        ];
      };
    in
    {
      environment.systemPackages = [ vscodium' ];
    };
}