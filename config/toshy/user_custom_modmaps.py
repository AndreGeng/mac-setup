# Tap Caps Lock for Escape; hold with another key for literal Ctrl.
multipurpose_modmap("User Caps Lock tap Esc hold Ctrl", {
    Key.CAPSLOCK: [Key.ESC, Key.LEFT_CTRL],
}, when=lambda ctx: cnfg.screen_has_focus)
