setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
    load '/usr/lib/bats/bats-file/load'
    docker build -t eps-sbom .

    # Remove all existing test output: *sbom*.json files
    find ./test -type f -name 'sbom*' -exec rm -f {} \;
    find ./test -type d -name 'node_modules' -exec rm -rf {} \;

    # Rename all the package*.json files to be discoverable
    find ./test -type f -name 'test-package*.json' -exec sh -c 'mv "$0" "${0%/*}/${0##*/test-}"' {} \;
}

teardown() {
    find ./test -type f -name 'sbom*' -exec rm -f {} \;
    find ./test -type d -name 'node_modules' -exec rm -rf {} \;

    find ./test -type d -name 'node_modules' -prune -o -type f -name 'package*.json' -exec sh -c 'mv "$0" "${0%/*}/test-${0##*/}"' {} \;
}

@test "No content allows SBOM to execute" {
    run docker run -i --rm -v ./test/no-issues/no-content:/github/workspace eps-sbom
    assert_success
}
