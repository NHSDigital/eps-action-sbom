.PHONY: install build test publish release submodule_update check-licenses clean

install:
	git submodule init
	git submodule update
	poetry install
	poetry run pre-commit install

test:
	PATH=$$PATH:test/bats/bin bats --print-output-on-failure test/test.bats

lint: lint-githubactions
	shellcheck *.sh

lint-githubactions:
	actionlint


clean:
	find test/*issues -type d -name 'node_modules' -exec rm -rf {} \;
	find test/*issues -type f -name '*sbom*' -exec rm -f {} \;
	find test/*issues -type f -name '.tool-versions' -exec rm -f {} \;
	find test/*issues -type f -name 'Makefile*' -exec rm -f {} \;
	find test/issues/* -type f \( \
		-name 'package.json' \
		-o -name 'package-lock.json' \
		-o -name 'requirements*.txt' \
		-o -name 'pyproject.toml' \
		-o -name 'poetry.lock' \
	\) -exec sh -c 'mv "$1" "${1}_no-check"' _ {} \;
	rm -rf .test_run
