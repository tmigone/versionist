#!/bin/sh -l
set -e

# Ensure we have a repo.yml file
if [ ! -f repo.yml ]; then
  echo "repo.yml not found, creating generic..."
    echo "type: generic" > repo.yml
fi

# Run versionist
balena-versionist

# Get version
if [[ -f "VERSION" ]]; then
  VERSION="v$(cat VERSION)"
elif [[ -f "package.json" ]]; then
  VERSION="v$(jq -r .version package.json)"
else
  echo "No VERSION or package.json file to get version from."
  exit 1
fi

# Commit and push changes
git config --local user.email "$INPUT_GITHUB_EMAIL"
git config --local user.name "$INPUT_GITHUB_USERNAME"
git add .
git commit -m "$VERSION"
git tag -a "$VERSION" -m "$VERSION"
git push "https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" --follow-tags