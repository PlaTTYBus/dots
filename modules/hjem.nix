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
          users.${user} = {
            directory = "/home/${user}";
          };
          extraModules= [
            inputs.hjem-rum.nixosModules.default
          ];
        };
      };
    };
}