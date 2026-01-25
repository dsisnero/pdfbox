# Crystal PDFBox Porting Plan

## Overview
This document outlines the strategy for porting Apache PDFBox from Java to Crystal. The goal is to create a comprehensive PDF manipulation library for Crystal that maintains compatibility with PDFBox's core functionality while leveraging Crystal idioms and standard libraries.

## Project Structure Reference
Apache PDFBox consists of several modules:
- **pdfbox** - Core PDF document manipulation
- **fontbox** - Font processing and rendering
- **xmpbox** - XMP metadata handling
- **io** - Input/output utilities
- **tools** - Command-line utilities
- **examples** - Example code
- **benchmark** - Performance testing

## Porting Philosophy

### Crystal Idioms
- Use Crystal's strong typing and compile-time checks
- Leverage Crystal's standard library (IO, File, String, etc.)
- Use Crystal's exception hierarchy
- Implement with Crystal's concurrency model (fibers/channels) where appropriate
- Follow Crystal naming conventions (snake_case for methods/variables)

### Design Principles
1. **API Compatibility**: Where possible, maintain similar API structure to aid migration
2. **Crystal First**: Rewrite Java patterns using Crystal idioms
3. **Test-Driven**: Port tests alongside implementation
4. **Modular**: Port module by module, ensuring each is functional before moving on
5. **Performance**: Leverage Crystal's performance characteristics

## Milestone Plan

### Milestone 1: Foundation & Core Types
**Goal**: Establish basic PDF document structure and core object model

**Tasks**:
1. Set up Crystal project structure mirroring PDFBox modules
2. Port core COS (Cos Object System) types:
   - COSBase, COSObject, COSArray, COSDictionary, COSName, COSString, COSInteger, COSBoolean, COSFloat
   - Use Crystal classes/structs with proper typing
3. Implement PDF document structure:
   - PDFDocument class (equivalent to PDDocument)
   - PDFPage class (equivalent to PDPage)
   - PDFBoxError hierarchy
4. Create basic I/O layer using Crystal's IO classes
5. Implement minimal PDF parsing/writing skeleton

**Key Files to Port**:
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/`
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/`

**Crystal Considerations**:
- Replace Java streams with Crystal IO
- Use Crystal's `Enumerable` for collections
- Implement `#to_s`, `#inspect` for debugging

### Milestone 2: PDF Parsing & Writing
**Goal**: Implement complete PDF file parsing and writing capabilities

**Tasks**:
1. Port PDF parser (PDFParser)
2. Implement PDF writer (PDFWriter)
3. Add stream handling and compression (Flate, LZW, etc.)
4. Implement cross-reference table handling
5. Add incremental update support
6. Implement encryption/decryption basics

