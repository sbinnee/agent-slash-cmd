#!/usr/bin/env bash

set -euo pipefail

# Keep original stdin on FD 3 so prompts still work inside loops
# that read file lists via process substitution.
exec 3<&0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
TOOL="claude"
DEFAULT_DIRECTION="repo"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--tool)
            if [[ -n "${2:-}" ]]; then
                TOOL="$2"
                shift 2
            else
                echo -e "${RED}Error: --tool requires a value${NC}"
                exit 1
            fi
            ;;
        -s|--source)
            if [[ -n "${2:-}" ]]; then
                DEFAULT_DIRECTION="$2"
                shift 2
            else
                echo -e "${RED}Error: --source requires a value${NC}"
                exit 1
            fi
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Sync provider-specific skills to a tool's directory"
            echo
            echo "Options:"
            echo "  -t, --tool TOOL    Tool name (default: claude)"
            echo "                     Supported: claude, codex"
            echo "  -s, --source SRC   Default apply direction at prompt: repo or local (default: repo)"
            echo "  -h, --help         Show this help message"
            echo
            echo "Provider is inferred from --tool:"
            echo "  claude -> skills/claude"
            echo "  codex -> skills/gpt"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Infer provider from tool
case "$TOOL" in
    claude) PROVIDER="claude" ;;
    codex) PROVIDER="gpt" ;;
    *) echo -e "${RED}Error: Unsupported tool '$TOOL'. Use 'claude' or 'codex'.${NC}"; exit 1 ;;
esac

REPO_SKILLS_DIR="./skills/$PROVIDER"
USER_SKILLS_DIR="$HOME/.$TOOL/skills"

case "$DEFAULT_DIRECTION" in
    repo|local) ;;
    *)
        echo -e "${RED}Error: Unsupported source '$DEFAULT_DIRECTION'. Use 'repo' or 'local'.${NC}"
        exit 1
        ;;
esac

if [[ "$DEFAULT_DIRECTION" == "repo" ]]; then
    DEFAULT_FROM_LABEL="repo"
    DEFAULT_TO_LABEL="local"
else
    DEFAULT_FROM_LABEL="local"
    DEFAULT_TO_LABEL="repo"
fi

# Prefer delta for prettier diffs when available.
if command -v delta > /dev/null 2>&1; then
    HAS_DELTA=1
else
    HAS_DELTA=0
fi

# Arrays to store skill info
declare -a skills=()
declare -a statuses=()
declare -a status_labels=()

echo "Comparing ${PROVIDER} skills between repo and local"
echo "Repo : $REPO_SKILLS_DIR"
echo "Local: $USER_SKILLS_DIR"
echo "Default direction: ${DEFAULT_FROM_LABEL} -> ${DEFAULT_TO_LABEL}"
echo

# Validate repo directory
if [[ ! -d "$REPO_SKILLS_DIR" ]]; then
    echo -e "${RED}Error: Repository skills directory not found: $REPO_SKILLS_DIR${NC}"
    exit 1
fi

# Create local skills directory if it doesn't exist
mkdir -p "$USER_SKILLS_DIR"

