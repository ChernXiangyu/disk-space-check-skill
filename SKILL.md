---
name: disk-space-check
description: Measure free disk space correctly before writing or copying large files, especially on macOS with Dropbox, iCloud, OneDrive or Google Drive, where two honest-looking figures disagree by hundreds of gigabytes - df (what a script can write now) and System Settings (which adds purgeable cloud-drive copies that are NOT freed in time for a script). Use this skill whenever you are about to judge whether a disk has room, write or copy large files (datasets, model weights, builds, archives), move data to an external drive or out of a synced folder "to save space", see "No space left on device", read df/du near 100% or a project rule that says the disk is full, or the user's Settings figure contradicts df; also when the user asks 磁盘满了吗 / 空间够不够 / 硬盘还剩多少.
---

# Checking disk space without fooling yourself (in either direction)

On macOS there are two free-space figures, and both are "true":

| figure | source | what it means |
|---|---|---|
| **writable** | `df`, `NSURLVolumeAvailableCapacityKey`, `shutil.disk_usage` | what a script, rsync or cp can write **right now** |
| **Settings** | System Settings → Storage, Finder, `NSURLVolumeAvailableCapacityForImportantUsageKey` | writable **plus purgeable** space: files the system *may* delete, chiefly downloaded cloud-drive files that are not pinned "available offline" |

With Dropbox (or iCloud, OneDrive, Google Drive) on File Provider the gap is often hundreds of gigabytes. Dropbox's own
documentation says files not marked "available offline" may be made online-only automatically when the disk is low,
and that macOS does not count them as occupied space; it gives no timing.

**Measured, 2026-10:** df said 52 GB writable, Settings said 683 GB. A 105 GB `rsync` into the Dropbox folder failed
with `No space left on device` when df reached 119 MB, while Settings still showed 626 GB. Nothing was evicted during
the copy, and newly written files that are still uploading cannot be evicted at all.

Both mistakes happen:
- **Trusting df alone** and concluding "the disk is full": one agent moved a project's data to an external drive and
  wrote "the home disk is nearly full" into the project's instructions; later sessions obeyed it until sixteen scripts
  depended on a drive that other computers do not have.
- **Trusting Settings alone** and starting a large copy: the disk fills to zero, the copy fails half-way, and other
  applications on the machine can fail too.

## Rule

1. **Report both figures**, labelled, whenever space matters. Never quote one as "the free space".
2. **Size any large write by the writable figure.** Leave a margin (at least 10-20 GB or 10%) for the system.
3. **If the writable figure is too small but Settings is large, free real space first**: ask the user to make large
   cloud-drive folders online-only (Dropbox: Finder → right-click → Make online-only; there is no supported command-line
   way), wait until df shows the room, then write. Or copy in batches below the writable figure, letting uploads finish
   between batches.
4. **Never move data out of a project, off a synced folder or onto an external drive because space looks short.**
   That trades a one-time cleanup for permanent path dependence. Ask the user.
5. **Never write "the disk is full" (or "there is plenty of room") into a project file without the command, both
   figures and the date.** A belief written into instructions outlives the session that formed it.
6. **During a long copy, watch the writable figure**; stop before it reaches zero.

## How to measure

### macOS

```bash
bash ~/.claude/skills/disk-space-check/scripts/disk_space.sh [path]   # default: $HOME
```

prints JSON with `writable_gb` (decide with this), `settings_gb`, `purgeable_gb_approx`, `opportunistic_gb` and
`total_gb`. It needs only `osascript` (JavaScript for Automation), present on every Mac.

What makes up the purgeable part (to explain it, not to "fix" it):
- cloud-drive copies under `~/Library/CloudStorage/` that are downloaded but not pinned;
- local Time Machine snapshots: `tmutil listlocalsnapshots /`;
- system caches macOS marks purgeable.

`ls -lO` shows the flag `dataless` on files that are already online-only. Opening one downloads it, which itself needs
writable space.

### Windows

`Get-PSDrive C` or `fsutil volume diskfree C:`. OneDrive "Files On-Demand" and Dropbox online-only files behave like the
macOS purgeable class, but Windows reports free space plainly: the figure is the writable one.

### Linux

`df -h <path>` is the writable figure (no purgeable class). Check quotas (`quota -s`) and, on clusters, the documented
scratch and home limits.

## Copying many gigabytes into a synced folder

1. Check the writable figure; if short, free space as in rule 3.
2. Copy with `rsync -a` (or `robocopy /E` on Windows), in batches if needed.
3. Verify: file counts and sizes per folder, and checksums or the source's manifest where one exists.
4. Delete originals elsewhere only after the user confirms.

## When you find a wrong "disk is full" (or "plenty of room") rule

1. Measure both figures and show them to the user.
2. Replace the rule with a measured one (command, both figures, date).
3. List what the old rule caused (data outside the project, hard-coded paths, a failed copy) and propose the fix.
