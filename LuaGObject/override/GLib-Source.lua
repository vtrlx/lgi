------------------------------------------------------------------------------
--
--  LuaGObject GLib Source support
--
--  Copyright (c) 2015 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local type, setmetatable, pairs = type, setmetatable, pairs

local LuaGObject = require 'LuaGObject'
local core = require 'LuaGObject.core'
local gi = core.gi
local component = require 'LuaGObject.component'
local record = require 'LuaGObject.record'
local ffi = require 'LuaGObject.ffi'
local ti = ffi.types

local GLib = LuaGObject.GLib
local Source = GLib.Source
local SourceFuncs = GLib.SourceFuncs

SourceFuncs._field.prepare = {
   name = 'prepare',
   offset = SourceFuncs._field.prepare.offset,
   ret = ti.boolean, Source, { ti.int, dir = 'out' }
}
local source_new = Source._new
function Source:_new(funcs)
   if type(funcs) == 'table' then
      funcs = SourceFuncs(funcs)
   end
   function funcs.finalize(source)
      funcs = nil
   end
   return source_new(self, funcs, Source._size)
end
