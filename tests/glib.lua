--[[--------------------------------------------------------------------------

  LGI testsuite, GLib test suite.

  Copyright (c) 2013 Pavel Holejsovsky
  Licensed under the MIT license:
  http://www.opensource.org/licenses/mit-license.php

--]]--------------------------------------------------------------------------

local LuaGObject = require 'LuaGObject'

local check = testsuite.check

-- Basic GLib testing
local glib = testsuite.group.new('glib')

function glib.timer()
   local Timer = LuaGObject.GLib.Timer
   check(Timer.new)
   check(Timer.start)
   check(Timer.stop)
   check(Timer.continue)
   check(Timer.elapsed)
   check(Timer.reset)
   check(not Timer.destroy)

   local timer = Timer()
   check(Timer:is_type_of(timer))
   timer = Timer.new()
   check(Timer:is_type_of(timer))

   local el1, ms1 = timer:elapsed()
   check(type(el1) == 'number')
   check(type(ms1) == 'number')

   LuaGObject.GLib.usleep(1000) -- wait one millisecond

   local el2, ms2 = timer:elapsed()
   check(el1 < el2)

   timer:stop()
   el2 = timer:elapsed()
   for i = 1, 1000000 do end
   check(timer:elapsed() == el2)
end

function glib.markup_base()
   local MarkupParser = LuaGObject.GLib.MarkupParser
   local MarkupParseContext = LuaGObject.GLib.MarkupParseContext

   local p = MarkupParser()
   local el, at = {}, {}
   function p.start_element(context, element_name, attrs)
      el[#el + 1] = element_name
      at[#at + 1] = attrs
   end
   function p.end_element(context)
   end
   function p.text(context, text, len)
   end
   function p.passthrough(context, text, len)
   end

   local pc = MarkupParseContext(p, {})
   local ok, err = pc:parse([[
<map>
 <entry key='method' value='printf' />
</map>
]])
   check(ok)
   check(#el == 2)
   check(el[1] == 'map')
   check(el[2] == 'entry')
   check(#at == 2)
   check(not next(at[1]))
   check(at[2].key == 'method')
   check(at[2].value == 'printf')
end

function glib.markup_error1()
   local MarkupParser = LuaGObject.GLib.MarkupParser
   local MarkupParseContext = LuaGObject.GLib.MarkupParseContext

   local saved_err
   local parser = MarkupParser {
      error = function(context, error)
	 saved_err = error
      end,
   }
   local context = MarkupParseContext(parser, 0)
   local ok, err = context:parse('invalid>uh')
   check(not ok)
   check(err:matches(saved_err))
end

function glib.markup_error2()
   local GLib = LuaGObject.GLib
   local MarkupParser = GLib.MarkupParser
   local MarkupParseContext = GLib.MarkupParseContext

   local saved_err
   local parser = MarkupParser {
      error = function(context, error)
	 saved_err = error
      end,
      start_element = function(context, element)
	 error(GLib.MarkupError('UNKNOWN_ELEMENT', 'snafu %d', 1))
      end,
   }
   local context = MarkupParseContext(parser, {})
   local ok, err = context:parse('<e/>')
   check(not ok)
   check(err:matches(GLib.MarkupError, 'UNKNOWN_ELEMENT'))
   check(err.message == 'snafu 1')
   check(saved_err:matches(err))
end

function glib.gsourcefuncs()
   local GLib = LuaGObject.GLib

   local called
   local source_funcs = GLib.SourceFuncs {
      prepare = function(source, timeout)
	 called = source
	 return true, 42
      end
   }

   local source = GLib.Source(source_funcs)
   local res, timeout  = source_funcs.prepare(source)
   check(res == true)
   check(timeout == 42)
   check(called == source)
end

function glib.coroutine_related_crash()
    -- This test does not have a specific assert() or check() call. Instead it
    -- is a regression test: Once upon a time this caused a segmentation fault
    -- due to a use-after-free.

    local glib = require("LuaGObject").GLib
    local mainloop = glib.MainLoop.new()
    coroutine.wrap(function()
	local co = coroutine.running()
	for i=1,100 do
	    glib.timeout_add(glib.PRIORITY_DEFAULT, 0, function()
		coroutine.resume(co)
		return false
	    end)
	    coroutine.yield()
	end
	mainloop:quit()
    end)()
    mainloop:run()
end
