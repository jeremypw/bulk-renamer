# ![icon](data/icons/com.github.jeremypw.redub-48.svg) Redub
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

Bulk file renamer providing a contractor plugin for Pantheon Files, the elementaryos file browser.
It may also be used as a stand-alone app or from the commandline.

Currently supports three different rename modes:
* adding numbers to the original name or to a new base.
* appending the date to the original name
* search and replace.

The file extension is excluded from renaming.

![Screenshot](/data/Screenshots/mainwindow.png?raw=true "Screenshot")

### Dependencies
These dependencies must be present before building
 - `valac`
 - `meson`
 - `glib-2.0`
 - `gtk+-3.0`

 You can install these on a Ubuntu-based system by executing this command:

 `sudo apt install valac meson libgtk-3-dev`

### Building
```
meson build --prefix=/usr  --buildtype=release
cd build
ninja
```

### Installing & executing
```
sudo ninja install
```

You will now find that the context menu in Pantheon Files shows an extra entry when more than one file item
has been selected. Clicking on this option results in the renamer window being launched with the selected files
appearing in the "Old Name" list.  You can also lauch the renamer from the command line with:
```
com.github.jeremypw.redub [OPTIONS] [FILES]
```

Current options are:

```
Help Options:
  -h, --help                    Show help options
  --help-all                    Show all help options
  --help-gapplication           Show GApplication options
  --help-gtk                    Show GTK+ Options

Application Options:
  -b, --base-name=BASE NAME     Base name of renamed files
  -c, --sort-by-created         Rename in creation date order
  -m, --sort-by-modified        Rename in modification date order
  -r, --reverse_order           Reverse sort order
  --display=DISPLAY             X display to use

```

###### *This app is based on the work of Vartan Belavejian <https://github.com/VartanBelavejian/ElementaryBulkRenamer>*


