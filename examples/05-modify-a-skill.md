# 05 · Modifying an existing skill

A **skill** (`.claude/skills/<name>/SKILL.md`) is a procedure the agent follows, run as `/<name>`. Changing one changes how the agent behaves, so it is governed like code: a reason, a test before and after, and a review gate.

**See the real diff:** `git log -p -1 --grep='session-end skill archives'` (the commit that made this change)

## Why change it

`/session-end` (v1, on `main`) updates STATUS.md at the end of a session but never shrinks it. STATUS.md grows with every Completed item; past 20 KB it crowds the agent's context and `scripts/doc-drift.sh` fails in CI, after the session has ended.

## The change

| File | Change |
|---|---|
| `docs/DECISIONS.md` | ADR-009 (Proposed): archive STATUS.md and check drift at session end |
| `.claude/skills/session-end/SKILL.md` | new first steps: archive, then drift check, then run the checks |
| `scripts/archive-status.sh` | the archiving itself, as a script so it can be tested |
| `scripts/tests/test-archive-status.sh` | happy path plus every unsafe setup |
| `.claude/settings.json` | allows exactly `scripts/archive-status.sh` (no arguments) |
| `CLAUDE.md` | session-end summary matches the skill |
| `evals/04-session-end-skill.md` | before/after eval |
| `.claude/STATUS.md`, indexes | record and links |

## Eval: before and after

| Version | Result |
|---|---|
| v1 | FAIL: STATUS.md stays at about 27.5 KB; doc-drift fails |
| v2 | PASS: 398 lines archived, STATUS.md 1.2 KB, doc-drift OK |

## Review, round 1: FAIL

Skills, settings and agents are in the gate table, so `security-reviewer` ran. It reproduced each problem on throwaway copies:

```
security-reviewer  STATUS: FAIL

[HIGH] scripts/archive-status.sh  Data loss when the archive write fails: without
  `set -e`, STATUS.md was cut to 5 items even though writing the archive failed,
  and the script still exited 0. 395 items lost while reporting success.
[HIGH] scripts/archive-status.sh  Follows symlinks: a planted symlink made it append
  STATUS.md lines to a file outside the repo (e.g. a shell profile).
[MEDIUM] .claude/settings.json  `archive-status.sh:*` allowed any arguments without a
  prompt, so it could rewrite files outside the project.
[MEDIUM] scripts/archive-status.sh  Inputs not validated; bad values exited 0.
[LOW] SKILL.md  Checks ran before the drift fixes, so recorded results could be stale.
[LOW] examples/05 missing; STATUS.md already called it done.
[LOW] ADR-009 Accepted before the failure paths were tested.
```

## Fixes

- **By construction:** the script takes **no path argument** and only ever touches `.claude/`, and the allow rule permits only that exact form. The unsafe use can't be written.
- Writes go to temp files, both files are checked, and only then moved into place. Any failure leaves STATUS.md untouched, with a non-zero exit.
- Refuses symlinks, odd paths and invalid settings.
- Skill steps reordered: archive, then drift, then checks, then record.
- ADR-009 stays **Proposed** until a full agent run of eval 04 passes.
- The test gained 12 failure-path cases. Each one reproduces a finding.

## Review, round 2: PASS

```
security-reviewer  STATUS: PASS

All 2 HIGH and 2 MEDIUM findings fixed and re-tested by the reviewer.
[LOW] trap set after mktemp: a failed run could leave temp files in .claude/
[LOW] files ended up 0600 after the move
[LOW] GIT_WORK_TREE could point the script at another folder
[LOW] the final STATUS.md was never size- or drift-checked
[LOW] STATUS.md called v2 done while ADR-009 waits for the eval
```

The LOW findings were cheap, so they were fixed before commit as well. The cleanup trap is set first. Files keep mode 644. The repo root comes from the script's own location, not git, so the environment can't redirect it. The skill re-checks after writing STATUS.md, and Next up now includes the full eval run. Each fix has a test case.

## Lesson

Changing the AI's instructions is a code change. The reviewer found real data-loss and write-outside-the-repo bugs in a "simple" housekeeping script, which **a prose-only change to the skill would never have been tested for**.
