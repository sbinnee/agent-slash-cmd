---
name: commit
description: Create exactly one git commit from staged changes. Use when users ask to commit staged work, with optional verbose body (`-v/--verbose`), rationale text (`-x/--explanation`), and optional tags (`-t/--tags`).
disable-model-invocation: true
argument-hint: [-v|--verbose] [-x|--explanation [<explanation>]] [-t|--tags "<tag1 tag2 ...>"]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git commit:*)
---

# Commit

Create exactly one commit from staged changes.

## Steps

1. Run and inspect:
- `git status`
- `git diff --staged HEAD`
- `git branch --show-current`
- `git log --oneline -10`
2. If nothing is staged, stop and say there is nothing to commit.
3. Build the commit message:
- HEAD: concise and specific (prefer <= 50 chars)
- BODY: optional; short by default, fuller with `-v/--verbose`
- `-x/--explanation`: interpret as intent/context and rewrite naturally into HEAD/BODY; do not paste the explanation verbatim unless the user explicitly asks for a direct quote
- `-x/--explanation`: do not add rigid labels like `Rationale:` or `Explanation:` just because `-x` is present
- `-t/--tags "<...>"`: include `tags: <...>` only when provided
4. Run one `git commit` for staged changes only.

Example for `-x` handling:
- Input explanation: `from local to repo. I've worked with codex to improve this skill`
- Good outcome: synthesize that intent into natural commit wording (e.g., "sync local skill improvements back to repo"), not a copied sentence.

## Message format
```text
<HEAD: concise summary, target 50 chars or less>

<BODY: short explanation of what/why; optional, but include when useful>

tags: <space-separated tags from -t/--tags>
```

## Constraints

- Never run `git add`.
- Do not include unstaged changes.
- Create exactly one commit.
