-- Workspace numbers start at 1. Match application classes, not window titles.
-- Handle application windows; leave panels, menus and transient dialogs alone.
if get_window_type() == "WINDOW_TYPE_NORMAL" then
    local class = string.lower(get_window_class() or "")
    local instance = string.lower(get_class_instance_name() or "")
    -- Keep Vicinae on the workspace where it opens.
    if class:find("vicinae", 1, true) or instance:find("vicinae", 1, true) then
        return
    end
    local workspace_one = {
        ["com.mitchellh.ghostty"] = true,
        ghostty = true,
        firefox = true,
        ["firefox-esr"] = true,
        ["google-chrome"] = true,
        ["google-chrome-stable"] = true,
        chromium = true,
        ["chromium-browser"] = true,
        ["brave-browser"] = true,
        ["brave-browser-beta"] = true,
        ["vivaldi-stable"] = true,
    }
    local target = (workspace_one[class] or workspace_one[instance]) and 1 or 2
    debug_print("workspace rule: " .. class .. " -> " .. target)
    set_window_workspace(target)
end
