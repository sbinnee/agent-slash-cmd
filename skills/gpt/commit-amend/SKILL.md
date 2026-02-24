---
name: commit-amend
description: Amend the latest git commit using the staged diff and keep existing tags if present.
---


# Commit Amend

Amend the latest commit using staged changes.

## Steps

1. Check state:
- `git status`
- `git diff --staged HEAD`
2. If nothing is staged, stop and warn.
3. Read latest commit message:
- `git log -1 --pretty=full`
4. Keep existing `tags:` line only if present in the latest commit message.
5. Write a new message from staged diff:
- HEAD: concise summary
- BODY: optional, only if useful
6. Run one amend commit using staged changes only:
- `git commit --amend -m "<HEAD>" -m "<BODY>" [-m "tags: ..."]`

## Constraints

- Never run `git add` or stage files.
- Do not add tags unless they already exist in the previous commit message.
