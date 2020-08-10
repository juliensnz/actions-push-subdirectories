#!/bin/bash

set -e

FOLDER=$1
GITHUB_USERNAME=$2
REPO_NAME="${3:-name}"
BASE=$(pwd)

git config --global user.email "contact@akeneo.com"
git config --global user.name "$GITHUB_USERNAME"

echo "Cloning folders in $FOLDER and pushing to $GITHUB_USERNAME"
echo "Using $REPO_NAME as the package.json key"

# sync to read-only clones
for folder in $FOLDER/*; do
  [ -d "$folder" ] || continue # only directories
  cd $BASE

  echo "$folder"

  echo "  Name: $REPO_NAME"
  CLONE_DIR="__${REPO_NAME}__clone__"
  echo "  Clone dir: $CLONE_DIR"

  # clone, delete files in the clone, and copy (new) files over
  # this handles file deletions, additions, and changes seamlessly
  git clone --depth 1 https://$API_TOKEN_GITHUB@github.com/$GITHUB_USERNAME/$REPO_NAME.git $CLONE_DIR &> /dev/null
  cd $CLONE_DIR
  find . | grep -v ".git" | grep -v "^\.*$" | xargs rm -rf # delete all files (to handle deletions in monorepo)
  cp -r $BASE/$folder/. .

  # Commit if there is anything to
  if [ -n "$(git status --porcelain)" ]; then
    echo  "  Committing $REPO_NAME to $GITHUB_REPOSITORY"
    git add .
    git commit --message "Update $REPO_NAME from $GITHUB_REPOSITORY"
    git push origin master
    echo  "  Completed $REPO_NAME"
  else
    echo "  No changes, skipping $REPO_NAME"
  fi

  cd $BASE
done
