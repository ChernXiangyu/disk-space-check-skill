#!/bin/bash
# Free space on the volume holding PATH (default $HOME), as macOS counts it.
# important_gb is what a user write can really get (purgeable cloud copies and snapshots are evicted on demand);
# plain_gb is what df reports. Decide with important_gb.
# Usage: disk_space.sh [path]
P="${1:-$HOME}"
if [ "$(uname)" != "Darwin" ]; then
  echo "not macOS: df is accurate here (no purgeable class); check quotas too" >&2
  df -h "$P"
  exit 0
fi
P="$(cd "$P" 2>/dev/null && pwd || echo "$P")"
osascript -l JavaScript - "$P" <<'JS'
ObjC.import("Foundation");
function run(argv) {
  var u = $.NSURL.fileURLWithPath(argv[0]);
  var keys = ["NSURLVolumeAvailableCapacityForImportantUsageKey", "NSURLVolumeAvailableCapacityForOpportunisticUsageKey",
              "NSURLVolumeAvailableCapacityKey", "NSURLVolumeTotalCapacityKey"];
  var r = u.resourceValuesForKeysError($(keys), null);
  var g = function (k) { var v = r.objectForKey(k); return v.isNil() ? null : Math.round(v.js / 1e8) / 10; };
  var imp = g(keys[0]), opp = g(keys[1]), plain = g(keys[2]), tot = g(keys[3]);
  return JSON.stringify({path: argv[0], important_gb: imp, opportunistic_gb: opp, plain_gb: plain, total_gb: tot,
                         purgeable_gb_approx: (imp !== null && plain !== null) ? Math.round((imp - plain) * 10) / 10 : null,
                         decide_with: "important_gb"});
}
JS
