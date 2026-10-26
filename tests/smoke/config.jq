$smoke[0] as $s | .pipeline as $defaults
| ($s.overrides | keys - $s.stages) as $stray
| if ($stray | length) > 0 then error("overrides name stages outside the smoke pipeline: \($stray | join(", "))") else . end
| {pipeline: [range(0; $s.stages | length) as $i | $s.stages[$i] as $name
    | [$defaults[] | select(.name == $name)]
    | if length != 1 then error("defaults.json has \(length) stages named \($name)") else .[0] end
    | del(.next, .onError) | .params = ((.params // {}) * ($s.overrides[$name] // {}))
    | if $i + 1 < ($s.stages | length) then .next = $s.stages[$i + 1] else . end]}
