setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
    load '/usr/lib/bats/bats-file/load'

	find test/*issues -type d -name 'node_modules' -exec rm -rf {} \;
	find test/*issues -type f -name '*sbom*' -exec rm -f {} \;
	find test/*issues -type f -name '.tool-versions' -exec rm -f {} \;
	find test/*issues -type f -name 'Makefile*' -exec rm -f {} \;

    docker build -t eps-sbom .
}

teardown() {
	find test/*issues -type d -name 'node_modules' -exec rm -rf {} \;
	find test/*issues -type f -name '*sbom*' -exec rm -f {} \;
	find test/*issues -type f -name '.tool-versions' -exec rm -f {} \;
	find test/*issues -type f -name 'Makefile*' -exec rm -f {} \;
}


@test "No content allows SBOM to execute" {
    cp test/.tool-versions test/no-issues/no-content/.tool-versions
    cp test/Makefile test/no-issues/no-content/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/no-content:/working eps-sbom
    assert_success
}

@test "Can generate an issue-free SBOM for NPM" {
    cp test/.tool-versions test/no-issues/npm-only/.tool-versions
    cp test/Makefile test/no-issues/npm-only/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-only:/working eps-sbom

    assert_exists test/no-issues/npm-only/sbom-npm.json

    # No python files should be made
    assert_not_exists test/no-issues/npm-only/sbom-python*.json
}

@test "Can generate an issue-free SBOM for Pip" {    
    cp test/.tool-versions test/no-issues/python-pip-only/.tool-versions
    cp test/Makefile test/no-issues/python-pip-only/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-pip-only:/working eps-sbom

    assert_exists test/no-issues/python-pip-only/sbom-python.json

    assert_not_exists test/no-issues/python-pip-only/sbom-npm.json
    assert_not_exists test/no-issues/python-pip-only/sbom-python-poetry.json
}

@test "Can generate an issue-free SBOM for Poetry" {
    cp test/.tool-versions test/no-issues/python-poetry-only/.tool-versions
    cp test/Makefile test/no-issues/python-poetry-only/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-poetry-only:/working eps-sbom

    assert_exists test/no-issues/python-poetry-only/sbom-python.json
    
    assert_not_exists test/no-issues/python-poetry-only/sbom-npm.json
    assert_not_exists test/no-issues/python-poetry-only/sbom-python-pip.json
}

@test "Can generate issue-free SBOM for NPM and Pip" {
    cp test/.tool-versions test/no-issues/npm-plus-pip/.tool-versions
    cp test/Makefile test/no-issues/npm-plus-pip/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-plus-pip:/working eps-sbom
    
    assert_exists test/no-issues/npm-plus-pip/sbom-python.json
    assert_exists test/no-issues/npm-plus-pip/sbom-npm.json

    assert_not_exists test/no-issues/npm-plus-pip/sbom-python-poetry.json
}

@test "Fails when a known NPM threat is encountered" {
    cp test/.tool-versions test/issues/npm-only/.tool-versions
    cp test/Makefile test/issues/npm-only/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/npm-only:/working eps-sbom
    assert_failure
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
}

@test "Passes when an ignored issues is encountered - npm" {
    cp test/.tool-versions test/issues/ignore-npm-issue/.tool-versions
    cp test/Makefile test/issues/ignore-npm-issue/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-npm-issue:/working eps-sbom
    assert_success
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
}

@test "Fails when a known python pip threat is encountered" {
    cp test/.tool-versions test/issues/python-pip-only/.tool-versions
    cp test/Makefile test/issues/python-pip-only/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/python-pip-only:/working eps-sbom
    assert_failure

    assert_output --partial "GHSA-5p8v-58qm-c7fp"
}

@test "Passes when an ignored issue is encountered - python pip" {
    cp test/.tool-versions test/issues/ignore-pip-issue/.tool-versions
    cp test/Makefile test/issues/ignore-pip-issue/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-pip-issue:/working eps-sbom
    assert_success
    assert_output --partial "GHSA-5p8v-58qm-c7fp"
}

@test "Fails when a known python poetry threat is encountered" {
    cp test/.tool-versions test/issues/python-poetry-only/.tool-versions
    cp test/Makefile test/issues/python-poetry-only/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/python-poetry-only:/working eps-sbom
    assert_failure

    assert_output --partial "GHSA-4jcv-vp96-94xr"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
}

@test "Passes when an ignored issue is encountered - python poetry" {
    cp test/.tool-versions test/issues/ignore-poetry-issue/.tool-versions
    cp test/Makefile test/issues/ignore-poetry-issue/Makefile

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/issues/ignore-poetry-issue:/working eps-sbom
    assert_success
    assert_output --partial "GHSA-4jcv-vp96-94xr"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
}
