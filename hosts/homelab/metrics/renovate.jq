def esc: tostring | gsub("\\\\"; "\\\\") | gsub("\""; "\\\"");
[.repositories[].packageFiles[][] | .packageFile as $f | .deps[] | . + {file: $f}] as $deps
| "# TYPE renovate_dependency gauge",
  ($deps[] | "renovate_dependency{dep=\"\(.depName|esc)\",current=\"\(.currentValue // ""|esc)\",file=\"\(.file|esc)\"} 1"),
  "# TYPE renovate_update_available gauge",
  ([$deps[] | .depName as $d | .currentValue as $c | (.updates // [])[]
    | "renovate_update_available{dep=\"\($d|esc)\",current=\"\($c|esc)\",new=\"\(.newValue // "digest"|esc)\",type=\"\(.updateType|esc)\"} 1"]
   | unique[]),
  "# TYPE renovate_last_success_timestamp_seconds gauge",
  "renovate_last_success_timestamp_seconds \($now)"
