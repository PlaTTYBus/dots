{
  packages =
    { inputs, pkgs, ... }:
    {
      # config goes into "config.nu" and "env.nu"
      nushell = inputs.wrappers.wrappers.nushell.wrap {
        inherit pkgs;
      };
    };

  config =
    { pkgs, ... }:
    {
      # installed to try out, fish stays the login shell
      environment.systemPackages = [ pkgs.custom.nushell ];

      custom.programs.print-config = {
        nushell = /* sh */ "moor ${pkgs.custom.nushell.configuration.constructFiles.generatedConfig.outPath}";
      };
    };
}
