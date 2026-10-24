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
