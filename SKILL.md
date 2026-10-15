---
name: disk-space-check
description: Measure free disk space correctly before deciding where large files go, especially on macOS, where df, du and diskutil's "free space" leave out purgeable space (Dropbox, iCloud, OneDrive and Google Drive local copies, APFS snapshots) and can report a disk as 99% full when hundreds of gigabytes are actually available. Use this skill whenever you are about to judge whether a disk has room, write or copy large files (datasets, model weights, builds, archives), move data to an external drive or out of a synced folder "to save space", see "No space left on device" or a df/du reading near 100%, or read a project rule that says the disk is full; also when the user asks 磁盘满了吗 / 空间够不够 / 硬盘还剩多少. Never move data out of a project or onto an external drive because df looks full.
---

# Checking disk space without fooling yourself

On macOS the number you get from `df -h`, `du`, `diskutil info` ("Container Free Space") or Python's
`shutil.disk_usage` is **not** the space you can use. It leaves out *purgeable* space: files the system can delete on
its own when room is needed. On a machine with Dropbox, iCloud Drive, OneDrive or Google Drive, purgeable space is
often hundreds of gigabytes, because every cloud file that has been downloaded is a local copy the File Provider can
evict at any time.

A real case: `df -h ~` said 99% used, 34 GiB free. macOS Settings said 1.3 TB of 2 TB used. The volume's
"available for important usage" was 683 GB; 630 GB was purgeable Dropbox copies. An agent that trusted df moved a
project's data to an external drive, wrote "the home disk is nearly full" into the project's instructions, and every
later session obeyed it. Months later sixteen scripts depended on the external drive and the project could not run on
another computer.

## Rule

1. **Measure with the operating system's own "available" figure** (below). Never decide from df, du, diskutil free
   space or `shutil.disk_usage` alone.
2. **Never move data out of a project, off a synced folder or onto an external drive because space looks short.**
   If the correct figure really is too small for what you are about to write, stop and ask the user.
3. **Never write "the disk is full" into a project file without the evidence**: the command, the figure, the date.
   A belief written into instructions outlives the session that formed it.

## How to measure

### macOS (the one that matters)

Run the bundled script:

```bash
bash ~/.claude/skills/disk-space-check/scripts/disk_space.sh [path]   # default: $HOME
```

It prints three figures for the volume holding `path`:

| figure | meaning | use it for |
|---|---|---|
| `important_gb` | `NSURLVolumeAvailableCapacityForImportantUsageKey`: what a user-initiated write can get, after macOS evicts purgeable files. Matches System Settings → Storage and Finder | **every decision** |
| `opportunistic_gb` | `...ForOpportunisticUsageKey`: room for caches and background work without evicting anything important | deciding whether to keep a cache |
| `plain_gb` | `NSURLVolumeAvailableCapacityKey`, same as df | explaining why df looked full |

`important_gb − plain_gb` is roughly the purgeable space. The script needs only `osascript` (JavaScript for
Automation), which every macOS has; no Python packages.

One-liner if the script is not at hand:

```bash
osascript -l JavaScript -e 'ObjC.import("Foundation"); var r=$.NSURL.fileURLWithPath("/Users").resourceValuesForKeysError($(["NSURLVolumeAvailableCapacityForImportantUsageKey"]),null); (r.objectForKey("NSURLVolumeAvailableCapacityForImportantUsageKey").js/1e9).toFixed(1)+" GB"'
```

What takes the purgeable space (to explain it, not to "fix" it):
- cloud-drive local copies: Dropbox, iCloud Drive, OneDrive, Google Drive on File Provider (`~/Library/CloudStorage/`);
- local Time Machine snapshots: `tmutil listlocalsnapshots /`;
- system caches macOS marks purgeable.

When macOS evicts a cloud copy, the file becomes online-only and is downloaded again the next time something reads it.
That is slower, not wrong. Files the user pinned "available offline" are not purgeable.

### Linux

`df` is honest there (no purgeable class), but check the right filesystem (`df -h <path>`), quotas (`quota -s`) and,
on clusters, the scratch versus home limits the cluster documents.

### Windows

`Get-PSDrive C` or `fsutil volume diskfree C:`; OneDrive "Files On-Demand" copies behave like macOS purgeable files.

## Writing large files into a synced folder

Writing many gigabytes into Dropbox or iCloud is fine when the important figure allows it: the client uploads, and
macOS evicts older local copies when it needs room. Copy in one go with `rsync -a`, verify (file counts, sizes,
checksums or a manifest), and only then delete any original elsewhere, after the user confirms.

## When you find a wrong "disk is full" rule

1. Measure as above and show both numbers (important versus df) to the user.
2. Propose replacing the rule with a measured one, recording the command, figures and date.
3. List what the old rule caused (data outside the project, hard-coded paths) and propose moving it back.
