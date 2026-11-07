{
  config =
    {
      inputs,
      lib,
      user,
      ...
    }:
    {
      imports = [
        inputs.hjem.nixosModules.default
        # alias for hjem
        (lib.mkAliasOptionModule [ "hj" ] [ "hjem" "users" user ])

      ];

      config = {
        hjem = {
          clobberByDefault = true;
          extraModules = [
            inputs.hjem-rum.hjemModules.default
          ];
        };
      };
    };
}
