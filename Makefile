.PHONY: install update format lint test

install:
	shards install

update:
	shards update

format:
	crystal tool format --check src spec

lint:
	ameba --fix src spec
	ameba src spec

test:
	crystal spec -Dpreview_mt -Dexecution_context

clean:
	rm -rf ./temp/*
