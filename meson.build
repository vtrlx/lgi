project('LuaGObject', 'c',
  version: '0.10.0',
  meson_version: '>= 0.50.0',
  default_options: [
    'warning_level=2',
    'buildtype=debugoptimized',
  ],
)

cc = meson.get_compiler('c')
test_c_args = []

if cc.get_id() == 'msvc'
  test_c_args += '-FImsvc_recommended_pragmas.h'
endif

add_project_arguments(cc.get_supported_arguments(test_c_args), language: 'c')

lua_possible_names = [
  'lua',
  'lua5.4', 'lua54',
  'lua5.3', 'lua53',
  'lua5.2', 'lua52',
  'lua5.1', 'lua51',
  'luajit'
]

lua_bin = get_option('lua-bin')
lua_name = get_option('lua-pc')

if lua_name == 'auto'
  lua_found = false

  foreach name : lua_possible_names
    if not lua_found
      lua_dep = dependency(name, required: false)
      lua_found = lua_dep.found()
      lua_name = name
    endif
  endforeach

  if not lua_found
    error('Failed to find lua pkg-config file, you can specify it manually with `-Dlua-pc=lua54`')
  endif

  if lua_bin == 'lua' and lua_name == 'luajit'
    lua_bin = 'luajit'
  endif

else
  lua_dep = dependency(lua_name)
endif

lua_prog = find_program(lua_bin, required: false)
if not lua_prog.found()
  error('Failed to find lua binary, you can specify it manually with `-Dlua-bin=lua54`')
endif

# lua doesn't have an official pkg-config file so we guess off its version
lua_version_split = lua_dep.version().split('.')
lua_abi_version = '@0@.@1@'.format(lua_version_split[0], lua_version_split[1])

# These are defined by the luajit.pc and some distros lua.pc
if lua_dep.type_name() == 'pkgconfig'
  lua_cpath = lua_dep.get_pkgconfig_variable('INSTALL_CMOD',
    define_variable: ['prefix', get_option('prefix')],
    default: join_paths(get_option('libdir'), 'lua', lua_abi_version),
  )
  lua_path = lua_dep.get_pkgconfig_variable('INSTALL_LMOD',
    define_variable: ['prefix', get_option('prefix')],
    default: join_paths(get_option('datadir'), 'lua', lua_abi_version)
  )
else
  lua_cpath = join_paths(get_option('libdir'), 'lua', lua_abi_version)
  lua_path = join_paths(get_option('datadir'), 'lua', lua_abi_version)
endif

gi_dep = dependency('girepository-2.0', version: '>= 2.80')
gi_datadir = gi_dep.get_pkgconfig_variable('gidatadir')

install_data('LuaGObject.lua', install_dir: lua_path)
subdir('LuaGObject')
if get_option('tests')
  subdir('tests')
endif
