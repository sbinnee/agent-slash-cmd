#!/usr/bin/env bash

set -euo pipefail

# Directories
REPO_SKILLS_DIR="./skills"
USER_SKILLS_DIR="$HOME/.claude/skills"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arrays to store skill info
declare -a skills=()
declare -a statuses=()
declare -a status_labels=()

echo "Scanning skills..."
echo

# Scan repo skills directory
if [[ ! -d "$REPO_SKILLS_DIR" ]]; then
    echo -e "${RED}Error: Repository skills directory not found: $REPO_SKILLS_DIR${NC}"
    exit 1
fi

# Create user skills directory if it doesn't exist
mkdir -p "$USER_SKILLS_DIR"

# Scan all skill directories in repo
for skill_dir in "$REPO_SKILLS_DIR"/*.md; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        repo_skill_file="$skill_dir/SKILL.md"
        user_skill_file="$USER_SKILLS_DIR/$skill_name/SKILL.md"

        if [[ ! -f "$repo_skill_file" ]]; then
            continue
        fi

        # Check if skill exists in user directory
        if [[ ! -f "$user_skill_file" ]]; then
            skills+=("$skill_name")
            statuses+=("N")
            status_labels+=("${GREEN}N${NC}")
        else
            # Compare content
            if ! diff -q "$repo_skill_file" "$user_skill_file" > /dev/null 2>&1; then
                skills+=("$skill_name")
                statuses+=("U")
                status_labels+=("${YELLOW}U${NC}")
            fi
        fi
    fi
done

# If no skills need updating
if [[ ${#skills[@]} -eq 0 ]]; then
    echo -e "${GREEN}All skills are up to date!${NC}"
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

# Function to copy skill
copy_skill() {
    local skill_name=$1
    local repo_skill_file="$REPO_SKILLS_DIR/$skill_name/SKILL.md"
    local user_skill_dir="$USER_SKILLS_DIR/$skill_name"
    local user_skill_file="$user_skill_dir/SKILL.md"

    mkdir -p "$user_skill_dir"
    cp "$repo_skill_file" "$user_skill_file"
    echo -e "${GREEN}✓${NC} Copied $skill_name"
}

# Function to diff skill
diff_skill() {
    local skill_name=$1
    local repo_skill_file="$REPO_SKILLS_DIR/$skill_name/SKILL.md"
    local user_skill_file="$USER_SKILLS_DIR/$skill_name/SKILL.md"

    # Check if nvim is available, fallback to vim
    if command -v nvim &> /dev/null; then
        nvim -d "$user_skill_file" "$repo_skill_file"
    elif command -v vim &> /dev/null; then
        vim -d "$user_skill_file" "$repo_skill_file"
    else
        echo -e "${RED}Error: Neither nvim nor vim is available${NC}"
        return 1
    fi
}

# Function to process a skill
process_skill() {
    local skill_name=$1
    local status=$2

    if [[ "$status" == "N" ]]; then
        copy_skill "$skill_name"
    else
        echo -e "${BLUE}Opening diff for $skill_name...${NC}"
        diff_skill "$skill_name"
    fi
}

# Read user input
read -p "Select a number to copy or update a skill: " selection

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
