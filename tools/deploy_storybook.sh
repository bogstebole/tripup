#!/bin/zsh
# Builds Storybook and puts it on Vercel (project "tripup-storybook"): the component library for reviewers. Like
# deploy_web.sh, the build is copied to a folder outside the repo first, so Vercel's .vercel link file never lands in
# git. Static files only: Vercel doesn't build anything.
#
#   tools/deploy_storybook.sh            (production)
#   tools/deploy_storybook.sh --preview  (a preview URL, production stays as it is)
set -e
ROOT=${0:A:h:h}
OUT=$HOME/Library/Caches/tripup-app/vercel/tripup-storybook
PROD=--prod
[[ $1 == --preview ]] && PROD=

cd $ROOT/storybook
npm run build-storybook
mkdir -p $OUT
rsync -a --delete --exclude .vercel dist/ $OUT/
cd $OUT
npx --yes vercel@65.2.0 deploy $PROD --yes
