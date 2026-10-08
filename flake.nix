{
  outputs =
    { self, ... }@args:
    let
      inputs = import ./inputs-patched.nix args;
      inherit (inputs.nixpkgs) lib;
      inherit (inputs.lamina.lib) mkHost mkPackages;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # provide package for each system
      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          f (
            import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );

      mkHostInfo = tags: {
        inherit tags;
        inherit (lib) nixosSystem;
        modules = [ ./modules ];
        specialArgs = {
          inherit inputs self;
          user = "pviel";
        };
        validTags = [
          "gui"
          "wm"
          "laptop"
          "vm"
        ];
      };

      # add tags to a hostInfo
      addTags = info: extraTags: (info // { tags = (info.tags or [ ]) ++ extraTags; });

      hostInfo = {
        desktop = mkHostInfo [
          "gui"
          "wm"
        ];

        tuxedo = mkHostInfo [
          "gui"
          "wm"
          "laptop"
        ];

        vmware = mkHostInfo [
          "gui"
          "wm"
          "vm"
        ];
      };
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop" hostInfo.desktop;
        tuxedo = mkHost "tuxedo" hostInfo.tuxedo;
        vmware = mkHost "vmware" hostInfo.vmware;
      }

      devShells = forAllSystems (pkgs: {
        default = import ./devshell.nix { inherit pkgs; };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rs);

      packages = forAllSystems (
        pkgs:
        mkPackages pkgs [ ./modules ] {
          inherit inputs self;
        }
      );
    };
}