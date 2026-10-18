{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      system,
      tags,
      user,
      ...
    }:
    let
      tomlFormat = pkgs.formats.toml { };
      umbrielWrapper = import ./_wrapper.nix { inherit inputs; };

      umbrielPackage = inputs.umbriel.packages.${system}.default;
      # vmwgfx returns TTM handles for imported dmabufs, which makes wlroots reject every gpu rendered
      # client (noctalia, ghostty, ...). Only patched for vms, so real hosts keep the cached wlroots
      umbrielVmPackage = umbrielPackage.override {
        wlroots_0_20 = pkgs.wlroots_0_20.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [ ../../../patches/wlroots-vmwgfx-dmabuf.patch ];
        });
      };
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
            package = if builtins.elem "vm" tags then umbrielVmPackage else umbrielPackage;
            settings =
              let
                inherit (config.custom.programs.umbriel) settings;
                # when Mod is Alt (e.g. in vms), explicit Alt binds resolve to the same chord as Mod binds,
                # umbriel does not warn about this, so drop the colliding Alt binds and keep the Mod ones
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
              # use noctalia colors
              "/home/${user}/.config/umbriel/noctalia.toml"
              # dynamic cursor
              "/home/${user}/.config/umbriel/cursor.toml"
            ];
          };
        };

        xdg.portal = {
          config = {
            # xdg-desktop-portal-gnome is not installed, gtk is the generic fallback
            common.default = [ "gtk" ];
            # this replaces umbriel-portals.conf from the umbriel portal package, so keep its default,
            # otherwise screencasting and screenshots never reach the umbriel portal
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
