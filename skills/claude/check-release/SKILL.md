---
name: check-release
description: Verify release readiness for a repository and prepare a version/changelog update plan. Use when the user asks to check if a release is ready, determine the next semantic version, validate branch and clean working tree, inspect version strings, or optionally run tests via $check-release with -t/--run-tests.
disable-model-invocation: true
argument-hint: [-t | --run-tests]
allowed-tools: Bash, Read, Edit, Grep, AskUserQuestion
---

# Check Release

Run a release-readiness check and report pass/fail for key gates before release.

## Inputs

Interpret invocation text as:

- Optional `-t` or `--run-tests`: run the project test suite.
- No flag: skip tests.

## Required Checks

Run these checks in order.

1. Verify branch:
`git branch --show-current`
Pass only when branch is `main`.

2. Verify clean working tree:
`git status --porcelain --untracked-files=no`
Ignore untracked files. Pass only when output is empty.

3. Read version sources:
- Read `pyproject.toml` and extract `version = "X.Y.Z"` when present.
- Read package `__init__.py` files when relevant and extract `__version__ = "X.Y.Z"` when present.
- Report mismatches or missing version declarations.

4. Inspect recent history:
`git log --oneline -20`
Also identify the latest release tag (prefer `v*`) and count commits since that tag.

5. Infer next version:
- Recommend major/minor/patch bump from commit intent (breaking/features/fixes).
- Ask user to confirm the exact next version before editing files.

6. Handle `CHANGELOG.md` when present:
- Detect current structure (`Unreleased` section and/or version headers).
- Preserve existing entries and format.
- After user confirms version, add or replace the target version header with today’s date.
- Summarize changes from commits between latest tag and `HEAD`.
- Collect commit-message `tags:` metadata when present and include aggregated tags in the changelog notes.

7. Run tests only when requested:
`uv run pytest`

## Output

Return a structured readiness summary including:

- Branch check (`main`) pass/fail
- Clean working tree pass/fail
- Version file findings (and mismatches)
- Latest release tag and commit count since release
- Recommended next version and user-confirmed version
- Changelog update status (if `CHANGELOG.md` exists)
- Test run status (if requested)

Ask for final confirmation before performing any release-adjacent write operations not already requested.
