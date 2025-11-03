non_quoted_conf = configuration_data()
non_quoted_conf.set('APP_ID', app_id)
non_quoted_conf.set('APP_ID_RELEVANT', app_id_relevant)
non_quoted_conf.set('HOMEPAGE', 'https://gitlab.gnome.org/Rirusha/Cassette')
non_quoted_conf.set('BUGTRACKER', 'https://gitlab.gnome.org/Rirusha/Cassette/-/issues')
non_quoted_conf.set('HELP', 'https://t.me/CassetteGNOME_Discussion')

desktop_file = i18n.merge_file(
  input: configure_file(
    output: app_id_relevant + '.desktop.in',
    input: app_id_relevant + '.desktop.in.in',
    configuration: non_quoted_conf),
  output: app_id_relevant + '.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'applications'
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

appstream_file = i18n.merge_file(
  input: configure_file(
    output: app_id_relevant + '.metainfo.xml.in',
    input: app_id_relevant + '.metainfo.xml.in.in',
    configuration: non_quoted_conf),
  output: app_id_relevant + '.metainfo.xml',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'metainfo'
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test('Validate appstream file', appstreamcli, args: ['validate', appstream_file])
endif

install_data(app_id + '.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas'
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file',
  compile_schemas,
  args: ['--strict', '--dry-run', meson.current_source_dir()])
  
  # Compile schemas in build directory for local development
  schema_src_file = meson.current_source_dir() / (app_id + '.gschema.xml')
  schema_build_file = configure_file(
    input: schema_src_file,
    output: app_id + '.gschema.xml',
    copy: true
  )
  
  # Compile schemas during build for development
  # Create a wrapper script to handle directory creation and compilation
  compile_script = find_program('sh')
  schema_build_dir = meson.current_build_dir() / 'glib-2.0' / 'schemas'
  
  custom_target('compile-schemas-build',
    input: schema_build_file,
    output: 'gschemas.compiled',
    command: [
      compile_script, '-c',
      'mkdir -p "@0@" && cp "@INPUT@" "@0@" && "@1@" "@0@"'.format(
        schema_build_dir,
        compile_schemas.full_path()
      )
    ],
    build_by_default: true,
    install: false,
  )
endif

blueprints = custom_target('blueprints',
  input: files(
    'ui/webkit/webkit-auth.blp',
    'ui/auth.blp',
    'ui/loadable.blp',
    'ui/main-content.blp',
    'ui/main-view.blp',
    'ui/base-view.blp',
    'ui/cant-show-view.blp',
    'ui/playlists-view.blp',
    'ui/save-stack.blp',
    'ui/cover-image.blp',
    'ui/playlist-micro.blp',
    'ui/playlist-create-button.blp',
    'ui/custom-button.blp',
    'ui/custom-menu-button.blp',
    'ui/menu-dialog.blp',
    'ui/shrinkable-bin.blp',
    'ui/info-marks.blp',
    'ui/track-info-panel.blp',
    'ui/track-carousel.blp',
    'ui/player-bar.blp',
    'ui/cache-indicator.blp',
    'ui/sidebar.blp',
    'ui/shortcuts-window.blp',
    'ui/window.blp',
    'ui/lyrics-line.blp',
    'ui/lyrics-panel.blp',
    'ui/loadable-widget.blp',
    'ui/narrow-toggle-button.blp',
    'ui/track-placeholder.blp',
    'ui/track-list.blp',
    'ui/track-info.blp',
    'ui/player-queue.blp',
    'ui/wave-settings.blp',
    'ui/track-base-content.blp',
    'ui/track-default-content.blp',
    'ui/track-queue-content.blp',
    'ui/action-card-custom.blp',
    'ui/action-card-station.blp',
    'ui/playlist-choose-dialog.blp',
    'ui/playlist-row.blp',
    'ui/headered-scrolled-window.blp',
    'ui/stations-view.blp',
    'ui/devel-view.blp',
    'ui/search-view.blp',
    'ui/account-info-dialog.blp',
    'ui/no-plus-dialog.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

gres = configure_file(
  output: app_id + '.gresource.xml',
  input: app_id + '.gresource.xml.in',
  configuration: non_quoted_conf
)

resources = gnome.compile_resources(
  'cassette-resources',
  gres,
  source_dir: meson.current_build_dir(),
  dependencies: blueprints,
  c_name: 'cassette'
)

subdir('icons')
