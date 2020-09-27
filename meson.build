project(
    'io.github.jeremypw.bulk-renamer', 'vala', 'c',
    meson_version : '>= 0.46',
    version: '1.0.0'
)

i18n = import('i18n')

add_project_arguments('-DGETTEXT_PACKAGE="io.github.jeremypw.bulk-renamer"', language:'c')

core_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0')
]

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('src')
subdir ('po')
