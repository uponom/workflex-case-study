# WorkFlex Case Study

This private repository is prepared for Yurii Ponomarenko's WorkFlex technical
case study submission.

> **Status:** Preparation only. The challenge brief has not yet been received,
> the implementation language has not been selected, and no solution code has
> been added.

## Overview

The final repository will contain a self-contained solution that a reviewer can
set up, run, and test from a fresh clone. The implementation will be designed
after the supplied challenge instructions and input files have been inspected.

## Development Approach

Work will follow a requirements-first, test-and-validation workflow:

1. inspect the complete challenge and derive acceptance criteria;
2. compare PowerShell and Python for the actual task and obtain the user's
   language decision;
3. create and maintain a living execution plan;
4. implement the solution in small, testable milestones;
5. run focused tests and full regression checks;
6. keep this README synchronized with the delivered behavior; and
7. verify the documented workflow from a clean state before submission.

Repository guidance is defined in [AGENTS.md](AGENTS.md). The execution-plan
standard is defined in [.agent/PLANS.md](.agent/PLANS.md), and the stable
preparation handoff is recorded in
[.agent/CASE_CONTEXT.md](.agent/CASE_CONTEXT.md). The task-specific plan will
be created as `.agent/EXEC_PLAN.md` after the challenge is received.

## Repository Layout

```text
.
├── .agent/
│   ├── CASE_CONTEXT.md          # Stable preparation and submission context
│   └── PLANS.md                 # Execution-plan requirements
├── .gitignore                   # Local and generated file exclusions
├── AGENTS.md                    # Durable development and review instructions
├── EVALUATION_PERMISSION.md     # WorkFlex recruitment-evaluation permission
├── LICENSE                      # PolyForm Noncommercial License 1.0.0
└── README.md                    # Reviewer-facing project documentation
```

The implementation, test, and configuration directories will be documented
here after the language and architecture are selected.

## Prerequisites

To be defined after the challenge brief and implementation language are
selected.

## Installation

To be defined after the project scaffold is created.

## Configuration

To be defined after the solution's runtime and external interfaces are known.
Secrets and machine-specific values will not be committed.

## Usage

To be defined with copy-pasteable commands and representative inputs and
outputs after the core workflow is implemented.

## Testing and Quality Checks

To be defined with exact commands for focused tests, the full test suite,
formatting, linting, static analysis, and an end-to-end smoke test.

## Architecture and Design Decisions

To be documented after the challenge requirements are known. The final section
will explain the component boundaries, data flow, important tradeoffs, and why
the selected design is appropriate for the scope and time limit.

## Assumptions and Limitations

To be updated throughout implementation. All unverified assumptions, deliberate
scope reductions, and known limitations will be listed explicitly before
submission.

## Security Considerations

The solution will apply proportionate input validation, safe error reporting,
secret handling, least privilege, and dependency minimization based on the
actual challenge. Specific security decisions and residual risks will be
documented here.

## License

The code is licensed under the
[PolyForm Noncommercial License 1.0.0](LICENSE). WorkFlex receives the
additional limited rights described in
[EVALUATION_PERMISSION.md](EVALUATION_PERMISSION.md) solely to evaluate Yurii
Ponomarenko's candidacy.
