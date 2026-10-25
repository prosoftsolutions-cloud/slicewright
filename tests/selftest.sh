# The self-test of the plugin's tests. It breaks one thing at a time, in
# temporary copies, and shows that the static checks (tests/static.sh) and the
# smoke checks (tests/smoke.sh check) catch each case. It starts no Claude
# session and no headless run.
# Usage: sh tests/selftest.sh   (no arguments)
# It prints one line per case: "ok <case>", "caught <case>: <the matching FAIL
# line>", or "MISSED <case>: <why>" followed by the case's output, indented.
# The last line is "selftest: passed, <n> cases" or "selftest: failed, <k> of <n> cases".
# Exit status: 0 every case passed, 1 a case was missed, 2 a tool is missing.
#
# To add a case, copy a block below and change its break and its expected
# result. A static case breaks a copy of plugins/slice. A smoke case breaks a
# run folder prepared from the sample with the finished-run fixture on top.

cannot_run() {
  printf 'selftest: %s\n' "$1" >&2
  exit 2
}

if [ "$#" -ne 0 ]; then
  cannot_run "takes no arguments; usage: sh tests/selftest.sh"
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || cannot_run "cannot find the script's folder"
REPO=$(CDPATH= cd -- "$script_dir/.." && pwd) || cannot_run "cannot find the repo root"
PLUGIN="$REPO/plugins/slice"
SAMPLE="$REPO/tests/sample/project"
FIXTURE="$REPO/tests/fixtures/finished-run"

# static.sh needs claude for claude plugin validate. The self-test itself never calls it.
command -v claude >/dev/null 2>&1 || cannot_run "claude is missing"
command -v jq >/dev/null 2>&1 || cannot_run "jq is missing"
command -v git >/dev/null 2>&1 || cannot_run "git is missing"
command -v mktemp >/dev/null 2>&1 || cannot_run "mktemp is missing"
command -v cmp >/dev/null 2>&1 || cannot_run "cmp is missing"

# Every copy, temporary file and run folder goes in W.
W=$(mktemp -d "${TMPDIR:-/tmp}/slicewright-selftest.XXXXXX") || cannot_run "mktemp -d failed"
if [ -z "$W" ] || [ ! -d "$W" ]; then
  cannot_run "mktemp -d returned no folder"
fi
MADE=$W

# The smoke checks from 3 to 8, as <n>:<name>. Checks 1 and 2 need a real session.
SMOKE_CHECKS="3:status 4:records 5:tests 6:acceptance 7:clean-tree 8:index"

TOTAL=0
MISSED=0

# begin <case>: starts a case. Its files in W are named after it, as <level>-<name>.
begin() {
  CASE=$1
  SLUG="${1%%/*}-${1#*/}"
  WHY=
  LOG=
  LINE=
  OUT=
  STATUS=
}

# miss <why> [<output file>]: the case is missed, unless an earlier step missed it already.
miss() {
  if [ -z "$WHY" ]; then
    WHY=$1
    LOG=${2:-}
  fi
}

# report_case: prints the case's line. It is caught when a FAIL line matched, ok otherwise.
report_case() {
  TOTAL=$((TOTAL + 1))
  if [ -n "$WHY" ]; then
    MISSED=$((MISSED + 1))
    printf 'MISSED %s: %s\n' "$CASE" "$WHY"
    if [ -n "$LOG" ] && [ -f "$LOG" ]; then
      sed 's/^/  /' "$LOG"
    fi
  elif [ -n "$LINE" ]; then
    printf 'caught %s: %s\n' "$CASE" "$LINE"
  else
    printf 'ok %s\n' "$CASE"
  fi
}

# step <what> <command> [<arg>...]: runs the command, unless the case is missed
# already. When the command fails, the case is missed.
step() {
  if [ -n "$WHY" ]; then
    return 0
  fi
  st_what=$1
  shift
  if ! "$@" >"$W/$SLUG.step" 2>&1; then
    miss "couldn't $st_what" "$W/$SLUG.step"
  fi
}

