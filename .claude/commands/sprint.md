---
description: Begin and complete the next incomplete sprint (tracker, Definition of Done, Documentation Manifest verification, build/test, commit/push).
---

# sprint: Implement the Next Sprint

## Background

### Role

You implement the lowest-numbered incomplete sprint in this repo end to end:
code, the documentation the sprint's Documentation Manifest promised, commit,
push, and ledger update.

### Repo assumptions

This skill is installed at user level and runs in whichever repo you are in.
Resolve each of these before step 1 and reuse the answers throughout.

- **Conventions file**: if `AGENTS.md` exists, that is the conventions file.
  Else if `CLAUDE.md` exists, use it. Else there is none and the code is the
  convention.
- **Sprint tooling**: `docs/sprints/tracker.go` is the ledger CLI. If it does
  not exist, stop and tell the user this repo is not set up for sprints.
- **Validation commands**: the build, test, and lint commands documented in
  the conventions file. If it documents none and the repo has a `go.mod`, use
  `go vet ./...` and `go test ./...`. If neither applies, ask the user which
  commands validate the repo before starting step 3.
- **Commit convention**: the one documented in the conventions file. If none
  is documented, use Conventional Commits.
- **Branch**: `git rev-parse --abbrev-ref HEAD`. Implementation never happens
  on `main`.

### The Documentation Manifest gate

Every sprint document planned with `kplan` carries a `## Documentation
Manifest` section listing the ADRs and cross-cutting docs that must change
with the code, split into New ADRs, Amended ADRs, Cross-cutting docs, and
Skipped (with reasoning). It is the contract between planning and
implementation. Sprints that ship code but skip the docs leave the
architectural record stale, and future readers (human or LLM) trust the old
ADR and assume nothing changed. Step 4 enforces the contract before anything
is committed.

---

## Behaviour

### 1. Find the next incomplete sprint

- Run `go run docs/sprints/tracker.go stats` and pick the lowest-numbered
  sprint whose status is not `completed` or `skipped`. Its number is `NNN`
  below.
- Read `docs/sprints/SPRINT-NNN.md`.
- If it has no `## Documentation Manifest` section, stop and ask the user to
  add one; the sprint predates the manifest requirement and cannot be marked
  complete without it.

### 2. Prepare the branch and ledger

- If the branch is `main`, create the implementation branch first:
  `git checkout -b project/<project>/sprint-NNN-<slug>`, where `<project>`
  matches an existing `docs/projects/<slug>/` directory or, failing that, a
  slug the user confirms, and `<slug>` is the kebab-case sprint title. If the
  branch is not `main`, stay on it.
- Run `go run docs/sprints/tracker.go start NNN`.

### 3. Implement the sprint

- Work through every item in the sprint's Definition of Done and every task
  in its Implementation Plan.
- Land every Documentation Manifest item as you go, not at the end.
- Run the validation commands and fix every build, test, and lint failure
  before moving on.
- If a manifest item turns out to be wrong (an amendment is not needed, or an
  unplanned ADR is needed), edit the Manifest section of
  `docs/sprints/SPRINT-NNN.md` in the same change so the divergence is
  explicit. Never silently skip an item or add to the Skipped list without
  saying so to the user.

### 4. Verify the Documentation Manifest landed

Before staging anything, re-read the Manifest and check each item:

- **New ADRs**: the file exists.
- **Amended ADRs**: the file contains a section headed `## Sprint NNN
  amendment` (the heading kplan specifies).
- **Cross-cutting docs**: `git diff main -- <file>` shows a substantive
  change for this sprint.
- **Skipped (with reasoning)**: the reasoning still holds.

If any required item is missing, do not commit. Either land the missing
change or, with the user's explicit agreement, remove it from the Manifest by
editing the sprint document.

### 5. Commit and push

- Stage all changes, code and docs together.
- Write the commit message in the commit convention. The subject summarises
  the sprint work; the body names each Manifest item that landed.
- Push the current branch with `git push -u origin HEAD`.

### 6. Mark the sprint complete

- Run `go run docs/sprints/tracker.go complete NNN`.
- Commit the ledger change and push.

---

## Output

### Progress updates

Post one line when each numbered step starts, and report validation results
verbatim when they fail.

### Final report

Tell the user: the sprint number and title, the branch, the commit hashes,
each Manifest item and where it landed, any Manifest edits made during
implementation and why, and the validation commands that passed.

### Blocked report

If you stop at step 1, 3, or 4, say which step, what is missing, and what the
user needs to decide. Do not commit partial work unless the user asks.
