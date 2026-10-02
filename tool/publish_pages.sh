#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
lumen_repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
lumen_project=${lumen_repo#*/}
lumen_flutter=${LUMEN_FLUTTER:-flutter}

"$lumen_flutter" build web --release --no-web-resources-cdn --base-href "/${lumen_project}/"
cp docs/research.html build/web/research.html
touch build/web/.nojekyll
node tool/cache_web.mjs

git fetch origin gh-pages
lumen_stage=$(mktemp -d "${TMPDIR:-/tmp}/lumen-pages.XXXXXX")
trap 'git worktree remove --force "$lumen_stage" >/dev/null 2>&1 || rmdir "$lumen_stage" 2>/dev/null || true' EXIT
git worktree add --detach "$lumen_stage" FETCH_HEAD
git -C "$lumen_stage" rm -r --quiet --ignore-unmatch .
cp -R build/web/. "$lumen_stage/"
git -C "$lumen_stage" add --all
if git -C "$lumen_stage" diff --cached --quiet; then
  echo 'The published build is already up to date.'
else
  git -C "$lumen_stage" commit -m "Publish Lumen from $(git rev-parse --short HEAD)"
  git -C "$lumen_stage" push origin HEAD:refs/heads/gh-pages
fi
echo "GitHub Pages will publish this build shortly."
