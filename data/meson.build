install_data(
    'redub.contract',
    install_dir: join_paths(get_option('datadir'), 'contractor')
)

icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data (
        join_paths('icons', meson.project_name () + '-' + i + '.svg'),
        rename: meson.project_name () + '.svg',
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

install_data (
    join_paths('icons', meson.project_name () + '-48.svg'),
    rename: meson.project_name () + '.svg',
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

i18n.merge_file (
    'desktop',
    input: meson.project_name () + '.desktop.in',
    output: meson.project_name () + '.desktop',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'applications'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'desktop'
)

i18n.merge_file (
    'appdata',
    input: meson.project_name () + '.appdata.xml.in',
    output: meson.project_name () + '.appdata.xml',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'metainfo'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'xml'
)

test (
    'Validate desktop file',
    find_program ('desktop-file-validate'),
    args: join_paths (meson.current_build_dir (),  meson.project_name () + '.desktop')
)

test (
    'Validate appdata file',
    find_program ('appstreamcli'),
    args: ['validate', '--pedantic', join_paths (meson.current_build_dir (), meson.project_name () + '.appdata.xml')]
)