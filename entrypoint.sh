#!/bin/sh -l
set -e

# Helpers
function get_version () {
  # Get version
  if [[ -f VERSION ]]; then
    VERSION="v$(cat VERSION)"
  elif [[ -f package.json ]]; then
    VERSION="v$(jq -r .version package.json)"
  else
    echo "No VERSION or package.json file to get version from."
  fi
}

# Defaults
INPUT_BRANCH=${INPUT_BRANCH:-master}
INPUT_NPM_ACCESS=${INPUT_NPM_ACCESS:-public}
REPO_URL="https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Dry run when running in development
if [[ $GITHUB_ACTOR == "nektos/act" ]]; then
  echo "--- Dry run ---"
  DRY_RUN_OPTION="--dry-run"
fi

# Log current version
get_version
echo "Current version: "$VERSION

# Ensure we have a repo.yml file
if [[ ! -f package.json && ! -f repo.yml ]]; then
  echo "No package.json or repo.yml found, creating generic type project..."
  echo "type: generic" > repo.yml
fi

# Run versionist
balena-versionist

# Log new version
get_version
echo "New version: "$VERSION

# Commit and push changes
git config --local user.email "$INPUT_GITHUB_EMAIL"
git config --local user.name "$INPUT_GITHUB_USERNAME"
git add .
git commit -m "$VERSION"
git tag -a "$VERSION" -m "$VERSION"
if [[ -z $DRY_RUN_OPTION ]]; then
  git push "${REPO_URL}" HEAD:${INPUT_BRANCH} --follow-tags
fi

# Push to NPM if a token was provided
if [[ -n "$INPUT_NPM_TOKEN" ]]; then
  echo "//registry.npmjs.org/:_authToken=${INPUT_NPM_TOKEN}" > .npmrc
  echo "unsafe-perm = true" >> .npmrc
  echo "Publishing to NPM..."
  echo "Publishing as: "$(npm whoami)
  echo "Access: "$INPUT_NPM_ACCESS
  npm publish "--access $INPUT_NPM_ACCESS" $DRY_RUN_OPTION
fi