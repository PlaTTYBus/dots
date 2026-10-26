{
    hosts = [ "desktop" ];

    config =
        { user, ... }:
        {
            fileSystems."/home/${user}/Data" = {
                device = "/dev/disk/by-label/DATA";
                fsType = "ntfs3";
                options = [
                    "nofail"
                    "uid=1000"
                    "gid=100"
                    "windows_names"
                ];
            };
        };
}
