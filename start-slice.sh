#!/bin/sh
# Prepares this working copy for a new slice, then starts Claude Code with the stable plugin.
# It checks the tools, switches to master and fast-forwards it to origin/master, puts the stable
# plugin's worktree in .slicewright/stable/ at origin/master, and validates that plugin: what the
# slice's intake checks. With an issue number, the session starts with /slice:new <number>.
# Usage: sh start-slice.sh [<issue number>]
# Exit status: 1 a check failed, 2 couldn't run. Otherwise the script becomes the Claude session.

REMOTE=origin
MAIN=master
STABLE=.slicewright/stable
# The activeSlicePath of .slicewright/config.json.
SLICE=slice

cannot_run() {
    printf 'start-slice: cannot run: %s\n' "$1" >&2
    exit 2
}

fail() {
    printf 'start-slice: %s\n' "$1" >&2
    exit 1
}

say() {
    printf 'start-slice: %s\n' "$1"
}

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || cannot_run "cannot find the repo root"
cd "$repo" || cannot_run "cannot open $repo"

if [ "$#" -gt 1 ]; then
    cannot_run "too many arguments; usage: sh start-slice.sh [<issue number>]"
fi
issue=${1#\#}
case $issue in
    *[!0-9]*) cannot_run "not an issue number: $1; usage: sh start-slice.sh [<issue number>]" ;;
esac

for tool in git gh claude; do
    command -v "$tool" >/dev/null 2>&1 || cannot_run "the $tool command is not installed"
done
gh auth status >/dev/null 2>&1 || fail "gh is not signed in: run gh auth login"

# The working copy: clean, on master, at origin/master.
if [ -n "$(git status --porcelain)" ]; then
    git status --short >&2
    fail "the working copy has uncommitted changes: commit, stash or discard them, then run again"
fi
git switch --quiet "$MAIN" || fail "cannot switch to $MAIN"
git fetch --quiet "$REMOTE" || fail "cannot fetch $REMOTE"
git merge --quiet --ff-only "$REMOTE/$MAIN" || fail "$MAIN has diverged from $REMOTE/$MAIN: reconcile them, then run again"
target=$(git rev-parse "$REMOTE/$MAIN") || cannot_run "cannot read $REMOTE/$MAIN"
if [ "$(git rev-parse HEAD)" != "$target" ]; then
    fail "$MAIN has commits that $REMOTE/$MAIN doesn't: push them or move them to a branch, then run again"
fi
say "$MAIN is at $(git rev-parse --short HEAD), the same as $REMOTE/$MAIN"

# The stable plugin: a detached worktree of this repository at origin/master.
git worktree prune
if [ ! -e "$STABLE" ]; then
    git worktree add --quiet --detach "$STABLE" "$target" || fail "cannot add the worktree $STABLE"
    say "added $STABLE/"
else
    common=$(git rev-parse --path-format=absolute --git-common-dir)
    stable_common=$(git -C "$STABLE" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    stable_top=$(git -C "$STABLE" rev-parse --show-toplevel 2>/dev/null)
    if [ "$stable_common" != "$common" ] || [ "$stable_top" != "$repo/$STABLE" ]; then
        fail "$STABLE/ is not a worktree of this repository: move it away, then run again"
    fi
    if [ -n "$(git -C "$STABLE" status --porcelain)" ]; then
        git -C "$STABLE" status --short >&2
        fail "$STABLE/ has local changes: discard them, then run again"
    fi
    if [ "$(git -C "$STABLE" rev-parse HEAD)" != "$target" ]; then
        git -C "$STABLE" checkout --quiet --detach "$target" || fail "cannot move $STABLE/ to $REMOTE/$MAIN"
        say "moved $STABLE/ to $REMOTE/$MAIN"
    fi
fi
if [ "$(git -C "$STABLE" rev-parse HEAD)" != "$target" ]; then
    fail "$STABLE/ is not at $REMOTE/$MAIN"
fi
say "$STABLE/ is at $(git -C "$STABLE" rev-parse --short HEAD)"

plugin=$repo/$STABLE/plugins/slice
if ! out=$(claude plugin validate "$plugin" 2>&1); then
    printf '%s\n' "$out" >&2
    fail "the stable plugin doesn't validate: fix $MAIN first"
fi
say "the stable plugin validates"

# A slice left in the slice folder: /slice:new asks whether to continue it or start over.
if [ -f "$SLICE/status.md" ]; then
    title=$(sed -n 's/^title: *//p' "$SLICE/status.md" | sed -n 1p)
    title=${title#\"}
    title=${title%\"}
    stage=$(sed -n 's/^stage: *//p' "$SLICE/status.md" | sed -n 1p)
    status=$(sed -n 's/^status: *//p' "$SLICE/status.md" | sed -n 1p)
    say "note: ./$SLICE/ holds a slice: \"$title\", at $stage ($status). /slice:new will ask whether to continue it or start over"
elif [ -f "$SLICE/input.md" ]; then
    say "note: ./$SLICE/ holds a slice that never finished starting. /slice:new will ask whether to continue it or start over"
fi

if [ -n "$issue" ]; then
    say "starting Claude with the stable plugin and /slice:new $issue"
    exec claude --plugin-dir "$plugin" "/slice:new $issue"
fi
say "starting Claude with the stable plugin"
exec claude --plugin-dir "$plugin"
