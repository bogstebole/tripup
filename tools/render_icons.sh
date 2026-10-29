#!/bin/zsh
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W="${ICONS_WORK:-/tmp/tripup-icons}"
list=($@); [[ ${#list} -eq 0 ]] && list=(tram dinner stay activity)
for i in $list; do
  "$CH" --headless=new --user-data-dir="$W/chrome-prof" --use-angle=swiftshader --enable-unsafe-swiftshader --hide-scrollbars --default-background-color=00000000 --window-size=1024,1024 --virtual-time-budget=8000 --screenshot="$W/icons3d/out/$i.png" "file://$W/icons3d/icons.html?icon=$i" >/dev/null 2>&1
  echo "$i: $(ls -la $W/icons3d/out/$i.png 2>/dev/null | awk '{print $5}')"
done
