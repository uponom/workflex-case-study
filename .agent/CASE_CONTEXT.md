# Case Study Handoff Context

This file records the stable preparation decisions needed to start the timed
WorkFlex case study in a fresh Codex chat. The challenge brief, once received,
overrides any assumption in this file.

## Current Status

- The challenge was supplied as one Markdown file and three CSV files rather
  than a ZIP; originals were preserved and hash-verified under `source/` in the
  attached definition folder.
- PowerShell 7 was selected, and implementation details and live progress are
  recorded in `.agent/EXEC_PLAN.md`.
- The submission repository is `uponom/workflex-case-study`.
- The repository is private, uses `main`, and has an HTTPS `origin`.
- The reviewer-facing entry point is `scripts/Invoke-AccessReview.ps1`.

## Challenge Process and Working Assumptions

- WorkFlex will send a download link for a ZIP containing Markdown instructions
  and additional exercise files 15 minutes before the scheduled time.
- For planning purposes, treat the 150-minute limit as starting when the ZIP
  link is received, not at the nominal scheduled time.
- The 150 minutes include reading, planning, implementation, tests,
  documentation, commits, push, and verification of the GitHub repository.
- The exercise is open-book, has no required technology stack, and allows
  current online resources, frameworks, libraries, and AI tools.
- The user has authorized Codex and other services involved in the workflow to
  process the ZIP contents.
- There is no starter code or scaffold. Use recent supported technology
  versions and create only the structure the solution needs.
- If the actual brief changes any of these assumptions, record the discrepancy
  in `.agent/EXEC_PLAN.md` and follow the brief.

## Project Folder Roles

- This Git repository contains only the self-contained submission.
- The user is responsible only for downloading the original ZIP into the
  attached `workflex-case-study-definition` folder. The user does not need to
  extract it.
- Codex must inspect the archive file list for unsafe paths, create `source/`,
  and extract the archive there without modifying or deleting the original ZIP.
- The separately attached folder named `workflex-case-study-definition` is for:
  - the original downloaded ZIP, preserved unchanged;
  - `source/`, containing an exact extraction of the ZIP;
  - `scratch/`, for private notes or disposable experiments; and
  - `.uv-cache/`, for a persistent `uv` cache when Python is used.
- Read the challenge from the attached definition folder. Copy only the input
  files that a reviewer needs into this repository.
- Never make the submitted solution depend on an absolute path, a symlink to
  the definition folder, or an uncommitted local file.

## Language Decision

- The user's preference is PowerShell when it is a natural, maintainable choice
  for the actual task.
- Choose Python when PowerShell would materially weaken implementation quality,
  library support, portability, testing, or reviewer experience.
- Before writing solution code, compare PowerShell and Python against the
  actual requirements. Explain advantages, disadvantages, delivery risks, and
  one recommendation, then wait for the user's decision.
- If the options are effectively equal, recommend PowerShell.
- Use one primary language. Do not introduce a PowerShell/Python hybrid unless
  the brief creates a clear need and the user approves the tradeoff.

## Verified Local Tooling

The following versions were verified during preparation:

- PowerShell 7.6.3
- `uv` 0.12.0
- system Python 3.9.6
- Homebrew Python 3.14.6
- `uv`-managed CPython 3.14.6

Do not rely on plain `python3`, because the Codex shell can resolve it to the
system Python 3.9.6. If Python is selected:

- prefer the `uv`-managed Python 3.14.6 unless dependency compatibility gives a
  concrete reason to choose another recent version;
- record the selected version in `.python-version`;
- use `pyproject.toml`, `uv.lock`, and a repository-local `.venv`;
- use `uv run` for project commands; and
- point `UV_CACHE_DIR` to `.uv-cache` in the attached definition folder when
  the default user cache is inaccessible from the Codex sandbox.

Each Codex shell command may receive a fresh environment. Do not assume a prior
`export UV_CACHE_DIR=...` remains active; pass or configure the cache location
for every relevant command.

If PowerShell is selected, target PowerShell 7 rather than Windows PowerShell
5.1 and add exact module, formatting, analysis, test, and run commands to
`AGENTS.md` and `README.md`.

## Git and GitHub

- Remote: `https://github.com/uponom/workflex-case-study.git`
- Visibility: private
- Default branch: `main`
- GitHub CLI account: `uponom`
- GitHub CLI credentials are stored in macOS Keychain. A sandboxed
  `gh auth status` can incorrectly report an invalid token when Keychain access
  is blocked. Recheck with appropriate host permission before asking the user
  to authenticate again.
- Git operations use HTTPS. Commit signing uses the user's SSH signing key.
  Never disable signing globally; if signing fails, inspect `ssh-add -l` and
  repository-local Git configuration.

## Licensing

- `LICENSE` applies the PolyForm Noncommercial License 1.0.0.
- `EVALUATION_PERMISSION.md` grants WorkFlex only the additional rights needed
  to clone, run, and test the solution for recruitment evaluation.
- Before implementation, check the challenge brief for intellectual-property,
  licensing, confidentiality, or repository-retention terms. If they conflict
  with the existing files, stop and explain the conflict to the user rather
  than silently changing or removing the terms.

## Submission Requirements

Before declaring the case study complete:

1. Reconcile the solution with every explicit requirement.
2. Run the documented focused, regression, quality, and smoke checks.
3. Verify setup and execution from a clean state using only `README.md`.
4. Confirm there are no secrets, machine-specific dependencies, caches, or
   unrelated source materials in Git.
5. Commit and push the final state to `origin/main`.
6. Verify the repository remains private and the remote branch contains the
   final commit.
7. Add `coding-challenge@getworkflex.com` as a repository collaborator only
   after the user explicitly confirms that repository review is complete. The
   invitation is currently deferred by the user.
8. Reply to the application email with the private repository link so WorkFlex
   can match the submission to the application.

Do not add the WorkFlex collaborator until the user explicitly asks to do so.
