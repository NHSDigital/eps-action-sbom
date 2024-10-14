setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
    load '/usr/lib/bats/bats-file/load'

    find test/*issues -type d -name 'node_modules' -exec rm -rf {} \; 2>/dev/null
    find test/*issues -type f -name '*sbom*' -exec rm -f {} \; 2>/dev/null
    find test/*issues -type f -name '.tool-versions' -exec rm -f {} \; 2>/dev/null
    find test/*issues -type f -name 'Makefile' -exec rm -f {} \; 2>/dev/null

    docker build -t eps-sbom-bats -f test/Dockerfile ${LOCAL_WORKSPACE_FOLDER}
}

teardown() {
	find test/*issues -type d -name 'node_modules' -exec rm -rf {} \; 2>/dev/null
	find test/*issues -type f -name '*sbom*' -exec rm -f {} \; 2>/dev/null
	find test/*issues -type f -name '.tool-versions' -exec rm -f {} \; 2>/dev/null
	find test/*issues -type f -name 'Makefile' -exec rm -f {} \; 2>/dev/null
}


@test "No content allows SBOM to execute" {
    export TEST_DIR=${LOCAL_WORKSPACE_FOLDER}/test/no-issues/no-content/
    echo "Testing: ${TEST_DIR}"

    cp test/.tool-versions ${TEST_DIR}
    cp test/Makefile ${TEST_DIR}
    run docker run -i --rm -v ${TEST_DIR}:/working/ eps-sbom-bats
    assert_success
}

@test "Can generate an issue-free SBOM for NPM" {
    export TEST_DIR=${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-only/
    echo "Testing: ${TEST_DIR}"

    cp test/.tool-versions ${TEST_DIR}
    cp test/Makefile ${TEST_DIR}
    run docker run -i --rm -v ${TEST_DIR}:/working/ eps-sbom-bats

    assert_success
    assert_exists ${TEST_DIR}/sbom-node.json
    assert_not_exists ${TEST_DIR}/sbom-python*.json
}
