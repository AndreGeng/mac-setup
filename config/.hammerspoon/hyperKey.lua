-- use karabiner to map rcmd to f19, then enjoy

-- A global variable for the Hyper Mode
local hyperKey = hs.hotkey.modal.new({}, "F18")

local hyperkeyTriggerPressed = function()
  hyperKey:enter();
end

local hyperkeyTriggerReleased = function()
  hyperKey:exit()
end

local f19 = hs.hotkey.bind({}, string.lower('F19'), hyperkeyTriggerPressed, hyperkeyTriggerReleased);
return hyperKey
