-- Execute the real rule with stubbed window APIs; never move desktop windows.
local rule = assert(arg[1], "Expected workspace rule path")
local cases = {
    {"Thunar", "thunar", "WINDOW_TYPE_NORMAL", 2},
    {"thunar", "Thunar", "WINDOW_TYPE_NORMAL", 2},
    {"", "thunar", "WINDOW_TYPE_NORMAL", 2},
    {"Thunar", "thunar", "WINDOW_TYPE_DIALOG", nil},
    {"Thunar", "thunar", "WINDOW_TYPE_DOCK", nil},
    {"Thunar", "thunar", "WINDOW_TYPE_NOTIFICATION", nil},
    {"xfce4-notifyd", "xfce4-notifyd", "WINDOW_TYPE_NORMAL", nil},
    {"Xfce4-panel", "xfce4-panel", "WINDOW_TYPE_NORMAL", nil},
    {"Vicinae", "vicinae", "WINDOW_TYPE_NORMAL", nil},
    {"com.mitchellh.ghostty", "ghostty", "WINDOW_TYPE_NORMAL", nil},
    {"firefox", "Navigator", "WINDOW_TYPE_NORMAL", nil},
    {"Unknown", "unknown", "WINDOW_TYPE_NORMAL", nil},
    {"Thunar-helper", "other", "WINDOW_TYPE_NORMAL", nil},
    {nil, nil, "WINDOW_TYPE_NORMAL", nil},
}

for index, case in ipairs(cases) do
    local moves = {}
    local env = setmetatable({
        get_window_class = function() return case[1] end,
        get_class_instance_name = function() return case[2] end,
        get_window_type = function() return case[3] end,
        set_window_workspace = function(target) moves[#moves + 1] = target end,
        debug_print = function() end,
    }, {__index = _G})
    assert(loadfile(rule, "t", env))()
    assert(#moves == (case[4] and 1 or 0) and moves[1] == case[4],
        "Unexpected workspace move in case " .. index)
end
print("PASS Devilspie2 moves only explicitly listed normal Thunar windows")
