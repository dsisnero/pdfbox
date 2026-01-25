# Makefile for PDFBox Crystal Port
# This Makefile helps manage the Apache PDFBox submodule and development tasks

.PHONY: help submodule-update submodule-init format lint test deps clean

# Default target
help:
	@echo "PDFBox Crystal Port - Development Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  help           - Show this help message"
	@echo "  submodule-init - Initialize and update the Apache PDFBox submodule"
	@echo "  submodule-update - Update the Apache PDFBox submodule to latest"
	@echo "  deps           - Install Crystal dependencies"
	@echo "  format         - Format Crystal code"
	@echo "  lint           - Run Crystal linter (ameba)"
	@echo "  lint-fix       - Run Crystal linter and fix issues"
	@echo "  test           - Run Crystal tests"
	@echo "  quality        - Run all quality checks (format, lint, test)"
	@echo "  clean          - Clean build artifacts"

# Submodule management
submodule-init:
	@echo "Initializing Apache PDFBox submodule..."
	git submodule init
	git submodule update --remote --merge
	@echo "Submodule initialized and updated to latest."

submodule-update:
	@echo "Updating Apache PDFBox submodule to latest..."
	git submodule update --remote --merge
	@echo "Submodule updated."

# Development tasks
deps:
	@echo "Installing Crystal dependencies..."
	BEADS_SKIP_HOOKS=1 shards install

format:
	@echo "Formatting Crystal code..."
	crystal tool format

lint:
	@echo "Running Crystal linter (ameba)..."
	ameba

lint-fix:
	@echo "Running Crystal linter and fixing issues..."
	ameba --fix

test:
	@echo "Running Crystal tests..."
	crystal spec

quality: format lint-fix test
	@echo "All quality checks passed!"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf .crystal lib/.crystal
	@echo "Clean complete."