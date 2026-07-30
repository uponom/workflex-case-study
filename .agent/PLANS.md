# Execution Plan Standard

Use this document when creating and maintaining `.agent/EXEC_PLAN.md` for the
case study. The execution plan is a living, self-contained specification and
progress record. A developer unfamiliar with the prior conversation should be
able to understand the goal, continue the work, and verify the result using the
repository and the plan alone.

The plan must stay useful under the 150-minute delivery limit. Prefer concise,
specific prose and observable evidence over extensive process documentation.

## Plan Lifecycle

Before implementation:

1. Read the complete brief and supplied files.
2. Write the requirements and observable acceptance criteria.
3. Record ambiguities, assumptions, risks, and items that are explicitly out of
   scope.
4. Compare PowerShell and Python and record the user's final choice.
5. Define milestones that each produce a demonstrably working result.

During implementation:

- Keep exactly one task marked `IN PROGRESS`.
- Update progress whenever a task is completed, split, removed, or discovered.
- Record design decisions when they are made, including the reason and rejected
  alternative.
- Record unexpected behavior, tool limitations, and evidence that changes the
  plan.
- Validate each milestone before starting the next one.
- Update time allocation when actual progress differs materially from the plan.

At completion:

- Reconcile every requirement with the delivered behavior.
- Record exact validation commands and concise results.
- Document remaining limitations and uncertainty.
- Confirm `README.md` matches the final solution.
- Complete the submission checklist in `.agent/CASE_CONTEXT.md`.
- Summarize the outcome and final repository state.

## Required Sections for `.agent/EXEC_PLAN.md`

### Purpose and User-Visible Outcome

Explain why the solution exists, what the reviewer can do with it, and how the
reviewer can observe successful behavior.

### Challenge Requirements and Acceptance Criteria

Separate explicit requirements from inferred requirements and optional
improvements. Phrase acceptance criteria as behavior a person can verify, not
only as internal implementation details.

### Constraints and Assumptions

Include the time limit, supplied inputs, required interfaces, environment
assumptions, security constraints, and unresolved ambiguities.

### Language Decision

Summarize the PowerShell and Python comparison, recommendation, important risks,
and the language selected by the user.

### Repository Orientation

Describe the relevant repository-relative paths, entry points, modules, tests,
and how the main components interact.

### Milestones

For each milestone, state:

- the working behavior it will add;
- the files or components it is expected to affect;
- dependencies on earlier work;
- exact validation commands; and
- the observable evidence of success.

Prefer small end-to-end increments. Steps must be safe to retry and should not
depend on unstated context.

### Progress

Use a timestamped checklist:

- `[ ]` pending
- `[~]` in progress
- `[x]` completed
- `[!]` blocked or intentionally omitted, with an explanation

### Decision Log

Record the date or elapsed-time point, decision, rationale, and consequences.

### Discoveries and Risks

Record unexpected findings, technical risks, time risks, and mitigations. Add
short evidence such as an error message or test result when it helps another
developer reproduce the finding.

### Validation Evidence

List the exact commands that were run, whether they passed, and what behavior
they prove. Include focused tests, the full test suite, quality checks, smoke
tests, and the clean-state setup check. Never record an unexecuted check as
passing.

### Outcome and Remaining Work

Summarize what was delivered, what was intentionally omitted, known
limitations, and whether the repository was pushed successfully.

### Submission Checklist

Track the final clean-state verification, commit and push, private repository
check, WorkFlex collaborator invitation, and preparation of the repository link
for the application-email reply. Do not mark an external action complete until
it has been verified.

## Suggested Time Budget

Adapt this budget to the actual challenge:

- 0-15 minutes: inspect the brief and inputs; derive requirements and language
  recommendation.
- 15-25 minutes: obtain the language decision; create the execution plan,
  minimal project scaffold, and initial README instructions.
- 25-105 minutes: implement and test milestone-sized vertical slices.
- 105-130 minutes: cover edge cases, run regression checks, and simplify.
- 130-142 minutes: verify setup and usage from a clean state; finish README and
  plan.
- 142-150 minutes: review Git state, commit, push, and verify the private
  repository.

Always preserve the final submission window. Reduce optional scope before
borrowing time from final validation and publication.
