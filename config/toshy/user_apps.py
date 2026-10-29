# Physical Ctrl becomes Super in GUI apps under Toshy; restore Ctrl for Vicinae.
keymap("User Vicinae Ctrl bracket launcher", {
    C("Super-Left_Brace"): C("LC-Left_Brace"),
}, when=lambda ctx: cnfg.screen_has_focus)

# Unmapped D chords must retain D instead of silently consuming the letter.
# Once a typing chord starts, subsequent keys in that hold stay ordinary text.
def user_d_nav_output(key, arrow=None):
    def emit():
        global user_d_nav_typing
        if arrow is not None and not user_d_nav_typing:
            return C(arrow)
        prefix = [] if user_d_nav_typing else [C("d")]
        user_d_nav_typing = True
        return prefix + [C(key)]
    return emit

keymap("User D HJKL arrows", {
    **{C("DNav-" + key): user_d_nav_output(key) for key in (
        "a b c e f g i m n o p q r s t u v w x y z "
        "0 1 2 3 4 5 6 7 8 9 Space Enter Tab Backspace Esc "
        "Minus Equal Left_Brace Right_Brace Semicolon Apostrophe Grave "
        "Backslash Comma Dot Slash"
    ).split()},
    C("DNav-h"): user_d_nav_output("h", "Left"),
    C("DNav-j"): user_d_nav_output("j", "Down"),
    C("DNav-k"): user_d_nav_output("k", "Up"),
    C("DNav-l"): user_d_nav_output("l", "Right"),
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
