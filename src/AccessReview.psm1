Set-StrictMode -Version Latest

function ConvertTo-ReviewBoolean {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Value,

        [Parameter(Mandatory)]
        [string] $FieldName
    )

    switch ($Value.Trim().ToLowerInvariant()) {
        'true' { return $true }
        'false' { return $false }
        default { throw "Invalid boolean '$Value' in $FieldName. Expected True or False." }
    }
}

function ConvertTo-ReviewDate {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Value,

        [Parameter(Mandatory)]
        [string] $FieldName,

        [switch] $AllowEmpty
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($AllowEmpty) {
            return $null
        }

        throw "Missing required date in $FieldName. Expected yyyy-MM-dd."
    }

    try {
        $parsed = [datetime]::ParseExact(
            $Value.Trim(),
            'yyyy-MM-dd',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None
        )
        return [datetime]::SpecifyKind($parsed, [System.DateTimeKind]::Utc)
    }
    catch {
        throw "Invalid date '$Value' in $FieldName. Expected yyyy-MM-dd."
    }
}

function Assert-RequiredColumnSchema {
    param(
        [Parameter(Mandatory)]
        [object[]] $Rows,

        [Parameter(Mandatory)]
        [string[]] $RequiredColumns,

        [Parameter(Mandatory)]
        [string] $SourceName
    )

    if ($Rows.Count -eq 0) {
        throw "$SourceName contains no data rows."
    }

    $actualColumns = @($Rows[0].PSObject.Properties.Name)
    $missing = @($RequiredColumns | Where-Object { $_ -notin $actualColumns })
    if ($missing.Count -gt 0) {
        throw "$SourceName is missing required column(s): $($missing -join ', ')."
    }
}

function Get-DuplicateIdentifier {
    param(
        [Parameter(Mandatory)]
        [object[]] $Rows,

        [Parameter(Mandatory)]
        [string] $PropertyName,

        [Parameter(Mandatory)]
        [string] $SourceName
    )

    $blank = @($Rows | Where-Object { [string]::IsNullOrWhiteSpace($_.$PropertyName) })
    if ($blank.Count -gt 0) {
        throw "$SourceName contains a blank $PropertyName."
    }

    return @(
        $Rows |
            Group-Object -Property $PropertyName |
            Where-Object Count -gt 1 |
            Sort-Object Name |
            ForEach-Object {
                [pscustomobject]@{
                    Source = $SourceName
                    Identifier = $_.Name
                    Count = $_.Count
                }
            }
    )
}

function ConvertTo-DataQualityIssue {
    param(
        [Parameter(Mandatory)] [string] $Code,
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $SubjectId,
        [Parameter(Mandatory)] [string] $Summary,
        [Parameter(Mandatory)] [string] $Evidence,
        [Parameter(Mandatory)] [string] $RecommendedAction
    )

    return [pscustomobject]@{
        Code = $Code
        Source = $Source
        SubjectId = $SubjectId
        Summary = $Summary
        Evidence = $Evidence
        RecommendedAction = $RecommendedAction
    }
}

