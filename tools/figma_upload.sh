#!/bin/zsh
# usage: figma_upload.sh <list-file>  (each line: <png path>|<submit url>)
while IFS='|' read -r f u; do
  [[ -z "$f" ]] && continue
  code=$(curl -s -o /dev/null -w "%{http_code}" -F "file=@$f;type=image/png" "$u")
  echo "$code ${f:t}"
done < "$1"
