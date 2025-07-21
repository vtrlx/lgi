-------------------------------------------------------------------------------
--
-- LGI GLib Timer support implementation.
--
-- Copyright (c) 2013 Pavel Holejsovsky
-- Licensed under the MIT license:
-- http://www.opensource.org/licenses/mit-license.php
--
-------------------------------------------------------------------------------

local pairs = pairs

local LuaGObject = require 'LuaGObject'
local core = require 'LuaGObject.core'
local record = require 'LuaGObject.record'
local ffi = require 'LuaGObject.ffi'
local ti = ffi.types

local Timer = LuaGObject.GLib.Timer:_resolve(true)

local module = core.gi.GLib.resolve
for name, def in pairs {
   new = { ret = { Timer, xfer = true } },
   elapsed = { ret = ti.double, { Timer }, { ti.ulong, dir = 'out' } },
} do
   local _ = Timer[name]
   def.addr = module['g_timer_' .. name]
   def.name = 'GLib.Timer.' .. name
   Timer[name] = core.callable.new(def)
end

Timer._free = core.gi.GLib.Timer.methods.destroy
Timer._method.destroy = nil
Timer._new = function(_, ...) return Timer.new(...) end
