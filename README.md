# disk-space-check — a Claude Code skill

A [Claude Code](https://claude.com/claude-code) skill that makes Claude measure free disk space the way the operating
system does before it decides where large files go.

**The problem.** On macOS, `df`, `du`, `diskutil`'s "free space" and Python's `shutil.disk_usage` leave out
*purgeable* space: local copies of Dropbox, iCloud Drive, OneDrive and Google Drive files, and APFS snapshots, which
macOS evicts on demand. On a machine with cloud drives this is often hundreds of gigabytes. An agent that trusts `df`
sees "99% full", moves a project's data to an external drive, writes "the disk is nearly full" into the project's
instructions, and every later session obeys it. In the case that prompted this skill, `df` showed 34 GiB free while
macOS had 683 GB available; sixteen scripts ended up hard-wired to an external drive.

## What it teaches Claude

- Measure with `NSURLVolumeAvailableCapacityForImportantUsageKey` (what System Settings shows), never with `df` alone.
- Never move data out of a project, a synced folder or onto an external drive because space looks short; if the
  correct figure is really too small, ask.
- Never write "the disk is full" into project instructions without the command, the figure and the date.
- Notes for Linux (df is honest; check quotas) and Windows (OneDrive Files On-Demand).

## Contents

| File | Purpose |
|---|---|
| `SKILL.md` | The skill Claude loads when disk space matters |
| `scripts/disk_space.sh` | Prints important, opportunistic and df-style free space (JSON) for the volume holding a path; macOS needs only `osascript` |

## Install

```bash
git clone https://github.com/ChernXiangyu/disk-space-check-skill ~/.claude/skills/disk-space-check
```

Then ask Claude anything that involves free space or writing large files; or run
`bash ~/.claude/skills/disk-space-check/scripts/disk_space.sh` yourself.

## License

MIT
