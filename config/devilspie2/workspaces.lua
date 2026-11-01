-- Workspace numbers start at 1. Match application classes, not window titles.
-- Handle application windows; leave panels, menus and transient dialogs alone.
if get_window_type() == "WINDOW_TYPE_NORMAL" then
    local class = string.lower(get_window_class() or "")
    local instance = string.lower(get_class_instance_name() or "")
    -- Move only explicitly listed applications; leave every other window where it opens.
    local application_workspaces = {
        thunar = 2,
    }
    local target = application_workspaces[class] or application_workspaces[instance]
    if target then
        debug_print("workspace rule: " .. class .. " -> " .. target)
        set_window_workspace(target)
    end
end
