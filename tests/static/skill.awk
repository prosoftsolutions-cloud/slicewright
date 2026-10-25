# Checks a SKILL.md's frontmatter, and prints one "<file>: <problem>" line per problem.
# Usage: awk -v file=<path> -v folder=<name> -v internal=<1|0> -f tests/static/skill.awk <path>
# The frontmatter runs from line 1, which must be ---, to the next --- line. POSIX awk only.

# Trims spaces and tabs, then removes one pair of matching surrounding quotes.
function clean(value,    first, last) {
    sub(/^[ \t]+/, "", value)
    sub(/[ \t]+$/, "", value)
    if (length(value) >= 2) {
        first = substr(value, 1, 1)
        last = substr(value, length(value), 1)
        if ((first == "\"" || first == "'") && first == last) {
            value = substr(value, 2, length(value) - 2)
        }
    }
    return value
}

BEGIN { state = "before" }

{
    line = $0
    sub(/\r$/, "", line)
}

NR == 1 {
    if (line != "---") {
        state = "none"
        exit
    }
    state = "inside"
    next
}

line == "---" {
    state = "closed"
    exit
}

!has_name && line ~ /^name:/ {
    has_name = 1
    name = clean(substr(line, 6))
    next
}

!has_description && line ~ /^description:/ {
    has_description = 1
    description = clean(substr(line, 13))
    next
}

!has_invocable && line ~ /^user-invocable:/ {
    has_invocable = 1
    invocable = clean(substr(line, 16))
    next
}

END {
    if (state != "closed") {
        print file ": has no frontmatter between --- lines"
        exit 0
    }
    if (!has_name) {
        print file ": name is missing"
    } else if (name != folder) {
        print file ": name is \"" name "\", not \"" folder "\""
    }
    if (!has_description || description == "") {
        print file ": description is missing or empty"
    }
    if (internal == 1 && (!has_invocable || invocable != "false")) {
        print file ": user-invocable is not false, and the skill is internal"
    }
    exit 0
}
