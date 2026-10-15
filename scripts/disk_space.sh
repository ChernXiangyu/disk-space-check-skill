#!/bin/bash
# Free space on the volume holding PATH (default $HOME). Prints JSON.
# writable_gb: what a script can write now (= df). Size every large write by this.
# settings_gb: what macOS System Settings shows; adds purgeable space (e.g. downloaded Dropbox files not pinned
#              "available offline"), which is NOT freed in time for a script's writes.
# Usage: disk_space.sh [path]
P="${1:-$HOME}"
if [ "$(uname)" != "Darwin" ]; then
  echo "not macOS: df is the writable figure (no purgeable class); check quotas too" >&2
  df -h "$P"
  exit 0
fi
P="$(cd "$P" 2>/dev/null && pwd || echo "$P")"
osascript -l JavaScript - "$P" <<'JS'
ObjC.import("Foundation");
function run(argv) {
  var u = $.NSURL.fileURLWithPath(argv[0]);
  var keys = ["NSURLVolumeAvailableCapacityKey", "NSURLVolumeAvailableCapacityForImportantUsageKey",
              "NSURLVolumeAvailableCapacityForOpportunisticUsageKey", "NSURLVolumeTotalCapacityKey"];
  var r = u.resourceValuesForKeysError($(keys), null);
  var g = function (k) { var v = r.objectForKey(k); return v.isNil() ? null : Math.round(v.js / 1e8) / 10; };
  var w = g(keys[0]), s = g(keys[1]), o = g(keys[2]), t = g(keys[3]);
  return JSON.stringify({path: argv[0], writable_gb: w, settings_gb: s,
                         purgeable_gb_approx: (w !== null && s !== null) ? Math.round((s - w) * 10) / 10 : null,
                         opportunistic_gb: o, total_gb: t,
                         decide_with: "writable_gb (settings_gb adds purgeable space that is not freed in time for scripts)"});
}
JS
