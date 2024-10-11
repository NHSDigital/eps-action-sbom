setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
    load '/usr/lib/bats/bats-file/load'

	find test/*issues -type d -name 'node_modules' -exec rm -rf {} \;
	find test/*issues -type f -name 'sbom*' -exec rm -f {} \;
	find test/*issues -type f -name '.tool-versions' -exec rm -f {} \;
	find test/*issues -type f -name 'Makefile' -exec rm -f {} \;

    docker build -t eps-sbom-bats -f test/Dockerfile .
}

teardown() {
	find test/*issues -type d -name 'node_modules' -exec rm -rf {} \;
	find test/*issues -type f -name '*sbom*' -exec rm -f {} \;
	find test/*issues -type f -name '.tool-versions' -exec rm -f {} \;
	find test/*issues -type f -name 'Makefile' -exec rm -f {} \;
}


@test "No content allows SBOM to execute" {
    export TEST_DIR=${LOCAL_WORKSPACE_FOLDER}/test/no-issues/no-content/
    echo "Testing: ${TEST_DIR}"

    cp test/.tool-versions ${TEST_DIR}
    cp test/Makefile ${TEST_DIR}
    cp check-sbom-issues-against-ignores.sh ${TEST_DIR}
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/no-content:/working eps-sbom-bats
    assert_success
}

@test "Can generate an issue-free SBOM for NPM" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-only:/working eps-sbom-bats

    assert_exists test/no-issues/npm-only/sbom-node.json

    # No python files should be made
    assert_not_exists test/no-issues/npm-only/sbom-python*.json
}

@test "Can generate an issue-free SBOM for Pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-pip-only:/working eps-sbom-bats

    assert_exists test/no-issues/python-pip-only/sbom-python-pip.json

    assert_not_exists test/no-issues/python-pip-only/sbom-node.json
    assert_not_exists test/no-issues/python-pip-only/sbom-python-poetry.json
}

@test "Can generate an issue-free SBOM for Poetry" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-poetry-only:/working eps-sbom-bats

    assert_exists test/no-issues/python-poetry-only/sbom-python-poetry.json
    
    assert_not_exists test/no-issues/python-poetry-only/sbom-node.json
    assert_not_exists test/no-issues/python-poetry-only/sbom-python-pip.json
}

@test "Can generate issue-free SBOM for NPM and Pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-plus-pip:/working eps-sbom-bats
    
    assert_exists test/no-issues/npm-plus-pip/sbom-python-pip.json
    assert_exists test/no-issues/npm-plus-pip/sbom-node.json

    assert_not_exists test/no-issues/npm-plus-pip/sbom-python-poetry.json
}

@test "Can generate issue-free SBOM for Pip and Poetry" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-pip-poetry:/working eps-sbom-bats

    assert_exists test/no-issues/python-pip-poetry/sbom-python-pip.json
    assert_exists test/no-issues/python-pip-poetry/sbom-python-poetry.json

    assert_not_exists test/no-issues/python-pip-poetry/sbom-node.json
}

@test "Fails when a known NPM threat is encountered" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/npm-only:/working eps-sbom-bats
    assert_failure
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
}

@test "Passes when an ignored issues is encountered - npm" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-npm-issue:/working eps-sbom-bats
    assert_success
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
}

@test "Fails when a known python pip threat is encountered" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/python-pip-only:/working eps-sbom-bats
    assert_failure

    assert_output --partial "GHSA-4jcv-vp96-94xr"
}

@test "Passes when an ignored issue is encountered - python pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-pip-issue:/working eps-sbom-bats
    assert_success
    assert_output --partial "GHSA-4jcv-vp96-94xr"
}

@test "Fails when a known python poetry threat is encountered" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/python-poetry-only:/working eps-sbom-bats
    assert_failure

    assert_output --partial "GHSA-4jcv-vp96-94xr"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
}

@test "Passes when an ignored issue is encountered - python poetry" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-poetry-issue:/working eps-sbom-bats
    assert_success
    assert_output --partial "GHSA-4jcv-vp96-94xr"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
}
