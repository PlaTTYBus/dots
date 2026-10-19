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

        extraOpts = {
          BookmarkBarEnabled = true;
          # chromium allows only one managed top level folder
          ManagedBookmarks = [
            { toplevel_name = "Bookmarks"; }
          ]
          ++ lib.mapAttrsToList
            (name: links: {
              inherit name;
              children = lib.mapAttrsToList (name: url: { inherit name url; }) links;
            })
            {
              FH = {
                eCampus = "https://ecampus.ustp.at/local/login/index.php";
                GitLab = "https://git.nwt.fhstp.ac.at";
                CiS = "https://cis.ustp.at/addons/STPCore/cis/login.php";
                Mensa = "https://cis.ustp.at/addons/STPCore/menueplan.php";
                Outlook = "https://outlook.cloud.microsoft/mail/";
              };
              Proton = {
                Mail = "https://mail.proton.me";
                Calendar = "https://calendar.proton.me";
                Drive = "https://drive.proton.me";
                Docs = "https://docs.proton.me";
                Lumo = "https://lumo.proton.me";
              };
            };
        };
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
