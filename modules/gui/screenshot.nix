{
  tags = [ "wm" ];

  config =
    {
      inputs,
      lib,
      pkgs,
      system,
      ...
    }:
    let
      focal = inputs.focal.packages.${system}.default.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/focal-noctalia-ocr-delay.patch ];
      });

      noctalia-annotate = pkgs.writeShellApplication {
        name = "noctalia-annotate";
        text = /* sh */ ''noctalia msg annotate "$1"'';
      };

      screen-record = pkgs.writeShellApplication {
        name = "screen-record";
        runtimeInputs = [
          focal
          pkgs.libnotify
          pkgs.procps
        ];
        text = /* sh */ ''
          if ! pgrep -x wf-recorder >/dev/null; then
            notify-send -a "focal" -i media-record "Screen recording" "Select an area, press Mod+Print again to stop"
          fi
          exec focal video --area selection
        '';
      };
    in
    {
      environment.systemPackages = [
        focal
        noctalia-annotate
        screen-record
      ];

      custom = {
        programs.umbriel.settings.keybinds = {
          "Print" = "spawn:focal image --area selection --no-notify --no-save";
          "Shift+Print" = "spawn:focal image --menu --no-notify --no-save --edit ${lib.getExe noctalia-annotate}";
          "Ctrl+Print" = "spawn:focal image --area selection --ocr";
          "Mod+Print" = {
            action = "spawn:${lib.getExe screen-record}";
            repeat = false;
          };
        };
      };
    };
}
