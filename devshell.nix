{ pkgs, ... }:
pkgs.mkShell {
  packages =
    with pkgs;
    [
      age
      sops
      cachix
      deadnix
      statix
      nil
      nixd
      nixfmt-rs
      pre-commit
      cargo-edit
    ]
    ++ [
      wlr-randr # used to get display info
    ];

  env = {
    # Required by rust-analyzer
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  nativeBuildInputs = with pkgs; [
    cargo
    rustc
    rust-analyzer
    rustfmt
    clippy
    pkg-config
  ];

  buildInputs = with pkgs; [
    pre-commit
  ];
}