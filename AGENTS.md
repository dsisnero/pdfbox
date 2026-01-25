# Agent Instructions

This project is a **Crystal port of Apache PDFBox** - a library for working with PDF documents in Crystal. It uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

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

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
   - **ALWAYS run `ameba --fix` before committing** to fix linting issues
   - **ALWAYS run `crystal spec` before committing** to ensure tests pass
   - **ALWAYS run `crystal tool format` before committing** to ensure consistent formatting
3. **Update issue status** - Close finished work, update in-progress items
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

