---
description: Multi-agent collaborative planning - draft, interview, compete with Codex, merge
---

# kplan: Collaborative Sprint Planning

## Background

### Role

You are the planner. You turn the seed below into an approved sprint document
by writing your own draft, interviewing the user, obtaining an independent
draft and critique from Codex, and merging the results. Codex is an external
CLI (`codex exec`). You are the only agent that talks to the user.

### Seed

$ARGUMENTS

### Repo assumptions

This command is installed at user level and runs in whichever repo you are in.
Resolve each of these before Phase 1 and reuse the answers throughout.

- **Conventions file**: if `AGENTS.md` exists, that is the conventions file.
  Else if `CLAUDE.md` exists, use it. Else there is none: say so in the
  orientation summary and rely on the code. Wherever this document says "the
  conventions file", substitute the file you resolved. In the prompt you hand
  to Codex, name the actual file; never name a file that does not exist.
- **Sprint tooling**: `docs/sprints/README.md` (template and conventions) and
  `docs/sprints/tracker.go` (ledger CLI). If `docs/sprints/` does not exist,
  stop and tell the user this repo is not set up for sprint planning; do not
  scaffold it. If the README exists but `tracker.go` does not, skip every
  `tracker.go` command below and say so in the final report.
- **Sprint number** `NNN`: one more than the highest existing
  `docs/sprints/SPRINT-*.md`, zero-padded to 3 digits (`001` if none exist).
  Every `NNN` below is this number.
- **Branch**: `git rev-parse --abbrev-ref HEAD`. Whether it is `main` decides
  Phase 6 step 6.

### Sprint document contract

A sprint document (draft or final) follows the template in
`docs/sprints/README.md` plus these sections, which kplan requires even if the
README does not list them:

- `## Risks & Mitigations`: table with columns Risk, Likelihood, Impact,
  Mitigation.
- `## Open Questions`: uncertainties the implementer must resolve.
- `## Documentation Manifest`: the format below. Never omitted, never empty.

The Documentation Manifest is the contract the `sprint` skill enforces before
it marks a sprint complete: every file listed must change during
implementation. Format:

```markdown
## Documentation Manifest

The implementation sprint MUST land the following docs changes alongside the
code. The `sprint` skill verifies each listed file changed before marking the
sprint complete.

### New ADRs

- `docs/adr/NNNN-<slug>.md` — one paragraph on what it codifies.

### Amended ADRs

- `docs/adr/NNNN-<existing>.md` — one sentence on which decision changes.
  The amendment lands as a new section headed `## Sprint NNN amendment`.

### Cross-cutting docs

- `<path>` — what to update. List every doc outside `docs/adr/` that
  describes behaviour this sprint changes (for example a status page, an
  architecture overview, or a local setup guide).

### Skipped (with reasoning)

- `<path>` — considered, not touched because <reason>.
```

A sprint that needs no docs changes still gets the section, containing only
"No documentation changes required because <reason>."

---

## Behaviour

Track the six phases with TodoWrite and run them in order; each phase's
artifact feeds a later one. Never fabricate an artifact you did not produce.
If a phase is blocked, stop and report it as described under Output.

### Phase 1: Orient

1. Read the conventions file.
2. Run `go run docs/sprints/tracker.go stats`.
3. Read the three highest-numbered sprint documents:
   `ls docs/sprints/SPRINT-*.md | sort | tail -3`.
4. Search the code for the modules, types, and patterns the seed touches. Note
   existing implementations this sprint would extend and the constraints it
   must respect (architecture, naming, test conventions).

Deliverable: an orientation summary of 3-5 bullets covering current state
relevant to the seed, recent sprint direction, likely files and modules, and
constraints. It is reused verbatim in Phase 2.

### Phase 2: Intent

Run `mkdir -p docs/sprints/drafts`, then write
`docs/sprints/drafts/SPRINT-NNN-INTENT.md`. Both agents read this file, so it
must be self-contained:

```markdown
# Sprint NNN Intent: [Title]

## Seed

[The seed, verbatim]

## Context

[Orientation summary from Phase 1]

## Recent Sprint Context

[One short paragraph per sprint read in Phase 1]

## Relevant Codebase Areas

[Modules, files, and patterns identified in Phase 1]

## Constraints

- Must follow the conventions in <conventions file, or "the existing code" if none>
- Must follow the sprint conventions in docs/sprints/README.md
- Must integrate with the existing architecture
- [Other constraints identified]

## Required Sections

Drafts follow the template in docs/sprints/README.md plus
`## Risks & Mitigations`, `## Open Questions`, and `## Documentation Manifest`
in this format:

[Copy the Documentation Manifest format from the sprint document contract]

## Success Criteria

[What makes this sprint successful]

## Open Questions

[Questions the drafts should try to answer]
```

### Phase 3: Draft

Write `docs/sprints/drafts/SPRINT-NNN-CLAUDE-DRAFT.md` following the sprint
document contract in full, including a Documentation Manifest, so Codex can
critique every section.

### Phase 4: Interview

Use AskUserQuestion to ask 2-4 questions. Choose from these topics and skip
any the seed already answers unambiguously:

1. Scope: does the draft's scope match the user's intent, or should it expand
   or narrow?
2. Priority: which parts are critical versus nice-to-have?
3. Technical preferences: strong opinions on architecture, sequencing, naming,
   or approach?
4. Sequencing: external dependencies, ordering constraints, or risks the draft
   missed?

Append the questions and answers to the intent document under a new
`## Interview Answers` section so Codex drafts against them. Apply them to
your own draft in Phase 6, not now.

