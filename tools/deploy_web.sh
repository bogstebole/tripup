#!/bin/zsh
# Builds the app for the web and puts it on Vercel (project "tripup", https://tripup-three.vercel.app): the link for
# anyone without the iPhone or Android build. The build is copied to a folder outside the repo first, so Vercel's
# .vercel link file never lands in git. Static files only: Vercel doesn't build anything.
#
#   tools/deploy_web.sh            (production)
#   tools/deploy_web.sh --preview  (a preview URL, production stays as it is)
set -e
ROOT=${0:A:h:h}
OUT=$HOME/Library/Caches/tripup-app/vercel/tripup
PROD=--prod
[[ $1 == --preview ]] && PROD=

cd $ROOT/app
flutter build web --release
mkdir -p $OUT
rsync -a --delete --exclude .vercel build/web/ $OUT/
cd $OUT
npx --yes vercel@65.2.0 deploy $PROD --yes
