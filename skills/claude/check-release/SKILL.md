---
name: check-release
description: Verify readiness to release a new version
disable-model-invocation: true
argument-hint: [-t | --run-tests]
allowed-tools: Bash, Read, Edit, Grep, AskUserQuestion
---

# Release Readiness Check

Run this checklist in order.

## Checks

1. Branch
- `git branch --show-current` must be `main`.

2. Clean working tree
- `git status --porcelain` must be empty.

3. Version sources
- Read `pyproject.toml` for `version = "X.Y.Z"`.
- Read `__init__.py` (if present) for `__version__ = "X.Y.Z"`.
- Report current version and mismatches.

4. Git history
- `git log --oneline -20`
- Find the latest `v*` tag and summarize commits since then.

5. Next version
- Suggest semantic version bump from commit history.
- Ask user to confirm the target version.

6. `CHANGELOG.md` (if present)
- Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0).
- Ensure `## [Unreleased]` exists at the top.
- Group commits since latest tag under: Added, Changed, Deprecated, Removed, Fixed, Security.
- After user confirms version `X.Y.Z`:
  - Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`.
  - Insert a new empty `## [Unreleased]` above it.
  - Update bottom compare links for `[Unreleased]` and `[X.Y.Z]`.
- Keep older entries unchanged.

7. Optional tests
- If `-t` or `--run-tests` is passed, run `uv run pytest`.

## Output

Report:
- Branch status ✓/✗
- Uncommitted changes ✓/✗
- Version files found and current version
- Last release tag and commits since
- Next version (after user confirmation)
- CHANGELOG.md updated (if applicable)
- Tests run (if requested)

Present a concise summary and ask for final confirmation before release actions.
