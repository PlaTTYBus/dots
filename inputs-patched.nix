args:
let
  # inputs from tack
  unpatchedInputs = (import ./.tack) {
    overrides = args.tackOverrides or { };
  };

  patcher = unpatchedInputs.nixpkgs.legacyPackages.x86_64-linux.callPackage ./patcher.nix { };
in
patcher.patch unpatchedInputs {
  nixpkgs = [
    ./patches/allow-unfree.patch
    # nixos/noctalia-greeter: support autologin
    # https://github.com/NixOS/nixpkgs/pull/560780
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/477a86df848b03eef447a06f0fd505ed2f10375d.patch";
      hash = "sha256-GeCd7EPZwvP79tc9Ss2hD/WIOfq/7XSo27WLn/z+2HQ=";
    })
  ];
  wrappers = [
    # expose options used to build each wrapped package
    ./patches/nix-wrappers-expose-options.patch

    # noctalia module
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/598
    (patcher.fetchpatch {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/commit/8dc6e5fa91c39033b6a8613b2ba5cfcc72728792.patch";
      hash = "sha256-Lo/wvbqEv5DoFQ/FwqXTTUn+Bfck/V6M3EfRG5jdTrY=";
    })
  ];
}