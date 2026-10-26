# Checks a plugin's defaults.json, and prints one "<subject>: <problem>" line per problem.
# Usage: jq -r --argjson skills '<JSON list of skill folder names>' -f tests/static/defaults.jq <plugin>/defaults.json
# It never raises an error on a JSON value: a value that isn't an object where one is expected counts as {}.

def obj: if type == "object" then . else {} end;

def text: type == "string" and length > 0;

# TBD, or slice:<name> where <name> is a folder under skills/ that holds a SKILL.md.
def valid_skill:
  type == "string"
  and (. == "TBD"
       or (startswith("slice:") and (ltrimstr("slice:") as $name | any($skills[]; . == $name))));

# Every invalid "skill" value at any depth, the top included, as JSON.
def bad_skills: obj | .. | objects | select(has("skill")) | .skill | select(valid_skill | not) | tojson;

def names_a_stage($names): . as $value | any($names[]; . == $value);

obj as $root
| ($root.sharedParams | obj) as $shared
| (if $shared.activeSlicePath | text then empty else "sharedParams: activeSlicePath is missing or empty" end),
  ($shared | bad_skills | "sharedParams: skill \(.) names no skill folder"),
  ($root.pipeline
   | if type != "array" or length == 0 then "pipeline: missing or empty"
     else
       [.[] | obj] as $stages
       | [$stages[].name | select(text)] as $names
       | range(0; $stages | length) as $i
       | $stages[$i] as $stage
       | ($stage.params | obj) as $params
       | (if $stage.name | text then "stage \($stage.name)" else "stage number \($i + 1)" end) as $subject
       | (if $stage.name | text then
            ([$names[] | select(. == $stage.name)] | length) as $count
            | select($count > 1 and ([range(0; $i) | select($stages[.].name == $stage.name)] | length) == 0)
            | "\($count) stages have this name"
          else "has no name" end),
         (if $stage.executionMode == "inline" or $stage.executionMode == "fork" then empty
          else "executionMode \($stage.executionMode | tojson) is not inline or fork" end),
         (if $stage.params != null and ($stage.params | type) != "object" then "params is not an object" else empty end),
         (if $stage.skill == null and ($params.context | text | not) then "has no skill and no params.context" else empty end),
         (if $stage.skill != null and ($stage.skill | valid_skill | not)
          then "skill \($stage.skill | tojson) names no skill folder" else empty end),
         ($params | bad_skills | "params skill \(.) names no skill folder"),
         (if $params | has("activeSlicePath") then "params sets activeSlicePath" else empty end),
         ($stage.next | select(. != null and (names_a_stage($names) | not)) | "next names no stage: \(tojson)"),
         ($stage.onError | select(. != null and (names_a_stage($names) | not)) | "onError names no stage: \(tojson)"),
         ($params.choices
          | if type == "object" then
              to_entries[]
              | select(.value != null and (.value | names_a_stage($names) | not))
              | "choice \(.key) names no stage: \(.value | tojson)"
            else empty end)
       | "\($subject): \(.)"
     end)
