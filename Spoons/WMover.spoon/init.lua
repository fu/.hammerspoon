--- === WMover ===
---
--- Windows mover - aka yet another window arranger
---

local obj={}
obj.__index = obj

-- Metadata
obj.name = "WMover"
obj.version = "0.1"
obj.author = "Christian Fufezan <christian@fufezan.net>"
obj.homepage = ""
obj.license = ""

obj.r_state = 50
obj.l_state = 50
obj.u_state = 100
obj.d_state = 100

hs.window.animationDuration = 0


obj.defaultHotkeys = {
  move_left = {{"cmd", "alt", "ctrl"}, "Left"},
  move_right = {{"cmd", "alt", "ctrl"}, "Right"},
  move_up = {{"cmd", "alt", "ctrl"}, "Up"},
  move_down = {{"cmd", "alt", "ctrl"}, "Down"}
}

obj.stepSize = {
  left = 25,
  right = 25,
  up = 50,
  down = 50
}

obj.win_states = {}

-- Internal functions to store/restore the current value of setFrameCorrectness.
local function _setFC()
   obj._savedFC = hs.window.setFrameCorrectness
   hs.window.setFrameCorrectness = obj.use_frame_correctness
end

local function _restoreFC()
   hs.window.setFrameCorrectness = obj._savedFC
end

function obj.moveCurrentWindowToScreen(how, win)
    local movedWin = nil
    _setFC()
    if how == "west" then
      movedWin = win:moveOneScreenWest()
    elseif how == "east" then
      movedWin = win:moveOneScreenEast()
    end
    _restoreFC()
    if movedWin == nil then
      return win
    else
     return movedWin
    end
end


local function _augmentF(f)
  f.u_state = 0
  f.d_state = 0
  f.r_state = 0
  f.l_state = 0
  return f
end

local function _setDefaultState()
  return {
    u_state = 0,
    d_state = 0,
    r_state = 0,
    l_state = 0
  }
end


function obj.resize_window_left()
  local win = hs.window.focusedWindow()
  local win_id = string.format("%i", win:id())

  local wstate = obj.win_states[win_id]

  if wstate == nil then
    wstate = _setDefaultState(wstate)
  end

  wstate.l_state = wstate.l_state + obj.stepSize.left
  if wstate.l_state >= 100 then
    hs.notify.new({title="WM", informativeText='Moving window'})
    wstate.l_state = 0
    win = obj.moveCurrentWindowToScreen("west", win)
  else
    local frame = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    local new_x = max.x
    local new_y = max.y
    local new_w = max.w * wstate.l_state / 100.0
    local new_h = max.h

    frame.x = new_x
    frame.y = new_y
    frame.w = new_w
    frame.h = new_h

    obj.win_states[win_id] = wstate
    win:setFrame(frame)

  end
end




  -- hs.notify.new({title="WM", informativeText=string.format(
  --   "x:%i y:%i w:%i h:%i add:%i",
  --   frame.x,
  --   frame.y,
  --   frame.w,
  --   frame.h,
  --   max.w * wstate.l_state / 100
  -- )}):send()

function obj.resize_window_right()
      local win = hs.window.focusedWindow()
      local win_id = string.format("%i", win:id())
      local moveScreen = false

      local wstate = obj.win_states[win_id]
      if wstate == nil then
        wstate = _setDefaultState(wstate)
      end

      local screen2 = win:screen()
      if wstate.r_state + obj.stepSize.right >= 100 then
        wstate.r_state = obj.stepSize.right
        if screen2:toEast() ~= nil then
          moveScreen = true
        end
      else
        wstate.r_state = wstate.r_state + obj.stepSize.right
      end

      if moveScreen == true then
        win = obj.moveCurrentWindowToScreen("east", win)
      else
        local frame = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        local new_x = max.w * wstate.r_state / 100
        local new_y = max.y
        local new_w = max.w * (1 - wstate.r_state / 100.0)
        local new_h = max.h

        frame.x = new_x
        frame.y = new_y
        frame.w = new_w
        frame.h = new_h

        obj.win_states[win_id] = wstate
        win:setFrame(frame)

      end



      -- hs.notify.new({title="WM", informativeText=string.format(
      --   "x:%i y:%i w:%i h:%i add:%i",
      --   frame.x,
      --   frame.y,
      --   frame.w,
      --   frame.h,
      --   max.w * wstate.r_state / 100
      -- )}):send()

end


function obj.resize_window_up()
      local win = hs.window.focusedWindow()
      local screen = win:screen()
      local max = screen:frame()
      local win_id = string.format("%i", win:id())
      local f = win:frame()

      if obj.win_states[win_id] ~= nil then
        f = obj.win_states[win_id]
      else
        f = _augmentF(f)
      end
      f.u_state = f.u_state + obj.stepSize.up
      if f.u_state > 100 then f.u_state = 0 end
      hs.notify.new({title="WM", informativeText=string.format("%i u_state:%i", win_id, f.u_state)}):send()
      f.h = max.h * f.u_state / 100.0
      f.y = max.y
      obj.win_states[win_id] = f
      win:setFrame(obj.win_states[win_id])
end

function obj.resize_window_down()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    local max = screen:frame()
    local win_id = string.format("%i", win:id())
    local f = win:frame()

    if obj.win_states[win_id] ~= nil then
      f = obj.win_states[win_id]
    else
      f = _augmentF(f)
    end
    f.d_state = f.d_state + obj.stepSize.down
    if f.d_state > 100 then f.d_state = 0 end
    hs.notify.new({title="WM", informativeText=string.format(
      "%i u_state:%i d_state:%i",
      win_id,
      f.u_state,
      f.d_state
    )}):send()
    f.h = max.h * f.d_state / 100
    f.y = max.y + max.h * (1 - f.d_state / 100)
    obj.win_states[win_id] = f
    win:setFrame(obj.win_states[win_id])
end


function obj:init()
    local hotkeyDefinitions = {
      move_left = self.resize_window_left,
      move_right = self.resize_window_right,
      move_up = self.resize_window_up,
      move_down = self.resize_window_down
    }
    -- hs.hotkey.bind(obj.defaultHotkeys.move_left, self.resize_window_left)
   hs.spoons.bindHotkeysToSpec(hotkeyDefinitions, obj.defaultHotkeys)

end

return obj