# edit <jq|sed> <script> <file> <original>: runs jq or sed with the script on
# the file, into a temporary file in W, and moves the result over the file.
# The file must then differ from the original.
edit() {
  if [ -n "$WHY" ]; then
    return 0
  fi
  if ! "$1" "$2" "$3" >"$W/$SLUG.edit" 2>"$W/$SLUG.err"; then
    miss "$1 failed on $3" "$W/$SLUG.err"
  elif ! mv "$W/$SLUG.edit" "$3" 2>"$W/$SLUG.err"; then
    miss "couldn't move the edit over $3" "$W/$SLUG.err"
  fi
  broke differ "$3" "$4"
}

# broke <command> [<arg>...]: the command tests that the break changed
# something. When the test fails, the case is missed.
broke() {
  if [ -n "$WHY" ]; then
    return 0
  fi
  if ! "$@"; then
    miss "the break changed nothing"
  fi
}

# differ <file> <other>: the two files aren't the same, byte for byte.
differ() {
  ! cmp -s "$1" "$2"
}

# write_file <file> <line>: writes one line to the file.
write_file() {
  printf '%s\n' "$2" >"$1"
}

# line_of <prefix>: the first line of the case's output that starts with the prefix.
line_of() {
  awk -v p="$1" 'index($0, p) == 1 { print; exit }' "$OUT"
}

# need_line <prefix>: the case's output must have a line that starts with the prefix.
need_line() {
  if [ -z "$WHY" ] && [ -z "$(line_of "$1")" ]; then
    miss "no line starting with '$1'" "$OUT"
  fi
}

# --- Static level: static.sh on a broken copy of plugins/slice ---

# static_copy <case>: begins the case with a new copy of plugins/slice, COPY.
static_copy() {
  begin "$1"
  COPY="$W/$SLUG"
  if ! cp -R "$PLUGIN" "$COPY" >"$W/$SLUG.cp" 2>&1; then
    miss "couldn't copy $PLUGIN to $COPY" "$W/$SLUG.cp"
  fi
}

# static_edit <jq|sed> <script> <file>: the break, on the file at that path in the copy.
static_edit() {
  edit "$1" "$2" "$COPY/$3" "$PLUGIN/$3"
}

# static_run: runs static.sh on the copy.
static_run() {
  if [ -n "$WHY" ]; then
    return 0
  fi
  OUT="$W/$SLUG.out"
  sh "$REPO/tests/static.sh" "$COPY" </dev/null >"$OUT" 2>&1
  STATUS=$?
}

# static_passes: static.sh must exit 0.
static_passes() {
  if [ -z "$WHY" ] && [ "$STATUS" -ne 0 ]; then
    miss "static.sh exited with status $STATUS, not 0" "$OUT"
  fi
}

# static_fails <marker>: static.sh must exit 1, and print a line that starts
# with "FAIL " and contains the marker. Exit 2 means it couldn't run.
static_fails() {
  if [ -n "$WHY" ]; then
    return 0
  fi
  if [ "$STATUS" -eq 2 ]; then
    miss "static.sh couldn't run: it exited with status 2" "$OUT"
    return 0
  fi
  if [ "$STATUS" -ne 1 ]; then
    miss "static.sh exited with status $STATUS, not 1" "$OUT"
    return 0
  fi
  LINE=$(awk -v m="$1" 'index($0, "FAIL ") == 1 && index($0, m) > 0 { print; exit }' "$OUT")
  if [ -z "$LINE" ]; then
    miss "no FAIL line contains '$1'" "$OUT"
  fi
}

# static/unbroken: the copy as it is.
static_copy static/unbroken
static_run
static_passes
report_case

# static/next: a stage's next names no stage.
static_copy static/next
static_edit jq '(.pipeline[] | select(.name == "implement") | .next) = "no-such-stage"' defaults.json
static_run
static_fails ': stage implement: '
report_case

