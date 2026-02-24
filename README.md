# My Slash Commands for Coding Agents
Personal collection of slash-style skills for coding agents.

Provider-specific versions are separated under:
- `skills/claude/`
- `skills/gpt/`

Reference:
- https://code.claude.com/docs/en/skills
- https://developers.openai.com/codex/skills/

## Skills
- commit: Create a git commit with optional tags
- commit-amend: Amend latest commit from staged changes
- check-release: Verify readiness to release a new version

## Helper
[sync-skills.sh](./sync-skills.sh)

Supported tools: `claude`, `codex`

Examples:
- `./sync-skills.sh --tool claude`
- `./sync-skills.sh --tool codex`
- `./sync-skills.sh --tool codex --source repo`
- `./sync-skills.sh --tool codex --source local`

By default, `sync-skills.sh` uses `repo -> local` as the default choice at each diff prompt.
