This repository is a reusable template for a Godot project intended to be
published to https://itch.io.

## Setup

### itch.io project setup

Create an itch.io project for your game. Leave it private for now. Make a note 
of the project's URL slug (the part of the URL after `itch.io/`), you will need
this later.

Choosing a good slug and is important; this name will be used for your 
executables as well.

### Software

You will need the following tools. Other than Rcedit, they must be reachable
from your PATH environment variable so that the build and publish scripts can
find them.

- Git for version control.
- Godot so you can actually make your game.
  - Available from https://godotengine.org/download or from Steam.
  - If you use the Steam version of Godot, make a symlink from 
    `godot.windows.opt.tools.64.exe` to `godot.exe`.
- Butler for uploading to itch.io.
  - Available from https://itchio.itch.io/butler.
- Bash or another compatible shell for running all `.sh` scripts. 
  - Git Bash works fine on Windows.
  - I haven't tested any other alternatives like the Windows Subsystem for 
    Linux.
- Zip for zipping up builds.
  - You probably already have zip if you're on Linux. If not, you can easily
    install it with your distribution's package manager.
  - Git Bash on Windows does not include zip. You can manually install it by
    following the following process (from 
    https://stackoverflow.com/a/55749636/7210209):
    1. Navigate to https://sourceforge.net/projects/gnuwin32/files/zip/3.0/
    2. Download zip-3.0-bin.zip
    3. In the zipped file, in the bin folder, find the file zip.exe.
    4. Extract the file “zip.exe” to your "mingw64" bin folder (for me: 
       C:\Program Files\Git\mingw64\bin)
    5. Navigate to https://sourceforge.net/projects/gnuwin32/files/bzip2/1.0.5/
    6. Download bzip2-1.0.5-bin.zip
    7. In the zipped file, in the bin folder, find the file bzip2.dll
    8. Extract bzip2.dll to your "mingw64" bin folder ( same folder - 
       C:\Program Files\Git\mingw64\bin )
- Rcedit for changing the file icon on your Windows executables.
  - Available from https://github.com/electron/rcedit
  - In Godot, go to Editor -> Editor Settings -> Export -> Windows and point to
    the rcedit executable.

### Itch credentials

The deployment script expects to find an itch.io credentials file at 
`cred/itch.cred`. Execute the following in bash to create these credentials,
starting from the root of the repository.

```
mkdir cred
cd cred
butler login -i itch.cred
```

A browser window will automatically open to itch.io, prompting you to confirm
that you want to allow access.

Note that this credential file is listed in .gitignore, so it will not be saved
in your repository. You will need to regenerate it whenever you work on the
project from a different machine.

### Game configuration

Update your game configuration in scripts/config.sh. Fill in your itch.io
username and the URL slug for your game. Take a note of the list of builds as
well. Remove any builds you don't plan to support, and add any new builds you
will need.

The build names are in the format `build_preset_name:executable_file_name`. 
You can name the build presets whatever you want; the names you choose here
will be used for the itch.io upload channels and will also be included in the
zip filenames for each platform.

### Notes on project structure

This project structure includes an outer directory for all meta information such
as build scripts, credential files, planning documents, etc. The actual Godot
project is inside a subdirectory called "godot".

Inverted directory structures where the meta information is contained within a
subdirectory are also valid.

