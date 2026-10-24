.PHONY: help install update submodule-init submodule-update format format-fix \
	lint lint-fix test quality clean

help: ## Show the available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

install: ## Install Crystal dependencies
	shards install

update: ## Update Crystal dependencies
	shards update

submodule-init: ## Check out the vendored Apache PDFBox source
	git submodule update --init --recursive vendor/pdfbox

submodule-update: ## Move the vendored Apache PDFBox to its pinned upstream commit
	git submodule update --remote --recursive vendor/pdfbox

format: ## Format gate (writes nothing)
	crystal tool format --check src spec

format-fix: ## Rewrite formatting in place
	crystal tool format src spec

lint: ## Lint gate (writes nothing)
	ameba src spec

lint-fix: ## Lint and apply safe fixes
	ameba --fix src spec

test: ## Run the spec suite
	crystal spec

quality: format lint test ## Run every gate

clean: ## Remove ./temp contents
	rm -rf ./temp/*
