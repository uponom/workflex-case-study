# Monthly Access Review

- **Review date:** 2026-08-15
- **Review status:** Complete - input integrity checks passed
- **Scope:** 73 employee rows, 192 group membership rows, 12 guest rows
- **Result:** 16 findings - 1 critical, 6 high, 7 medium, 2 low

## Executive summary

Access checks identified: disabled privileged accounts - 1; privileged accounts with stale or missing sign-ins - 4; expired guests - 1; guests expiring within 14 days - 2. Additional identity-hygiene findings should be confirmed during the same review cycle.

### Management actions

1. Have IT & Security remove or formally reapprove privileges on disabled privileged accounts immediately.
2. Ask privileged account owners to confirm business need and ownership within three business days.
3. Ask each guest sponsor to remove or extend access before the stated deadline.
4. Review the additional stale and identity-hygiene findings before the next monthly review.

## Immediate and high-priority findings

| Severity | Subject | Issue | Evidence | Owner | Due |
|---|---|---|---|---|---|
| Critical | Priya Nair (U065) | Disabled account still retains privileged access | Account disabled; privilege: Global Administrator, SEC-PrivilegedAccess, PROD-Admins | IT & Security | Immediate |
| High | Diego Fuentes (G05) | Enabled guest access is past its expiry date | Expired 16 days ago on 2026-07-30; company: LinguaPro SL | Julia Berg | Immediate |
| High | Elena Petrova (U070) | Administrative role is assigned to an external email identity | Email elena.petrova.freelance@gmail.com; role: User Administrator | IT & Security | Within 3 business days |
| High | Priya Nair (U065) | Privileged account has stale or missing sign-in activity | Last sign-in 2026-05-03 (104 days ago); privilege: Global Administrator, SEC-PrivilegedAccess, PROD-Admins | IT & Security | Within 3 business days |
| High | Marek Kowalski (U066) | Privileged account has stale or missing sign-in activity | Last sign-in 2026-06-01 (75 days ago); privilege: Global Administrator, SEC-PrivilegedAccess | Marek Kowalski | Within 3 business days |
| High | Sofia Lindqvist (U067) | Privileged account has stale or missing sign-in activity | Last sign-in 2026-06-12 (64 days ago); privilege: Intune Administrator | Sofia Lindqvist | Within 3 business days |
| High | Backup Service (U068) | Privileged account has stale or missing sign-in activity | No sign-in is recorded; privilege: Exchange Administrator | IT & Security | Within 3 business days |

## Detailed findings

### Disabled accounts retaining privileges (1)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| Critical | Priya Nair (U065) | Account disabled; privilege: Global Administrator, SEC-PrivilegedAccess, PROD-Admins | IT & Security | Validate the disablement, remove privileged roles and security-group memberships, and preserve an audit record. | Immediate |

### Privileged accounts with stale or missing sign-ins (4)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| High | Priya Nair (U065) | Last sign-in 2026-05-03 (104 days ago); privilege: Global Administrator, SEC-PrivilegedAccess, PROD-Admins | IT & Security | Confirm the named owner and business need; remove or time-bound privileges that are no longer required. | Within 3 business days |
| High | Marek Kowalski (U066) | Last sign-in 2026-06-01 (75 days ago); privilege: Global Administrator, SEC-PrivilegedAccess | Marek Kowalski | Confirm the named owner and business need; remove or time-bound privileges that are no longer required. | Within 3 business days |
| High | Sofia Lindqvist (U067) | Last sign-in 2026-06-12 (64 days ago); privilege: Intune Administrator | Sofia Lindqvist | Confirm the named owner and business need; remove or time-bound privileges that are no longer required. | Within 3 business days |
| High | Backup Service (U068) | No sign-in is recorded; privilege: Exchange Administrator | IT & Security | Confirm the named owner and business need; remove or time-bound privileges that are no longer required. | Within 3 business days |

### Expired guest access (1)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| High | Diego Fuentes (G05) | Expired 16 days ago on 2026-07-30; company: LinguaPro SL | Julia Berg | Confirm whether access is still needed; request approved removal or a documented extension. | Immediate |

### Guest access near expiry (2)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| Medium | Ahmed Saleh (G07) | Expires in 7 days on 2026-08-22; company: RedTeam Labs | Olga Larsen | Confirm whether access should expire as scheduled or submit a documented extension before the deadline. | Before expiry |
| Medium | Ken Tanaka (G09) | Expires in 12 days on 2026-08-27; company: APIWorks KK | Omar Lind | Confirm whether access should expire as scheduled or submit a documented extension before the deadline. | Before expiry |

### Administrative roles on external email identities (1)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| High | Elena Petrova (U070) | Email elena.petrova.freelance@gmail.com; role: User Administrator | IT & Security | Confirm this is an approved managed identity; migrate administration to a controlled company account or remove the role. | Within 3 business days |

### Enabled employee accounts with stale sign-ins (4)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| Medium | Emil Sturm (U059) | Last sign-in 2026-06-29 (47 days ago) | IT & Security / Compliance Research manager | Confirm employment and access need with the department owner; investigate or disable through the approved offboarding process. | Within 7 business days |
| Medium | Lena Farkas (U060) | Last sign-in 2026-06-10 (66 days ago) | IT & Security / Operations manager | Confirm employment and access need with the department owner; investigate or disable through the approved offboarding process. | Within 7 business days |
| Medium | Rene Haas (U061) | Last sign-in 2026-07-07 (39 days ago) | IT & Security / Engineering manager | Confirm employment and access need with the department owner; investigate or disable through the approved offboarding process. | Within 7 business days |
| Medium | Tessa Meyer (U062) | Last sign-in 2026-05-12 (95 days ago) | IT & Security / Marketing manager | Confirm employment and access need with the department owner; investigate or disable through the approved offboarding process. | Within 7 business days |

### Enabled guests with stale sign-ins (1)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| Medium | Viktor Olsen (G11) | Last sign-in 2026-03-11 (157 days ago); expiry 2027-07-01 | Yusuf Dubois | Confirm ongoing business need and request removal if the collaboration has ended. | Within 7 business days |

### Disabled accounts with residual standard groups (2)

| Severity | Subject | Evidence | Responsible | Recommended action | Due |
|---|---|---|---|---|---|
| Low | Emil Olsen (U063) | Residual groups: ALL-Staff, OPS-All, Logistics-Tools | IT & Security | Confirm retention requirements and remove obsolete group memberships through the approved cleanup process. | Before the next monthly review |
| Low | Marco Benes (U064) | Residual groups: ALL-Staff, Board-Reports | IT & Security | Confirm retention requirements and remove obsolete group memberships through the approved cleanup process. | Before the next monthly review |

## Review rules and assumptions

- A privileged account has an admin role or membership in a group whose export type is `security`.
- Privileged sign-in is stale only when it is more than 30 days old; exactly 30 days is not stale.
- Guest expiry is near when it falls from the review date through 14 days after it, inclusive.
- Additional hygiene controls flag enabled standard users after 30 days and enabled guests after 90 days without sign-in.
- The inviter is the guest sponsor. Employee manager relationships were not supplied, so IT & Security is the fallback owner.
- All findings are recommendations for human review. This tool changes no identity, role, group, guest, or Teams resource.

## Data quality

**Passed.** Employee and guest identifiers are unique, every group membership references an existing employee, and every guest inviter exists. Required columns were present and all dates and booleans parsed strictly.

---
Generated deterministically by the read-only WorkFlex access-review tool.
