{
  packages =
    { pkgs, ... }:
    let
      tokyonight-base-package = pkgs.callPackage ./_tokyonight-gtk-theme.nix {
        colorVariants = [ "dark" ];
        sizeVariants = [ "compact" ];
        themeVariants = [ "all" ];
      };
    in
    {
      # fix some ugly styling for nemo in tokyonight
      tokyonight-gtk-theme = tokyonight-base-package.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ./tokyonight-style.patch ];

        postInstall = (o.postInstall or "") + ''
          rm -rf $out/share/themes/*Light*

          for theme in "$out"/share/themes/*Dark*; do
            ln -s "$theme" "''${theme/Dark/Light}";
          done
        '';
      });

      tokyonight-dynamic-gtk-theme =
        let
          tokyonight-theme-default = tokyonight-base-package.override {
            colorVariants = [ "dark" ];
            sizeVariants = [ "compact" ];
            themeVariants = [ "default" ];
          };
          tokyonight-template-default = pkgs.runCommand "tokyonight-template" { } /* sh */ ''
            mkdir -p $out/share/themes

            src="${tokyonight-theme-default}";
            cp -RT "$src/share/themes/Tokyonight-Dark-Compact/" "$out/"
          '';
        in
        pkgs.writeShellApplication {
          name = "tokyonight-dynamic-gtk-theme";
          runtimeInputs = [
            pkgs.dconf
          ];
          text = /* sh */ ''
            if [[ -z "''${1:-}" || -z "''${2:-}" ]]; then
                echo "ERROR: Two hex colors are required (e.g., #FF0000)."
                exit 1
            fi

            # strip the leading #s
            THEME_NAME="Tokyonight-''${1#\#}-''${2#\#}"
            # generate into the cache instead of /tmp, so the theme still exists on the next boot,
            # apps autostarted before noctalia regenerates it would fall back to adwaita otherwise
            CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/dynamic-themes"
            THEME_DIR="$CACHE_DIR/$THEME_NAME"
            mkdir -p "$CACHE_DIR"

            # uncomment for debugging
            # rm -rf "$THEME_DIR"

            # regenerate when the template changed, e.g. after an update of the theme
            if [[ "$(cat "$THEME_DIR/.source" 2>/dev/null)" != "${tokyonight-template-default}" ]]; then
              rm -rf "$THEME_DIR"
              cp -r ${tokyonight-template-default} "$THEME_DIR"
              chmod -R +w "$THEME_DIR"

              # replace the accents ($1) and on-accent ($2) colors
              find "$THEME_DIR" -name "*.css" -type f -exec sed -i \
                -e "s/#27a1b9/$1/g" \
                -e "s/rgba(26, 27, 38, 0.87)/$1/g" \
                -e "s/#e1e2e7/$2/g" \
                {} +
              sed -i "s/Tokyonight-Dark-Compact/$THEME_NAME/g" "$THEME_DIR/index.theme"

              # add overrides at the end of the file
              # wow this indentation is ass
              cat <<-EOF | tee -a "$THEME_DIR/gtk-3.0/gtk.css" "$THEME_DIR/gtk-3.0/gtk-dark.css" > /dev/null
            /* nemo selected item expander color */
            treeview.view.expander:selected {
              color: $1;
            }

            /* nemo selected item rename highlight color */
            treeview entry selection {
              color: #ffffff;
              background-color: $2;
            }
            EOF

              echo "${tokyonight-template-default}" > "$THEME_DIR/.source"
            fi

            mkdir -p "$HOME/.local/share/themes"
            ln -sfn "$THEME_DIR" "$HOME/.local/share/themes/$THEME_NAME"

            # remove the themes generated for previous colors
            find "$CACHE_DIR" -mindepth 1 -maxdepth 1 -name 'Tokyonight-*' ! -name "$THEME_NAME" -exec rm -rf {} +
            find "$HOME/.local/share/themes" -maxdepth 1 -name 'Tokyonight-*' -xtype l -delete
            dconf write "/org/gnome/desktop/interface/gtk-theme" "'$THEME_NAME'"
          '';
        };
    };

  tags = [ "gui" ];

  config =
    {
      config,
      lib,
      pkgs,
      user,
      ...
    }:
    {
      options.custom = {
        gtk = {
          theme = {
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.custom.tokyonight-gtk-theme;
              description = "Package providing the theme.";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = "Tokyonight-Dark-Compact";
              description = "The name of the theme within the package.";
            };
          };
        };
      };

      config = {
        environment.systemPackages = [
          config.custom.gtk.theme.package
        ];

        # set dynamic icon theme with noctalia
        custom.programs.noctalia.user-templates = {
          "gtk-theme" = {
            # dummy values so noctalia doesn't complain
            input_path = "/home/${user}/.config/user-dirs.conf";
            post_hook = ''${lib.getExe pkgs.custom.tokyonight-dynamic-gtk-theme} "{{ colors.primary.default.hex }}" "{{ colors.on_primary.default.hex | set_alpha 0.8 }}"'';
            output_path = "/dev/null";
          };
        };
      };
    };
}