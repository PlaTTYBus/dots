{
    config = _: {
        services = {
            # turns off tlp from nixos-hardware, noctalia only offers profile switching with power-profiles-daemon
            power-profiles-daemon.enable = true;

            scx = {
                enable = true;
                scheduler = "scx_lavd";
                extraArgs = [ "--autopower" ];
            };
        };
    };
}
