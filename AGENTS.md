# Repository Instructions

## Purpose

This repository contains Yurii Ponomarenko's WorkFlex case study submission.
Keep the solution focused, self-contained, reproducible, secure, and easy for a
reviewer to understand and run.

The challenge brief is the source of truth. Do not implement behavior that
conflicts with it, and distinguish explicit requirements from assumptions and
optional improvements.

Read `.agent/CASE_CONTEXT.md` at the start of a fresh chat. It contains the
stable challenge logistics, user decisions, verified local tooling, and
submission requirements established during preparation.

## Working Directories

- This repository is the submission repository and the working directory for
  Git operations.
- The separately attached project folder named
  `workflex-case-study-definition` contains the original challenge archive,
  extracted source material, private notes, and the shared `uv` cache.
- Do not use absolute paths or symlinks to the definition directory in the
  submitted solution. Copy any required challenge inputs into this repository
  so a fresh clone is sufficient to run and test the solution.

## Required Workflow

1. Read `.agent/CASE_CONTEXT.md`, `.agent/PLANS.md`, `README.md`, and the current
   Git status.
2. Inspect the supplied challenge materials in the attached definition folder,
   including archive paths when an archive is supplied. Preserve the originals
   and place verified copies under its `source/` directory before reading the
   complete brief and every supplied file.
3. Extract explicit requirements, constraints, expected outputs, ambiguities,
   and acceptance criteria.
4. Check the brief for intellectual-property, confidentiality, licensing, and
   submission terms that may conflict with the prepared repository.
5. Compare PowerShell and Python against the actual task. Explain the benefits,
   drawbacks, risks, and recommendation to the user. Do not begin implementation
   until the user selects the language.
6. Create `.agent/EXEC_PLAN.md` using `.agent/PLANS.md`. Keep it current while
   implementing.
7. Implement the smallest complete solution in verified milestones. Prefer a
   working vertical slice over broad unfinished scaffolding.
8. After every milestone, run focused tests for the changed behavior. Then run
   all available regression checks before considering the milestone complete.
9. Review the diff for correctness, security, unnecessary complexity, secrets,
   generated files, and stale documentation.
10. Update `README.md`, `.agent/EXEC_PLAN.md`, and tests whenever behavior,
    commands, architecture, assumptions, or limitations change.
11. Before submission, verify the documented setup from a clean state, confirm
    the repository is self-contained, and complete every item in the submission
    checklist in `.agent/CASE_CONTEXT.md`.

## Engineering Standards

- Optimize for correctness, clarity, reviewer experience, and delivery within
  the 150-minute limit.
- Keep the design as simple as the requirements allow. Avoid speculative
  abstractions, premature optimization, and unnecessary dependencies.
- Use recent supported language and dependency versions. Pin dependencies with
  the stack's standard lock mechanism when dependencies are needed.
- Separate core logic from external I/O so behavior is testable.
- Validate external input and produce actionable errors without exposing
  secrets or sensitive data.
- Make repeated operations safe and deterministic where practical.
- Preserve backward-compatible behavior unless the challenge explicitly
  requires a breaking change.
- Never commit credentials, tokens, local environment files, caches, build
  output, or unrelated challenge materials.
- Do not claim that a check passed unless it was actually run. Record any check
  that could not be run and explain why.

## Build and Validation Commands

The implementation targets PowerShell 7 and has no runtime package dependency.
Run the reviewer workflow from the repository root:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-AccessReview.ps1
```

Run the full Pester suite:

```powershell
pwsh -NoProfile -Command 'Invoke-Pester -Path ./tests -Output Detailed'
```

Run PSScriptAnalyzer and fail on any warning or error:

```powershell
pwsh -NoProfile -Command '
  $issues = foreach ($path in @("./src", "./scripts", "./tests")) {
    Invoke-ScriptAnalyzer -Path $path -Recurse -Severity Error,Warning
  }
  $issues | Format-Table
  "ISSUES=$(@($issues).Count)"
  if (@($issues).Count -gt 0) { exit 1 }
'
```

Pester 6.0.1 and PSScriptAnalyzer 1.25.0 are development-only dependencies.
Regenerate committed output whenever review behavior or rendering changes and
verify that a second run produces no diff.

Every functional change must have proportionate automated coverage where
practical. Validation should include:

- focused tests for the changed behavior;
- the complete automated test suite;
- formatting, linting, and static analysis configured for the selected stack;
- at least one end-to-end or CLI smoke test of the reviewer-facing workflow;
- negative cases for important invalid input and failure paths; and
- a final clean-state run using only instructions in `README.md`.

## Documentation Standards

`README.md` is reviewer-facing and must always match the current implementation.
It should cover the problem and solution, implemented features, prerequisites,
setup, configuration, usage examples, tests, architecture, design decisions,
assumptions, limitations, security considerations, repository layout, and
licensing. Remove placeholder sections before submission.

`.agent/EXEC_PLAN.md` is the living implementation record. It must contain
requirements, progress, decisions, discoveries, risks, validation evidence, and
remaining work. Update it at every meaningful stopping point.

Keep this file concise and practical. Add a new rule only when required by the
challenge or when a repeated mistake or ambiguity shows that durable guidance
is needed. Use a nested `AGENTS.md` only if a subdirectory genuinely needs
different commands or conventions.

## Git and Review

- Keep commits small, coherent, and reviewable.
- Commit only completed, validated milestones.
- Use descriptive imperative commit messages.
- Do not rewrite shared history or perform destructive Git operations.
- Inspect `git diff` and `git status` before every commit.
- Run a final review of all changes against the challenge requirements and the
  acceptance criteria in `.agent/EXEC_PLAN.md`.

## Definition of Done

The submission is done only when:

- every explicit requirement is implemented or clearly documented as out of
  scope;
- acceptance criteria are demonstrated by tests or reproducible commands;
- focused and full regression checks pass;
- the reviewer can set up and run the solution from a fresh clone using only
  `README.md`;
- no secret, machine-specific path, cache, or unnecessary generated file is
  committed;
- documentation and the execution plan describe the delivered behavior;
- known limitations and unverified assumptions are explicit; and
- the final commit is pushed to the verified private GitHub repository;
- `coding-challenge@getworkflex.com` has been added as a collaborator; and
- the private repository link is ready to send in reply to the application
  email.
