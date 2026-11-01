# Ctrl+Cmd navigation; Caps holds literal Ctrl, while physical Ctrl becomes
# Super in GUI apps under Toshy. Cmd is represented by Right Ctrl.
keymap("User Ctrl Cmd HJKL arrows", {
    C("LC-RC-h"): C("Left"),
    C("LC-RC-j"): C("Down"),
    C("LC-RC-k"): C("Up"),
    C("LC-RC-l"): C("Right"),
    C("Super-RC-h"): C("Left"),
    C("Super-RC-j"): C("Down"),
    C("Super-RC-k"): C("Up"),
    C("Super-RC-l"): C("Right"),
}, when=lambda ctx: cnfg.screen_has_focus and not ctx_app_is_remote)

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
