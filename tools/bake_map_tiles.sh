#!/bin/zsh
# Bakes the Lisbon map tiles the Android app ships (app/assets/map/tiles/): runs app/perf/bake_tiles.dart on the
# Android emulator (or a phone), which draws each tile with the app's own tile code, then pulls the PNGs and writes
# them as WebP (quality 95: about 1/255 from the PNG on average, a third of the size of lossless) with the index (the
# style's hash and the tile names). Run it again after changing app/assets/map/style-google.json; until then the app
# ignores the old tiles and draws every tile on the phone.
#
#   tools/bake_map_tiles.sh [device]       (default: the only device adb sees)
set -e
ROOT=${0:A:h:h}
APP=$ROOT/app
SDK=${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}
ADB=$SDK/platform-tools/adb
DEVICE=${1:-$($ADB devices | awk 'NR==2 {print $1}')}
export JAVA_HOME=${JAVA_HOME:-/opt/homebrew/opt/openjdk@21} ANDROID_HOME=$SDK
OUT=$(mktemp -d)

cd $APP
flutter build apk --profile --no-tree-shake-icons --target-platform android-arm64 -t perf/bake_tiles.dart
$ADB -s $DEVICE install -r build/app/outputs/flutter-apk/app-profile.apk
$ADB -s $DEVICE shell am force-stop com.bogste.tripup
$ADB -s $DEVICE logcat -c
$ADB -s $DEVICE shell am start -n com.bogste.tripup/.MainActivity >/dev/null
echo "Baking on $DEVICE..."
until $ADB -s $DEVICE logcat -d -v raw -s flutter:I | grep -q "BAKE DONE"; do sleep 5; done
$ADB -s $DEVICE pull /sdcard/Android/data/com.bogste.tripup/files/baked $OUT >/dev/null

rm -f $APP/assets/map/tiles/*.webp(N)
for png in $OUT/baked/*.png; do
  cwebp -quiet -q 95 -m 6 -sharp_yuv $png -o $APP/assets/map/tiles/${png:t:r}.webp
done
cp $OUT/baked/index.json $APP/assets/map/tiles/index.json
echo "Baked $(ls $APP/assets/map/tiles/*.webp | wc -l | tr -d ' ') tiles, $(du -sh $APP/assets/map/tiles | cut -f1). Reinstall the app (this left the baking build on the device)."
rm -rf $OUT
