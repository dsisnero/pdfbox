# Architecture

`pdfbox` is a Crystal port of Apache PDFBox. The codebase is organized around the
same major layers as the Java implementation:

- `src/pdfbox/cos` and parser code handle low-level PDF object and parsing logic.
- `src/pdfbox/pdmodel` implements the higher-level document model and APIs.
- `src/pdfbox/pdfwriter` is responsible for serialization and writer parity.
- `spec/` ports Java tests and adds Crystal-facing coverage where needed.

The source of truth for behavior is the Java code and tests in `vendor/pdfbox/`.
When the Crystal implementation and the Java implementation diverge, align the
Crystal code to the Java logic rather than inventing a new abstraction.
