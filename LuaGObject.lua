------------------------------------------------------------------------------
--
--  LuaGOBject Lua-side core.
--
--  Copyright (c) 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

-- This is simple forwarder to real package 'LuaGObject/init.lua'.  Normally,
-- LuaGObject/init.lua could suffice, but this file is needed if ever the user
-- wants to run LGI without installation, as Lua lacks './?/init.lua' in its
-- package search path.

return require 'LuaGObject.init'