function Import-AccessReviewData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $UsersPath,

        [Parameter(Mandatory)]
        [string] $GroupMembershipsPath,

        [Parameter(Mandatory)]
        [string] $GuestsPath
    )

    foreach ($path in @($UsersPath, $GroupMembershipsPath, $GuestsPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Input file not found: $path"
        }
    }

    $rawUsers = @(Import-Csv -LiteralPath $UsersPath)
    $rawMemberships = @(Import-Csv -LiteralPath $GroupMembershipsPath)
    $rawGuests = @(Import-Csv -LiteralPath $GuestsPath)

    Assert-RequiredColumnSchema -Rows $rawUsers -SourceName 'users.csv' -RequiredColumns @(
        'user_id', 'display_name', 'email', 'department', 'admin_roles',
        'account_enabled', 'last_sign_in_utc', 'created_utc'
    )
    Assert-RequiredColumnSchema -Rows $rawMemberships -SourceName 'group_memberships.csv' -RequiredColumns @(
        'user_id', 'group_name', 'group_type', 'granted_utc'
    )
    Assert-RequiredColumnSchema -Rows $rawGuests -SourceName 'guests.csv' -RequiredColumns @(
        'guest_id', 'display_name', 'email', 'company', 'invited_by_user_id',
        'account_enabled', 'access_expires_utc', 'last_sign_in_utc'
    )

    $dataQualityIssues = [System.Collections.Generic.List[object]]::new()
    foreach ($duplicate in @(Get-DuplicateIdentifier -Rows $rawUsers -PropertyName 'user_id' -SourceName 'users.csv')) {
        $dataQualityIssues.Add((ConvertTo-DataQualityIssue `
            -Code 'DuplicateUserId' -Source $duplicate.Source -SubjectId $duplicate.Identifier `
            -Summary 'Duplicate employee identifier' `
            -Evidence "user_id $($duplicate.Identifier) occurs $($duplicate.Count) times" `
            -RecommendedAction 'Correct the source export so each employee ID occurs exactly once, then rerun the review.'))
    }
    foreach ($duplicate in @(Get-DuplicateIdentifier -Rows $rawGuests -PropertyName 'guest_id' -SourceName 'guests.csv')) {
        $dataQualityIssues.Add((ConvertTo-DataQualityIssue `
            -Code 'DuplicateGuestId' -Source $duplicate.Source -SubjectId $duplicate.Identifier `
            -Summary 'Duplicate guest identifier' `
            -Evidence "guest_id $($duplicate.Identifier) occurs $($duplicate.Count) times" `
            -RecommendedAction 'Correct the source export so each guest ID occurs exactly once, then rerun the review.'))
    }

    $users = @(
        foreach ($row in $rawUsers) {
            $roles = @(
                $row.admin_roles -split '[;|]' |
                    ForEach-Object { $_.Trim() } |
                    Where-Object { $_ }
            )

            [pscustomobject]@{
                UserId = $row.user_id.Trim()
                DisplayName = $row.display_name.Trim()
                Email = $row.email.Trim()
                Department = $row.department.Trim()
                AdminRoles = [string[]] $roles
                AccountEnabled = ConvertTo-ReviewBoolean -Value $row.account_enabled -FieldName "users.csv:$($row.user_id):account_enabled"
                LastSignInUtc = ConvertTo-ReviewDate -Value $row.last_sign_in_utc -FieldName "users.csv:$($row.user_id):last_sign_in_utc" -AllowEmpty
                CreatedUtc = ConvertTo-ReviewDate -Value $row.created_utc -FieldName "users.csv:$($row.user_id):created_utc"
            }
        }
    )

    $memberships = @(
        foreach ($row in $rawMemberships) {
            $groupType = $row.group_type.Trim().ToLowerInvariant()
            if ($groupType -notin @('security', 'm365')) {
                throw "Invalid group type '$($row.group_type)' for user $($row.user_id). Expected security or m365."
            }

            [pscustomobject]@{
                UserId = $row.user_id.Trim()
                GroupName = $row.group_name.Trim()
                GroupType = $groupType
                GrantedUtc = ConvertTo-ReviewDate -Value $row.granted_utc -FieldName "group_memberships.csv:$($row.user_id):granted_utc"
            }
        }
    )

    $guests = @(
        foreach ($row in $rawGuests) {
            [pscustomobject]@{
                GuestId = $row.guest_id.Trim()
                DisplayName = $row.display_name.Trim()
                Email = $row.email.Trim()
                Company = $row.company.Trim()
                InvitedByUserId = $row.invited_by_user_id.Trim()
                AccountEnabled = ConvertTo-ReviewBoolean -Value $row.account_enabled -FieldName "guests.csv:$($row.guest_id):account_enabled"
                AccessExpiresUtc = ConvertTo-ReviewDate -Value $row.access_expires_utc -FieldName "guests.csv:$($row.guest_id):access_expires_utc"
                LastSignInUtc = ConvertTo-ReviewDate -Value $row.last_sign_in_utc -FieldName "guests.csv:$($row.guest_id):last_sign_in_utc" -AllowEmpty
            }
        }
    )

    $uniqueUsers = [System.Collections.Generic.List[object]]::new()
    $userById = @{}
    foreach ($user in $users) {
        if (-not $userById.ContainsKey($user.UserId)) {
            $userById[$user.UserId] = $user
            $uniqueUsers.Add($user)
        }
    }

    $orphanMemberships = @($memberships | Where-Object { -not $userById.ContainsKey($_.UserId) })
    foreach ($orphanGroup in @($orphanMemberships | Group-Object UserId | Sort-Object Name)) {
        $groupNames = @($orphanGroup.Group | ForEach-Object GroupName | Sort-Object -Unique)
        $membershipUserId = if ([string]::IsNullOrWhiteSpace($orphanGroup.Name)) { '<blank>' } else { $orphanGroup.Name }
        $dataQualityIssues.Add((ConvertTo-DataQualityIssue `
            -Code 'OrphanMembership' -Source 'group_memberships.csv' -SubjectId $membershipUserId `
            -Summary 'Group membership references an unknown employee' `
            -Evidence "user_id $membershipUserId has $($orphanGroup.Count) membership row(s): $($groupNames -join ', ')" `
            -RecommendedAction 'Correct or remove the orphaned membership rows, then rerun the review.'))
    }

    $uniqueGuests = [System.Collections.Generic.List[object]]::new()
    $guestById = @{}
    foreach ($guest in $guests) {
        if (-not $guestById.ContainsKey($guest.GuestId)) {
            $guestById[$guest.GuestId] = $guest
            $uniqueGuests.Add($guest)
        }
    }

    $orphanInviters = @($uniqueGuests | Where-Object { -not $userById.ContainsKey($_.InvitedByUserId) })
    foreach ($guest in @($orphanInviters | Sort-Object GuestId)) {
        $inviterUserId = if ([string]::IsNullOrWhiteSpace($guest.InvitedByUserId)) { '<blank>' } else { $guest.InvitedByUserId }
        $dataQualityIssues.Add((ConvertTo-DataQualityIssue `
            -Code 'MissingGuestInviter' -Source 'guests.csv' -SubjectId $guest.GuestId `
            -Summary 'Guest inviter does not exist in the employee export' `
            -Evidence "guest_id $($guest.GuestId) references invited_by_user_id $inviterUserId" `
            -RecommendedAction 'Assign a valid accountable sponsor or correct the inviter reference, then rerun the review.'))
    }

    $groupsByUser = @{}
    foreach ($membership in $memberships) {
        if (-not $groupsByUser.ContainsKey($membership.UserId)) {
            $groupsByUser[$membership.UserId] = [System.Collections.Generic.List[object]]::new()
        }
        $groupsByUser[$membership.UserId].Add($membership)
    }

    return [pscustomobject]@{
        Users = @($uniqueUsers)
        Memberships = $memberships
        Guests = @($uniqueGuests)
        UserById = $userById
        GroupsByUser = $groupsByUser
        DataQualityIssues = @($dataQualityIssues)
        SourceCounts = [pscustomobject]@{
            Users = $rawUsers.Count
            Memberships = $rawMemberships.Count
            Guests = $rawGuests.Count
        }
    }
}

