# This script builds all versions of the game. It outputs both zipped and
# unzipped versions of each build listed in config.sh.

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
cd "$SCRIPT_DIR"

source config.sh

echo "Starting build of $GAME"
echo
echo "Generating version number..."
./update_version.sh
echo "Done"
VERSION_STRING=$(cat "../version.txt")

echo "Version string is:"
echo "$VERSION_STRING"
echo
mkdir -p ../build
cd ../build
for BUILD_TARGET in $BUILDS; do
    BUILD=$(echo "$BUILD_TARGET" | cut -d: -f1)
    BUILD_FILE=$(echo "$BUILD_TARGET" | cut -d: -f2)
    BUILD_DIR="$GAME-$BUILD$SUFFIX"
    echo "Building target '$BUILD'"
    echo
    echo "Making any missing paths..."
    mkdir -p "$BUILD_DIR"
    echo "Done"
    echo 
    echo "Cleaning up any previous build..."
    rm -rf "$BUILD_DIR/"*
    rm -rf "$BUILD_DIR.zip"
    echo "Done"
    echo
    echo "Exporting Godot project..."
    godot --path ../godot --no-window --export "$BUILD" "../build/$BUILD_DIR/$BUILD_FILE"
    echo "Done"
    echo
    echo "Copying version info..."
    cp -r "../license/" "$BUILD_DIR/"
    cp "../version.txt" "$BUILD_DIR/"
    cp "../changes.txt" "$BUILD_DIR/"
    echo "Done"
    echo
    echo "Zipping up..."
    zip -r "$BUILD_DIR.zip" "$BUILD_DIR/"
    echo "Done"
    echo
done
echo "Building standalone license files..."
cd ../build/
mkdir -p "$GAME-license/"
rm -rf "$GAME-license/"*
rm -rf "$GAME-license.zip"
cp -r "../license" "$GAME-license/"
cp "../version.txt" "$GAME-license/"
cp "../changes.txt" "$GAME-license/"
zip -r "$GAME-license" "$GAME-license/"
echo "Done"
echo "Build complete"
