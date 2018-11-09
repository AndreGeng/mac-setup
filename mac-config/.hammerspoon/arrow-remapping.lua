local fireKey = function(configItem)
  return function()
    hs.eventtap.keyStroke(configItem.mapTo.mod, string.lower(configItem.mapTo.key), 20000)
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

  {key='escape', mod={'cmd'}, mapTo = {mod= {'cmd', 'shift'}, key='`'}}
}, function(configItem)
  local arrowRemappings = hs.hotkey.bind(configItem.mod, configItem.key, fireKey(configItem), nil, fireKey(configItem))
end)
