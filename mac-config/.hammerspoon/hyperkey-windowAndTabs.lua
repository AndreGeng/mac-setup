local hyperKey = require('hyperKey')
local windowManagementModal = hs.hotkey.modal.new({}, "F17")

windowManagementModal:bind({}, 'escape', function()
  windowManagementModal:exit()
end, nil)

hyperKey:bind({}, "W", function()
  windowManagementModal:enter()
end, nil)

windowManagementModal.entered = function()
  modalIndicator.show('WM')
end

windowManagementModal.exited = function()
  modalIndicator.hide()
end

function resize_win(direction)
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()
        local stepw = max.w/20
        local steph = max.h/20
        if direction == "right" then f.w = f.w+stepw end
        if direction == "left" then f.w = f.w-stepw end
        if direction == "up" then f.h = f.h-steph end
        if direction == "down" then f.h = f.h+steph end
        if direction == "halfright" then f.x = max.x + max.w/2 f.y = max.y f.w = max.w/2 f.h = max.h end
        if direction == "halfleft" then f.x = max.x f.y = max.y f.w = max.w/2 f.h = max.h end
        if direction == "halfup" then f.x = max.x f.y = max.y f.w = max.w f.h = max.h/2 end
        if direction == "halfdown" then f.x = max.x f.y = max.y + max.h/2 f.w = max.w f.h = max.h/2 end
        if direction == "cornerNE" then f.x = max.w/2 f.y = 0 f.w = max.w/2 f.h = max.h/2 end
        if direction == "cornerSE" then f.x = max.w/2 f.y = max.h/2 f.w = max.w/2 f.h = max.h/2 end
        if direction == "cornerNW" then f.x = 0 f.y = 0 f.w = max.w/2 f.h = max.h/2 end
        if direction == "cornerSW" then f.x = 0 f.y = max.h/2 f.w = max.w/2 f.h = max.h/2 end
        if direction == "center" then f.x = (max.w-f.w)/2 f.y = (max.h-f.h)/2 end
        if direction == "fcenter" then f.x = stepw*5 f.y = steph*5 f.w = stepw*20 f.h = steph*20 end
        if direction == "fullscreen" then f = max end
        if direction == "shrink" then f.w = f.w-(stepw*2) f.h = f.h-(steph*2) end
        if direction == "expand" then f.w = f.w+(stepw*2) f.h = f.h+(steph*2) end
        if direction == "mright" then f.x = f.x+stepw end
        if direction == "mleft" then f.x = f.x-stepw end
        if direction == "mup" then f.y = f.y-steph end
        if direction == "mdown" then f.y = f.y+steph end
        win:setFrame(f)
    else
        hs.alert.show("No focused window!")
    end
end
windowManagementModal:bind({}, "K", function() resize_win('mup') end, nil, function() resize_win('mup') end)
windowManagementModal:bind({}, "H", function() resize_win('mleft') end, nil, function() resize_win('mleft') end)
windowManagementModal:bind({}, "L", function() resize_win('mright') end, nil, function() resize_win('mright') end)
windowManagementModal:bind({}, "J", function() resize_win('mdown') end, nil, function() resize_win('mdown') end)
windowManagementModal:bind({}, "I", function() resize_win('shrink') end, nil, function() resize_win('shrink') end)
windowManagementModal:bind({}, "O", function() resize_win('expand') end, nil, function() resize_win('expand') end)
windowManagementModal:bind({}, "F", function() resize_win('fullscreen') end, nil, function() resize_win('fullscreen') end)
windowManagementModal:bind({}, "W", function() resize_win('halfup') end, nil, function() resize_win('halfup') end)
windowManagementModal:bind({}, "S", function() resize_win('halfdown') end, nil, function() resize_win('halfdown') end)
windowManagementModal:bind({}, "A", function() resize_win('halfleft') end, nil, function() resize_win('halfleft') end)
windowManagementModal:bind({}, "D", function() resize_win('halfright') end, nil, function() resize_win('halfright') end)

-- ikbc

-- switch tabs
local nextTab = function()
    hs.eventtap.keyStroke({'cmd', 'shift'}, ']')
end
hyperKey:bind({}, string.lower("k"), nextTab, nil)
local previousTab = function()
    hs.eventtap.keyStroke({'cmd', 'shift'}, '[')
end
hyperKey:bind({}, string.lower("j"), previousTab , nil)

-- toggle window within different monitor
function sendWindowNextMonitor()
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():next()
  win:moveToScreen(nextScreen)
end
hyperKey:bind({}, ";", sendWindowNextMonitor, nil)
-- ikbc
-- hs.hotkey.bind({}, 'home', sendWindowNextMonitor, nil)

-- toggle window
function toggleAppWindows()
  -- local switcher = hs.window.switcher.new({hs.application.frontmostApplication():name()})
  -- switcher:next()
  hs.eventtap.keyStroke({'cmd'}, '`', 20000)
  print('toggleAppWindows')
end
hyperKey:bind({}, 'n',toggleAppWindows , nil)
