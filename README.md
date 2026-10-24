# PDFBox Crystal

A **Crystal language port** of [Apache PDFBox](https://pdfbox.apache.org/), the
Java library for creating, reading, and modifying PDF documents.

## What it is

`pdfbox` brings PDFBox's capabilities to Crystal:

- create new PDF documents;
- manipulate existing PDF documents;
- extract text and content from PDF documents.

This is an **active porting project**. It tracks the Java behavior class by
class, with upstream tests ported first; coverage is recorded per symbol in
`plans/inventory/` and summarized in [`plans/parity.md`](plans/parity.md).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     pdfbox:
       github: dsisnero/pdfbox
   ```

2. Run `shards install`.

## Usage

```crystal
require "pdfbox"

# Load a document and extract its text.
document = Pdfbox::Loader.load_pdf("input.pdf")
puts Pdfbox::Text::PDFTextStripper.new.get_text(document)
document.close
```

The API mirrors the Java class names where Crystal allows it (e.g.
`Loader`, `Pdmodel::Document`, `Pdmodel::PDPage`,
`Text::PDFTextStripper`), so the
[Java API documentation](https://pdfbox.apache.org/docs/2.0.27/javadocs/) is a
usable companion reference.

## Documentation

| Doc | Purpose |
| --- | --- |
| [docs/architecture.md](docs/architecture.md) | High-level structure and source-of-truth boundaries |
| [docs/development.md](docs/development.md) | Local workflow, setup, upstream/vendor notes, temp-file conventions |
| [docs/coding-guidelines.md](docs/coding-guidelines.md) | Porting rules and Crystal-specific expectations |
| [docs/testing.md](docs/testing.md) | Test-first parity workflow and quality gates |
| [docs/pr-workflow.md](docs/pr-workflow.md) | Commit, push, and review expectations |
| [docs/resuming.md](docs/resuming.md) | How a new session resumes work |

## Development

```bash
make submodule-init   # check out the vendored Apache PDFBox source
make install          # shards install
make format           # formatting gate (writes nothing)
make lint             # ameba gate (writes nothing)
make test             # crystal spec
make quality          # format + lint + test
make clean            # remove ./temp contents
```

`make help` lists every target. To apply fixes instead of checking, use
`make format-fix` and `make lint-fix`.

See [docs/development.md](docs/development.md) for the pin of the vendored
upstream source and the local workflow.

## Contributing

1. Fork it (<https://github.com/dsisnero/pdfbox/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run `make quality`
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file.

Apache PDFBox itself is licensed under the Apache License 2.0. See
[docs/development.md](docs/development.md) for how its vendored source is
checked out and pinned.

## Contributors

- [your-name-here](https://github.com/dsisnero) — creator and maintainer
