#!/usr/bin/env bash

set -ex

ensure_docker_running() {
  if docker info >/dev/null 2>&1; then
    return
  fi

  echo "Docker daemon not reachable, attempting to start it..."

  if command -v colima >/dev/null 2>&1; then
    colima start
  elif [ -d "/Applications/Docker.app" ]; then
    open -a Docker
  else
    echo "Could not find colima or Docker.app to start the Docker daemon. Please start Docker manually." >&2
    exit 1
  fi

  echo "Waiting for Docker daemon to become available..."
  for _ in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then
      echo "Docker daemon is up."
      return
    fi
    sleep 2
  done

  echo "Timed out waiting for the Docker daemon to start." >&2
  exit 1
}

ensure_docker_running

for i in emulator-run-cmd install-sdk; do
  echo "=== Processing $i ==="
  cd $i
  docker run -t -v $(pwd):/opt/app -w /opt/app node:24 bash -c 'npm install && npm audit fix && npm run build && npm prune --production'
  git add -f node_modules
  git add -f package-lock.json
  git add -f lib || echo "$1 lib directory not found, skipping"
  cd ..
done

git checkout -b release-$(git rev-list HEAD --count)
git commit -m "Add output of ./prepare-release-local.sh" || echo "Nothing to commit"
git reset --hard
git status
echo "Successfully prepared for release. Please review the changes and push the branch to GitHub."
