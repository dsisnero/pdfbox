# Agent Instructions

This project is a **Crystal port of Apache PDFBox** - a library for working with PDF documents in Crystal.

## Issue Tracking

This project uses **bd (beads)** for ALL issue tracking and task management.
**DO NOT use todo lists** - use beads issues with proper tags and labels instead.

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

