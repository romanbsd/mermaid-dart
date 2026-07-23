---
name: upstream-sync
description: Synchronize and release-tag mermaid-dart against a tagged Mermaid.js release. Use when checking for new stable `mermaid@X.Y.Z` tags, porting upstream bug fixes or features, updating the pinned Mermaid parity renderer, catching up with upstream, or creating and pushing the matching mermaid-dart release tag. Treat tags—not individual commits—as synchronization units.
---

# Sync Mermaid upstream

Port one upstream release range into idiomatic Dart while preserving Mermaid.js
behavior. Work autonomously unless a product choice or an overlapping user change
requires clarification.

## Invocation

- `$upstream-sync`: sync to the newest stable `mermaid@X.Y.Z` tag.
- `$upstream-sync check`: report newer stable tags without editing files.
- `$upstream-sync mermaid@X.Y.Z`: sync to that specific tag.
- `$upstream-sync release-tag`: tag the current committed parity release with
  the exact upstream tag name and push that tag to `origin`.
- `$upstream-sync release-tag mermaid@X.Y.Z`: tag a specific committed parity
  release.

Ignore `v*`, `@mermaid-js/*`, `untagged-*`, and prerelease tags. Accept a
prerelease only when the user explicitly names it.

## 1. Establish the release range

1. Read `AGENTS.md` and inspect `rtk git status --short`. Preserve unrelated
   user changes. Stop before editing only when existing changes overlap the sync.
2. Use `../mermaid` as the preferred upstream checkout. Verify that its remote
   points to `mermaid-js/mermaid`, then run:

   ```sh
   rtk git -C ../mermaid fetch --tags --prune origin
   ```

   If that checkout is absent, locate another trusted Mermaid checkout. If none
   exists, ask before choosing a persistent clone location.
3. Derive the baseline from all repository pins:
   - `tool/mermaid_parity/reference/package.json`
   - `tool/mermaid_parity/reference/package-lock.json`
   - `tool/mermaid_parity/fixtures.json`
   - version assertions and documentation

   They must agree. The CLI version `X.Y.Z` maps to tag `mermaid@X.Y.Z`.
   Diagnose disagreement instead of guessing a baseline.
4. List only matching upstream tags:

   ```sh
   rtk git -C ../mermaid tag --list 'mermaid@*' --sort=-version:refname
   ```

5. Select the requested tag, or the newest stable tag newer than the baseline.
   Verify it is an ancestor-compatible forward range. If no newer tag exists,
   report that the Dart port is current and stop.

When several releases are skipped, inspect each intervening tag's release notes,
but implement the aggregate `baseline..target` range as one sync. Never create a
per-commit port queue.

## 2. Build a release-level inventory

Inspect the tag range before editing:

```sh
rtk git -C ../mermaid diff --stat <baseline-tag>..<target-tag>
rtk git -C ../mermaid diff --name-status <baseline-tag>..<target-tag>
rtk git -C ../mermaid log --oneline --decorate <baseline-tag>..<target-tag>
```

Read the upstream changelog/release notes and the relevant upstream tests and
source. Commits are evidence for understanding the release, not work units.

Use the repository knowledge graph first to map affected behavior to Dart
parsers, ASTs, layout, rendering, themes, configuration, public API, and tests.
Fall back to text search for literals, diagnostics, fixtures, and version pins.

Classify every user-visible release item as:

- **Port**: behavior supported by this pure-Dart parser/renderer.
- **Add**: a new Mermaid diagram, syntax, option, theme variable, or API surface.
- **Not applicable**: website, browser integration, build, documentation, or
  JavaScript-only infrastructure with no observable Mermaid behavior.
- **Needs decision**: a genuine product or dependency choice.

Record a concise reason for anything not applicable. Do not silently omit
parser changes, bug fixes, configuration defaults, diagnostics, accessibility,
layout, styling, or serialization behavior.

## 3. Port behavior test-first

For each relevant release item:

1. Port the closest upstream behavioral test or add a focused Dart regression
   test. Add parity fixtures when rendering or geometry changed.
2. Run the narrow test and confirm it fails for the expected reason.
3. Implement the smallest correct change.
4. Rerun the narrow test, then related parser/rendering tests.
5. Refactor only with the tests green.

Preserve upstream semantics while expressing them naturally in modern Dart.
Keep public APIs strongly typed, model closed sets with enums, and name
non-obvious Mermaid defaults or geometry constants. Do not transliterate
JavaScript structure or weaken assertions merely to make parity pass.

For a new diagram type, cover the complete slice: detection, parsing, typed AST,
configuration and theme defaults, layout, scene rendering, SVG serialization,
public dispatch, diagnostics, upstream fixtures, and focused edge cases.

## 4. Advance the parity baseline

Advance version pins only after every relevant behavior in the release range is
implemented. Update together:

- exact `@mermaid-js/mermaid-cli` version in `reference/package.json`
- `reference/package-lock.json`
- `fixtures.json` `mermaidVersion`
- hard-coded version assertions and CLI help
- README parity documentation
- `CHANGELOG.md`

Regenerate the lockfile rather than hand-editing it:

```sh
rtk npm install --prefix tool/mermaid_parity/reference --save-exact \
  --package-lock-only @mermaid-js/mermaid-cli@<target-version>
```

Search for the old version afterward and explain any intentional remaining
occurrence. If relevant work must be deferred, leave the baseline pins unchanged
so the repository does not falsely claim parity.

## 5. Validate the completed tag sync

Run:

```sh
rtk dart format --output=none --set-exit-if-changed .
rtk dart analyze
rtk dart test
rtk npm ci --prefix tool/mermaid_parity/reference
rtk dart run tool/mermaid_parity.dart --update-reference --report-only
rtk dart run tool/mermaid_parity.dart
rtk git diff --check
```

Investigate parity failures as possible upstream behavior changes before
changing comparison tolerances. Add normalization only for proven
backend-representation differences that preserve visible behavior.

## 6. Tag the committed release

Run this section only for `release-tag` mode or when the user explicitly asks
to tag the completed release. Tagging is a post-merge operation: never tag
uncommitted sync work.

1. Require a clean worktree. Fetch `origin` and its tags.
2. Derive the release version from the committed parity pins unless the user
   supplied a tag. Require every pin to equal `X.Y.Z`, then use the exact tag
   name `mermaid@X.Y.Z`.
3. Verify `../mermaid` contains that exact upstream tag.
4. Resolve the mermaid-dart release commit:
   - default to `HEAD`;
   - require its committed parity pins to match the tag;
   - require it to be reachable from the repository's remote default branch.
5. Check both local and `origin` tags. If the tag already points to the release
   commit, report success without recreating it. If it points elsewhere, stop
   and report both object IDs; never move or force-push a release tag.
6. Create an annotated tag and push only that tag:

   ```sh
   rtk git tag -a mermaid@X.Y.Z -m "Mermaid.js X.Y.Z parity"
   rtk git push origin refs/tags/mermaid@X.Y.Z
   ```

7. Fetch the remote tag and verify that its peeled commit is the intended
   release commit. Do not create a GitHub release or publish the Dart package
   unless separately requested.

## Completion report

Report:

- baseline and target tags;
- intervening stable tags covered;
- ported features and fixes;
- release items classified not applicable, with reasons;
- version pins advanced;
- formatting, analysis, tests, and parity results;
- matching mermaid-dart tag status: pending, created, already correct, or
  blocked;
- any remaining blocker.

Do not commit, push branches, open a PR, create a GitHub release, or publish a
package unless the user separately asks. Create and push only the exact release
tag in explicit `release-tag` mode.
