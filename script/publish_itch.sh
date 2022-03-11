SCRIPT_PATH=`readlink -f "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`

cd "$SCRIPT_DIR"

source config.sh
source ../cred/itch_username.sh

BUILDS="$BUILDS license:license"

cd ../build
for BUILD_TARGET in $BUILDS ; do
    BUILD=`echo "$BUILD_TARGET" | cut -d: -f1`
    echo "Publishing $BUILD"
    butler -i ../cred/itch.cred push $GAME-$BUILD $ACCOUNT/$GAME:$BUILD --userversion-file $GAME-$BUILD/version.txt 
done
