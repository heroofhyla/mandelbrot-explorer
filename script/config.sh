# This file defines the project name and all the available builds. Builds for
# Linux, web, and Windows are included by default, but feel free add or remove
# entries based on your target platform.

# Username of your itch.io account.
ACCOUNT="change-me"

# Name of your game as it appears in the itch.io slug. Will also be used when
# naming build folders.
GAME="change-me"

# Space-separated list of builds. Each entry is an itch.io upload channel name
# followed by a colon, followed by the name of the game executable file.
BUILDS="win32:$GAME.exe win64:$GAME.exe web:index.html linux32:$GAME.x86 linux64:$GAME.x86_64"

