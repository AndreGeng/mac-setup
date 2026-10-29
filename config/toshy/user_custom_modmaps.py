# Tap D for d; hold D with H/J/K/L for cursor navigation.
# Ghostty consumes the F24 carrier with its repository-owned ignore binding.
add_modifier("USER_D_NAV", aliases=["DNav"], key=Key.F24)
multipurpose_modmap("User D navigation modifier", {
    Key.D: [Key.D, Key.F24],
}, when=lambda ctx: cnfg.screen_has_focus)

# Tap Caps Lock for Escape; hold with another key for literal Ctrl.
multipurpose_modmap("User Caps Lock tap Esc hold Ctrl", {
    Key.CAPSLOCK: [Key.ESC, Key.LEFT_CTRL],
}, when=lambda ctx: cnfg.screen_has_focus)
