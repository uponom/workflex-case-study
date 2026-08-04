# WorkFlex Monthly Access Review

A read-only PowerShell 7 tool for a deterministic monthly review of employee,
group-membership, privileged-access, and guest CSV exports. It validates the
source data, applies documented review rules, and generates an actionable
manager report plus Microsoft Teams message drafts. It never changes access or
sends messages.

The exercise review date is fixed at **2026-08-15**. The supplied data produces
16 findings: 1 critical, 6 high, 7 medium, and 2 low.

## Run it

### Prerequisite

- PowerShell 7 (tested with 7.6.3)

There are no runtime package dependencies. From the repository root:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-AccessReview.ps1
```

This writes, or deterministically replaces:

- [`output/access-review-2026-08-15.md`](output/access-review-2026-08-15.md) -
  the non-technical manager report with owners, evidence, actions, and due dates;
- [`output/teams-messages-2026-08-15.md`](output/teams-messages-2026-08-15.md) -
  human-reviewed message drafts addressed to the responsible people.

The script resolves its default paths relative to the repository, so it can be
invoked from another working directory. Paths and date can also be explicit:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-AccessReview.ps1 `
  -InputDirectory ./data `
  -OutputDirectory ./output `
  -AsOfDate 2026-08-15
```

Exit code `0` means the review and input integrity checks completed. If one of
the reportable integrity checks below fails, both artifacts are still written,
the report status is `Incomplete`, and the CLI exits with code `2`. A structural
or parsing error that prevents a safe import, such as a missing column or an
invalid date, terminates with code `1` and an actionable error.

## What it reviews

The mandatory controls flag:

- privileged accounts whose last sign-in is missing or more than 30 days old;
- disabled accounts that retain an admin role or privileged-group membership;
- enabled guests that are expired or expire within 14 days, inclusive.

Additional hygiene controls flag enabled standard accounts with sign-ins older
than 30 days, enabled guests inactive for more than 90 days, admin roles on an
external email identity, and disabled accounts left in standard groups.

For this export, an admin role or any `security` group makes an account
privileged. The exact supplied anomalies and recommendations are in the
[generated report](output/access-review-2026-08-15.md).

### Input integrity checks

Before evaluating access, the tool checks that:

- employee `user_id` and guest `guest_id` values are unique;
- every membership `user_id` references an employee in `users.csv`; and
- every guest `invited_by_user_id` references an employee in `users.csv`.

Failures become high-severity findings in the manager report and Teams drafts
for IT & Security. The report explains the affected source, ID, evidence, and
required correction, and clearly states that the review must be rerun before
sign-off. Best-effort processing is deterministic: the first row for a
duplicated ID is used, orphan memberships remain unattached, and a guest with a
missing inviter is assigned to IT & Security for review.

## Tests and quality checks

Pester and PSScriptAnalyzer are development-only dependencies. The solution was
tested with Pester 6.0.1 and PSScriptAnalyzer 1.25.0.

```powershell
# Automated behavior, boundary, validation, and output tests
pwsh -NoProfile -Command 'Invoke-Pester -Path ./tests -Output Detailed'

# Static analysis; expected result: ISSUES=0
pwsh -NoProfile -Command '
  $issues = foreach ($path in @("./src", "./scripts", "./tests")) {
    Invoke-ScriptAnalyzer -Path $path -Recurse -Severity Error,Warning
  }
  $issues | Format-Table
  "ISSUES=$(@($issues).Count)"
  if (@($issues).Count -gt 0) { exit 1 }
'
```

The tests cover the exact mandatory findings, the strict `>30`-day sign-in
boundary, the inclusive 14-day guest-expiry boundary, supplementary controls,
invalid booleans, duplicate employee and guest IDs, orphan memberships,
missing guest inviters, incomplete-report generation, CLI exit codes, and
end-to-end artifact generation.

## Design

```text
CSV files -> strict import and validation -> normalized records
          -> deterministic review rules -> typed finding records
          -> manager report + Teams drafts
