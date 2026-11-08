{
  hosts = [ "qemu" ];

  config =
    { pkgs, user, ... }:
    {
      users.users.${user}.packages = [ pkgs.claude-code ];
    };
}
