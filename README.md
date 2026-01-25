# PDFBox Crystal

A **Crystal language port** of [Apache PDFBox](https://pdfbox.apache.org/) - an open-source library for working with PDF documents.

## About Apache PDFBox

Apache PDFBox is a Java library that allows:
- Creation of new PDF documents
- Manipulation of existing PDF documents  
- Extraction of content from PDF documents
- Command-line utilities for PDF operations

This Crystal port aims to bring the powerful PDF manipulation capabilities of Apache PDFBox to the Crystal programming language.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     pdfbox:
       github: dsisnero/pdfbox
   ```

2. Run `shards install`

## Usage

```crystal
require "pdfbox"

# TODO: Add Crystal-specific usage examples
# This will include PDF creation, manipulation, and content extraction
```

## Development

This project follows Crystal development best practices and includes a Makefile for common tasks:

### Using the Makefile
```bash
make help              # Show all available commands
make submodule-init    # Initialize Apache PDFBox submodule
make submodule-update  # Update Apache PDFBox submodule to latest
make deps              # Install Crystal dependencies
make format            # Format Crystal code
make lint              # Run Crystal linter (ameba)
make lint-fix          # Run Crystal linter and fix issues
make test              # Run Crystal tests
make quality           # Run all quality checks (format, lint, test)
make clean             # Clean build artifacts
```

### Manual Commands
```bash
crystal tool format    # Format Crystal code
ameba                  # Run Crystal linter
ameba --fix            # Fix Crystal linting issues automatically
crystal spec           # Run all tests
shards install         # Install dependencies
shards update          # Update dependencies
```

## Project Status

This is an **active porting project** of Apache PDFBox to Crystal. The goal is to provide a comprehensive PDF manipulation library for the Crystal ecosystem while maintaining compatibility with the original Apache PDFBox API where possible.

## Contributing

1. Fork it (<https://github.com/dsisnero/pdfbox/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Development Workflow
- Always run `ameba --fix` before committing to fix linting issues
- Always run `crystal spec` before committing to ensure tests pass
- Always run `crystal tool format` before committing for consistent formatting

## License

This project is licensed under the MIT License - see the LICENSE file for details.

**Note:** This is a port of Apache PDFBox, which is licensed under the Apache License 2.0. The original Apache PDFBox source code and documentation are included as a git submodule in the `apache_pdfbox/` directory for reference during the porting process. Use `make submodule-init` to initialize it or `make submodule-update` to update it to the latest version.

## Contributors

- [your-name-here](https://github.com/dsisnero) - creator and maintainer
