local hyperKey = require('hyperKey')
hyperKey:bind({}, "C", function() hs.application.launchOrFocus("Google Chrome") end, nil)
hyperKey:bind({}, "i", function() hs.application.launchOrFocus("iTerm") end, nil)