function ConvertTo-AccessFinding {
    param(
        [Parameter(Mandatory)] [string] $Type,
        [Parameter(Mandatory)] [string] $Severity,
        [Parameter(Mandatory)] [string] $SubjectId,
        [Parameter(Mandatory)] [string] $SubjectName,
        [string] $SubjectEmail = '',
        [Parameter(Mandatory)] [string] $ResponsibleName,
        [string] $ResponsibleEmail = '',
        [Parameter(Mandatory)] [string] $Summary,
        [Parameter(Mandatory)] [string] $Evidence,
        [Parameter(Mandatory)] [string] $RecommendedAction,
        [Parameter(Mandatory)] [string] $Due
    )

    [pscustomobject]@{
        Type = $Type
        Severity = $Severity
        SubjectId = $SubjectId
        SubjectName = $SubjectName
        SubjectEmail = $SubjectEmail
        ResponsibleName = $ResponsibleName
        ResponsibleEmail = $ResponsibleEmail
        Summary = $Summary
        Evidence = $Evidence
        RecommendedAction = $RecommendedAction
        Due = $Due
    }
}

function Get-AccessReviewFinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $Data,

        [Parameter(Mandatory)]
        [datetime] $AsOfDate,

        [ValidateRange(1, 3650)]
        [int] $PrivilegedStaleDays = 30,

        [ValidateRange(0, 365)]
        [int] $GuestExpiryWarningDays = 14,

        [ValidateRange(1, 3650)]
        [int] $StandardUserStaleDays = 30,

        [ValidateRange(1, 3650)]
        [int] $GuestStaleDays = 90,

        [string] $InternalEmailDomain = 'helioworks.example'
    )

    $reviewDate = $AsOfDate.Date
    $findings = [System.Collections.Generic.List[object]]::new()

    foreach ($issue in $Data.DataQualityIssues) {
        $findings.Add((ConvertTo-AccessFinding -Type 'DataQualityIssue' -Severity 'High' `
            -SubjectId $issue.SubjectId -SubjectName $issue.Source `
            -ResponsibleName 'IT & Security' `
            -Summary $issue.Summary `
            -Evidence "$($issue.Code): $($issue.Evidence)" `
            -RecommendedAction $issue.RecommendedAction `
            -Due 'Immediate'))
    }

    foreach ($user in $Data.Users) {
        $userGroups = if ($Data.GroupsByUser.ContainsKey($user.UserId)) {
            @($Data.GroupsByUser[$user.UserId])
        }
        else {
            @()
        }
        $privilegedGroups = @($userGroups | Where-Object GroupType -eq 'security')
        $privilegeLabels = @($user.AdminRoles) + @($privilegedGroups | ForEach-Object GroupName)
        $isPrivileged = $privilegeLabels.Count -gt 0

        if ($isPrivileged) {
            $daysSinceSignIn = if ($null -eq $user.LastSignInUtc) {
                $null
            }
            else {
                ($reviewDate - $user.LastSignInUtc.Date).Days
            }

            if ($null -eq $daysSinceSignIn -or $daysSinceSignIn -gt $PrivilegedStaleDays) {
                $signInEvidence = if ($null -eq $daysSinceSignIn) {
                    'No sign-in is recorded'
                }
                else {
                    "Last sign-in $($user.LastSignInUtc.ToString('yyyy-MM-dd')) ($daysSinceSignIn days ago)"
                }
                $ownerIsUser = $user.AccountEnabled -and $user.DisplayName -notmatch '(?i)service' -and $user.Email -notmatch '(?i)^svc-'
                $responsibleName = if ($ownerIsUser) { $user.DisplayName } else { 'IT & Security' }
                $responsibleEmail = if ($ownerIsUser) { $user.Email } else { '' }

                $findings.Add((ConvertTo-AccessFinding -Type 'StalePrivilegedAccount' -Severity 'High' `
                    -SubjectId $user.UserId -SubjectName $user.DisplayName -SubjectEmail $user.Email `
                    -ResponsibleName $responsibleName -ResponsibleEmail $responsibleEmail `
                    -Summary 'Privileged account has stale or missing sign-in activity' `
                    -Evidence "$signInEvidence; privilege: $($privilegeLabels -join ', ')" `
                    -RecommendedAction 'Confirm the named owner and business need; remove or time-bound privileges that are no longer required.' `
                    -Due 'Within 3 business days'))
            }

            if (-not $user.AccountEnabled) {
                $findings.Add((ConvertTo-AccessFinding -Type 'DisabledPrivilegedAccount' -Severity 'Critical' `
                    -SubjectId $user.UserId -SubjectName $user.DisplayName -SubjectEmail $user.Email `
                    -ResponsibleName 'IT & Security' `
                    -Summary 'Disabled account still retains privileged access' `
                    -Evidence "Account disabled; privilege: $($privilegeLabels -join ', ')" `
                    -RecommendedAction 'Validate the disablement, remove privileged roles and security-group memberships, and preserve an audit record.' `
                    -Due 'Immediate'))
            }

            $isInternalEmail = $user.Email.EndsWith("@$InternalEmailDomain", [System.StringComparison]::OrdinalIgnoreCase)
            if (-not $isInternalEmail -and $user.AdminRoles.Count -gt 0) {
                $findings.Add((ConvertTo-AccessFinding -Type 'ExternalPrivilegedEmail' -Severity 'High' `
                    -SubjectId $user.UserId -SubjectName $user.DisplayName -SubjectEmail $user.Email `
                    -ResponsibleName 'IT & Security' `
                    -Summary 'Administrative role is assigned to an external email identity' `
                    -Evidence "Email $($user.Email); role: $($user.AdminRoles -join ', ')" `
                    -RecommendedAction 'Confirm this is an approved managed identity; migrate administration to a controlled company account or remove the role.' `
                    -Due 'Within 3 business days'))
            }
        }
        elseif ($user.AccountEnabled -and $null -ne $user.LastSignInUtc) {
            $daysSinceSignIn = ($reviewDate - $user.LastSignInUtc.Date).Days
            if ($daysSinceSignIn -gt $StandardUserStaleDays) {
                $findings.Add((ConvertTo-AccessFinding -Type 'StaleStandardAccount' -Severity 'Medium' `
                    -SubjectId $user.UserId -SubjectName $user.DisplayName -SubjectEmail $user.Email `
                    -ResponsibleName "IT & Security / $($user.Department) manager" `
                    -Summary 'Enabled employee account has stale sign-in activity' `
                    -Evidence "Last sign-in $($user.LastSignInUtc.ToString('yyyy-MM-dd')) ($daysSinceSignIn days ago)" `
                    -RecommendedAction 'Confirm employment and access need with the department owner; investigate or disable through the approved offboarding process.' `
                    -Due 'Within 7 business days'))
            }
        }

        if (-not $user.AccountEnabled -and -not $isPrivileged -and $userGroups.Count -gt 0) {
            $findings.Add((ConvertTo-AccessFinding -Type 'DisabledResidualMembership' -Severity 'Low' `
                -SubjectId $user.UserId -SubjectName $user.DisplayName -SubjectEmail $user.Email `
                -ResponsibleName 'IT & Security' `
                -Summary 'Disabled account remains in non-privileged groups' `
                -Evidence "Residual groups: $(@($userGroups | ForEach-Object GroupName) -join ', ')" `
                -RecommendedAction 'Confirm retention requirements and remove obsolete group memberships through the approved cleanup process.' `
                -Due 'Before the next monthly review'))
        }
    }

    foreach ($guest in $Data.Guests) {
        $sponsor = if ($Data.UserById.ContainsKey($guest.InvitedByUserId)) {
            $Data.UserById[$guest.InvitedByUserId]
        }
        else {
            [pscustomobject]@{
                DisplayName = 'IT & Security'
                Email = ''
            }
        }
        $daysToExpiry = ($guest.AccessExpiresUtc.Date - $reviewDate).Days

        if ($daysToExpiry -lt 0) {
            $findings.Add((ConvertTo-AccessFinding -Type 'ExpiredGuest' -Severity 'High' `
                -SubjectId $guest.GuestId -SubjectName $guest.DisplayName -SubjectEmail $guest.Email `
                -ResponsibleName $sponsor.DisplayName -ResponsibleEmail $sponsor.Email `
                -Summary 'Enabled guest access is past its expiry date' `
                -Evidence "Expired $(-$daysToExpiry) days ago on $($guest.AccessExpiresUtc.ToString('yyyy-MM-dd')); company: $($guest.Company)" `
                -RecommendedAction 'Confirm whether access is still needed; request approved removal or a documented extension.' `
                -Due 'Immediate'))
        }
        elseif ($daysToExpiry -le $GuestExpiryWarningDays) {
            $findings.Add((ConvertTo-AccessFinding -Type 'GuestNearExpiry' -Severity 'Medium' `
                -SubjectId $guest.GuestId -SubjectName $guest.DisplayName -SubjectEmail $guest.Email `
                -ResponsibleName $sponsor.DisplayName -ResponsibleEmail $sponsor.Email `
                -Summary 'Guest access expires within the review window' `
                -Evidence "Expires in $daysToExpiry days on $($guest.AccessExpiresUtc.ToString('yyyy-MM-dd')); company: $($guest.Company)" `
                -RecommendedAction 'Confirm whether access should expire as scheduled or submit a documented extension before the deadline.' `
                -Due 'Before expiry'))
        }
        elseif ($guest.AccountEnabled -and $null -ne $guest.LastSignInUtc) {
            $daysSinceSignIn = ($reviewDate - $guest.LastSignInUtc.Date).Days
            if ($daysSinceSignIn -gt $GuestStaleDays) {
                $findings.Add((ConvertTo-AccessFinding -Type 'StaleGuest' -Severity 'Medium' `
                    -SubjectId $guest.GuestId -SubjectName $guest.DisplayName -SubjectEmail $guest.Email `
                    -ResponsibleName $sponsor.DisplayName -ResponsibleEmail $sponsor.Email `
                    -Summary 'Enabled guest has not signed in for more than 90 days' `
                    -Evidence "Last sign-in $($guest.LastSignInUtc.ToString('yyyy-MM-dd')) ($daysSinceSignIn days ago); expiry $($guest.AccessExpiresUtc.ToString('yyyy-MM-dd'))" `
                    -RecommendedAction 'Confirm ongoing business need and request removal if the collaboration has ended.' `
                    -Due 'Within 7 business days'))
            }
        }
    }

    $severityRank = @{ Critical = 0; High = 1; Medium = 2; Low = 3 }
    return @(
        $findings |
            Sort-Object @{ Expression = { $severityRank[$_.Severity] } }, Type, SubjectId
    )
}

