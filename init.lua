hs.notify.new({title="Hammerspoon", informativeText="started"}):send()

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.notify.new({title="Hammerspoon", informativeText="Config reloaded"}):send()
  hs.reload()
end)

-- hs.loadSpoon("SpeedMenu")
-- hs.loadSpoon("WMover")
hs.loadSpoon("CMeters")

