# virtiofs share between the vm hosts and the qemu guest, the guest works on the dots of the host
# virt-manager: Filesystem, driver virtiofs, source path /shared, target path shared (needs shared memory)
let
  # the target path in virt-manager, the guest mounts the share by this tag
  tag = "shared";
  sharedDir = "/shared";
in
{
  hosts = [
    "desktop"
    "tuxedo"
    "qemu"
  ];

  config =
    { host, user, ... }:
    let
      dotsDir = "/home/${user}/projects/dots";
    in
    if host == "qemu" then
      {
        fileSystems.${sharedDir} = {
          device = tag;
          fsType = "virtiofs";
          options = [ "nofail" ];
        };

        # nh, /etc/nixos and the shell aliases expect the dots in the home directory
        custom.symlinks.${dotsDir} = "${sharedDir}/dots";

        # tmpfiles creates missing parents of the symlink as root, which would lock the user out of ~/projects
        systemd.tmpfiles.rules = [ "d /home/${user}/projects 0755 ${user} users -" ];
      }
    else
      {
        # virtiofsd does not follow symlinks out of the shared directory, so bind the dots into it
        fileSystems."${sharedDir}/dots" = {
          device = dotsDir;
          fsType = "none";
          options = [
            "bind"
            "nofail"
            "x-systemd.requires-mounts-for=${dotsDir}"
          ];
        };
      };
}
