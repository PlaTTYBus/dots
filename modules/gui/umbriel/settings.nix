{
    tags = [ "wm" ];

    config =
        {
            config,
            host,
            lib,
            tags,
            ...
        }:
        {
            custom.programs = {
                umbriel.settings =
                    let
                        gap = if host == "desktop" then 8 else 4;
                        strut = gap + 8;
                    in
                    {
                        output =
                            config.custom.hardware.monitors
                            |> lib.map (
                                d:
                                let
                                    rotation = toString (lib.mod (d.transform * 90) 360);
                                    flipped = d.transform > 3;
                                in
                                {
                                    inherit (d) name;
                                    value = {
                                        inherit (d) scale;
                                        mode = "${toString d.width}x${toString d.height}@${toString d.refreshRate}";
                                        position = [
                                            d.x
                                            d.y
                                        ];
                                        inherit (d) vrr;
                                        hdr = if d.hdr then "fullscreen" else "off";
                                        transform = "${lib.optionalString flipped "flipped-"}${
                                            if rotation == "0" then "normal" else rotation
                                        }";
                                        workspace_axis = if d.isVertical then "horizontal" else "vertical";
                                        workspaces = map toString d.workspaces;
                                    };
                                }
                            )
                            |> lib.listToAttrs;
                    }
                    //
                        (
                            config.custom.hardware.monitors
                            |> lib.concatMap (d: if d.isVertical then d.workspaces else [ ])
                            |> map (w: {
                                workspace = [
                                    {
                                        name = toString w;
                                        layout.struts = {
                                            left = 0;
                                            right = 0;
                                            top = strut;
                                            bottom = strut;
                                        };
                                    }
                                ];
                            })
                            |> lib.custom.recursiveMergeAttrsList
                        )
                    //
                        {
                            general = {
                                mod_key = lib.mkIf (builtins.elem "vm" tags) "Alt";
                                xwayland = true; # needs a restart
                                show_cheatsheet = false;
                                focus_on_activate = true;
                                honor_restored_maximize = false;
                            };

                            workspaces = {
                                back_and_forth = true;
                                empty_above = false;
                            };

                            animation = {
                                enabled = true;
                                duration_ms = 250;
                                curve = "easeout";

                                windows_in = {
                                    enabled = true;
                                    curve = "spring:1,1900";
                                    style = "popin";
                                    scale = 0.85;
                                };

                                windows_out = {
                                    enabled = true;
                                    curve = "spring:1,900";
                                    style = "fade";
                                    scale = 0.8;
                                };

                                windows_move = {
                                    enabled = true;
                                    curve = "spring:1,4400";
                                };

                                workspaces = {
                                    enabled = true;
                                    curve = "spring:1,800";
                                };

                                overview = {
                                    enabled = true;
                                    curve = "spring:1,800";
                                    workspace_curve = "spring:1,1000";
                                };

                                scratchpad = {
                                    enabled = true;
                                    curve = "spring:1,800";
                                    dim = 0.8;
                                    blur = false;
                                };

                                border = {
                                    enabled = true;
                                    curve = "spring:1,600";
                                };

                                dim_unfocused = {
                                    enabled = false;
                                    duration_ms = 250;
                                    curve = "easeout";
                                    dim = 0.0;
                                };

                                layers = {
                                    enabled = false;
                                    duration_ms = 250;
                                    curve = "easeout";
                                };
                            };

                            appearance = {
                                prefer_no_csd = true;
                                border_width = 2;
                                outer_border_width = 0;
                                corner_radius = 10;
                                drag_opacity = 0.75;
                                opaque_fullscreen = false;

                                blur = {
                                    enabled = true;
                                    optimized = true;
                                    passes = 3;
                                    radius = 3;
                                    noise = 0.02;
                                    brightness = 0.9;
                                    contrast = 0.9;
                                    saturation = 1.1;
                                };

                                shadow = {
                                    enabled = true;
                                    softness = 10;
                                    offset_x = 2;
                                    offset_y = 2;
                                };
                            };

                            colors = {
                                backdrop = "#00000000";
                                shadow = "#0000007F";
                            };

                            overview = {
                                zoom = 0.5;
                            };

                            layout = {
                                mode = "scrolling";
                                inherit gap;
                                extent_presets = [
                                    0.33333
                                    0.5
                                    0.66667
                                    1.0
                                ];

                                struts = {
                                    left = strut;
                                    right = strut;
                                    top = 0;
                                    bottom = 0;
                                };

                                scrolling = {
                                    default_extent_fraction = 0.5;
                                    center_underfull_strip = true;
                                    center_focused = "never";
                                };

                                master = {
                                    position = "left";
                                    default_width_fraction = 0.5;
                                    new_on_top = true;
                                };
                            };

                            input = {
                                middle_click_paste = false;

                                keyboard = {
                                    inherit (config.services.xserver.xkb) layout variant options;
                                    repeat_rate = 25;
                                    repeat_delay = 600;
                                    numlock_toggle = true;
                                    track_layout = "global";
                                };

                                touchpad = {
                                    tap = true;
                                    natural_scroll = false;
                                };

                                mouse = {
                                    sensitivity = 0.0;
                                    scroll_wheel_step = 60;
                                };

                                cursor = {
                                    theme = config.custom.gtk.cursor.name;
                                    size = config.custom.gtk.cursor.size;
                                    # the virtio-gpu cursor plane is invisible or offset under spice
                                    hardware_cursor = !(builtins.elem "vm" tags);
                                    follows_focus = false;
                                    hide_when_typing = false;
                                    hide_timeout_ms = 0;
                                };

                                focus = {
                                    follows_mouse = true;
                                };
                            };

                            window_rule = [
                                {
                                    blur = true;
                                    blur_optimized = true;
                                }
                                {
                                    match.app_id = "^dev.noctalia.UmbrielSharePicker$";
                                    default_floating = true;
                                    default_floating_size_px = {
                                        width = 800;
                                        height = 600;
                                    };
                                }
                                {
                                    match.title = "^(Picture-in-Picture|Picture in picture)$";
                                    default_floating = true;
                                    default_maximize = false;
                                    default_position = {
                                        x = 20;
                                        y = 20;
                                        anchor = "bottom_right";
                                    };
                                }
                                # vm displays are sdr and their irregular redraws make vrr flicker on oled
                                # the nix wrapper turns the app id into the name of the wrapped binary
                                {
                                    match.app_id = "^[.]virt-manager-wrapped$";
                                    hdr = "off";
                                    vrr = "disabled";
                                }
                                {
                                    match.is_alone = true;
                                    default_maximize = config.custom.programs.noctalia.minibar;
                                    default_maximize_to_edges = !config.custom.programs.noctalia.minibar;
                                }
                            ];
                        };
            };
        };
}
