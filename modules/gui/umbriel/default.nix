{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      system,
      user,
      ...
    }:
    let
      tomlFormat = pkgs.formats.toml { };
      umbrielWrapper = import ./_wrapper.nix { inherit inputs; };
    in
    {
      options.custom = {
        programs.umbriel = {
          settings = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            description = "Configuration for umbriel";
          };
        };
      };

      config = {
        programs.umbriel = {
          enable = true;
          package = umbrielWrapper.wrap {
            inherit pkgs;
            package = inputs.umbriel.packages.${system}.default;
            settings =
              let
                inherit (config.custom.programs.umbriel) settings;
                # with Mod = Alt, explicit Alt binds collide with Mod binds and umbriel does not warn
                normalize = key: lib.toLower (lib.replaceStrings [ "Mod+" ] [ "Alt+" ] key);
                modChords =
                  settings.keybinds
                  |> lib.attrNames
                  |> lib.filter (lib.hasPrefix "Mod+")
                  |> map normalize;
              in
              if (settings.general.mod_key or null) == "Alt" then
                settings
                // {
                  keybinds = lib.filterAttrs (
                    key: _: lib.hasPrefix "Mod+" key || !(lib.elem (normalize key) modChords)
                  ) settings.keybinds;
                }
              else
                settings;

            includeOptional = [
              "/home/${user}/.config/umbriel/noctalia.toml"
              "/home/${user}/.config/umbriel/cursor.toml"
            ];
          };
        };

        xdg.portal = {
          config = {
            common.default = [ "gtk" ];
            # replaces umbriel-portals.conf, without the umbriel default screencasts and screenshots break
            umbriel = {
              default = [
                "umbriel"
                "gtk"
              ];
              "org.freedesktop.impl.portal.FileChooser" = "gtk";
            };
          };

          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        custom.programs = {
          print-config = {
            umbriel =
              let
                inherit (config.programs.umbriel.package.configuration.constructFiles) generatedConfig userConfig;
              in
              /* sh */ ''cat "${generatedConfig.outPath}" "${userConfig.outPath}" | moor --lang toml'';
          };
        };
      };
    };
}
