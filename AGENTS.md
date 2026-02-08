# Agent Instructions

This project is a **Crystal port of Apache PDFBox** - a library for working with PDF documents in Crystal.

**Apache PDFBox Source:** The original Java source code is available in the `./apache_pdfbox/` directory. Use this as the reference implementation when porting features.

**Test-Driven Development (TDD):**
- **Port tests first** before implementing functionality
- Reference test files in `./apache_pdfbox/pdfbox/src/test/` for expected behavior
- Write Crystal specs that match the behavior of the original Java tests
- Ensure tests fail appropriately before implementation (red-green-refactor)

**Use Apache PDFBox Source** when porting the code over.  When ever you start to port a method understand how the Java source code implements it first.  Whenever you run into questions, look at the Java source file for how they do it.

**Crystal Idioms & Standard Library:** Prefer Crystal idioms and standard library over Java patterns. Adapt Java APIs to fit Crystal's type system and conventions (e.g., use `Enumerable`, `IO`, Crystal's exception hierarchy).

**Critical: Follow Apache PDFBox Logic Exactly:** When porting methods, maintain the same logic, algorithms, and architecture as the Apache PDFBox Java source. The goal is to create a faithful port, not a reimplementation. When debugging or implementing features:
1. Study the corresponding Java source code thoroughly before writing Crystal code
2. Understand how objects are resolved, parsed, and cached in the Java implementation
3. Map Java patterns to Crystal idioms while preserving the underlying logic
4. Pay special attention to lazy resolution patterns, object pools, and caching mechanisms used in Apache PDFBox
5. **do not simplify** There are no time constraints or other reasons to simplify.  Port the method so the same logic applies
## Issue Tracking

This project uses **bd (beads)** for ALL issue tracking and task management.
**DO NOT use todo tool** - use beads issues with proper tags and labels and status instead.
**DO NOT use task tool** - use beads issues with proper tags and labels , and status instead

Run `bd prime` for workflow context, or install hooks (`bd hooks install`) for auto-injection.

**Quick reference:**
- `bd ready` - Find unblocked work
- `bd create "Title" --type task --priority 2` - Create issue
- `bd close <id>` - Complete work
- `bd sync` - Sync with git (run at session end)

For full workflow details: `bd prime`

## Crystal Development Commands

**Code Quality & Formatting:**
```bash
crystal tool format    # Format Crystal code
ameba                  # Run Crystal linter
ameba --fix            # Fix Crystal linting issues automatically
```

**Testing:**
```bash
crystal spec           # Run all tests
```

**Build & Dependencies:**
```bash
shards install         # Install dependencies
shards update          # Update dependencies
```

## TDD / Porting Workflow

**When porting features from Apache PDFBox:**

1. **Port tests first** - Create or port corresponding test files before implementing functionality
2. **Run quality checks** - After each significant change:
   ```bash
   crystal tool format    # Ensure consistent formatting
   ameba --fix           # Fix linting issues automatically
   crystal spec          # Ensure all tests pass
   ```
3. **Fix ameba issues** - Address any remaining linting warnings that can't be auto-fixed
4. **Follow existing patterns** - Mimic code style, naming conventions, and architecture of already-ported components

**Critical:**
- ALWAYS run `crystal spec` after any test changes to verify they fail appropriately before implementation
- ALWAYS fix compilation errors before running tests
- ALWAYS address ameba warnings before committing

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **Create beads issues for remaining work** - Use `bd create` for anything that needs follow-up. **DO NOT use todo lists**.
2. **Run quality gates** (if code changed) - Tests, linters, builds
   - **ALWAYS run `ameba --fix` before committing** to fix linting issues
   - **ALWAYS run `crystal spec` before committing** to ensure tests pass
   - **ALWAYS run `crystal tool format` before committing** to ensure consistent formatting
3. **Update beads issue status** - Close finished work with `bd close`, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
- **ALWAYS fix ameba issues before committing**
- **ALWAYS ensure specs pass before committing and pushing**
- **ALWAYS use beads issues instead of todo lists**
- **Create beads issues with proper tags and labels for all tasks**

## Temporary Files

- **Use ./temp directory for all temporary files** - Never use /tmp or system temp directories
- **Makefile clean rule** - `make clean` automatically removes all files in ./temp/
- **Git ignored** - ./temp/ is already in .gitignore
- **Examples:** Use `./temp/embedded_block.txt` instead of `/tmp/embedded_block.txt`

This ensures:
1. Temporary files are project-scoped and don't pollute system temp
2. Easy cleanup with `make clean`
3. No accidental commits of temporary files
4. Consistent location for all agents

