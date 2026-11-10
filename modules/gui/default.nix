{
    tags = [ "gui" ];

    config =
        {
            inputs,
            lib,
            pkgs,
            user,
            ...
        }:
        {
            environment = {
                sessionVariables = {
                    NIXOS_OZONE_WL = "1";
                    # fall back to xwayland for qt apps without the wayland plugin
                    QT_QPA_PLATFORM = "wayland;xcb";
                };

                systemPackages = [
                    # run gparted with all the permissions crap fixed, I don't want it permanently installed
                    (pkgs.writeShellApplication {
                        name = "gparted";
                        # gparted runs as root, so allow only root to connect to xwayland while it runs,
                        # xhost +local: would open xwayland to every local process
                        text = /* sh */ ''
                            nix-shell -p xhost gparted --command "xhost si:localuser:root && sudo gparted; xhost -si:localuser:root"
                        '';
                    })
                    pkgs.wl-clipboard
                ];
            };

            # saves approx 700 mb
            services.speechd.enable = false;

            users.users.${user}.packages = with pkgs; [
                vesktop
                obsidian
                stable.zotero
                stable.firefox
                spotify
                super-productivity
                # nomachine deletes old releases from its server, which breaks the nixpkgs hash
                (nomachine-client.overrideAttrs {
                    version = "10.2.3";
                    src = inputs.nomachine;
                    # the tack file has no .tar.gz extension for stdenv to detect
                    unpackCmd = "tar xzf $curSrc";

                    # patchelf grows the first segment of these non-PIE binaries into the code segment,
                    # .dynamic becomes read-only and ld.so segfaults on startup, so leave the binaries alone
                    # and let nix-ld provide /lib64/ld-linux-x86-64.so.2
                    dontAutoPatchelf = true;
                    dontPatchELF = true;

                    # replaces the vendor launcher scripts that the nixpkgs installPhase removes
                    postFixup = ''
                        for bin in nxplayer nxrunner; do
                            makeWrapper $out/bin/$bin.bin $out/bin/$bin \
                                --set NX_SYSTEM $out/NX \
                                --set MALLOC_CHECK_ 0 \
                                --prefix LD_LIBRARY_PATH : $out/NX/lib:${
                                    lib.makeLibraryPath [
                                        stdenv.cc.cc.lib
                                        zlib
                                        libpulseaudio
                                    ]
                                }
                        done

                        # libnxcau.so needs libpulse.so.0 for audio to work, but doesn't
                        # have a DT_NEEDED entry for it.
                        patchelf --add-needed libpulse.so.0 $out/NX/lib/libnxcau.so
                    '';
                })
                vlc
            ];
        };
}
