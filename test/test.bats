setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
    load '/usr/lib/bats/bats-file/load'
    docker build -t eps-sbom .

    # Remove all existing test output: *sbom*.json files
    rm -f test/**/*sbom*.json
    rm -rf test/**/node_modules
}

teardown() {
    rm -f test/**/*sbom*.json
    rm -rf test/**/node_modules
}

@test "No content allows SBOM to execute" {
    run docker run -i --rm -v ./test/no-issues/no-content:/github/workspace eps-sbom
    assert_success
}

@test "Can generate an issue-free SBOM for NPM" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-only:/github/workspace eps-sbom

    assert_exists test/no-issues/npm-only/sbom-node.json

    # No python files should be made
    assert_not_exists test/no-issues/npm-only/sbom-python*.json
}

@test "Can generate an issue-free SBOM for Pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-pip-only:/github/workspace eps-sbom

    assert_exists test/no-issues/python-pip-only/sbom-python-pip.json

    assert_not_exists test/no-issues/python-pip-only/sbom-node.json
    assert_not_exists test/no-issues/python-pip-only/sbom-python-poetry.json
}

@test "Can generate an issue-free SBOM for Poetry" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-poetry-only:/github/workspace eps-sbom

    assert_exists test/no-issues/python-poetry-only/sbom-python-poetry.json
    
    assert_not_exists test/no-issues/python-poetry-only/sbom-node.json
    assert_not_exists test/no-issues/python-poetry-only/sbom-python-pip.json
}

@test "Can generate issue-free SBOM for NPM and Pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-plus-pip:/github/workspace eps-sbom
    
    assert_exists test/no-issues/npm-plus-pip/sbom-python-pip.json
    assert_exists test/no-issues/npm-plus-pip/sbom-node.json

    assert_not_exists test/no-issues/npm-plus-pip/sbom-python-poetry.json
}

@test "Can generate issue-free SBOM for Pip and Poetry" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-pip-poetry:/github/workspace eps-sbom

    assert_exists test/no-issues/python-pip-poetry/sbom-python-pip.json
    assert_exists test/no-issues/python-pip-poetry/sbom-python-poetry.json

    assert_not_exists test/no-issues/python-pip-poetry/sbom-node.json
}

@test "Fails when a known NPM threat is encountered" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/npm-only:/github/workspace eps-sbom
    assert_failure
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
}

@test "Passes when an ignored issues is encountered - npm" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-npm-issue:/github/workspace eps-sbom
    assert_success
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
}

@test "Fails when a known python pip threat is encountered" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/python-pip-only:/github/workspace eps-sbom
    assert_failure

    assert_output --partial "GHSA-4jcv-vp96-94xr"
}

@test "Passes when an ignored issue is encountered - python pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-pip-issue:/github/workspace eps-sbom
    assert_success
    assert_output --partial "GHSA-4jcv-vp96-94xr"
}

@test "Fails when a known python poetry threat is encountered" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/python-poetry-only:/github/workspace eps-sbom
    assert_failure

    assert_output --partial "GHSA-4jcv-vp96-94xr"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
}

@test "Passes when an ignored issue is encountered - python poetry" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-poetry-issue:/github/workspace eps-sbom
    assert_success
    assert_output --partial "GHSA-4jcv-vp96-94xr"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
}