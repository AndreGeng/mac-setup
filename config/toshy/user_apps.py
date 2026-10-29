# Physical Ctrl becomes Super in GUI apps under Toshy; restore Ctrl for Vicinae.
keymap("User Vicinae Ctrl bracket launcher", {
    C("Super-Left_Brace"): C("LC-Left_Brace"),
}, when=lambda ctx: cnfg.screen_has_focus)

# Toggle Fcitx directly so Ctrl+Space remains available to Herdr.
def user_toggle_fcitx():
    subprocess.Popen(["/usr/bin/fcitx5-remote", "-t"], stdout=DEVNULL, stderr=DEVNULL)

keymap("User Cmd Space input method", {
    C("RC-Space"): user_toggle_fcitx,
}, when=lambda ctx:
    cnfg.screen_has_focus and
    not ctx_app_is_remote
)
