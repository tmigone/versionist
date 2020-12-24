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

# check_required_inputs: checks for required inputs, exits if not present
function check_required_inputs () {
  if [[ -z "$DRY_RUN" ]]; then
    if [[ -z "$INPUT_GITHUB_EMAIL" ]]; then
      echo "ERROR: INPUT_GITHUB_EMAIL is required!"
      exit 1
    fi

    if [[ -z "$INPUT_GITHUB_USERNAME" ]]; then
      echo "ERROR: INPUT_GITHUB_USERNAME is required!"
      exit 1
    fi

    if [[ -z "$INPUT_GITHUB_TOKEN" ]]; then
      echo "ERROR: INPUT_GITHUB_TOKEN is required!"
      exit 1
    fi
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
  echo "Current version: $CURRENT_VERSION"

  # Setup GitHub
  git config --local user.email "$INPUT_GITHUB_EMAIL"
  git config --local user.name "$INPUT_GITHUB_USERNAME"

  # Check if there are changes with the "Change-type" footer
  create_tag_if_not_exists "$CURRENT_VERSION"
  local CHECK_CHANGE_TYPE=$(git log "$CURRENT_VERSION"..HEAD | grep "Change-type")
  if [[ -z "$CHECK_CHANGE_TYPE" ]]; then
    echo "No commits were annotated with a change type since version $CURRENT_VERSION. Exiting..."
    exit 0
  fi

  # Run versionist
  balena-versionist
  local NEW_VERSION=$(get_version)
  echo "New version: $NEW_VERSION"

  # Commit and push changes
  git add .
  git commit -m "$NEW_VERSION"
  create_tag_if_not_exists "$NEW_VERSION"
  if [[ -z $DRY_RUN ]]; then
    git push "${REPO_URL}" HEAD:${INPUT_BRANCH} --follow-tags
  fi

  # Set outputs
  echo "::set-output name=version::$(get_version)"
  echo "::set-output name=updated::true"

}

# create_tag_if_not_exists: creates an annotated tag for the given version if it does not exist
function create_tag_if_not_exists () {
  local VERSION=$1
  local CHECK_TAG_EXISTS=$(git tag | grep "$VERSION")
  if [[ -z "$CHECK_TAG_EXISTS" ]]; then
    echo "Tag for $VERSION not found. Creating it..."
    git tag -a "$VERSION" -m "$VERSION"
  fi
}

# Defaults
INPUT_BRANCH=${INPUT_BRANCH:-master}
REPO_URL="https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# development: Dry run when running in development
if [[ $GITHUB_ACTOR == "nektos/act" ]]; then
  DRY_RUN="--dry-run"
fi

# Initialize
check_required_inputs
check_repo_yml

echo "--- Versionist ---"
[[ -n "$DRY_RUN" ]] && echo "Running in dry run mode: no actions will be commited."
echo "Current version: $(get_version)"
echo "Repository type: $(get_repo_type)"
echo "Repository branch: $INPUT_BRANCH"
echo "GitHub user: $INPUT_GITHUB_USERNAME"
echo "GitHub email: $INPUT_GITHUB_EMAIL"
echo "GitHub token: ok!"

echo "::set-output name=version::$(get_version)"
echo "::set-output name=updated::false"

run_versionist