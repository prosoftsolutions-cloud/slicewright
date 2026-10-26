# Static level: checks a plugin folder without a model.
# It runs claude plugin validate on the repo and on the plugin folder, checks that every JSON file
# parses, checks the pipeline in defaults.json, and checks each skill's frontmatter.
# Usage: sh tests/static.sh [<plugin folder>]   (default: plugins/slice)
# Exit status: 0 every check passed, 1 a check failed, 2 couldn't run.

# The skills that may be user-invocable. Every other skill is internal.
USER_INVOCABLE="new resume configure"

cannot_run() {
    printf 'static: cannot run: %s\n' "$1" >&2
    exit 2
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || cannot_run "cannot find the script's folder"
repo=$(CDPATH= cd -- "$script_dir/.." && pwd) || cannot_run "cannot find the repo root"

if [ "$#" -gt 1 ]; then
    cannot_run "too many arguments; usage: sh tests/static.sh [<plugin folder>]"
fi
plugin=${1:-"$repo/plugins/slice"}
if [ ! -d "$plugin" ]; then
    cannot_run "$plugin is not a folder"
fi
plugin=$(CDPATH= cd -- "$plugin" && pwd) || cannot_run "cannot open the folder $plugin"
command -v claude >/dev/null 2>&1 || cannot_run "the claude command is not installed"
command -v jq >/dev/null 2>&1 || cannot_run "the jq command is not installed"

problems=0

# Prints one FAIL line and counts it as a problem.
fail() {
    printf 'FAIL %s\n' "$1"
    problems=$((problems + 1))
}

# Prints a FAIL line, with the given prefix, for each non-empty line of the given text.
fail_lines() {
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            fail "$1$line"
        fi
    done <<EOF
$2
EOF
}

# Prints PASS <check> when the check added no problem since the count it started from.
pass_unless_failed() {
    if [ "$problems" -eq "$2" ]; then
        printf 'PASS %s\n' "$1"
    fi
}

# validate: claude plugin validate on the repo and on the plugin folder. Only the exit status counts.
validate() {
    output=$(claude plugin validate "$1" </dev/null 2>&1)
    if [ "$?" -ne 0 ]; then
        fail "validate: $1: claude plugin validate failed"
        printf '%s\n' "$output" | sed 's/^/  /'
    fi
}

start=$problems
validate "$repo"
validate "$plugin"
pass_unless_failed validate "$start"

# json: every JSON file under the plugin folder and under the repo's .claude-plugin holds exactly one value.
start=$problems
if [ -d "$repo/.claude-plugin" ]; then
    files=$(find "$plugin" "$repo/.claude-plugin" -type f -name '*.json' | sort -u)
else
    files=$(find "$plugin" -type f -name '*.json' | sort -u)
fi
while IFS= read -r file; do
    if [ -n "$file" ]; then
        jq -e -s 'length == 1' "$file" >/dev/null 2>&1
        status=$?
        if [ "$status" -eq 1 ]; then
            fail "json: $file: does not hold exactly one JSON value"
        elif [ "$status" -ne 0 ]; then
            fail "json: $file: does not parse"
        fi
    fi
done <<EOF
$files
EOF
pass_unless_failed json "$start"

# defaults: the pipeline in defaults.json, against the skill folders that hold a SKILL.md.
start=$problems
set --
for dir in "$plugin"/skills/*/; do
    if [ -f "${dir}SKILL.md" ]; then
        name=${dir%/}
        set -- "$@" "${name##*/}"
    fi
done
skills=$(jq -n -c '$ARGS.positional' --args "$@")
output=$(jq -r --argjson skills "$skills" -f "$repo/tests/static/defaults.jq" "$plugin/defaults.json" 2>/dev/null)
if [ "$?" -eq 0 ]; then
    fail_lines "defaults: " "$output"
else
    fail "defaults: $plugin/defaults.json: does not parse"
fi
pass_unless_failed defaults "$start"

# skills: each skill folder has a SKILL.md with a valid frontmatter.
start=$problems
for dir in "$plugin"/skills/*/; do
    if [ -d "$dir" ]; then
        name=${dir%/}
        name=${name##*/}
        file="$plugin/skills/$name/SKILL.md"
        if [ -f "$file" ]; then
            case " $USER_INVOCABLE " in
                *" $name "*) internal=0 ;;
                *) internal=1 ;;
            esac
            output=$(awk -v file="$file" -v folder="$name" -v internal="$internal" -f "$repo/tests/static/skill.awk" "$file" 2>/dev/null)
            if [ "$?" -eq 0 ]; then
                fail_lines "skills: " "$output"
            else
                fail "skills: $file: tests/static/skill.awk failed on it"
            fi
        else
            fail "skills: $plugin/skills/$name: has no SKILL.md"
        fi
    fi
done
pass_unless_failed skills "$start"

if [ "$problems" -eq 0 ]; then
    printf 'static: passed\n'
    exit 0
fi
printf 'static: failed, %s problems\n' "$problems"
exit 1
