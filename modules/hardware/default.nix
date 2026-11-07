{
    config = _: {
        services = {
            # turns off tlp from nixos-hardware, noctalia only offers profile switching with power-profiles-daemon
            power-profiles-daemon.enable = true;

            scx-loader = {
                enable = true;
                config = {
                    default_sched = "scx_lavd";
                    default_mode = "Auto";
                    scheds.scx_lavd.auto_mode = [
                        "--autopower"
                        "--pinned-slice-us"
                        "500"
                    ];
                };
            };
        };
    };
}
