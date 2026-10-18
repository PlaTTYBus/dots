{
  packages =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      helium = pkgs.callPackage ./_package.nix {
        inherit (inputs._meta.helium) version;
        src = inputs.helium;

        flags = [
          "--restore-last-session"
          "--hide-crash-restore-bubble"
        ];
      };
    };

  tags = [ "gui" ];

  config =
    { lib, pkgs, ... }:
    {
      programs.chromium = {
        # NOTE: programs.chromium.enable does not install any package!, it only creates policy files
        enable = true;

        extensions = [
          # Dark Reader
          "eimadpbcbfnmbkopoojfekhnkhdbieeh"
          # Refined Github
          "hlepfoohegkhhmjieoechaddaejaokhf"
          # JSON Viewer
          "gbmdgpbipfallnflgajpaliibnhdgobh"
          # Redirector
          "lioaeidejmlpffbndjhaameocfldlhin"
          # Return YouTube Dislike
          "gebbhagfogifgggkldgodflihgfeippi"
          # Session Manager
          "edacconmaakjimmfgnblocblbcdcpbko"
          # SponsorBlock for YouTube - Skip Sponsorships
          "mnjggcdmjocbbbhaepdhchncahnbgone"
          # Tokyo Night Storm
          "pgbjifpikialeahbdendkjioeafbmfkn"
          # Youtube-shorts block
          "jiaopdjbehhjgokpphdfgmapkobbnmjp"
          # Proton Pass
          "ghmbeldphafepmbegfdlkpapadhbakde"
          # Privacy Badger
          "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"
        ];
      };

      environment = {
        sessionVariables = {
          DEFAULT_BROWSER = lib.getExe pkgs.custom.helium;
          BROWSER = lib.getExe pkgs.custom.helium;
        };

        systemPackages = [
          pkgs.custom.helium
        ];
      };

      xdg.mime.defaultApplications = {
        "text/html" = "helium.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
        "x-scheme-handler/about" = "helium.desktop";
        "x-scheme-handler/unknown" = "helium.desktop";
      };
    };
}
