.PHONY: install update format lint test

install:
	BEADS_DIR=$$(pwd)/.beads shards install

update:
	BEADS_DIR=$$(pwd)/.beads shards update

format:
	crystal tool format --check src spec

lint:
	ameba --fix src spec
	ameba src spec

test:
	crystal spec -Dpreview_mt -Dexecution_context

clean:
	rm -rf ./temp/*
