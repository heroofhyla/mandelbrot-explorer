# Writes the current version number to version.txt at the root of the
# repository. Also copies version.txt, changes.txt, and license/ into
# ../godot/version_info/ so that they're accessible to in-game scripts.

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
cd "$SCRIPT_DIR"

source config.sh

VERSION_INFO=../godot/version_info/
mkdir -p "$VERSION_INFO"

version=$(git describe --long)

echo "$version" > ../version.txt
cp ../version.txt "$VERSION_INFO/"
cp ../changes.txt "$VERSION_INFO/"
cp -r ../license/ "$VERSION_INFO/"