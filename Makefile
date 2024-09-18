.PHONY: install build test publish release clean submodule_update

test:
	bats test/test.bats

lint:
	shellcheck *.sh
