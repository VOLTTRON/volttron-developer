#!/bin/env bash

# This script sets up the user environment.
#
# The script will do the following:
#   1. clone each repository in the GIT_REPO_NAMES variable
#      uses GIT_URL, GIT_BRANCH, and GIT_FORK variables
#      NOTE: All of the repos will use the GIT_FORK and GIT_BRANCH variables so they need to
#            be in all repositories.
#   2. cd into the cloned repository and run pipenv --python PYTHON where PYTHON is the version of python to use
#   3. execute pipenv sync on the cloned repository
# using the GIT_URL and GIT_BRANCH.  One side effect of this is that all of the
# repositories must have the branch available for it.

set -eu

# Container directory for all of the repositories.
ROOT_ENV=/repos/devsetup
# Python version to use as base version
PYTHON=3.7

# Main url for git location
GIT_URL=https://github.com
# Branch to clone from for each repository
GIT_BRANCH=pipenv
# User name to clone from
GIT_FORK=VOLTTRON
# repositories to clone from.
GIT_REPO_NAMES="volttron-utils volttron-client volttron-server"

# Container directory must exist before we can start
if [ ! -d "$ROOT_ENV" ]; then
  echo "Root directory $ROOT_ENV does not exist!"
  exit 1
fi

# Capture the current directory so we can go back to it.
CD=$(pwd)
cd "$ROOT_ENV"

for repo in $GIT_REPO_NAMES
do
  # Do nothing if we already have a repo directory
  if [ -d "$ROOT_ENV/$repo" ]; then
    echo "Ignoring $repo as the directory exists."
    continue
  fi

  echo "Cloning $repo"
  result=$(git clone "$GIT_URL/$GIT_FORK/$repo" -b $GIT_BRANCH)

  cd "$ROOT_ENV/$repo"

  result=$(pipenv --python "$PYTHON")
  result=$(pipenv sync)

  cd "$ROOT_ENV"
done

cd "$CD"