**Key Files to Port**:
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/`
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/`
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/encryption/`

**Crystal Considerations**:
- Use Crystal's `Compress::Deflate` for Flate compression
- Implement custom decoders for PDF-specific compression
- Use Crystal's `Crypto` module for encryption where applicable

### Milestone 3: Content Stream & Graphics
**Goal**: Implement PDF content stream parsing and rendering

**Tasks**:
1. Port PDFStreamEngine and content stream processors
2. Implement graphics state operations
3. Add text rendering and extraction
4. Implement image handling
5. Add path construction and painting operators
6. Implement color spaces

**Key Files to Port**:
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/`
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/`
- `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/util/`

**Crystal Considerations**:
- Use Crystal's `Math` module for transformations
- Implement matrix operations using Crystal structs
- Consider using `Cairo` or similar for rendering if needed

### Milestone 4: Fonts & Text (FontBox Module)
**Goal**: Port FontBox module for font handling

**Tasks**:
1. Port font loading and parsing (TrueType, Type1, etc.)
2. Implement font metrics and glyph extraction
3. Add font substitution and fallback
4. Implement text extraction with proper encoding
5. Add font embedding capabilities

**Key Files to Port**:
- `apache_pdfbox/fontbox/src/main/java/org/apache/fontbox/`
- Font-related files in pdfbox module

**Crystal Considerations**:
- Investigate Crystal font libraries for potential integration
- Implement encoding conversions using Crystal's `String`/`Bytes`

### Milestone 5: XMP Metadata (XMPBox Module)
**Goal**: Port XMP metadata handling

**Tasks**:
1. Port XMP metadata parsing and creation
2. Implement metadata extraction from PDFs
3. Add metadata embedding capabilities
4. Implement XMP schema handling

**Key Files to Port**:
- `apache_pdfbox/xmpbox/src/main/java/org/apache/xmpbox/`

**Crystal Considerations**:
- Use Crystal's XML parsing libraries
- Implement as lightweight metadata wrapper

### Milestone 6: Tools & Utilities
**Goal**: Port command-line tools and utilities

**Tasks**:
1. Port core utilities (PDFMerger, PDFSplit, etc.)
2. Implement image extraction/embedding tools
3. Add text extraction utilities
4. Implement form handling tools
5. Create Crystal-friendly CLI interface

**Key Files to Port**:
- `apache_pdfbox/tools/src/main/java/org/apache/pdfbox/tools/`
- Utility classes in `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/util/`

**Crystal Considerations**:
- Use Crystal's `OptionParser` for CLI
- Create executable shards for tools
- Add `--help` and proper error messages

### Milestone 7: Advanced Features
**Goal**: Implement advanced PDF features

**Tasks**:
1. Port form handling (AcroForms)
2. Implement annotations
3. Add digital signatures
4. Implement PDF/A compliance features
5. Add layer (OCG) support

### Milestone 8: Performance & Optimization
**Goal**: Optimize for Crystal performance characteristics

**Tasks**:
1. Profile and optimize critical paths
2. Implement caching strategies
3. Add memory management optimizations
4. Implement parallel processing where beneficial
5. Create benchmarks

### Milestone 9: Prawn Compatibility Layer
**Goal**: Add Prawn Ruby gem compatibility shim

**Tasks**:
1. Analyze Prawn API and common patterns
2. Create compatibility layer mapping Prawn API to PDFBox
3. Implement most-used Prawn features
4. Create migration guide from Prawn to Crystal PDFBox
5. Add examples of Prawn-style usage

## Testing Strategy

### Test Porting Approach
1. **Port tests alongside implementation**: Each milestone includes porting relevant tests
2. **Maintain test coverage**: Aim for equivalent or better coverage than Java version
3. **Use Crystal's spec framework**: Convert JUnit tests to Crystal specs
4. **Test data preservation**: Use original PDF test files from Apache PDFBox

### Test Categories
1. **Unit tests**: Individual class/function tests
2. **Integration tests**: Module interaction tests
3. **Regression tests**: PDF file round-trip tests
4. **Performance tests**: Benchmark against Java version

## Development Workflow

### Module Porting Process
For each module:
1. Analyze Java source structure
2. Design Crystal equivalent structure
3. Port core data types
4. Port main functionality
5. Port tests
6. Verify with test PDFs
7. Optimize for Crystal

### Code Organization
```
src/
├── pdfbox/          # Core PDFBox port
│   ├── cos/         # COS object system
│   ├── pdmodel/     # PDF document model
│   ├── pdfparser/   # PDF parsing
│   ├── pdfwriter/   # PDF writing
│   └── ...
├── fontbox/         # Font processing
├── xmpbox/          # XMP metadata
├── io/              # I/O utilities
└── tools/           # Command-line tools
```

### Beads Issue Tracking
Each milestone will be created as a beads epic with:
- `--type=epic` for milestones
- `--type=task` for individual porting tasks
- Proper dependencies between tasks
- Priority based on dependency chain

## Crystal-Specific Considerations

### Memory Management
- Use Crystal's automatic memory management
- Implement `#finalize` for cleanup where needed
- Be mindful of large PDF file handling

### Concurrency
- Consider using fibers for async PDF processing
- Implement thread-safe operations for shared resources
- Use channels for pipeline processing if beneficial

### Error Handling
- Define comprehensive error hierarchy
- Use Crystal's exception mechanism
- Provide helpful error messages for PDF-specific issues

### Dependencies
- Minimize external dependencies
- Use Crystal stdlib where possible
- Consider well-maintained shards for specific needs (compression, crypto)

## Success Metrics

### Functional
- ✅ All original Apache PDFBox tests pass
- ✅ Can process standard PDF test suite
- ✅ Performance comparable to Java version
- ✅ Memory usage appropriate for Crystal

### API
- ✅ Crystal-idiomatic API
- ✅ Comprehensive documentation
- ✅ Good error messages
- ✅ Prawn compatibility layer functional

### Community
- ✅ Clear contribution guidelines
- ✅ Good examples and tutorials
- ✅ Active maintenance

## Timeline & Priority
1. **Phase 1 (Milestones 1-3)**: Core PDF functionality (Months 1-3)
2. **Phase 2 (Milestones 4-6)**: Complete feature set (Months 4-6)
3. **Phase 3 (Milestones 7-9)**: Advanced features & polish (Months 7-9)

## Risks & Mitigations

### Technical Risks
- **PDF specification complexity**: Mitigate by focused, test-driven approach
- **Font rendering challenges**: Mitigate by leveraging existing Crystal font libraries
- **Performance issues**: Mitigate by profiling and Crystal-specific optimizations

### Project Risks
- **Scope creep**: Mitigate by strict milestone adherence
- **Maintenance burden**: Mitigate by comprehensive tests and documentation
- **Community adoption**: Mitigate by good documentation and Prawn compatibility

## Next Steps
1. Create beads epics for each milestone
2. Start with Milestone 1: Foundation & Core Types
3. Set up continuous integration
4. Establish contribution guidelines
5. Begin porting with core COS types

---

*This plan is a living document and will be updated as the porting progresses.*