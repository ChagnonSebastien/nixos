def esc: tostring | gsub("\\\\"; "\\\\") | gsub("\""; "\\\"");
def image: .ArtifactName | sub("@sha256:.*$"; "");
[.[] | image as $img | (.Results // [])[] | (.Vulnerabilities // [])[] | . + {img: $img}] as $v
| [.[] | image] as $images
| "# TYPE trivy_vulnerabilities gauge",
  ($images | unique[] as $img
    | ("CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN") as $sev
    | (true, false) as $fix
    | [$v[] | select(.img == $img and .Severity == $sev and ((.FixedVersion // "") != "") == $fix) | [.VulnerabilityID, .PkgName]] | unique | length
    | "trivy_vulnerabilities{image=\"\($img|esc)\",severity=\"\($sev)\",fixable=\"\($fix)\"} \(.)"),
  "# TYPE trivy_vulnerability gauge",
  ([$v[] | select(.Severity == "CRITICAL")
    | "trivy_vulnerability{image=\"\(.img|esc)\",id=\"\(.VulnerabilityID|esc)\",pkg=\"\(.PkgName|esc)\",installed=\"\(.InstalledVersion|esc)\",fixed=\"\(.FixedVersion // ""|esc)\"} 1"]
   | unique[]),
  "# TYPE trivy_last_scan_timestamp_seconds gauge",
  "trivy_last_scan_timestamp_seconds \($now)",
  "# TYPE trivy_scan_failed gauge",
  ($failed | split("\n")[] | select(. != "") | "trivy_scan_failed{image=\"\(.|esc)\"} 1")
