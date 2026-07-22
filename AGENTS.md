# Project Rules

## Dart implementation

- Write idiomatic, modern Dart that takes advantage of the current SDK's language features.
- Prefer concise, strongly typed code and appropriate Dart constructs such as sealed and final classes, pattern matching, records, collection elements, and exhaustive switches when they make the code clearer and more correct.
- Model nullability explicitly, keep public APIs small and typed, and follow the effective Dart conventions enforced by the repository analyzer.
- Prefer enums over strings for closed, known sets of values; use string conversion only at serialization, parsing, or interoperability boundaries.
- Preserve Mermaid.js behavior and algorithms while expressing them naturally in Dart; do not transliterate JavaScript conventions that have a clearer Dart equivalent.

## Development workflow

- Use test-driven development: add or update a failing behavioral test first, implement the smallest correct change, then refactor with the suite green.
- Port relevant upstream Mermaid.js parser cases and add focused Dart tests for edge cases, diagnostics, and regressions.
- Before considering a change complete, run formatting, static analysis, and the relevant tests.

## Dependencies

- Prefer established, actively maintained third-party Dart packages for solved infrastructure problems instead of reimplementing them.
- Evaluate packages for API fit, maintenance, platform support, license, and compatibility with the repository's Dart SDK constraint.
- Keep Mermaid-specific grammar, AST, and behavior in this repository; use dependencies for reusable foundations such as parser combinators, collections, or utilities.
- Add a dependency only when it materially improves correctness, maintainability, or implementation effort, and use the narrowest suitable API.
