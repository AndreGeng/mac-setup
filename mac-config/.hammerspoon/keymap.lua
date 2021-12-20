local hyperKey = require('hyperKey')
-- switch tabs
local nextTab = function()
    hs.eventtap.keyStroke({'cmd', 'shift'}, ']')
end
hyperKey:bind({}, string.lower("k"), nextTab, nil)
local previousTab = function()
    hs.eventtap.keyStroke({'cmd', 'shift'}, '[')
end
hyperKey:bind({}, string.lower("j"), previousTab , nil)

-- toggle window
function toggleAppWindows()
  -- local switcher = hs.window.switcher.new({hs.application.frontmostApplication():name()})
  -- switcher:next()
  hs.eventtap.keyStroke({'cmd'}, '`', 20000)
  print('toggleAppWindows')
end
hyperKey:bind({}, 's',toggleAppWindows , nil)

function yabai(args, alterArgs)

  -- Runs in background very fast
  hs.task.new("/usr/local/bin/yabai",function(exitCode)
  end, args):start()

end

hs.hotkey.bind({"cmd"}, 'i', function() yabai({"-m", "window", "--toggle", "zoom-fullscreen"}) end)

hs.hotkey.bind({"cmd"}, 'h', function() yabai({"-m", "window", "--focus", "west"}) end,nil)
hs.hotkey.bind({"cmd"}, 'l', function() yabai({"-m", "window", "--focus", "east"}) end,nil)
hs.hotkey.bind({"cmd"}, 'j', function() yabai({"-m", "window", "--focus", "south"}) end,nil)
hs.hotkey.bind({"cmd"}, 'k', function() yabai({"-m", "window", "--focus", "north"}) end,nil)
