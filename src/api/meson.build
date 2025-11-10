api_base_deps = [
  dependency('gee-0.8'),
  dependency('gio-2.0'),
  dependency('json-glib-1.0'),
  dependency('libsoup-3.0'),
]

api_base_vala_args = [
  '--abi-stability',
  '--hide-internal',
  '--target-glib', '2.76',
  '--vapidir', meson.current_source_dir() / 'lib',
]

api_base_sources = files(
  'lib/session/header.vala',
  'lib/session/parameter.vala',
  'lib/session/post-content.vala',
  'lib/session/request.vala',
  'lib/session/session.vala',
  'lib/data-object.vala',
  'lib/enums.vala',
  'lib/errors.vala',
  'lib/jsoner.vala',
  'lib/utils.vala',
)

api_base_lib = static_library(
  'cassette-api-base',
  api_base_sources,
  dependencies: api_base_deps,
  vala_args: api_base_vala_args,
  vala_header: 'libapi-base-4.h',
  vala_vapi: 'libapi-base-4.vapi',
  vala_gir: 'ApiBase-4.gir',
  install: false,
)

libapi_base_dep = declare_dependency(
  link_with: api_base_lib,
  include_directories: [
    include_directories('.'),
    include_directories('lib'),
  ],
  dependencies: api_base_deps
)

meson.override_dependency('libapi-base-4', libapi_base_dep)
