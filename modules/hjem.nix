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
          ${user} = {
            user = user;
            directory = "/persist/home/${user}";
          }
        };
      };
    };
}