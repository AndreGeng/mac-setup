local fireKey = function(configItem)
  return function()
    hs.eventtap.event.newKeyEvent(configItem.mapTo.mod, string.lower(configItem.mapTo.key), true):post()
    hs.eventtap.event.newKeyEvent(configItem.mapTo.mod, string.lower(configItem.mapTo.key), false):post()
  end
end
hs.fnutils.each({
  {key='h', mod={'ctrl'}, mapTo = {mod = {}, key = 'left'}},
  {key='l', mod={'ctrl'}, mapTo = {mod = {}, key = 'right'}},
  {key='j', mod={'ctrl'}, mapTo = {mod = {}, key = 'down'}},
  {key='k', mod={'ctrl'}, mapTo = {mod = {}, key = 'up'}},
  {key='h', mod={'ctrl shift'}, mapTo = {mod = {'shift'}, key = 'left'}},
  {key='l', mod={'ctrl shift'}, mapTo = {mod = {'shift'}, key = 'right'}},
  {key='j', mod={'ctrl shift'}, mapTo = {mod = {'shift'}, key = 'down'}},
  {key='k', mod={'ctrl shift'}, mapTo = {mod = {'shift'}, key = 'up'}},
  {key='h', mod={'alt'}, mapTo = {mod = {'alt'}, key = 'left'}},
  {key='l', mod={'alt'}, mapTo = {mod = {'alt'}, key = 'right'}},

  {key=',', mod={'ctrl'}, mapTo = {mod= {}, key='delete'}},
  {key='.', mod={'ctrl'}, mapTo = {mod= {'ctrl'}, key='k'}}
}, function(configItem)
  local arrowRemappings = hs.hotkey.bind(configItem.mod, configItem.key, fireKey(configItem), nil, fireKey(configItem))
end)


local deleteToEndOfLine = function()
    hs.eventtap.event.newKeyEvent({'cmd', 'shift'}, string.lower('right'), true):post()
    hs.eventtap.event.newKeyEvent({'cmd', 'shift'}, string.lower('right'), false):post()
    hs.eventtap.event.newKeyEvent({}, string.lower('delete'), true):post()
    hs.eventtap.event.newKeyEvent({}, string.lower('delete'), false):post()
end
local remapCtrlK = hs.hotkey.bind({'ctrl'}, '.', deleteToEndOfLine, nil, deleteToEndOfLine)
