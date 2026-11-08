.PHONY: help install update submodule-init submodule-update sidecars format format-fix \
	lint lint-fix test quality clean

help: ## Show the available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install: ## Install Crystal dependencies
	shards install

update: ## Update Crystal dependencies
	shards update

submodule-init: ## Check out the vendored Apache PDFBox source
	git submodule update --init --recursive vendor/pdfbox

submodule-update: ## Move the vendored Apache PDFBox to its pinned upstream commit
	git submodule update --remote --recursive vendor/pdfbox

sidecars: ## Delete macOS AppleDouble ._* sidecars that break spec discovery
	@find src spec -name '._*' -delete 2>/dev/null || true

format: sidecars ## Format gate (writes nothing)
	crystal tool format --check src spec

format-fix: sidecars ## Rewrite formatting in place
	crystal tool format src spec

lint: sidecars ## Lint gate (writes nothing)
	ameba src spec

lint-fix: sidecars ## Lint and apply safe fixes
	ameba --fix src spec

test: sidecars ## Run the spec suite
	crystal spec

quality: format lint test ## Run every gate

clean: ## Remove ./temp contents (including dotfiles)
	@mkdir -p ./temp
	@find ./temp -mindepth 1 -maxdepth 1 -exec rm -rf {} +