### Phase 5: Compete

Run Codex as a yielded, pollable process, substituting `NNN` and the
conventions file name:

```bash
codex exec -s workspace-write "Read docs/sprints/drafts/SPRINT-NNN-INTENT.md; it is the concentrated intent for our next sprint, including Required Sections and Interview Answers. Familiarize yourself with our sprint planning style in docs/sprints/README.md and with project conventions in <conventions file>, and inspect the relevant codebase areas. Then write your own draft to docs/sprints/drafts/SPRINT-NNN-CODEX-DRAFT.md. Only AFTER your draft is complete, read Claude's draft at docs/sprints/drafts/SPRINT-NNN-CLAUDE-DRAFT.md and write a specific, actionable critique of it to docs/sprints/drafts/SPRINT-NNN-CLAUDE-DRAFT-CODEX-CRITIQUE.md. Do not edit Claude's draft and do not write the final sprint document." < /dev/null
```

Invocation rules:

- `exec` is a subcommand; flags go after it. `-s workspace-write` gives Codex
  write access to the working tree (`--full-auto` no longer exists).
- Do not pass `--model`; a pinned name breaks when Codex updates its model
  list.
- Keep `< /dev/null`. With stdin open, a non-interactive `codex exec` can hang
  waiting for input even though the prompt was passed as an argument.
- Report progress to the user at least once per minute while it runs.
- Treat 15 minutes with no terminal output and neither expected file as a
  stall. Interrupt, run `codex --version`, and retry once with a prompt that
  lists only the files to read and the two files to write, keeping
  `< /dev/null`.
- After exit, verify both files exist, are non-empty, and contain what was
  asked (a sprint draft; a critique). Do not trust exit status alone.
- If the retry also stalls or fails, the phase is blocked: stop, keep the
  Phase 1-4 artifacts, and do not merge.

Then read both files:

- `docs/sprints/drafts/SPRINT-NNN-CODEX-DRAFT.md`
- `docs/sprints/drafts/SPRINT-NNN-CLAUDE-DRAFT-CODEX-CRITIQUE.md`

### Phase 6: Merge

1. Evaluate the critique: which points are valid, what you missed, what you
   defend.
2. Compare the drafts on architecture, phasing and ordering, risk coverage,
   and Definition of Done completeness.
3. Write `docs/sprints/drafts/SPRINT-NNN-MERGE-NOTES.md`:

   ```markdown
   # Sprint NNN Merge Notes

   ## Claude Draft Strengths
   ## Codex Draft Strengths
   ## Valid Critiques Accepted
   ## Critiques Rejected (with reasoning)
   ## Interview Refinements Applied
   ## Final Decisions
   ```

4. Write `docs/sprints/SPRINT-NNN.md` following the sprint document
   contract, combining the best of both drafts, the accepted critiques, and
   the interview answers.
5. Run `go run docs/sprints/tracker.go sync`.
6. Request approval as described under Output. Then:
   - If the user requests changes: revise the final document, re-run step 5,
     and ask again.
   - If the user approves and the branch is `main`: create the implementation
     branch. Implementation never happens on `main`. The uncommitted drafts
     and `SPRINT-NNN.md` travel with the working tree.

     ```bash
     git checkout -b "project/<project>/sprint-NNN-<slug>"
     ```

     `<project>` is the kebab-case slug of the project this sprint belongs
     to: match an existing `docs/projects/<slug>/` directory when one applies;
     if none does and the project is not obvious from Phase 1, ask the user
     for it in the approval request. `<slug>` is the kebab-case sprint title
     (for example "Connector Fleet" becomes `connector-fleet`).
   - If the user approves and the branch is not `main`: stay on it and create
     nothing.

   Do not commit or push in this phase; commits belong to implementation
   (the `sprint` skill).

---

## Output

### Progress updates

Post one line at each phase transition naming the phase and its artifact.
While Codex runs, post progress at least once per minute.

### Approval request

After Phase 6 step 5, send the user: the path to `docs/sprints/SPRINT-NNN.md`,
a short summary of the sprint's approach and the key decisions from the merge
notes, the project slug question if needed, and an explicit request to
approve or request changes. Do not paste the whole document.

### Final report

After the branch decision, tell the user which branch implementation will
happen on and whether it was created or reused, and confirm the checklist
below is complete. Mention any skipped `tracker.go` commands.

### Blocked report

If a phase is blocked, say which phase, what was attempted (including any
retry), which artifacts exist on disk, and that no merge was produced.

### Completion checklist

- [ ] Orientation summary written
- [ ] `docs/sprints/drafts/SPRINT-NNN-INTENT.md` written, with Interview Answers
- [ ] `docs/sprints/drafts/SPRINT-NNN-CLAUDE-DRAFT.md` written
- [ ] Interview conducted (2-4 questions answered)
- [ ] `docs/sprints/drafts/SPRINT-NNN-CODEX-DRAFT.md` received and read
- [ ] `docs/sprints/drafts/SPRINT-NNN-CLAUDE-DRAFT-CODEX-CRITIQUE.md` received and read
- [ ] `docs/sprints/drafts/SPRINT-NNN-MERGE-NOTES.md` written
- [ ] `docs/sprints/SPRINT-NNN.md` written, with a non-empty Documentation Manifest
- [ ] Ledger synced via `go run docs/sprints/tracker.go sync`
- [ ] User approved the final document
- [ ] Implementation branch created off `main`, or existing non-`main` branch reused
