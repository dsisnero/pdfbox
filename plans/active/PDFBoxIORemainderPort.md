# Phase: pdfbox-io ScratchFile + IOUtils + backlog cleanup

**Goal:** Port the remaining unported `pdfbox-io` classes/tests and remove the
stale auto-generated placeholder specs.

## Source of truth

- `vendor/pdfbox/io/src/main/java/org/apache/pdfbox/io/{ScratchFile,
  ScratchFileBuffer, MemoryUsageSetting, IOUtils}.java`
- `vendor/pdfbox/io/src/test/java/org/apache/pdfbox/io/{ScratchFileBufferTest,
  TestIOUtils}.java`

## Done (red-green)

- [x] `MemoryUsageSetting` (main-memory-only / temp-file-only).
- [x] `ScratchFile` + `ScratchFileBuffer`: contiguous storage per buffer,
      Java `seek` semantics (negative -> `IO::Error`, past size -> `IO::EOFError`),
      `eof?`, `closed?`, `create_view` raises `UnsupportedOperationError`,
      `ScratchFile#close` closes all live buffers.
- [x] `IOUtils#populateBuffer` -> `Pdfbox::IO::Utils.populate_buffer`.
- [x] Specs `spec/pdfbox/io/scratch_file_buffer_spec.cr` (7) and
      `spec/pdfbox/io/io_utils_spec.cr` (1).
- [x] Removed `spec/porting/pdfbox-6req_spec.cr` (89 vacuous placeholders for
      the 10 IO test classes, all covered by the real `spec/pdfbox/io/*` specs);
      inventory refs repointed. `testPDFBOX5111/5158/5764` marked `partial`
      (documented skips: network/temp-file/ByteBuffer).

## Notes

- `ScratchFileBuffer` uses contiguous in-memory (or temp-file) storage rather
  than Java's page packing; the observable behavior used by the tests is
  identical.
