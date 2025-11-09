# Unit tests for Feature 1.1: Help Overlay
# Tests are designed according to instructions/tests.md
#
# NOTE: Full unit test execution requires complete app resources (blueprints, gresources).
# This test verifies the test infrastructure is in place. Full test execution will be
# completed when comprehensive test infrastructure is set up (see Feature 5.1).

if get_option('tests')
  # Simple test that verifies test infrastructure is in place
  # This test doesn't require UI resources - it just checks that the test framework works
  help_overlay_test = executable(
    'help-overlay-test',
    sources: files(
      'unit/help-overlay-test.vala',
      '../src/config.vapi',
    ),
    dependencies: [
      dependency('libadwaita-1'),
      dependency('gtk4'),
      dependency('gio-2.0'),
    ],
    include_directories: config_h_dir,
    c_args: ['-w'],
  )

  test('Help overlay test infrastructure', help_overlay_test)
  
  # Unit test for Feature 1.2: Accessible Names
  accessible_names_test = executable(
    'accessible-names-test',
    sources: files(
      'unit/accessible-names-test.vala',
      '../src/config.vapi',
    ),
    dependencies: [
      dependency('libadwaita-1'),
      dependency('gtk4'),
      dependency('gio-2.0'),
    ],
    include_directories: config_h_dir,
    c_args: ['-w'],
  )
  
  test('Accessible names test infrastructure', accessible_names_test)

  playlist_guards_src = configure_file(
    input: '../src/widgets/views/playlist-guards.vala',
    output: 'playlist-guards.vala',
    copy: true
  )

  playlist_view_test = executable(
    'playlist-view-test',
    sources: [
      'unit/playlist-view-test.vala',
      playlist_guards_src,
      '../src/config.vapi',
    ],
    dependencies: [
      dependency('gio-2.0'),
      dependency('gee-0.8'),
      dependency('libtape-0.2', fallback : ['libtape', 'lib_dep']),
    ],
    include_directories: config_h_dir,
    c_args: ['-w'],
  )

  test('Playlist view guard test', playlist_view_test)

  audio_cache_test = executable(
    'audio-cache-test',
    sources: files(
      'unit/audio-cache-test.vala',
      '../src/config.vapi',
    ),
    dependencies: [
      dependency('gio-2.0'),
      dependency('gee-0.8'),
      dependency('libtape-0.2', fallback : ['libtape', 'lib_dep']),
    ],
    include_directories: config_h_dir,
    c_args: ['-w'],
  )

  test('Audio cache playback decoding', audio_cache_test)
endif

