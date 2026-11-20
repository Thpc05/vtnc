-- Disposable config for the nested test Hyprland (tools/headless/nested.sh).
-- Outputs are created at runtime with `hyprctl output create headless`;
-- Hyprland names them HEADLESS-1, HEADLESS-2... in creation order and
-- matches these rules against them as they appear. Theo's real hardware:
-- a FullHD laptop panel and a QuadHD monitor.

hl.monitor({ output = "HEADLESS-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HEADLESS-2", mode = "2560x1440@60", position = "1920x0", scale = 1 })

hl.config({
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
    },
})