# static/choice: a choices value names no stage.
static_copy static/choice
static_edit jq '(.pipeline[] | select(.name == "design-review") | .params.choices.approve) = "no-such-stage"' defaults.json
static_run
static_fails ': stage design-review: '
report_case

# static/duplicate: two stages with the same name. No next, onError or choices names clarify.
static_copy static/duplicate
static_edit jq '(.pipeline[] | select(.name == "clarify") | .name) = "intake"' defaults.json
static_run
static_fails ': stage intake: '
report_case

# static/skill: a stage's skill names no skill folder.
static_copy static/skill
static_edit jq '(.pipeline[] | select(.name == "deploy") | .skill) = "slice:no-such-skill"' defaults.json
static_run
static_fails ': stage deploy: '
report_case

# static/name: a SKILL.md whose name differs from its folder.
static_copy static/name
static_edit sed 's/^name: plan$/name: planner/' skills/plan/SKILL.md
static_run
static_fails '/skills/plan/SKILL.md: '
report_case

# static/user-invocable: an internal skill without user-invocable: false.
static_copy static/user-invocable
static_edit sed '/^user-invocable: false$/d' skills/review/SKILL.md
static_run
static_fails '/skills/review/SKILL.md: '
report_case

# static/json: a JSON file that doesn't parse. Dropping the last line drops the closing }.
# The validation fails too; the case matches the json check's line by its path.
static_copy static/json
static_edit sed '$d' .claude-plugin/plugin.json
static_run
static_fails '/.claude-plugin/plugin.json: '
report_case

# --- Smoke level: smoke.sh check on a broken run folder ---

# The smoke source, built once: the sample, with the finished-run fixture laid on top.
# The /. form merges into doc/ and brings the hidden .slicewright/.
SOURCE="$W/source"
SOURCE_LOG="$W/source.log"
SOURCE_WHY=
if ! cp -R "$SAMPLE" "$SOURCE" >"$SOURCE_LOG" 2>&1; then
  SOURCE_WHY="couldn't copy the sample $SAMPLE to $SOURCE"
elif ! cp -R "$FIXTURE/." "$SOURCE" >"$SOURCE_LOG" 2>&1; then
  SOURCE_WHY="couldn't lay the fixture $FIXTURE over $SOURCE"
fi

# smoke_prepare <case>: begins the case with a new run folder, RUN, prepared
# from the smoke source by smoke.sh prepare. Its project is P.
smoke_prepare() {
  begin "$1"
  RUN="$W/$SLUG"
  P="$RUN/project"
  if [ -n "$SOURCE_WHY" ]; then
    miss "$SOURCE_WHY" "$SOURCE_LOG"
    return 0
  fi
  sh "$REPO/tests/smoke.sh" prepare "$SOURCE" "$RUN" </dev/null >"$W/$SLUG.prepare" 2>&1
  sp_status=$?
  if [ "$sp_status" -ne 0 ]; then
    miss "smoke.sh prepare exited with status $sp_status" "$W/$SLUG.prepare"
  fi
}

# smoke_edit <jq|sed> <script> <file>: the break, on the file at that path in
# the project. The original is the fixture's file.
smoke_edit() {
  edit "$1" "$2" "$P/$3" "$FIXTURE/$3"
}

# smoke_run: evaluates the checks on the run folder.
smoke_run() {
  if [ -n "$WHY" ]; then
    return 0
  fi
  OUT="$W/$SLUG.out"
  sh "$REPO/tests/smoke.sh" check "$RUN" </dev/null >"$OUT" 2>&1
  STATUS=$?
}

# smoke_exits_1: smoke.sh check must exit 1, because checks 1 and 2 always
# fail without a session. Exit 2 means it found no run folder.
smoke_exits_1() {
  if [ -n "$WHY" ]; then
    return 1
  fi
  if [ "$STATUS" -eq 1 ]; then
    return 0
  fi
  if [ "$STATUS" -eq 2 ]; then
    miss "smoke.sh check exited with status 2: not a run folder" "$OUT"
  else
    miss "smoke.sh check exited with status $STATUS, not 1" "$OUT"
  fi
  return 1
}

