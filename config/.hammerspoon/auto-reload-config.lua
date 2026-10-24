-- Watch the repository directory even when ~/.hammerspoon is a symlink.
local function reloadConfig(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
      return
    end
  end
end

local configPath = assert(hs.fs.pathToAbsolute(hs.configdir))
local watcher = hs.pathwatcher.new(configPath, reloadConfig):start()
hs.alert.show('Config reloaded')

-- require() retains this object in package.loaded, preventing collection.
return watcher