list_skill_names() {
    (
        if [[ -d "$REPO_SKILLS_DIR" ]]; then
            for skill_dir in "$REPO_SKILLS_DIR"/*; do
                [[ -d "$skill_dir" ]] && basename "$skill_dir"
            done
        fi
        if [[ -d "$USER_SKILLS_DIR" ]]; then
            for skill_dir in "$USER_SKILLS_DIR"/*; do
                [[ -d "$skill_dir" ]] && basename "$skill_dir"
            done
        fi
    ) | sort -u
}

# Scan all skill directories in repo/local union
while IFS= read -r skill_name; do
    [[ -z "$skill_name" ]] && continue

    repo_skill_dir="$REPO_SKILLS_DIR/$skill_name"
    user_skill_dir="$USER_SKILLS_DIR/$skill_name"

    if [[ -f "$repo_skill_dir/SKILL.md" ]] && [[ -f "$user_skill_dir/SKILL.md" ]]; then
        # Compare entire skill directory (SKILL.md + nested files like agents/openai.yaml)
        if ! diff -qr "$repo_skill_dir" "$user_skill_dir" > /dev/null 2>&1; then
            skills+=("$skill_name")
            statuses+=("U")
            status_labels+=("${YELLOW}U${NC}")
        fi
    elif [[ -f "$repo_skill_dir/SKILL.md" ]] || [[ -f "$user_skill_dir/SKILL.md" ]]; then
        skills+=("$skill_name")
        statuses+=("N")
        status_labels+=("${GREEN}N${NC}")
    fi
done < <(list_skill_names)

# If no skills need updating
if [[ ${#skills[@]} -eq 0 ]]; then
    echo -e "${GREEN}All skills are up to date between repo and local.${NC}"
    exit 0
fi

# Display menu
echo "Skills status:"
echo
for i in "${!skills[@]}"; do
    idx=$((i + 1))
    echo -e "[${idx}] (${status_labels[$i]}) ${skills[$i]}"
done
echo -e "[*] Copy and update all"
echo
echo -e "${GREEN}N${NC}: new, ${YELLOW}U${NC}: need update"
echo

render_diff() {
    local left_file=$1
    local right_file=$2

    if [[ "$HAS_DELTA" -eq 1 ]]; then
        (diff -u "$left_file" "$right_file" || true) | delta --paging=never
    else
        diff -u "$left_file" "$right_file" || true
    fi
}

files_differ() {
    local repo_file=$1
    local local_file=$2

    if [[ -e "$repo_file" && -e "$local_file" ]]; then
        if cmp -s "$repo_file" "$local_file"; then
            return 1
        fi
        return 0
    fi

    if [[ -e "$repo_file" || -e "$local_file" ]]; then
        return 0
    fi

    return 1
}

list_skill_files() {
    local skill_name=$1
    local repo_skill_dir="$REPO_SKILLS_DIR/$skill_name"
    local user_skill_dir="$USER_SKILLS_DIR/$skill_name"

    (
        if [[ -d "$repo_skill_dir" ]]; then
            (
                cd "$repo_skill_dir"
                find . \( -type f -o -type l \) -print | sed 's|^\./||'
            )
        fi
        if [[ -d "$user_skill_dir" ]]; then
            (
                cd "$user_skill_dir"
                find . \( -type f -o -type l \) -print | sed 's|^\./||'
            )
        fi
    ) | sort -u
}

sync_file_between() {
    local from_root=$1
    local to_root=$2
    local from_label=$3
    local skill_name=$4
    local rel_path=$5
    local source_file="$from_root/$skill_name/$rel_path"
    local target_file="$to_root/$skill_name/$rel_path"
    local cleanup_dir

    if [[ -e "$source_file" ]]; then
        mkdir -p "$(dirname "$target_file")"
        cp -R "$source_file" "$target_file"
    else
        rm -f "$target_file"
        cleanup_dir="$(dirname "$target_file")"
        while [[ "$cleanup_dir" != "$to_root/$skill_name" ]]; do
            rmdir "$cleanup_dir" 2>/dev/null || break
            cleanup_dir="$(dirname "$cleanup_dir")"
        done
        rmdir "$to_root/$skill_name" 2>/dev/null || true
    fi

    echo -e "${GREEN}✓${NC} Applied $skill_name/$rel_path (${from_label})"
}

# Function to process a skill
process_skill() {
    local skill_name=$1
    local status=$2

    local rel_path
    local repo_file
    local local_file
    local left_file
    local right_file
    local answer
    local changed_count=0
    local applied_count=0
    local default_choice

    if [[ "$DEFAULT_DIRECTION" == "repo" ]]; then
        default_choice="r"
    else
        default_choice="l"
    fi

    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue

        repo_file="$REPO_SKILLS_DIR/$skill_name/$rel_path"
        local_file="$USER_SKILLS_DIR/$skill_name/$rel_path"

        if ! files_differ "$repo_file" "$local_file"; then
            continue
        fi

        changed_count=$((changed_count + 1))
        echo -e "${BLUE}Diff for $skill_name/$rel_path${NC}"
        if [[ -e "$local_file" ]]; then
            left_file="$local_file"
        else
            left_file="/dev/null"
        fi
        if [[ -e "$repo_file" ]]; then
            right_file="$repo_file"
        else
            right_file="/dev/null"
        fi
        render_diff "$left_file" "$right_file"

        read -r -p "Apply direction [r/l/s] (r: repo->local, l: local->repo, s: skip, default: $default_choice): " answer <&3
        case "$answer" in
            "") answer="$default_choice" ;;
        esac

        case "$answer" in
            r|R)
                sync_file_between "$REPO_SKILLS_DIR" "$USER_SKILLS_DIR" "repo->local" "$skill_name" "$rel_path"
                applied_count=$((applied_count + 1))
                ;;
            l|L)
                sync_file_between "$USER_SKILLS_DIR" "$REPO_SKILLS_DIR" "local->repo" "$skill_name" "$rel_path"
                applied_count=$((applied_count + 1))
                ;;
            s|S|n|N)
                echo -e "${YELLOW}Skipped $skill_name/$rel_path${NC}"
                ;;
            *)
                echo -e "${YELLOW}Skipped $skill_name/$rel_path (invalid input: $answer)${NC}"
                ;;
        esac
        echo
    done < <(list_skill_files "$skill_name")

    if [[ "$changed_count" -eq 0 ]]; then
        echo -e "${GREEN}No file-level changes for $skill_name${NC}"
    elif [[ "$applied_count" -eq 0 ]]; then
        echo -e "${YELLOW}No changes applied for $skill_name${NC}"
    else
        echo -e "${GREEN}Applied $applied_count/$changed_count changes for $skill_name${NC}"
    fi
}

# Read user input
read -r -p "Select a number to sync a skill: " selection <&3

# Process selection
if [[ "$selection" == "*" ]]; then
    echo
    echo "Processing all skills..."
    echo
    for i in "${!skills[@]}"; do
        process_skill "${skills[$i]}" "${statuses[$i]}"
    done
    echo
    echo -e "${GREEN}All skills processed!${NC}"
elif [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#skills[@]} ]]; then
    idx=$((selection - 1))
    echo
    process_skill "${skills[$idx]}" "${statuses[$idx]}"
    echo
    echo -e "${GREEN}Done!${NC}"
else
    echo -e "${RED}Invalid selection${NC}"
    exit 1
fi
