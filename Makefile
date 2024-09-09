.PHONY: install build test publish release clean submodule_update

test:
	bats test/test.bats

submodule_update:
	git submodule update

lint:
	shellcheck *.sh
