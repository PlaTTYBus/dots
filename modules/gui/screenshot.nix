{
  tags = [ "wm" ];

  config =
    {
      inputs,
      system,
      ...
    }:
    let
      focal = inputs.focal.packages.${system}.default.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/focal-noctalia-ocr-delay.patch ];
      });
    in
    {
      environment.systemPackages = [
        focal
      ];

      custom = {
        programs.umbriel.settings.keybinds = {
          "Print" = "spawn:focal image --area selection --no-notify --no-save";
          "Shift+Print" = "spawn:focal image --menu";
          "Ctrl+Print" = "spawn:focal image --area selection --ocr";
          "Mod+Print" = "spawn:focal video --area selection";
        };
      };
    };
}
