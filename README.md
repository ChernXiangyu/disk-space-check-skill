# disk-space-check — a Claude Code skill

A [Claude Code](https://claude.com/claude-code) skill that makes Claude measure free disk space the way the operating
system does before it decides where large files go.

**The problem.** On macOS two free-space figures disagree, often by hundreds of gigabytes: `df` (what a script can
write now) and System Settings (which adds *purgeable* space, chiefly downloaded Dropbox/iCloud/OneDrive files that are
not pinned offline). Trusting `df` alone, one agent declared the disk full, moved a project's data to an external drive
and wrote that into the project's instructions; sixteen scripts ended up hard-wired to the drive. Trusting Settings
alone, another agent (the author of this skill's first version) started a 105 GB copy that failed with
`No space left on device` when `df` hit 119 MB, while Settings still showed 626 GB: Dropbox does not evict files in
time for a script's writes.

## What it teaches Claude

- Report both figures, labelled; size every large write by the writable one (`df`).
- If only the Settings figure is large, free real space first (make cloud folders online-only), or copy in batches.
- Never move data out of a project, a synced folder or onto an external drive because space looks short; ask.
- Never write "the disk is full" into project instructions without the command, the figure and the date.
- Notes for Linux (df is honest; check quotas) and Windows (OneDrive Files On-Demand).

## Contents

| File | Purpose |
|---|---|
| `SKILL.md` | The skill Claude loads when disk space matters |
| `scripts/disk_space.sh` | Prints writable (df), Settings and purgeable space (JSON) for the volume holding a path; macOS needs only `osascript` |

## Install

```bash
git clone https://github.com/ChernXiangyu/disk-space-check-skill ~/.claude/skills/disk-space-check
```

Then ask Claude anything that involves free space or writing large files; or run
`bash ~/.claude/skills/disk-space-check/scripts/disk_space.sh` yourself.

## License

MIT