```

[`src/AccessReview.psm1`](src/AccessReview.psm1) separates import, validation,
finding detection, and Markdown rendering. The thin
[`scripts/Invoke-AccessReview.ps1`](scripts/Invoke-AccessReview.ps1) entry point
provides safe defaults and orchestration. The design is intentionally local and
dependency-free: its rules can be tested without Microsoft Graph or a tenant.

Structural validation fails with an actionable error for a missing file or
column, an empty identifier, an invalid ISO date or boolean, or an unknown group
type. Duplicate identifiers and broken employee references are reportable data
quality findings: the tool emits an incomplete best-effort review and returns a
nonzero status. Findings are sorted by severity, type, and stable subject ID so
repeated runs are comparable.

## Connecting it to Microsoft Graph

### Authentication model

For a scheduled production job, use **app-only authentication** under a
dedicated workload identity. In Azure, the preferred deployment is an Azure
Automation runbook or timer-triggered function with a managed identity. Grant
only read-only Microsoft Graph application permissions with admin consent. For
a non-Azure runner, use an app registration with workload identity federation
or a certificate stored in a managed vault; do not use a client secret in code
or configuration.

This follows Microsoft's guidance for
[app-only access](https://learn.microsoft.com/en-us/entra/identity-platform/app-only-access-primer)
and [certificate credentials](https://learn.microsoft.com/en-us/entra/msidweb/authentication/certificates).

### Permission scopes

| Application permission | Why it is needed |
|---|---|
| `User.Read.All` | Read employee and guest profiles, enabled state, department, and sponsor relationships. |
| `AuditLog.Read.All` | Read `signInActivity`; this property also requires an appropriate Entra ID license. |
| `GroupMember.Read.All` | Read group metadata and memberships used by the privilege policy. |
| `RoleManagement.Read.Directory` | Read directory-role definitions and assignments. |
| `EntitlementManagement.Read.All` | Optional: read access-package assignment schedules when they are the guest-expiry source. |

Microsoft documents these in the
[Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference).
`Member.Read.Hidden` would be added only if a reviewed privileged group has
hidden membership. The collector should not receive `Directory.ReadWrite.All`,
role-write, group-write, user-write, or Teams-send permissions.

### Data collection and mapping

The production collector would replace the CSV import while preserving the
normalized records and review engine:

1. Read users and guests from `/v1.0/users`, selecting `accountEnabled`,
   `createdDateTime`, `department`, `userType`, and `signInActivity`. Microsoft
   documents the permission and paging constraints on
   [List users](https://learn.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0).
2. Read active directory-role assignments from
   `/v1.0/roleManagement/directory/roleAssignments` and map their role
   definitions. See
   [List role assignments](https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roleassignments?view=graph-rest-1.0).
3. Read membership only for an approved privileged-group policy or allowlist;
   unlike this limited CSV, not every security group should be assumed
   privileged in production.
4. Resolve each guest's accountable sponsor from the organization's governance
   source. Guest expiry is not a universal Entra user property: map it from an
   [access-package assignment schedule](https://learn.microsoft.com/en-us/graph/api/resources/accesspackageassignment?view=graph-rest-1.0)
   or a governed custom extension, rather than inventing it from account age.
5. Follow every `@odata.nextLink`, retry `429` and transient `5xx` responses
   using `Retry-After` with bounded backoff, and write a complete snapshot only
   after all required queries succeed. A partial snapshot must fail the run.

The Graph adapter should save the same normalized schema to a protected staging
location and then call the existing rules. This keeps tenant I/O separate from
policy logic and provides an auditable monthly input snapshot.

## Scheduling and monitoring

Schedule one UTC run per month in Azure Automation (PowerShell 7) using the
managed identity above. Prevent overlapping runs and key the input snapshot and
reports by review date, making reruns idempotent. Publish reports to a private,
retention-controlled SharePoint library or storage account, then open a review
ticket assigned to IT & Security; do not post the drafts automatically.

Send structured logs to Azure Monitor / Log Analytics with run ID, review date,
input freshness, source counts, finding counts by severity and type, duration,
retry count, and output location. Never log tokens or unnecessary personal
data. Alert IT & Security on:

- failed or incomplete Graph collection, exhausted retries, or stale input;
- missing output, an unexpectedly empty dataset, or an unexpected zero-finding
  result;
- a material month-over-month count change; or
- a critical finding not acknowledged in the review ticket within its SLA.

Retain run status, input snapshot, report, reviewer decision, approval/ticket
reference, and eventual remediation evidence for the organization's defined
audit period.

## Actions that must never be autonomous

The automation may read data, calculate findings, create reports, and prepare
drafts. It must never autonomously:

- disable or delete a user or guest;
- remove, add, or time-limit a role or group membership;
- renew, extend, approve, or revoke guest access;
- send Teams/email messages or represent a finding as a final decision;
- dismiss a finding based only on inactivity or missing telemetry; or
- change the privilege policy, reviewer, owner, or evidence-retention record.

Every access change requires human validation of identity, employment/business
need, impact, documented approval, and an auditable change workflow. High-risk
changes should use least privilege, separation of duties, and rollback or
break-glass procedures outside this reporting tool.

## Review decisions, assumptions, and limitations

- Dates use whole UTC calendar days. A privileged sign-in exactly 30 days old
  is not stale; a guest expiring exactly 14 days after review is near expiry.
- Active non-privileged employees become stale after more than 30 days without
  sign-in; enabled guests become stale after more than 90 days.
- A missing privileged sign-in is a finding, not proof that the account was
  unused; Graph retention, licensing, and workload-account behavior need human
  interpretation.
- Treating every exported `security` group as privileged is an exercise-only
  conservative assumption because there is no `is_privileged` field.
  Production requires an approved allowlist/policy and role-assignable-group
  metadata rather than a group name or `security` type alone.
- Employee manager data was not supplied. An active human administrator is
  asked to confirm their own access; disabled accounts, service accounts,
  external administrators, and other cases without a reliable owner are routed
  to IT & Security. Standard stale-account drafts identify the department
  manager as the business reviewer.
- `invited_by_user_id` is treated as the guest's accountable sponsor. A missing
  inviter is a data-quality finding and falls back to IT & Security.
- Microsoft Teams content is draft-only. The tool does not call Graph, Teams, a
  ticketing system, or an access-control API; it never sends a message or
  disables, deletes, assigns, removes, renews, or otherwise changes access.

## Repository layout

```text
data/       Reproducible challenge CSV inputs
output/     Generated manager report and Teams drafts
scripts/    Reviewer-facing CLI
src/        Import, validation, review, and rendering module
tests/      Pester test suite
.agent/     Execution plan and development context
```

## License

The code is under the [PolyForm Noncommercial License 1.0.0](LICENSE).
WorkFlex also receives the limited rights in
[EVALUATION_PERMISSION.md](EVALUATION_PERMISSION.md) to clone, run, test, and
review it solely for evaluating Yurii Ponomarenko's candidacy.
