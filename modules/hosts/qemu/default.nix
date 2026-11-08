# manual virt-manager settings for this guest
# - Overview: chipset Q35, firmware UEFI (grub is installed for efi)
# - CPU: "Copy host CPU configuration" (host-passthrough)
# - Memory: enable shared memory, virtiofs needs it
# - Storage: create the disk in a pool on /var/lib/libvirt/vms (zfs dataset tuned for qcow2), not the default pool
#   disk bus VirtIO, cache mode none, discard mode unmap, IO mode io_uring
#   install.sh picks /dev/vda automatically
# - NIC: device model virtio
# - Video: model Virtio, enable 3D acceleration, otherwise umbriel falls back to software rendering
# - Display Spice: listen type None, enable OpenGL
# - Channel: keep the qemu-ga channel (org.qemu.guest_agent.0) that virt-manager adds
# - Filesystem: driver virtiofs, source path /shared, target path shared, see shared.nix
{
  hosts = [ "qemu" ];

  config =
    { lib, ... }:
    {
      custom = {
        hardware = {
          monitors = [
            {
              name = "Virtual-1";
              width = 1920;
              height = 1080;
              workspaces = [
                1
                2
                3
                4
                5
                6
                7
                8
                9
              ];
            }
          ];
        };
      };
      boot.zfs.requestEncryptionCredentials = lib.mkForce false; # VM is not encrypted
      networking.hostId = "2b859231";

      services.qemuGuest.enable = true;

      # by default the arc may grow into most of the guest ram
      boot.kernelParams = [ "zfs.zfs_arc_max=${toString (2 * 1024 * 1024 * 1024)}" ];
      # the host handles snapshots and scrubs of the image
      services = {
        zfs.autoScrub.enable = lib.mkForce false;
        sanoid.enable = lib.mkForce false;
      };
    };
}
