#!/bin/sh -l
set -e

function get_version () {
  # Get version
  if [[ -f "VERSION" ]]; then
    VERSION="v$(cat VERSION)"
  elif [[ -f "package.json" ]]; then
    VERSION="v$(jq -r .version package.json)"
  else
    echo "No VERSION or package.json file to get version from."
    exit 1
  fi
}

# Ensure we have a repo.yml file
if [[ ! -f package.json && ! -f repo.yml ]]; then
  echo "No package.json or repo.yml found, creating generic type project..."
  echo "type: generic" > repo.yml
fi

get_version
echo "Current version: "$VERSION

# Run versionist
balena-versionist

get_version
echo "New version:"$VERSION

# # Commit and push changes
# git config --local user.email "$INPUT_GITHUB_EMAIL"
# git config --local user.name "$INPUT_GITHUB_USERNAME"
# git add .
# git commit -m "$VERSION"
# git tag -a "$VERSION" -m "$VERSION"
# git push "https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" HEAD:master --follow-tags

# Push to NPM if a token was provided
# npm publish