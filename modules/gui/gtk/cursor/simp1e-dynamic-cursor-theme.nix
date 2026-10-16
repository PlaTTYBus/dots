{
  packages =
    { pkgs, ... }:
    {
      simp1e-dynamic-cursor-theme = pkgs.writeShellApplication {
        name = "simp1e-dynamic-cursor-theme";
        runtimeInputs = with pkgs; [
          (python3.withPackages (ps: [ ps.pillow ]))
          librsvg.out # otherwise it uses .dev
          xcursorgen
          dconf
        ];

        text = /* sh */ ''
          # $1 is the accent color, $2 is a comma separated list of sizes to generate
          # build in the cache instead of /tmp, so the cursor theme still exists on the next boot
          out="''${XDG_CACHE_HOME:-$HOME/.cache}/dynamic-themes/simp1e-cursors"

          # refresh the sources when simp1e-cursors is updated
          if [[ "$(cat "$out/.source" 2>/dev/null)" != "${pkgs.simp1e-cursors.src}" ]]; then
            rm -rf "$out"
            mkdir -p "$(dirname "$out")"
            cp -r --no-preserve=mode ${pkgs.simp1e-cursors.src} "$out"
            chmod -R u+w "$out"
            rm "$out"/src/color_schemes/*.txt
            rm "$out/src/templates/left.svg"
            echo "${pkgs.simp1e-cursors.src}" > "$out/.source"
          fi

          cp "/tmp/Simp1e-Noctalia.txt" "$out/src/color_schemes/Simp1e-Noctalia.txt"

          HOME=/tmp sh "$out/build.sh" --sizes="$2"

          THEME_NAME="Simp1e-Noctalia-$1"
          mkdir -p "$HOME/.local/share/icons"
          ln -sfn "$out/built_themes/$THEME_NAME" "$HOME/.local/share/icons/$THEME_NAME"

          # remove the cursor themes built for previous colors
          find "$out/built_themes" -mindepth 1 -maxdepth 1 -name 'Simp1e-Noctalia-*' ! -name "$THEME_NAME" -exec rm -rf {} +
          find "$HOME/.local/share/icons" -maxdepth 1 -name 'Simp1e-Noctalia-*' -xtype l -delete

          # update gtk with cursor
          dconf write "/org/gnome/desktop/interface/cursor-theme" "'$THEME_NAME'"

          # update umbriel with cursor
          cat << EOF > "$XDG_CONFIG_HOME/umbriel/cursor.toml"
          [input.cursor]
          theme = "$THEME_NAME"
          EOF
        '';
      };
    };

  tags = [ "gui" ];

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        # set dynamic icon theme with noctalia
        custom.programs.noctalia.user-templates = {
          "cursor-theme" = {
            input_path = ./Simp1e-Noctalia.txt;
            output_path = "/tmp/Simp1e-Noctalia.txt";
            post_hook =
              let
                # calculate all possible cursors sizes based on monitor scales
                sizes =
                  config.custom.hardware.monitors
                  |> lib.map (m: lib.ceil (config.custom.gtk.cursor.size * m.scale))
                  |> lib.sort (p: q: p < q)
                  |> lib.unique
                  |> lib.concatMapStringsSep "," toString;
              in
              ''${lib.getExe pkgs.custom.simp1e-dynamic-cursor-theme} "{{ colors.primary.default.hex_stripped }}" "${sizes}"'';
          };
        };
      };
    };
}
