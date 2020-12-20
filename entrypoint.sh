#!/bin/bash
set -e

# get_version: gets the current project version based on repository files. File priority is:
# - VERSION file
# - package.json file
# - defaults to v0.0.1 if previous files not present
function get_version () {
  local VERSION=v0.0.1

  if [[ -f VERSION ]]; then
    VERSION="v$(cat VERSION)"
  elif [[ -f package.json ]]; then
    VERSION="v$(jq -r .version package.json)"
  fi

  echo "$VERSION"
}

# check_repo_yml: creates repo.yml file if not present, sets the repo type to 'generic'
function check_repo_yml () {
  if [[ ! -f repo.yml ]]; then
    echo "No repo.yml found, initializing as generic..."
    echo "type: generic" > repo.yml
  fi
}

# get_repo_type: gets the repository type from repo.yml
function get_repo_type () {
  local REPO_TYPE=generic

  if [[ -f repo.yml ]]; then
    REPO_TYPE="$(yq r repo.yml type)"
    REPO_TYPE=${REPO_TYPE:-generic}
  fi

  echo "$REPO_TYPE"
}

# run_versionist: run balena_versionist
function run_versionist () {
  local CURRENT_VERSION=$(get_version)

  echo "Running balena-versionist..."
  echo "- Current version: $CURRENT_VERSION"

  # Create annotated tag for current version if it does not exist
  local CHECK_TAG_EXISTS=$(git tag | grep "$CURRENT_VERSION")
  if [[ -z "$CHECK_TAG_EXISTS" ]]; then
    echo "- Tag for $CURRENT_VERSION not found. Creating it..."
    git tag -a "$CURRENT_VERSION" -m "$CURRENT_VERSION"
  fi

  # Bail if there are no changes with "Change-type" footer
  local CHECK_CHANGE_TYPE=$(git log "$CURRENT_VERSION"..HEAD | grep "Change-type")
  if [[ -z "$CHECK_CHANGE_TYPE" ]]; then
    echo "- No commits were annotated with a change type since version $CURRENT_VERSION. Exiting..."
    exit 0
  fi

  # Run versionist
  balena-versionist
  local NEW_VERSION=$(get_version)

  echo "- New version: $NEW_VERSION"

  # Commit and push changes
  git config --local user.email "$INPUT_GITHUB_EMAIL"
  git config --local user.name "$INPUT_GITHUB_USERNAME"
  git add .
  git commit -m "$NEW_VERSION"
  git tag -a "$NEW_VERSION" -m "$NEW_VERSION"
  if [[ -z $DRY_RUN ]]; then
    git push "${REPO_URL}" HEAD:${INPUT_BRANCH} --follow-tags
  fi
  
}

# run_npm_publish: Publish package to NPM if repo type is 'node' and a NPM token was provided.
function run_npm_publish () {
  local REPO_TYPE=$(get_repo_type)
  if [[ "$REPO_TYPE" == 'node' && -n "$INPUT_NPM_TOKEN" ]]; then
    echo "//registry.npmjs.org/:_authToken=${INPUT_NPM_TOKEN}" > .npmrc
    echo "unsafe-perm = true" >> .npmrc
    echo "Publishing to NPM..."
    echo "- Publishing as: "$(npm whoami)
    echo "- Access: "$INPUT_NPM_ACCESS
    npm install
    npm publish --access $INPUT_NPM_ACCESS $DRY_RUN
  fi
}

# Defaults
INPUT_BRANCH=${INPUT_BRANCH:-master}
INPUT_NPM_ACCESS=${INPUT_NPM_ACCESS:-public}
REPO_URL="https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# development: Dry run when running in development
if [[ $GITHUB_ACTOR == "nektos/act" ]]; then
  DRY_RUN="--dry-run"
fi

# Initialize
check_repo_yml

echo "--- Versionist ---"
[[ -n "$DRY_RUN" ]] && echo "Running in dry run mode: no actions will be commited."
echo "Current version: $(get_version)"
echo "Repository type: $(get_repo_type)"

run_versionist
run_npm_publish