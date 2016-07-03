# === Luakit Makefile Configuration ==========================================

# Compile/link options.
CC         ?= gcc
CFLAGS     += -std=gnu99 -ggdb -W -Wall -Wextra
LDFLAGS    +=
CPPFLAGS   +=

# Get current luakit version.
VERSION    ?= $(shell ./build-utils/getversion.sh)
CPPFLAGS   += -DVERSION=\"$(VERSION)\"

# === Default build options ==================================================

DEVELOPMENT_PATHS ?= 1
USE_LUAJIT        ?= 1
USE_UNIQUE        ?= 1

# === Paths ==================================================================

PREFIX     ?= /usr/local
MANPREFIX  ?= $(PREFIX)/share/man
DOCDIR     ?= $(PREFIX)/share/luakit/docs

INSTALLDIR := $(DESTDIR)$(PREFIX)
MANPREFIX  := $(DESTDIR)$(MANPREFIX)
DOCDIR     := $(DESTDIR)$(DOCDIR)

# Should luakit be built to load relative config paths (./lib ./config) ?
# (Useful when running luakit from it's source directory, disable otherwise).
ifneq ($(DEVELOPMENT_PATHS),0)
	CPPFLAGS += -DDEVELOPMENT_PATHS
endif

# === Platform specific ======================================================

uname_s := $(shell uname -s)

# Mac OSX
ifeq ($(uname_s),Darwin)
	LINKER_EXPORT_DYNAMIC = 0
endif

# Some systems need the --export-dynamic linker option to load other
# dynamically linked C Lua modules (for example lua-filesystem).
ifneq ($(LINKER_EXPORT_DYNAMIC),0)
	LDFLAGS += -Wl,--export-dynamic
endif

# === Lua package name detection =============================================

LUA_PKG_NAMES += lua-5.1 lua5.1 lua51

# Force linking against Lua's Just-In-Time compiler.
# See http://luajit.org/ for more information.
ifeq ($(USE_LUAJIT),1)
	LUA_PKG_NAME  := luajit
else
# User hasn't specificed, use LuaJIT if we can find it.
ifneq ($(USE_LUAJIT),0)
	LUA_PKG_NAMES := luajit $(LUA_PKG_NAMES)
endif
endif

# Search for Lua package name if not forced by user.
ifeq ($(LUA_PKG_NAME),)
LUA_PKG_NAME = $(shell sh -c '(for name in $(LUA_PKG_NAMES); do \
	       pkg-config --exists $$name && echo $$name; done) | head -n 1')
endif

# === Required build packages ================================================

# Packages required to build luakit.
PKGS += gtk+-3.0
PKGS += gthread-2.0
CPPFLAGS += -DWITH_WEBKIT2
PKGS += webkit2gtk-4.0
PKGS += sqlite3
PKGS += $(LUA_PKG_NAME)

# For systems using older WebKit-GTK versions which bundle JavaScriptCore
# within the WebKit-GTK package.
ifneq ($(NO_JAVASCRIPTCORE),1)
	PKGS += javascriptcoregtk-4.0
endif

# Build luakit with single instance support?
ifneq ($(USE_UNIQUE),0)
	CPPFLAGS += -DWITH_UNIQUE
endif

# Check user has correct packages installed (and found by pkg-config).
PKGS_OK := $(shell pkg-config --print-errors --exists $(PKGS) && echo 1)
ifneq ($(PKGS_OK),1)
	$(error Cannot find required package(s\) to build luakit. Please \
	check you have the above packages installed and try again.)
endif

# Add pkg-config options to compile flags.
CFLAGS  += $(shell pkg-config --cflags $(PKGS))
CFLAGS  += -I./

# Add pkg-config options to linker flags.
LDFLAGS += $(shell pkg-config --libs $(PKGS))
