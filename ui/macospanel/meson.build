macos_ui_deps = [
  ibus_dep,
  glib_dep,
  gobject_dep,
  gio_dep,
  dependency('appleframeworks', modules: [
    'Foundation',
    'AppKit',
    'Cocoa',
    'CoreFoundation',
  ]),
]

configure_file(
  input: 'macospanel.xml.in',
  output: '@BASENAME@',
  configuration: {
    'VERSION': meson.project_version(),
    'libexecdir': get_option('prefix') / get_option('libexecdir'),
  },
  install: true,
  install_dir: pkgdatadir / 'component',
)

executable('ibus-ui-macos',
  files(
    'main.m',
    'panel.c',
    'candidatewindow.m',
    '../../client/macos/glibrunloop.m',
  ),
  dependencies: macos_ui_deps,
  include_directories: [
    config_h_inc,
    include_directories('.'),
    include_directories('../../client/macos'),
  ],
  objc_args: [
    '-fobjc-arc',
  ],
  install: true,
  install_dir: get_option('libexecdir'),
)
