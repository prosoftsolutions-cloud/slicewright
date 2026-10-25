# The smoke level of the plugin's tests. It runs the pipeline headless on a
# copy of the sample project, within a time limit, and checks what the run
# leaves. Run it from the repo root as `sh tests/smoke.sh`: see usage below.

LIMIT_MINUTES=90
WAIT_SECONDS=540
CHECK_SECONDS=120
CONFIG_NAME=smoke.json
SLICE_DIR=slice
RECORDS="input.md spec.md design.md plan.md implement.md code-reviews.md"
TEST_COMMAND="sh test.sh"
RECORDS_INDEX=.slicewright/slices/index.md

unset CDPATH

case $0 in
  */*) SCRIPT_DIR=${0%/*} ;;
  *) SCRIPT_DIR=. ;;
esac
REPO=$(cd -P "$SCRIPT_DIR/.." && pwd -P) || exit 2
PLUGIN_DIR="$REPO/plugins/slice"
SMOKE_DATA="$REPO/tests/smoke"
SAMPLE="$REPO/tests/sample/project"
REQUEST="$REPO/tests/sample/request.md"
ACCEPT="$REPO/tests/sample/accept.sh"

# The command's run folder, once it is known.
RUN=

usage() {
  cat <<'EOF'
usage: sh tests/smoke.sh [--minutes <n>]
         run the smoke test in the foreground: prepare, session, checks, report
       sh tests/smoke.sh start [--minutes <n>]
         prepare, start the session in the background, and return
       sh tests/smoke.sh wait <run folder>
         wait for a background run to end, and print its report
       sh tests/smoke.sh check <run folder>
         evaluate the checks again on what a run left
       sh tests/smoke.sh prepare <source folder> <run folder>
         copy a source folder, write the test configuration, and commit
EOF
  exit 2
}

say() {
  printf '%s\n' "$*"
}

# The last line of every command whose run folder exists.
run_line() {
  if [ -n "$RUN" ] && [ -d "$RUN" ]; then
    say "run: $RUN"
  fi
}

# Exit 2: the command couldn't run.
fail() {
  say "error: $*"
  run_line
  exit 2
}

not_run_folder() {
  say "error: $1 isn't a run folder: it has no project/ folder"
  exit 2
}

# A path made absolute against the current folder, without resolving links.
abs_path() {
  ap_path=$1
  while :; do
    case $ap_path in
      ?*/) ap_path=${ap_path%/} ;;
      *) break ;;
    esac
  done
  case $ap_path in
    /*) say "$ap_path" ;;
    *) say "${PWD:-$(pwd)}/$ap_path" ;;
  esac
}

physical_dir() {
  (cd -P "$1" 2>/dev/null && pwd -P)
}

parent_of() {
  po_parent=${1%/*}
  say "${po_parent:-/}"
}

# Whether an absolute path, which may not exist yet, is the repo or inside it.
in_repo() {
  ir_parent=$(physical_dir "$(parent_of "$1")") || return 1
  ir_path="${ir_parent%/}/${1##*/}"
  case $ir_path in
    "$REPO" | "$REPO"/*) return 0 ;;
  esac
  return 1
}

need_tools() {
  nt_missing=
  for nt_tool in "$@"; do
    if ! command -v "$nt_tool" >/dev/null 2>&1; then
      nt_missing="$nt_missing $nt_tool"
    fi
  done
  if [ -n "$nt_missing" ]; then
    fail "missing tools:$nt_missing; install them and put them on PATH"
  fi
}

# Joins the non-empty lines of $1 with $2, " / " by default, into one line.
one_line() {
  printf '%s\n' "$1" | awk -v sep="${2:- / }" '
    { sub(/\r$/, ""); sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "") }
    $0 != "" { if (n++) printf "%s", sep; printf "%s", $0 }
    END { printf "\n" }'
}

# run.txt holds "key: value" lines; the last value of a key counts.
run_value() {
  if [ -f "$RUN/run.txt" ]; then
    awk -v k="$1" '
      $0 == k ":" { v = ""; f = 1 }
      index($0, k ": ") == 1 { v = substr($0, length(k) + 3); f = 1 }
      END { if (f) print v }' "$RUN/run.txt"
  fi
}

record() {
  printf '%s: %s\n' "$1" "$2" >>"$RUN/run.txt"
}

frontmatter_value() {
  awk -v k="$1" '
    { sub(/\r$/, "") }
    $0 ~ /^---[ \t]*$/ { if (++fm == 2) exit; next }
    fm == 1 && index($0, k ":") == 1 {
      v = substr($0, length(k) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      print v; exit
    }' "$2"
}

# watchdog <pid> <seconds> [marker]: checks the process every 5 seconds. At
# the limit it writes the marker, sends TERM, and sends KILL 30 seconds later
# if the process is still alive. Its PID is left in WATCHDOG_PID; the caller
# kills it as soon as the process ends.
watchdog() {
  (
    wd_pid=$1
    wd_limit=$2
    wd_marker=${3:-}
    wd_sleep=
    trap 'if [ -n "$wd_sleep" ]; then kill "$wd_sleep" 2>/dev/null; fi; exit 0' TERM
    wd_elapsed=0
    while kill -0 "$wd_pid" 2>/dev/null; do
      if [ "$wd_elapsed" -ge "$wd_limit" ]; then
        if [ -n "$wd_marker" ]; then
          : >"$wd_marker"
        fi
        kill -TERM "$wd_pid" 2>/dev/null
        sleep 30 &
        wd_sleep=$!
        wait "$wd_sleep"
        wd_sleep=
        if kill -0 "$wd_pid" 2>/dev/null; then
          kill -KILL "$wd_pid" 2>/dev/null
        fi
        exit 0
      fi
      sleep 5 &
      wd_sleep=$!
      wait "$wd_sleep"
      wd_sleep=
      wd_elapsed=$((wd_elapsed + 5))
    done
  ) </dev/null >/dev/null 2>&1 &
  WATCHDOG_PID=$!
}

# The rules the session is allowed up front, joined with commas.
allowed_tools() {
  at_rules=$(awk '{ sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "") } $0 != "" && substr($0, 1, 1) != "#"' \
    "$SMOKE_DATA/allowed-tools") || return 1
  at_skills=$(jq -r '[.. | objects | .skill? // empty | strings] | unique | .[] | select(. != "TBD") | "Skill(\(.))"' \
    "$RUN/project/.slicewright/$CONFIG_NAME") || return 1
  printf '%s\n' "$at_rules" 'Skill(slice:run)' 'Skill(slice:tracking)' "$at_skills" \
    "Read(/$PLUGIN_DIR/**)" 'Read(~/.slicewright/**)' |
    awk 'NF && !seen[$0]++ { if (n++) printf ","; printf "%s", $0 } END { printf "\n" }'
}

# prepare <source> <run> [quiet]: the copy, the configuration and the commit.
do_prepare() {
  dp_source=$(abs_path "$1")
  RUN=$(abs_path "$2")
  if [ ! -d "$dp_source" ]; then
    fail "the source folder $dp_source doesn't exist"
  fi
  if [ -e "$RUN" ] || [ -L "$RUN" ]; then
    fail "the run folder $RUN already exists; give a new one"
  fi
  dp_parent=$(parent_of "$RUN")
  if [ ! -d "$dp_parent" ]; then
    fail "the run folder's parent $dp_parent doesn't exist"
  fi
  if in_repo "$RUN"; then
    fail "the run folder $RUN is inside the repo $REPO; give one outside it"
  fi
  need_tools jq git
  mkdir "$RUN" || fail "couldn't create the run folder $RUN"
  cp -R "$dp_source" "$RUN/project" || fail "couldn't copy $dp_source to $RUN/project"
  mkdir -p "$RUN/project/.slicewright" || fail "couldn't create $RUN/project/.slicewright"
  if ! dp_error=$(jq --slurpfile smoke "$SMOKE_DATA/pipeline.json" -f "$SMOKE_DATA/config.jq" \
    "$PLUGIN_DIR/defaults.json" 2>&1 >"$RUN/project/.slicewright/$CONFIG_NAME"); then
    fail "couldn't generate the test configuration: $(one_line "$dp_error")"
  fi
  dp_ignore="$RUN/project/.gitignore"
  if [ -s "$dp_ignore" ] && [ -n "$(tail -c 1 "$dp_ignore")" ]; then
    printf '\n' >>"$dp_ignore" || fail "couldn't write $dp_ignore"
  fi
  printf '/%s/\n' "$SLICE_DIR" >>"$dp_ignore" || fail "couldn't write $dp_ignore"
  git -C "$RUN/project" init -q || fail "git init failed in $RUN/project"
  git -C "$RUN/project" config --local user.name "Slicewright smoke test" || fail "git config failed"
  git -C "$RUN/project" config --local user.email smoke-test@slicewright.invalid || fail "git config failed"
  git -C "$RUN/project" config --local commit.gpgsign false || fail "git config failed"
  git -C "$RUN/project" add -A || fail "git add failed in $RUN/project"
  git -C "$RUN/project" commit -q -m "Sample project for a smoke run" || fail "git commit failed in $RUN/project"
  if [ "${3:-}" != quiet ]; then
    say "prepared: $RUN/project"
    say "run: $RUN"
  fi
}

# Sets RESULT to the last result event of the session, and COST and DURATION.
load_result() {
  RESULT=
  COST=unknown
  DURATION=unknown
  if [ -s "$RUN/session.jsonl" ]; then
    RESULT=$(jq -c -n -R '[inputs | fromjson? | select(type == "object" and .type == "result")] | last // empty' \
      "$RUN/session.jsonl" 2>/dev/null)
  fi
  if [ -n "$RESULT" ]; then
    lr_value=$(printf '%s\n' "$RESULT" | jq -r '.total_cost_usd | numbers' 2>/dev/null)
    if [ -n "$lr_value" ]; then
      COST=$lr_value
    fi
    lr_value=$(printf '%s\n' "$RESULT" | jq -r '.duration_ms | numbers' 2>/dev/null)
    if [ -n "$lr_value" ]; then
      DURATION=$lr_value
    fi
  fi
}

time_limit_stopped() {
  [ "$(run_value time_limit_reached)" = yes ] || [ -e "$RUN/timed-out" ]
}

# result <n> <name> PASS|FAIL <detail>
result() {
  rs_detail=$(one_line "$4")
  say "$3 $1 $2: $rs_detail"
  if [ "$3" != PASS ]; then
    FAILED=$((FAILED + 1))
  fi
}

check_session() {
  if [ ! -s "$RUN/session.jsonl" ]; then
    result 1 session FAIL "no session output"
    return
  fi
  if time_limit_stopped; then
    result 1 session FAIL "the time limit of $(run_value limit_minutes) minutes stopped the session"
    return
  fi
  if [ "$(run_value interrupted)" = yes ]; then
    result 1 session FAIL "the session was interrupted before it ended"
    return
  fi
  cs_exit=$(run_value exit_code)
  if [ -z "$cs_exit" ]; then
    result 1 session FAIL "no exit code recorded in run.txt"
    return
  fi
  if [ "$cs_exit" != 0 ]; then
    result 1 session FAIL "the session exited with status $cs_exit"
    return
  fi
  if [ -z "$RESULT" ]; then
    result 1 session FAIL "no result event in the session output"
    return
  fi
  cs_verdict=$(printf '%s\n' "$RESULT" | jq -r '
    if .is_error == true or .subtype != "success"
    then "the result is an error: subtype \(.subtype | tostring), is_error \(.is_error | tostring)"
    else "ok" end' 2>/dev/null)
  if [ "$cs_verdict" = ok ]; then
    result 1 session PASS "the session ended with success, within the time limit"
  else
    result 1 session FAIL "${cs_verdict:-the result event cannot be read}"
  fi
}

check_isolation() {
  ci_plugin=$(run_value plugin_dir)
  ci_init=
  if [ -s "$RUN/session.jsonl" ]; then
    ci_init=$(jq -c -n -R 'first(inputs | fromjson? | select(type == "object" and .type == "system" and .subtype == "init"))' \
      "$RUN/session.jsonl" 2>/dev/null)
  fi
  if [ -z "$ci_init" ]; then
    result 2 isolation FAIL "no init event in the session output"
    return
  fi
  if [ -z "$ci_plugin" ]; then
    result 2 isolation FAIL "no plugin_dir in run.txt"
    return
  fi
  ci_verdict=$(printf '%s\n' "$ci_init" | jq -r --arg pd "$ci_plugin" '
    [(.plugins // [])[] | select(.path != "builtin") | {name, path}] as $p
    | [(.mcp_servers // []) | if type == "array" then .[] | (.name? // tostring) else keys[] end] as $m
    | if $p == [{name: "slice", path: $pd}] and ($m | length) == 0
      then "PASS only slice, from \($pd), and no MCP server"
      else "FAIL plugins: \(if $p == [] then "none" else [$p[] | "\(.name) at \(.path)"] | join(", ") end); MCP servers: \(if $m == [] then "none" else $m | join(", ") end)"
      end' 2>/dev/null)
  case $ci_verdict in
    "PASS "*) result 2 isolation PASS "${ci_verdict#PASS }" ;;
    "FAIL "*) result 2 isolation FAIL "${ci_verdict#FAIL }" ;;
    *) result 2 isolation FAIL "the init event has no plugins list that can be read" ;;
  esac
}

check_status() {
  cst_file="$RUN/project/$SLICE_DIR/status.md"
  if [ ! -f "$cst_file" ]; then
    result 3 status FAIL "no $SLICE_DIR/status.md"
    return
  fi
  cst_names=$(jq -r '.pipeline[].name' "$RUN/project/.slicewright/$CONFIG_NAME" 2>/dev/null)
  if [ -z "$cst_names" ]; then
    result 3 status FAIL "no stage names in .slicewright/$CONFIG_NAME"
    return
  fi
  cst_count=0
  for cst_name in $cst_names; do
    cst_count=$((cst_count + 1))
  done
  cst_problems=$(SMOKE_STAGES=$cst_names awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    BEGIN {
      n = split(ENVIRON["SMOKE_STAGES"], want, "\n")
      for (i = 1; i <= n; i++) if (want[i] != "") wanted[want[i]] = 1
    }
    { sub(/\r$/, "") }
    fm < 2 && $0 ~ /^---[ \t]*$/ { fm++; next }
    fm == 1 {
      if ($0 ~ /^status:/) { has_status = 1; status = trim(substr($0, 8)) }
      else if ($0 ~ /^next:/) { has_next = 1; nxt = trim(substr($0, 6)) }
      next
    }
    $0 ~ /^## / { stages = ($0 ~ /^## Stages[ \t]*$/); if (stages) table = 1; next }
    stages && $0 ~ /^\|/ {
      if (++lines == 1) next
      if ($0 ~ /^\|[ \t:]*-/) next
      split($0, cell, "|")
      rows++
      row_name[rows] = trim(cell[2]); row_status[rows] = trim(cell[3])
      count[row_name[rows]]++
    }
    END {
      if (fm < 2) print "no frontmatter"
      if (!has_status) print "no status in the frontmatter"
      else if (status != "done") print "status is " (status == "" ? "empty" : status)
      if (!has_next) print "no next in the frontmatter"
      else if (nxt != "") print "next is " nxt
      if (!table) { print "no Stages table"; exit }
      for (i = 1; i <= n; i++) {
        s = want[i]
        if (s == "") continue
        if (!(s in count)) print "no row for " s
        else if (count[s] > 1) print count[s] " rows for " s
      }
      for (r = 1; r <= rows; r++) {
        s = row_name[r]
        if (!(s in wanted)) print "unexpected row " s
        else if (row_status[r] != "done") print s " is " (row_status[r] == "" ? "empty" : row_status[r])
      }
    }' "$cst_file")
  if [ -z "$cst_problems" ]; then
    result 3 status PASS "status done, next empty, and one done row for each of the $cst_count stages"
  else
    result 3 status FAIL "$(one_line "$cst_problems" "; ")"
  fi
}

check_records() {
  cr_missing=
  cr_empty=
  for cr_file in $RECORDS; do
    cr_path="$RUN/project/$SLICE_DIR/$cr_file"
    if [ ! -f "$cr_path" ]; then
      cr_missing="${cr_missing:+$cr_missing, }$cr_file"
    elif [ ! -s "$cr_path" ]; then
      cr_empty="${cr_empty:+$cr_empty, }$cr_file"
    fi
  done
  if [ -z "$cr_missing" ] && [ -z "$cr_empty" ]; then
    result 4 records PASS "$SLICE_DIR/ holds $RECORDS"
  else
    cr_detail=
    if [ -n "$cr_missing" ]; then
      cr_detail="missing: $cr_missing"
    fi
    if [ -n "$cr_empty" ]; then
      cr_detail="${cr_detail:+$cr_detail; }empty: $cr_empty"
    fi
    result 4 records FAIL "$cr_detail in $SLICE_DIR/"
  fi
}

# Removes a scratch folder: only the non-empty path mktemp -d returned, when
# it is an existing folder outside the run folder.
remove_scratch() {
  if [ -z "$1" ] || [ ! -d "$1" ]; then
    return 0
  fi
  rs_scratch=$(physical_dir "$1") || return 0
  rs_run=$(physical_dir "$RUN") || return 0
  if [ -z "$rs_scratch" ] || [ "$rs_scratch" = / ] || [ -z "$rs_run" ]; then
    return 0
  fi
  case $rs_scratch in
    "$rs_run" | "$rs_run"/*) return 0 ;;
  esac
  rm -rf "$1"
}

# run_in_copy tests|acceptance: runs the command in a scratch copy of the
# project, under the watchdog. Sets COPY_STATUS, COPY_TIMED_OUT, COPY_TAIL,
# COPY_LAST and COPY_NOT_OK.
run_in_copy() {
  COPY_STATUS=
  COPY_TIMED_OUT=no
  COPY_TAIL=
  COPY_LAST=
  COPY_NOT_OK=
  ric_scratch=$(mktemp -d 2>/dev/null)
  if [ -z "$ric_scratch" ] || [ ! -d "$ric_scratch" ]; then
    COPY_TAIL="couldn't make a scratch folder"
    return
  fi
  ric_copy="$ric_scratch/project"
  if mkdir "$ric_copy" && cp -R "$RUN/project/." "$ric_copy"; then
    if [ "$1" = tests ]; then
      (
        cd "$ric_copy" || exit 2
        exec $TEST_COMMAND
      ) </dev/null >"$ric_scratch/output" 2>&1 &
    else
      (
        cd "$ric_copy" || exit 2
        exec sh "$ACCEPT" "$ric_copy"
      ) </dev/null >"$ric_scratch/output" 2>&1 &
    fi
    ric_pid=$!
    watchdog "$ric_pid" "$CHECK_SECONDS" "$ric_scratch/timed-out"
    wait "$ric_pid"
    COPY_STATUS=$?
    kill "$WATCHDOG_PID" 2>/dev/null
    if [ -e "$ric_scratch/timed-out" ]; then
      COPY_TIMED_OUT=yes
    fi
    # The scratch copy is removed below, so its path reads as <copy>.
    awk -v s="$ric_copy" '{
        out = ""
        while ((i = index($0, s)) > 0) { out = out substr($0, 1, i - 1) "<copy>"; $0 = substr($0, i + length(s)) }
        print out $0
      }' "$ric_scratch/output" >"$ric_scratch/output.txt"
    COPY_TAIL=$(tail -n 5 "$ric_scratch/output.txt")
    COPY_LAST=$(tail -n 1 "$ric_scratch/output.txt")
    COPY_NOT_OK=$(grep '^not ok' "$ric_scratch/output.txt")
  else
    COPY_TAIL="couldn't copy the project to a scratch folder"
  fi
  remove_scratch "$ric_scratch"
}

check_tests() {
  run_in_copy tests
  if [ -z "$COPY_STATUS" ]; then
    result 5 tests FAIL "$COPY_TAIL"
  elif [ "$COPY_TIMED_OUT" = yes ]; then
    result 5 tests FAIL "\`$TEST_COMMAND\` didn't end within $CHECK_SECONDS seconds; its last lines: $(one_line "$COPY_TAIL")"
  elif [ "$COPY_STATUS" -eq 0 ]; then
    result 5 tests PASS "\`$TEST_COMMAND\` passed${COPY_LAST:+: $COPY_LAST}"
  else
    result 5 tests FAIL "\`$TEST_COMMAND\` exited with status $COPY_STATUS: $(one_line "$COPY_TAIL")"
  fi
}

check_acceptance() {
  if [ ! -f "$ACCEPT" ]; then
    result 6 acceptance FAIL "no tests/sample/accept.sh"
    return
  fi
  run_in_copy acceptance
  if [ -z "$COPY_STATUS" ]; then
    result 6 acceptance FAIL "$COPY_TAIL"
  elif [ "$COPY_TIMED_OUT" = yes ]; then
    result 6 acceptance FAIL "accept.sh didn't end within $CHECK_SECONDS seconds; its last lines: $(one_line "$COPY_TAIL")"
  elif [ "$COPY_STATUS" -eq 0 ]; then
    result 6 acceptance PASS "${COPY_LAST:-accept.sh passed}"
  elif [ -n "$COPY_NOT_OK" ]; then
    result 6 acceptance FAIL "$(one_line "$COPY_NOT_OK")"
  else
    result 6 acceptance FAIL "accept.sh exited with status $COPY_STATUS: $(one_line "$COPY_TAIL")"
  fi
}

check_clean_tree() {
  if [ ! -d "$RUN/project/.git" ]; then
    result 7 clean-tree FAIL "no project/.git: the copy isn't under version control"
    return
  fi
  if ! cct_out=$(git --no-optional-locks -C "$RUN/project" status --porcelain --untracked-files=all 2>&1); then
    result 7 clean-tree FAIL "git status failed: $(one_line "$cct_out")"
    return
  fi
  cct_paths=$(printf '%s\n' "$cct_out" | awk -v d="$SLICE_DIR/" '
    function outside(p) { if (substr(p, 1, 1) == "\"") p = substr(p, 2); return index(p, d) != 1 }
    $0 != "" {
      p = substr($0, 4); k = index(p, " -> ")
      if (k) { if (outside(substr(p, 1, k - 1)) || outside(substr(p, k + 4))) print p }
      else if (outside(p)) print p
    }')
  if [ -z "$cct_paths" ]; then
    result 7 clean-tree PASS "no uncommitted change outside $SLICE_DIR/"
  else
    result 7 clean-tree FAIL "uncommitted changes outside $SLICE_DIR/: $(one_line "$cct_paths" ", ")"
  fi
}

check_index() {
  cx_status="$RUN/project/$SLICE_DIR/status.md"
  if [ ! -f "$cx_status" ]; then
    result 8 index FAIL "no $SLICE_DIR/status.md"
    return
  fi
  cx_created=$(frontmatter_value created "$cx_status")
  cx_date=$(printf '%s\n' "$cx_created" | awk '{ print substr($0, 1, 10); exit }')
  case $cx_date in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *)
      result 8 index FAIL "no created date in $SLICE_DIR/status.md"
      return
      ;;
  esac
  cx_index="$RUN/project/$RECORDS_INDEX"
  if [ ! -f "$cx_index" ]; then
    result 8 index FAIL "no $RECORDS_INDEX"
    return
  fi
  cx_line=$(awk -v p="## $cx_date " '{ sub(/\r$/, "") } index($0, p) == 1 { print; exit }' "$cx_index")
  if [ -n "$cx_line" ]; then
    result 8 index PASS "$cx_line"
  else
    result 8 index FAIL "no line starting with '## $cx_date ' in $RECORDS_INDEX"
  fi
}

# Evaluates the eight checks and prints the report. Returns 0 when all pass.
report() {
  FAILED=0
  load_result
  check_session
  check_isolation
  check_status
  check_records
  check_tests
  check_acceptance
  check_clean_tree
  check_index
  say "cost_usd: $COST"
  say "duration_ms: $DURATION"
  if time_limit_stopped; then
    rp_limit=$(run_value limit_minutes)
    say "time limit: the session was stopped after ${rp_limit:-unknown} minutes"
  fi
  if [ "$FAILED" -eq 0 ]; then
    say "result: passed"
  else
    say "result: failed, $FAILED of 8 checks failed"
  fi
  say "run: $RUN"
  [ "$FAILED" -eq 0 ]
}

on_signal() {
  GOT_SIGNAL=yes
  if [ "$INTERRUPTED" = yes ]; then
    return
  fi
  INTERRUPTED=yes
  record interrupted yes
  if [ -n "$SESSION_PID" ]; then
    # TERM now, and KILL 30 seconds later if the session is still alive.
    watchdog "$SESSION_PID" 0
    STOPPER_PID=$WATCHDOG_PID
  fi
}

# The session part: the headless session under the watchdog, the record,
# the report in checks.txt, and last the ended file.
session_part() {
  sp_plugin=$(run_value plugin_dir)
  sp_limit=$(run_value limit_minutes)
  sp_allowed=$(run_value allowed_tools)
  case $sp_limit in
    '' | *[!0-9]*) fail "run.txt has no limit_minutes" ;;
  esac
  if [ -z "$sp_plugin" ] || [ -z "$sp_allowed" ]; then
    fail "run.txt has no plugin_dir or allowed_tools"
  fi
  if [ ! -f "$RUN/request.md" ]; then
    fail "no request.md in $RUN"
  fi
  sp_request=$(cat "$RUN/request.md")
  INTERRUPTED=no
  GOT_SIGNAL=no
  SESSION_PID=
  STOPPER_PID=
  trap on_signal INT TERM
  (
    cd "$RUN/project" || exit 2
    unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SESSION_ID CLAUDE_CODE_CHILD_SESSION
    unset CLAUDE_CODE_SESSION_ATTENDED CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN
    unset CLAUDE_PID CLAUDE_EFFORT AI_AGENT
    exec claude -p "/slice:new --config $CONFIG_NAME $sp_request" \
      --output-format stream-json --verbose \
      --setting-sources project,local --strict-mcp-config \
      --plugin-dir "$sp_plugin" \
      --permission-mode acceptEdits --permission-prompts none \
      --no-session-persistence --allowedTools "$sp_allowed"
  ) </dev/null >"$RUN/session.jsonl" 2>"$RUN/session.err" &
  SESSION_PID=$!
  watchdog "$SESSION_PID" $((sp_limit * 60)) "$RUN/timed-out"
  SESSION_WATCHDOG=$WATCHDOG_PID
  wait "$SESSION_PID"
  sp_status=$?
  # A trapped signal ends the wait early: wait again for the real status.
  while [ "$GOT_SIGNAL" = yes ]; do
    GOT_SIGNAL=no
    wait "$SESSION_PID"
    sp_status=$?
  done
  trap - INT TERM
  kill "$SESSION_WATCHDOG" 2>/dev/null
  if [ -n "$STOPPER_PID" ]; then
    kill "$STOPPER_PID" 2>/dev/null
  fi
  if [ -e "$RUN/timed-out" ]; then
    sp_time_limit=yes
  else
    sp_time_limit=no
  fi
  load_result
  record ended "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  record exit_code "$sp_status"
  record time_limit_reached "$sp_time_limit"
  record interrupted "$INTERRUPTED"
  record cost_usd "$COST"
  record duration_ms "$DURATION"
  report >"$RUN/checks.txt"
  sp_rc=$?
  if [ "$sp_rc" -ne 0 ]; then
    sp_rc=1
  fi
  printf '%s\n' "$sp_rc" >"$RUN/ended"
  cat "$RUN/checks.txt"
  return "$sp_rc"
}

# The foreground run and start: refusals, prepare, run.txt, then the session.
launch() {
  ln_mode=$1
  shift
  ln_minutes=$LIMIT_MINUTES
  if [ $# -gt 0 ]; then
    if [ "$1" != --minutes ]; then
      usage
    fi
    if [ $# -lt 2 ]; then
      fail "--minutes needs a positive whole number of minutes"
    fi
    if [ $# -gt 2 ]; then
      usage
    fi
    case $2 in
      [1-9] | [1-9]*[0-9])
        case $2 in
          *[!0-9]*) fail "--minutes needs a positive whole number of minutes, not '$2'" ;;
        esac
        ;;
      *) fail "--minutes needs a positive whole number of minutes, not '$2'" ;;
    esac
    ln_minutes=$2
  fi
  if [ -e "${HOME:-}/.slicewright/$CONFIG_NAME" ]; then
    fail "${HOME:-}/.slicewright/$CONFIG_NAME exists, and the runner would merge it into the test configuration; move it away for the smoke run"
  fi
  need_tools claude jq git
  if [ ! -d "$SAMPLE" ]; then
    fail "the sample project $SAMPLE is missing"
  fi
  if [ ! -f "$REQUEST" ]; then
    fail "the sample request $REQUEST is missing"
  fi
  ln_tmp=${TMPDIR:-/tmp}
  while :; do
    case $ln_tmp in
      */) ln_tmp=${ln_tmp%/} ;;
      *) break ;;
    esac
  done
  if [ ! -d "${ln_tmp:-/}" ]; then
    fail "the temporary folder ${ln_tmp:-/} doesn't exist"
  fi
  ln_base="$ln_tmp/slicewright-smoke"
  if in_repo "$ln_base"; then
    fail "the runs folder $ln_base is inside the repo $REPO; set TMPDIR to a folder outside it"
  fi
  mkdir -p "$ln_base" || fail "couldn't create $ln_base"
  ln_run="$ln_base/$(date -u +%Y%m%dT%H%M%SZ)-$$"
  if [ "$ln_mode" = foreground ]; then
    say "run: $ln_run"
  fi
  do_prepare "$SAMPLE" "$ln_run" quiet
  if [ "$ln_mode" = foreground ]; then
    say "prepared: $RUN/project"
  fi
  cp "$REQUEST" "$RUN/request.md" || fail "couldn't copy the request to $RUN/request.md"
  ln_allowed=$(allowed_tools) || fail "couldn't build the allowed tools"
  record plugin_dir "$PLUGIN_DIR"
  record limit_minutes "$ln_minutes"
  record allowed_tools "$ln_allowed"
  record started "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  record smoke_pid "$$"
  if [ "$ln_mode" = foreground ]; then
    say "session: started, time limit $ln_minutes minutes"
    session_part
    exit $?
  fi
  nohup sh "$REPO/tests/smoke.sh" _finish "$RUN" </dev/null >"$RUN/smoke.log" 2>&1 &
  record smoke_pid "$!"
  say "prepared: $RUN/project"
  say "session: started in the background, time limit $ln_minutes minutes"
  say "next: sh tests/smoke.sh wait $RUN"
  say "run: $RUN"
  exit 0
}

