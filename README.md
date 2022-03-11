This is a Mandelbrot Set generator written using the Godot game engine.

It progressively renders each iteration of the set to the screen, with each
thread working on a line at a time.  The number of threads is configurable; my
PC seems to choke if I use more than 4 or 5.

For each pixel, the red and yellow channels represent the real and imaginary
components of the value at that point, for the current iteration. If the
magnitude of the number reaches 4, or if either component reaches NaN, the
number is outside the set. For points outside the set, the blue channel is set
to 128 and the red and green channels represent the number of the first
iteration where the point was calculated to be outside the set. The iteration
count is capped at 256.

Whenever you click the mouse within the image, the display zooms in 8x at the
clicked point and the iterations start over. Floating point errors start to
become very obvious after zooming in a few times, which means this program is
not suitable for deep exploration.

## Building and Publishing

The code should work as-is in Godot. But if you want to build executables or
publish to itch.io using the included scripts, you need to follow some
additional steps.

### itch.io project setup

Create an itch.io project for your game. Leave it private for now. Make a note 
of the project's URL slug (the part of the URL after `itch.io/`), you will need
this later.

Choosing a good slug is important; this name will be used for your executables
as well.

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

The deployment script expects to find itch.io credentials under `creds`.
Execute the following in bash to create these credentials, starting from the
root of the repository and replacing the placeholder with your itch username.

```
mkdir cred
cd cred
echo "ACCOUNT=<your itch.io username goes here>" > itch_username.sh
butler login -i itch.cred
```

A browser window will automatically open to itch.io, prompting you to confirm
that you want to allow access.

Note that this cred directory is listed in .gitignore, so it will not be saved
in your repository. You will need to regenerate it whenever you work on the
project from a different machine.

### Game configuration

Update your game configuration in `scripts/config.shq. Fill in the URL slug for
your game. Take a note of the list of builds as well. Remove any builds you
don't plan to support, and add any new builds you will need.

The build names are in the format `build_preset_name:executable_file_name`. 
You can name the build presets whatever you want; the names you choose here
will be used for the itch.io upload channels and will also be included in the
zip filenames for each platform.

### Commit tagging

As part of the build process, a version number is generated and written to
version.txt, both at the root of the repository and in `godot/version_info/`.
This version number is based on the output of `git describe`, and will fail if
there are no tags in the repository. Make a habit of tagging before building.

### Updating changelog

The file `changes.txt` should be used as a changelog. It is automatically copied
into `godot/version_info/` by the build script.
