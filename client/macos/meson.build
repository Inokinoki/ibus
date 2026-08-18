macos_im_deps = [
  ibus_dep,
  glib_dep,
  gobject_dep,
  gio_dep,
  dependency('appleframeworks', modules: [
    'Foundation',
    'AppKit',
    'Cocoa',
    'Carbon',
    'InputMethodKit',
    'CoreFoundation',
  ]),
]

executable('ibus-macos',
  files(
    'main.m',
    'ibusimcontroller.m',
    'keymap.m',
    'glibrunloop.m',
  ),
  dependencies: macos_im_deps,
  include_directories: config_h_inc,
  objc_args: [
    '-fobjc-arc',
  ],
  install: true,
  install_dir: get_option('libexecdir') / 'IBus.app' / 'Contents' / 'MacOS',
)

configure_file(
  input: 'Info.plist.in',
  output: '@BASENAME@',
  configuration: {
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: get_option('libexecdir') / 'IBus.app' / 'Contents',
)
