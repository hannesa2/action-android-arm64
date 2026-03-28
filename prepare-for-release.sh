#!/usr/bin/env bash

set -ex

for i in emulator-run-cmd install-sdk; do
  echo "=== Processing $i ==="
  cd $i
  docker run -t -v $(pwd):/opt/app -w /opt/app node:24 bash -c 'npm install && npm audit fix && npm run build && npm prune --production'
  git add -f node_modules
  git add -f lib || echo "$1 lib directory not found, skipping"
  cd ..
done

git checkout -b release-$(git rev-list HEAD --count)
git commit -m "Add output of ./prepare-for-release.sh"
git reset --hard
git status
echo "Successfully prepared for release. Please review the changes and push the branch to GitHub."
