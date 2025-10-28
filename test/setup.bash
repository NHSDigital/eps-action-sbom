#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"


rm -rf .test_run
mkdir -p .test_run

rsync -av --exclude='bats' --exclude='test_helper' test/ .test_run/ 2>&1 >/dev/null

# Copy .tool-versions and test/Makefile to all test directories
find "${ROOT_DIR}"/.test_run/issues "${ROOT_DIR}"/.test_run/no-issues -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    cp "${ROOT_DIR}"/.tool-versions "$dir/"
    cp "${ROOT_DIR}"/test/Makefile "$dir/"
done

# Rename the files back to their original names for testing
find .test_run/*issues/* -type f \( \
    -name 'package.json_no-check' \
    -o -name 'package-lock.json_no-check' \
    -o -name 'requirements*.txt_no-check' \
    -o -name 'pyproject.toml_no-check' \
    -o -name 'poetry.lock_no-check' \
    -o -name 'go.sum_no-check' \
    -o -name 'go.mod_no-check' \
\) -exec sh -c 'mv "$1" "${1%_no-check}"' _ {} \;

find .test_run/*issues -type d -name 'node_modules' -exec rm -rf {} \;
find .test_run/*issues -type f -name '*sbom*' -exec rm -f {} \;

#  build -t eps-sbom -f test/Dockerfile .

if [ -z $LOCAL_WORKSPACE_FOLDER ]; then
    LOCAL_WORKSPACE_FOLDER=$(pwd)
fi
