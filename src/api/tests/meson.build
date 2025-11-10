test('Test Jsoner',
  executable('jsoner-test',
    sources: ['jsoner-test.vala'],
    dependencies: [dependencies, lib_dep],
  )
)

if get_option('run_net_tests')
  test('Test SoupWrapper',
    executable('session-test',
      sources: ['session-test.vala'],
      dependencies: [dependencies, lib_dep],
    ),
    is_parallel: true,
    timeout: 9000
  )
endif
