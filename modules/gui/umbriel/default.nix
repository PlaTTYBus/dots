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
                # when Mod is Alt (e.g. in vms), explicit Alt binds resolve to the same chord as Mod binds,
                # umbriel does not warn about this, so drop the colliding Alt binds and keep the Mod ones
                normalize = key: lib.toLower (lib.replaceStrings [ "Mod+" ] [ "Alt+" ] key);
                modChords = settings.keybinds |> lib.attrNames |> lib.filter (lib.hasPrefix "Mod+") |> map normalize;
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
              # use noctalia colors
              "/home/${user}/.config/umbriel/noctalia.toml"
              # dynamic cursor
              "/home/${user}/.config/umbriel/cursor.toml"
            ];
          };
        };

        xdg.portal = {
          config = {
            common.default = [ "gnome" ];
            obs.default = [ "gnome" ];
            umbriel = {
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