# ![icon](data/icons/io.github.jeremypw.bulk-renamer-48.svg) Bulk-renamer
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

Bulk file renamer providing a contractor plugin for Pantheon Files, the elementaryos file browser.
It may also be used as a stand-alone app or from the commandline.

The starting point may either be the original filename or a constant basename.
The starting point may be modified by -

* adding constant text
* adding a number sequence with a chosen start number and number of digits
* adding a letter sequence with chosen start letters
* adding a chosen date with or without a time

In each case the added characters may be prepended, appended, or may replace an existing character sequence.
When prepending or appending, an arbitrary separator may be specified.

Multiple such modifications may be made.

The order in which the files are modified may be -

* by name
* by creation date
* by modification date

In each case the order may be reversed.

The file extension is usually excluded from renaming but there is an option to include it in replacement modifications.

The renaming may be undone if the app has not been closed or reconfigured in the meantime.

The modification settings are saved and restored on closing and opening the app.

A contractor is provided for the elementaryos Files app so it can be used from the selection context menu.

Files can also be drag/dropped into the app for renaming or chosen with a FileChooser dialog.

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
io.github.jeremypw.bulk-renamer [OPTIONS] [FILES]
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