function ConvertTo-MarkdownCell {
    param([AllowNull()][object] $Value)

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return '-'
    }

    return ([string]$Value).Replace('|', '\|').Replace("`r`n", '<br>').Replace("`n", '<br>')
}

function Get-FindingTypeTitle {
    param([Parameter(Mandatory)][string] $Type)

    switch ($Type) {
        'DataQualityIssue' { 'Input data quality issues' }
        'DisabledPrivilegedAccount' { 'Disabled accounts retaining privileges' }
        'StalePrivilegedAccount' { 'Privileged accounts with stale or missing sign-ins' }
        'ExpiredGuest' { 'Expired guest access' }
        'GuestNearExpiry' { 'Guest access near expiry' }
        'ExternalPrivilegedEmail' { 'Administrative roles on external email identities' }
        'StaleStandardAccount' { 'Enabled employee accounts with stale sign-ins' }
        'StaleGuest' { 'Enabled guests with stale sign-ins' }
        'DisabledResidualMembership' { 'Disabled accounts with residual standard groups' }
        default { $Type }
    }
}

function New-AccessReviewReport {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [object[]] $Findings,
        [Parameter(Mandatory)] [pscustomobject] $Data,
        [Parameter(Mandatory)] [datetime] $AsOfDate,
        [Parameter(Mandatory)] [string] $OutputPath
    )

    $allFindings = @($Findings)
    $severityCounts = @{}
    foreach ($severity in @('Critical', 'High', 'Medium', 'Low')) {
        $severityCounts[$severity] = @($allFindings | Where-Object Severity -eq $severity).Count
    }
    $dataQualityIssues = @($Data.DataQualityIssues)
    $reviewStatus = if ($dataQualityIssues.Count -eq 0) {
        'Complete - input integrity checks passed'
    }
    else {
        "Incomplete - input data quality issues found: $($dataQualityIssues.Count)"
    }

    $disabledPrivilegedCount = @($allFindings | Where-Object Type -eq 'DisabledPrivilegedAccount').Count
    $stalePrivilegedCount = @($allFindings | Where-Object Type -eq 'StalePrivilegedAccount').Count
    $expiredGuestCount = @($allFindings | Where-Object Type -eq 'ExpiredGuest').Count
    $nearExpiryGuestCount = @($allFindings | Where-Object Type -eq 'GuestNearExpiry').Count

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Monthly Access Review')
    $lines.Add('')
    $lines.Add("- **Review date:** $($AsOfDate.ToString('yyyy-MM-dd'))")
    $lines.Add("- **Review status:** $reviewStatus")
    $lines.Add("- **Scope:** $($Data.SourceCounts.Users) employee rows, $($Data.SourceCounts.Memberships) group membership rows, $($Data.SourceCounts.Guests) guest rows")
    $lines.Add("- **Result:** $($allFindings.Count) findings - $($severityCounts.Critical) critical, $($severityCounts.High) high, $($severityCounts.Medium) medium, $($severityCounts.Low) low")
    $lines.Add('')
    $lines.Add('## Executive summary')
    $lines.Add('')
    if ($dataQualityIssues.Count -gt 0) {
        $lines.Add("The review is incomplete. Input integrity issues found: $($dataQualityIssues.Count). These issues can make ownership or access results ambiguous. The tool performed a deterministic best-effort review, but the source data must be corrected and the review rerun before sign-off.")
        $lines.Add('')
    }
    $lines.Add("Access checks identified: disabled privileged accounts - $disabledPrivilegedCount; privileged accounts with stale or missing sign-ins - $stalePrivilegedCount; expired guests - $expiredGuestCount; guests expiring within 14 days - $nearExpiryGuestCount. Additional identity-hygiene findings should be confirmed during the same review cycle.")
    $lines.Add('')
    $lines.Add('### Management actions')
    $lines.Add('')
    $managementActions = [System.Collections.Generic.List[string]]::new()
    if ($dataQualityIssues.Count -gt 0) {
        $managementActions.Add('Correct the listed source-data issues and rerun the review before approval; do not treat this run as complete.')
    }
    $managementActions.Add('Have IT & Security remove or formally reapprove privileges on disabled privileged accounts immediately.')
    $managementActions.Add('Ask privileged account owners to confirm business need and ownership within three business days.')
    $managementActions.Add('Ask each guest sponsor to remove or extend access before the stated deadline.')
    $managementActions.Add('Review the additional stale and identity-hygiene findings before the next monthly review.')
    for ($index = 0; $index -lt $managementActions.Count; $index++) {
        $lines.Add("$($index + 1). $($managementActions[$index])")
    }
    $lines.Add('')
    $lines.Add('## Immediate and high-priority findings')
    $lines.Add('')
    $lines.Add('| Severity | Subject | Issue | Evidence | Owner | Due |')
    $lines.Add('|---|---|---|---|---|---|')
    foreach ($finding in @($allFindings | Where-Object Severity -in @('Critical', 'High'))) {
        $lines.Add("| $(ConvertTo-MarkdownCell $finding.Severity) | $(ConvertTo-MarkdownCell "$($finding.SubjectName) ($($finding.SubjectId))") | $(ConvertTo-MarkdownCell $finding.Summary) | $(ConvertTo-MarkdownCell $finding.Evidence) | $(ConvertTo-MarkdownCell $finding.ResponsibleName) | $(ConvertTo-MarkdownCell $finding.Due) |")
    }

    $typeOrder = @(
        'DisabledPrivilegedAccount',
        'StalePrivilegedAccount',
        'ExpiredGuest',
        'GuestNearExpiry',
        'ExternalPrivilegedEmail',
        'StaleStandardAccount',
        'StaleGuest',
        'DisabledResidualMembership'
    )

    $lines.Add('')
    $lines.Add('## Detailed findings')
    foreach ($type in $typeOrder) {
        $typed = @($allFindings | Where-Object Type -eq $type)
        if ($typed.Count -eq 0) {
            continue
        }

        $lines.Add('')
        $lines.Add("### $(Get-FindingTypeTitle $type) ($($typed.Count))")
        $lines.Add('')
        $lines.Add('| Severity | Subject | Evidence | Responsible | Recommended action | Due |')
        $lines.Add('|---|---|---|---|---|---|')
        foreach ($finding in $typed) {
            $lines.Add("| $(ConvertTo-MarkdownCell $finding.Severity) | $(ConvertTo-MarkdownCell "$($finding.SubjectName) ($($finding.SubjectId))") | $(ConvertTo-MarkdownCell $finding.Evidence) | $(ConvertTo-MarkdownCell $finding.ResponsibleName) | $(ConvertTo-MarkdownCell $finding.RecommendedAction) | $(ConvertTo-MarkdownCell $finding.Due) |")
        }
    }

    $lines.Add('')
    $lines.Add('## Review rules and assumptions')
    $lines.Add('')
    $lines.Add('- A privileged account has an admin role or membership in a group whose export type is `security`.')
    $lines.Add('- Privileged sign-in is stale only when it is more than 30 days old; exactly 30 days is not stale.')
    $lines.Add('- Guest expiry is near when it falls from the review date through 14 days after it, inclusive.')
    $lines.Add('- Additional hygiene controls flag enabled standard users after 30 days and enabled guests after 90 days without sign-in.')
    $lines.Add('- The inviter is the guest sponsor. Employee manager relationships were not supplied, so IT & Security is the fallback owner.')
    $lines.Add('- All findings are recommendations for human review. This tool changes no identity, role, group, guest, or Teams resource.')
    $lines.Add('')
    $lines.Add('## Data quality')
    $lines.Add('')
    if ($dataQualityIssues.Count -eq 0) {
        $lines.Add('**Passed.** Employee and guest identifiers are unique, every group membership references an existing employee, and every guest inviter exists. Required columns were present and all dates and booleans parsed strictly.')
    }
    else {
        $lines.Add('**Incomplete review.** Correct every issue below and rerun the tool. For deterministic best-effort output, only the first row for a duplicated ID was analyzed, orphaned memberships were not attached to an employee, and guests with a missing inviter were routed to IT & Security.')
        $lines.Add('')
        $lines.Add('| Check | Source | Reference | Problem | Required action |')
        $lines.Add('|---|---|---|---|---|')
        foreach ($issue in $dataQualityIssues) {
            $lines.Add("| $(ConvertTo-MarkdownCell $issue.Code) | $(ConvertTo-MarkdownCell $issue.Source) | $(ConvertTo-MarkdownCell $issue.SubjectId) | $(ConvertTo-MarkdownCell $issue.Evidence) | $(ConvertTo-MarkdownCell $issue.RecommendedAction) |")
        }
    }
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('Generated deterministically by the read-only WorkFlex access-review tool.')

    if ($PSCmdlet.ShouldProcess($OutputPath, 'Write access-review report')) {
        $outputDirectory = Split-Path -Parent $OutputPath
        if ($outputDirectory) {
            $null = New-Item -ItemType Directory -Path $outputDirectory -Force
        }
        Set-Content -LiteralPath $OutputPath -Value $lines -Encoding utf8
    }
}

