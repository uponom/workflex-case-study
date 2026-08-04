# WorkFlex Monthly Access Review Execution Plan

## Purpose and User-Visible Outcome

Build a read-only PowerShell 7 tool that turns the three supplied identity CSV
exports into two deterministic Markdown artifacts: an actionable access-review
report for a non-technical manager and draft Microsoft Teams messages for the
people responsible for remediation. A reviewer can run one command from a
fresh clone and reproduce the committed reports for 2026-08-15.

## Challenge Requirements and Acceptance Criteria

The tool must use 2026-08-15 as the deterministic review date, ingest users,
group memberships, and guests, and detect at minimum privileged accounts with
missing or more-than-30-day-old sign-ins, disabled accounts retaining roles or
privileged group membership, and guests already expired or expiring within 14
days. It must add defensible access-review checks, generate manager-readable
findings and responsible-person Teams drafts, include source code, and provide
a short technical README covering Microsoft Graph authentication, least-
privilege scopes, scheduling, monitoring, and prohibited autonomous actions.

Acceptance is observable when:

- one documented command produces both Markdown outputs;
- the mandatory data anomalies are present with evidence and recommended
  action;
- additional findings are clearly separated from mandatory controls;
- all dates and threshold boundaries are deterministic;
- invalid booleans, dates, duplicate identifiers, or broken references fail
  with actionable errors;
- Pester tests cover required findings and important threshold boundaries;
- PSScriptAnalyzer reports no errors; and
- setup, tests, and execution work using only files in a fresh clone.

## Constraints and Assumptions

The original input files remain unchanged outside the repository. Reproducible
copies of the three CSV files will be committed under `data/`. Every group with
`group_type=security` is treated as privileged for this exercise because the
export has no role-assignable or sensitivity flag; a real deployment must use
an approved policy or allowlist. A guest's inviter is the accountable sponsor.
The export has no employee manager relationship, so IT & Security is the
fallback owner for disabled, service, external-admin, and ordinary stale-user
findings. Reports are drafts only and the tool performs no external write.

The remaining challenge window includes implementation, validation,
documentation, commits, push, collaborator invitation, and repository
verification. Optional polish must be reduced before final validation time.

## Language Decision

PowerShell 7 was selected by the user. It fits CSV and Microsoft identity
automation directly, needs no runtime dependency for report generation, and
allows native Microsoft Graph integration later. Pester 6.0.1 and
PSScriptAnalyzer 1.25.0 are available for development validation. Python would
offer stronger general-purpose data modelling but would add environment and
packaging work without a material benefit for this scope.

## Repository Orientation

- `data/` contains the three supplied CSV inputs required to reproduce output.
- `src/AccessReview.psm1` contains parsing, validation, finding detection, and
  Markdown rendering.
- `scripts/Invoke-AccessReview.ps1` is the reviewer-facing CLI entry point.
- `tests/AccessReview.Tests.ps1` contains Pester tests.
- `output/` contains the generated access report and Teams drafts.
- `README.md` is the required short technical README and runbook.

## Milestones

### Milestone 1: Validated data model and findings engine

Create the input layout and PowerShell module, validate schemas and references,
normalize booleans and dates, and return deterministically sorted findings.
Validate with focused PowerShell invocations and the real supplied data.

### Milestone 2: Reports and CLI

Add Markdown renderers and the CLI, then generate
`output/access-review-2026-08-15.md` and
`output/teams-messages-2026-08-15.md`. Validate that all mandatory findings and
responsible-person messages are present.

### Milestone 3: Automated tests and technical README

Add Pester coverage for exact findings, threshold boundaries, malformed input,
and output generation. Replace the preparation README with exact setup, run,
architecture, Graph, scheduling, monitoring, safety, and limitation guidance.

### Milestone 4: Final verification and submission

Run Pester, PSScriptAnalyzer, direct CLI smoke tests, Markdown checks, clean-
state reproduction, diff review, and secret/path scans. Commit and push the
final state, verify the private remote, invite the WorkFlex collaborator, and
prepare the repository link for the email reply.

## Progress

- [x] 2026-08-04: Read all source files and preserved verified copies outside
  the repository.
- [x] 2026-08-04: Derived requirements, anomalies, assumptions, and language
  recommendation.
- [x] 2026-08-04: User selected PowerShell 7.
- [x] 2026-08-04: Implement and validate Milestone 1.
- [x] 2026-08-04: Implement CLI and both generated artifacts (Milestone 2).
- [x] 2026-08-04: Add Pester coverage and replace the technical README
  (Milestone 3).
- [~] 2026-08-04: Perform final verification and submission (Milestone 4).

## Decision Log

- 2026-08-04: Use root `README.md` as the required technical README. Generated
  outputs remain limited to the findings report and Teams-message drafts.
- 2026-08-04: Treat all `security` group memberships as privileged for this
  deterministic export and document the production-policy limitation.
- 2026-08-04: Include active stale employees, stale guests, privileged external
  email accounts, and disabled residual memberships as additional controls.
- 2026-08-04: Keep the runtime dependency-free; Pester and PSScriptAnalyzer are
  development-only verification tools.
- 2026-08-04: Keep the engine read-only and generate one Teams draft per
  finding. More concise grouping is possible later, but per-finding evidence,
  owner, and requested action are clearer and directly reviewable.

## Discoveries and Risks

- The supplied materials are direct Markdown/CSV files, not a ZIP. No symlinks,
  duplicate IDs, or broken user references were found.
- Manager data is absent, so some Teams drafts must target IT & Security rather
  than a named line manager.
- Guest expiry is supplied by the exercise but is not a universal property on
  every Entra guest object. Production mapping depends on the organization's
  entitlement-management or custom-extension design.
- CSV booleans and dates are strings and require strict normalization to avoid
  truthiness and locale bugs.
- Strict-mode testing exposed PowerShell empty-array property enumeration in
  the first focused run. Explicit array normalization fixed the issue before
  report generation, and exact IDs/counts are now regression-tested.

## Validation Evidence

- Original and `source/` copies have matching SHA-256 hashes: passed.
- Dataset integrity analysis found 73 users, 192 memberships, 12 guests, no
  duplicate identifiers, and no orphan references: passed.
- `pwsh -NoProfile -Command 'Invoke-Pester -Path ./tests -Output Detailed'`:
  passed, 9 tests, 0 failed.
- PSScriptAnalyzer over `src`, `scripts`, and `tests` at Error/Warning severity:
  passed, `ISSUES=0`.
- `pwsh -NoProfile -File ./scripts/Invoke-AccessReview.ps1`: passed; generated
  16 findings (1 critical, 6 high, 7 medium, 2 low) and both Markdown outputs.
- Two consecutive CLI runs produced identical SHA-256 hashes for both output
  files: passed.
- Credential and machine-specific-path scan returned no matches: passed.
- Clean-state reproduction and final Git checks: pending.

## Outcome and Remaining Work

The complete local solution and required deliverables are implemented. It
detects all mandatory anomalies plus four additional hygiene controls, emits
the manager report and 16 accountable Teams drafts, and documents a read-only
Graph production architecture. Final clean-state verification and GitHub
submission remain.

## Submission Checklist

- [ ] Clean-state setup and run verified from `README.md`.
- [ ] All tests and quality checks pass.
- [ ] Final documentation and generated outputs match implementation.
- [ ] Signed commits pushed to `origin/main`.
- [ ] GitHub repository verified private and synchronized.
- [ ] `coding-challenge@getworkflex.com` added as collaborator.
- [ ] Private repository link ready for the application-email reply.
