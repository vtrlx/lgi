set -x
sudo make install LUA_VERSION="${LUA_VERSION}"
xvfb-run -a sh -c 'LD_PRELOAD="${sanitizers}" "$@"' - lua -e '
  Gtk = require("LuaGObject").Gtk
  c = Gtk.Box()
  w = Gtk.Label()
  c:append(w)
  assert(w.parent == c)
  a, b = dofile("LuaGObject/version.lua"), require("LuaGObject.version")
  assert(a == b, string.format("%s == %s", a, b))
'
