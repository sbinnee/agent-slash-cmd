---
name: check-release
description: Verify readiness to release a new version
disable-model-invocation: true
argument-hint: [-t | --run-tests]
allowed-tools: Bash, Read, Edit, Grep, AskUserQuestion
---

# Release Readiness Check

Verify that the project is ready to release a new version. This checks:
1. No uncommitted changes
2. On the main branch
3. Version strings exist in `pyproject.toml` and/or `__init__.py`
4. CHANGELOG.md exists and can be updated (if present)
5. Git history to infer next version

## Checks to perform

### 1. Verify main branch
```bash
git branch --show-current
```
Ensure output is `main`.

### 2. Verify no uncommitted changes
```bash
git status --porcelain
```
Should return empty output.

### 3. Check version files
Read `pyproject.toml` and look for `version = "X.Y.Z"` pattern.
Read `__init__.py` if it exists and look for `__version__ = "X.Y.Z"` pattern.
Extract the current version from these files.

### 4. Show git history
```bash
git log --oneline -20
```
Look for tags like `v*` in the output to identify the last release. Based on the commits since the last tagged release, help the user determine what the next version should be (semantic versioning).

### 5. Infer next version
- Count commits since last tag/release
- Ask user to confirm the next version number
- Suggest a version bump based on commit messages (if they mention breaking changes, features, or fixes)

### 6. Handle CHANGELOG.md
If `CHANGELOG.md` exists:
- Check if it has an "Unreleased" section or version headers
- Follow the existing format (e.g., `## [X.Y.Z] - YYYY-MM-DD`)
- Once user confirms the version, auto-update CHANGELOG.md to add/replace the version header with today's date
- For contents, read all the git messages (head and body) from HEAD to the latest tag to summarize changes
- If there were "tags" in git messages, aggregate them all and include them
- Preserve existing entries

### 7. Optional: Run tests
If the user passed `-t` or `--run-tests` in arguments, run tests. Otherwise skip.
```bash
uv run pytest
```

## Output

Report:
- Branch status ✓/✗
- Uncommitted changes ✓/✗
- Version files found and current version
- Last release tag and commits since
- Next version (after user confirmation)
- CHANGELOG.md updated (if applicable)
- Tests run (if requested)

Present a summary. Ask for final confirmation before showing the next steps.