function New-TeamsMessageDraft {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [object[]] $Findings,
        [Parameter(Mandatory)] [datetime] $AsOfDate,
        [Parameter(Mandatory)] [string] $OutputPath
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Draft Microsoft Teams Messages')
    $lines.Add('')
    $lines.Add("**Review date:** $($AsOfDate.ToString('yyyy-MM-dd'))")
    $lines.Add('')
    $lines.Add('These are human-reviewed drafts only. The tool does not send messages or change access.')

    $index = 0
    foreach ($finding in @($Findings)) {
        $index++
        $recipient = if ($finding.ResponsibleEmail) {
            "$($finding.ResponsibleName) <$($finding.ResponsibleEmail)>"
        }
        else {
            $finding.ResponsibleName
        }

        $greeting = if ($finding.ResponsibleName -eq 'IT & Security') {
            'Hi IT & Security team'
        }
        else {
            "Hi $($finding.ResponsibleName)"
        }
        $responseRequest = if ($finding.Type -eq 'DataQualityIssue') {
            'Please reply with **corrected** or **investigating**, plus the corrected export or a ticket reference. Access decisions from this run must wait for a clean rerun.'
        }
        else {
            'Please reply with **keep**, **remove**, or **investigating**, plus a ticket or approval reference where applicable. No access will be changed automatically.'
        }

        $lines.Add('')
        $lines.Add("## $index. $(Get-FindingTypeTitle $finding.Type) - $($finding.SubjectName)")
        $lines.Add('')
        $lines.Add("**To:** $recipient")
        $lines.Add('')
        $lines.Add("**Severity:** $($finding.Severity)")
        $lines.Add('')
        $lines.Add('> ' + $greeting + ',')
        $lines.Add('>')
        $lines.Add("> Our monthly access review found that **$($finding.SubjectName)** ($($finding.SubjectId)) needs attention: $($finding.Summary.ToLowerInvariant()).")
        $lines.Add('>')
        $lines.Add("> Evidence: $($finding.Evidence).")
        $lines.Add('>')
        $lines.Add("> Requested action: $($finding.RecommendedAction) Target: $($finding.Due.ToLowerInvariant()).")
        $lines.Add('>')
        $lines.Add("> $responseRequest")
        $lines.Add('>')
        $lines.Add('> Thank you.')
    }

    if ($PSCmdlet.ShouldProcess($OutputPath, 'Write Teams-message drafts')) {
        $outputDirectory = Split-Path -Parent $OutputPath
        if ($outputDirectory) {
            $null = New-Item -ItemType Directory -Path $outputDirectory -Force
        }
        Set-Content -LiteralPath $OutputPath -Value $lines -Encoding utf8
    }
}

