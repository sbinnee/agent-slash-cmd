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
- `git log -1 --pretty=%B`
4. Write a message for the **full combined commit** (old + new changes):
- Use the existing message as baseline.
- Extend it if the new changes add to it; rewrite parts that the new changes supersede.
- Keep existing `tags:` line only if present.
5. Run one amend commit using staged changes only:
- `git commit --amend -m "<message>"`

## Constraints

- Never run `git add` or stage files.
- Message must reflect the whole commit, not just the new diff.
- Do not add tags unless already present.
