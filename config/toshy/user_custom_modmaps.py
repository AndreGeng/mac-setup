# Tap D for d; hold D with H/J/K/L for cursor navigation.
# Ghostty consumes the F24 carrier with its repository-owned ignore binding.
add_modifier("USER_D_NAV", aliases=["DNav"], key=Key.F24)
# Reset once on each physical D press; keep typing fallback for the whole hold.
user_d_nav_typing = False

def user_d_nav_begin(ctx):
    global user_d_nav_typing
    user_d_nav_typing = False
    return cnfg.screen_has_focus

multipurpose_modmap("User D navigation modifier", {
    Key.D: [Key.D, Key.F24],
}, when=user_d_nav_begin)

# Tap Caps Lock for Escape; hold with another key for literal Ctrl.
multipurpose_modmap("User Caps Lock tap Esc hold Ctrl", {
    Key.CAPSLOCK: [Key.ESC, Key.LEFT_CTRL],
}, when=lambda ctx: cnfg.screen_has_focus)