# smoke_passes: checks 1 and 2 fail, and every check from 3 to 8 passes.
smoke_passes() {
  smoke_exits_1 || return 0
  need_line "FAIL 1 session:"
  need_line "FAIL 2 isolation:"
  for sp_check in $SMOKE_CHECKS; do
    need_line "PASS ${sp_check%%:*} ${sp_check#*:}:"
  done
}

# smoke_fails <n> <name>: check n fails, and every other check from 3 to 8 passes.
smoke_fails() {
  smoke_exits_1 || return 0
  LINE=$(line_of "FAIL $1 $2:")
  if [ -z "$LINE" ]; then
    miss "no line starting with 'FAIL $1 $2:'" "$OUT"
    return 0
  fi
  for sf_check in $SMOKE_CHECKS; do
    if [ "$sf_check" != "$1:$2" ]; then
      need_line "PASS ${sf_check%%:*} ${sf_check#*:}:"
    fi
  done
}

# smoke/unbroken: the fixture as it is.
smoke_prepare smoke/unbroken
smoke_run
smoke_passes
report_case

# smoke/stage-failed: a stage row set to failed in status.md. slice/ is ignored, so no commit.
smoke_prepare smoke/stage-failed
smoke_edit sed 's/^| review | done |/| review | failed |/' slice/status.md
smoke_run
smoke_fails 3 status
report_case

# smoke/record-removed: a record removed from slice/.
smoke_prepare smoke/record-removed
step "remove slice/plan.md" rm "$P/slice/plan.md"
broke test ! -e "$P/slice/plan.md"
smoke_run
smoke_fails 4 records
report_case

# smoke/acceptance: a change that breaks the acceptance check: the sample's greet.sh, committed.
smoke_prepare smoke/acceptance
broke differ "$FIXTURE/greet.sh" "$SAMPLE/greet.sh"
step "copy the sample's greet.sh over the project's" cp "$SAMPLE/greet.sh" "$P/greet.sh"
step "add greet.sh" git -C "$P" add greet.sh
step "commit greet.sh" git -C "$P" commit -q -m "Put the sample's greet.sh back"
smoke_run
smoke_fails 6 acceptance
report_case

# smoke/uncommitted: an uncommitted file outside slice/.
smoke_prepare smoke/uncommitted
step "write notes.txt" write_file "$P/notes.txt" "A note nobody committed."
broke test -f "$P/notes.txt"
smoke_run
smoke_fails 7 clean-tree
report_case

# smoke/index-entry: the records index entry removed, committed.
smoke_prepare smoke/index-entry
step "write the new index" write_file "$W/$SLUG.index" "# Slices"
step "move the new index over .slicewright/slices/index.md" mv "$W/$SLUG.index" "$P/.slicewright/slices/index.md"
broke differ "$P/.slicewright/slices/index.md" "$FIXTURE/.slicewright/slices/index.md"
step "add the index" git -C "$P" add .slicewright/slices/index.md
step "commit the index" git -C "$P" commit -q -m "Remove the slice's index entry"
smoke_run
smoke_fails 8 index
report_case

# --- The end ---

if [ "$MISSED" -gt 0 ]; then
  printf 'kept: %s\n' "$W"
  printf 'selftest: failed, %s of %s cases\n' "$MISSED" "$TOTAL"
  exit 1
fi
case $W in
  */slicewright-selftest.*) removable=yes ;;
  *) removable=no ;;
esac
if [ -n "$W" ] && [ "$W" = "$MADE" ] && [ "$removable" = yes ]; then
  rm -rf "$W"
else
  printf 'kept: %s\n' "$W"
fi
printf 'selftest: passed, %s cases\n' "$TOTAL"
exit 0
