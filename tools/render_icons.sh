#!/bin/zsh
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
list=($@); [[ ${#list} -eq 0 ]] && list=(tram dinner stay activity)
for i in $list; do
  "$CH" --headless=new --user-data-dir="/private/tmp/claude-501/-Users-bogste-Documents-Projects-Personal-Bending-Spoon-Test-Task/a17cf25d-7d06-4373-882a-47056c330e48/scratchpad/chrome-prof" --use-angle=swiftshader --enable-unsafe-swiftshader --hide-scrollbars --default-background-color=00000000 --window-size=1024,1024 --virtual-time-budget=8000 --screenshot="/private/tmp/claude-501/-Users-bogste-Documents-Projects-Personal-Bending-Spoon-Test-Task/a17cf25d-7d06-4373-882a-47056c330e48/scratchpad/icons3d/out/$i.png" "file:///private/tmp/claude-501/-Users-bogste-Documents-Projects-Personal-Bending-Spoon-Test-Task/a17cf25d-7d06-4373-882a-47056c330e48/scratchpad/icons3d/icons.html?icon=$i" >/dev/null 2>&1
  echo "$i: $(ls -la /private/tmp/claude-501/-Users-bogste-Documents-Projects-Personal-Bending-Spoon-Test-Task/a17cf25d-7d06-4373-882a-47056c330e48/scratchpad/icons3d/out/$i.png 2>/dev/null | awk '{print $5}')"
done
