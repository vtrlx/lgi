#
# Makefile for compiling LuaGObject core module in standard-Lua variant
#
# Author: Pavel Holejsovsky <pavel.holejsovsky@gmail.com>
# License: MIT
#

PREFIX = /usr/local
HOST_OS = $(shell uname -s | tr A-Z a-z)
LUA_VERSION=5.1
LUA_LIBDIR = $(PREFIX)/lib/lua/$(LUA_VERSION)
LUA_SHAREDIR = $(PREFIX)/share/lua/$(LUA_VERSION)

PKG_CONFIG ?= pkg-config
GINAME = girepository-2.0
PKGS = $(GINAME) gmodule-2.0 libffi
VERSION_FILE = version.lua

LUA_LIB = -llua

ifneq ($(filter cygwin% msys% mingw%, $(HOST_OS)),)
CORE = lua_gobject_core.dll
LIBFLAG = -shared
LIBS += $(LUA_LIB)
else
ifeq ($(HOST_OS),darwin)
CORE = lua_gobject_core.so
LIBFLAG = -bundle -undefined dynamic_lookup
CCSHARED = -fno-common
GOBJECT_INTROSPECTION_LIBDIR = $(shell $(PKG_CONFIG) --variable=libdir $(GINAME))
else
CORE = lua_gobject_core.so
LIBFLAG = -shared
CCSHARED = -fPIC
endif
endif

OBJS = buffer.o callable.o core.o gi.o marshal.o object.o record.o

ifndef CFLAGS
ifndef COPTFLAGS
CFLAGS = -Wall -Wextra -O2 -g
endif
endif
ifeq ($(HOST_OS),darwin)
CFLAGS += -DGOBJECT_INTROSPECTION_LIBDIR=\"$(GOBJECT_INTROSPECTION_LIBDIR)\"
endif
ALL_CFLAGS = $(CCSHARED) $(COPTFLAGS) $(LUA_CFLAGS) $(shell $(PKG_CONFIG) --cflags $(PKGS)) $(CFLAGS)
LIBS += $(shell $(PKG_CONFIG) --libs $(PKGS))
ALL_LDFLAGS = $(LIBFLAG) $(LDFLAGS)
DEPCHECK = .depcheck

# Precondition check
$(DEPCHECK) : Makefile
	$(PKG_CONFIG) --exists '$(GINAME) >= 2.80.0' --print-errors
	touch $@

.PHONY : all clean install

all : $(CORE) $(VERSION_FILE)
clean :
	rm -f $(CORE) $(OBJS)

%.o : %.c
	$(CC) $(CPPFLAGS) $(ALL_CFLAGS) -c -o $@ $<

$(CORE) : $(OBJS)
	$(CC) $(ALL_LDFLAGS) -o $@ $(OBJS) $(LIBS)

$(VERSION_FILE) : Makefile ../Makefile
	echo "return '$(VERSION)'" > $@

buffer.o : buffer.c lua_gobject.h $(DEPCHECK)
callable.o : callable.c lua_gobject.h $(DEPCHECK)
core.o : core.c lua_gobject.h $(DEPCHECK)
gi.o : gi.c lua_gobject.h $(DEPCHECK)
marshal.o : marshal.c lua_gobject.h $(DEPCHECK)
object.o : object.c lua_gobject.h $(DEPCHECK)
record.o : record.c lua_gobject.h $(DEPCHECK)

OVERRIDES = $(wildcard override/*.lua)
CORESOURCES = $(wildcard *.lua)

install : $(CORE) $(VERSION_FILE)
	mkdir -p $(DESTDIR)$(LUA_LIBDIR)/LuaGObject
	cp $(CORE) $(DESTDIR)$(LUA_LIBDIR)/LuaGObject
	mkdir -p $(DESTDIR)$(LUA_SHAREDIR)
	cp ../LuaGObject.lua $(DESTDIR)$(LUA_SHAREDIR)
	mkdir -p $(DESTDIR)$(LUA_SHAREDIR)/LuaGObject
	cp $(CORESOURCES) $(DESTDIR)$(LUA_SHAREDIR)/LuaGObject
	mkdir -p $(DESTDIR)$(LUA_SHAREDIR)/LuaGObject/override
	cp $(OVERRIDES) $(DESTDIR)$(LUA_SHAREDIR)/LuaGObject/override