cmd_wait() {
  if [ $# -ne 1 ] || [ -z "$1" ]; then
    usage
  fi
  wt_run=$(abs_path "$1")
  if [ ! -d "$wt_run/project" ]; then
    not_run_folder "$wt_run"
  fi
  RUN=$wt_run
  need_tools jq git
  wt_elapsed=0
  while :; do
    if [ -e "$RUN/ended" ]; then
      if [ -f "$RUN/checks.txt" ]; then
        cat "$RUN/checks.txt"
      else
        report
      fi
      if [ "$(cat "$RUN/ended")" = 0 ]; then
        exit 0
      fi
      exit 1
    fi
    wt_pid=$(run_value smoke_pid)
    if [ -z "$wt_pid" ] || ! kill -0 "$wt_pid" 2>/dev/null; then
      if [ -e "$RUN/ended" ]; then
        continue
      fi
      say "ended: the background run stopped without finishing; checks evaluated now"
      if [ -z "$wt_pid" ]; then
        # No run started here: write nothing, as check does.
        report
        exit 1
      fi
      # The run started and its process is gone: record it as ended, as
      # session_part does, with ended written last.
      load_result
      record cost_usd "$COST"
      record duration_ms "$DURATION"
      report >"$RUN/checks.txt"
      printf '%s\n' 1 >"$RUN/ended"
      cat "$RUN/checks.txt"
      exit 1
    fi
    if [ "$wt_elapsed" -ge "$WAIT_SECONDS" ]; then
      say "running: the session has not ended yet"
      say "run: $RUN"
      exit 3
    fi
    sleep 5
    wt_elapsed=$((wt_elapsed + 5))
  done
}

cmd_check() {
  if [ $# -ne 1 ] || [ -z "$1" ]; then
    usage
  fi
  ck_run=$(abs_path "$1")
  if [ ! -d "$ck_run/project" ]; then
    not_run_folder "$ck_run"
  fi
  RUN=$ck_run
  need_tools jq git
  report
  exit $?
}

cmd_finish() {
  if [ $# -ne 1 ] || [ -z "$1" ]; then
    usage
  fi
  fn_run=$(abs_path "$1")
  if [ ! -d "$fn_run/project" ]; then
    not_run_folder "$fn_run"
  fi
  RUN=$fn_run
  session_part
  exit $?
}

case ${1-} in
  start)
    shift
    launch start "$@"
    ;;
  wait)
    shift
    cmd_wait "$@"
    ;;
  check)
    shift
    cmd_check "$@"
    ;;
  prepare)
    shift
    if [ $# -ne 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
      usage
    fi
    do_prepare "$1" "$2"
    exit 0
    ;;
  _finish)
    shift
    cmd_finish "$@"
    ;;
  --minutes)
    launch foreground "$@"
    ;;
  '')
    if [ $# -ne 0 ]; then
      usage
    fi
    launch foreground
    ;;
  *)
    usage
    ;;
esac