function Invoke-AccessReview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $UsersPath,
        [Parameter(Mandatory)] [string] $GroupMembershipsPath,
        [Parameter(Mandatory)] [string] $GuestsPath,
        [Parameter(Mandatory)] [datetime] $AsOfDate,
        [Parameter(Mandatory)] [string] $OutputDirectory
    )

    $data = Import-AccessReviewData -UsersPath $UsersPath -GroupMembershipsPath $GroupMembershipsPath -GuestsPath $GuestsPath
    $findings = @(Get-AccessReviewFinding -Data $data -AsOfDate $AsOfDate)
    $dateSuffix = $AsOfDate.ToString('yyyy-MM-dd')
    $reportPath = Join-Path $OutputDirectory "access-review-$dateSuffix.md"
    $messagesPath = Join-Path $OutputDirectory "teams-messages-$dateSuffix.md"

    New-AccessReviewReport -Findings $findings -Data $data -AsOfDate $AsOfDate -OutputPath $reportPath
    New-TeamsMessageDraft -Findings $findings -AsOfDate $AsOfDate -OutputPath $messagesPath

    return [pscustomobject]@{
        ReviewDate = $dateSuffix
        FindingCount = $findings.Count
        CriticalCount = @($findings | Where-Object Severity -eq 'Critical').Count
        HighCount = @($findings | Where-Object Severity -eq 'High').Count
        MediumCount = @($findings | Where-Object Severity -eq 'Medium').Count
        LowCount = @($findings | Where-Object Severity -eq 'Low').Count
        DataQualityIssueCount = $data.DataQualityIssues.Count
        ReviewStatus = if ($data.DataQualityIssues.Count -eq 0) { 'Complete' } else { 'Incomplete' }
        ReportPath = (Resolve-Path -LiteralPath $reportPath).Path
        TeamsMessagesPath = (Resolve-Path -LiteralPath $messagesPath).Path
    }
}

Export-ModuleMember -Function @(
    'Import-AccessReviewData',
    'Get-AccessReviewFinding',
    'New-AccessReviewReport',
    'New-TeamsMessageDraft',
    'Invoke-AccessReview'
)
