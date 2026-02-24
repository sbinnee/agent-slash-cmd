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
Keep a Changelog Standard [keep a changelog](https://keepachangelog.com/en/1.1.0)

If CHANGELOG.md exists:
- Format Verification: Ensure the file follows the Keep a Changelog format. Look for the ## [Unreleased] section at the top.
- Git Log Analysis: Read all git messages (subject and body) from HEAD to the latest git tag.
- Auto-Summarization: Categorize the git messages into the standard Keep a Changelog headers:
    - Added: For new features.
    - Changed: For changes in existing functionality.
    - Deprecated: For soon-to-be removed features.
    - Removed: For now removed features.
    - Fixed: For any bug fixes.
    - Security: In case of vulnerabilities.
- Version Transition:
    - Once the user confirms the version (e.g., 1.2.3), rename the ## [Unreleased] section to ## [1.2.3] - YYYY-MM-DD.
    - Create a new, empty ## [Unreleased] section above the new version header.
- Link References: Update the link definitions at the bottom of the file (e.g., [Unreleased]: https://github/.../compare/v1.2.3...HEAD and [1.2.3]: https://github/.../compare/v1.2.2...v1.2.3).
- Preservation: Ensure all historical version entries below the current change remains untouched.

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
