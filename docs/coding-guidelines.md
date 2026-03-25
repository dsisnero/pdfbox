# Coding Guidelines

- Read the matching Java source before porting a method.
- Port behavior faithfully; do not simplify algorithms or edge-case handling.
- Prefer small, reviewable changes that keep writer, parser, and model behavior aligned.
- Use Crystal idioms where they preserve Java semantics and public behavior.
- Keep new code ASCII unless the file already requires another encoding.
- Add comments only when the logic is difficult to understand without them.

For parity work, preserve Java exception behavior and test setup as closely as
the Crystal API allows.
