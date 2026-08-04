[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Pester fixtures declared in BeforeAll are consumed by It blocks.'
)]
param()

BeforeAll {
    $repositoryRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $repositoryRoot 'src/AccessReview.psm1') -Force

    $dataPaths = @{
        UsersPath = Join-Path $repositoryRoot 'data/users.csv'
        GroupMembershipsPath = Join-Path $repositoryRoot 'data/group_memberships.csv'
        GuestsPath = Join-Path $repositoryRoot 'data/guests.csv'
    }
    $reviewDate = [datetime] '2026-08-15'
    $reviewData = Import-AccessReviewData @dataPaths
    $reviewFindings = @(Get-AccessReviewFinding -Data $reviewData -AsOfDate $reviewDate)

    function ConvertTo-TestReviewData {
        param(
            [Parameter(Mandatory)] [datetime] $LastSignInUtc,
            [datetime] $GuestExpiryUtc = [datetime] '2027-01-01'
        )

        $user = [pscustomobject]@{
            UserId = 'U001'
            DisplayName = 'Test Admin'
            Email = 'admin@helioworks.example'
            Department = 'IT'
            AdminRoles = [string[]] @('Global Administrator')
            AccountEnabled = $true
            LastSignInUtc = $LastSignInUtc
            CreatedUtc = [datetime] '2025-01-01'
        }
        $guest = [pscustomobject]@{
            GuestId = 'G001'
            DisplayName = 'Test Guest'
            Email = 'guest@example.net'
            Company = 'Example'
            InvitedByUserId = 'U001'
            AccountEnabled = $true
            AccessExpiresUtc = $GuestExpiryUtc
            LastSignInUtc = [datetime] '2026-08-01'
        }

        return [pscustomobject]@{
            Users = @($user)
            Memberships = @()
            Guests = @($guest)
            UserById = @{ U001 = $user }
            GroupsByUser = @{}
            DataQualityIssues = @()
            SourceCounts = [pscustomobject]@{
                Users = 1
                Memberships = 0
                Guests = 1
            }
        }
    }
}

Describe 'Import-AccessReviewData' {
    It 'loads and validates the supplied dataset' {
        $reviewData.Users.Count | Should -Be 73
        $reviewData.Memberships.Count | Should -Be 192
        $reviewData.Guests.Count | Should -Be 12
        $reviewData.DataQualityIssues.Count | Should -Be 0
    }

    It 'rejects an invalid boolean with an actionable error' {
        $users = Join-Path $TestDrive 'users.csv'
        $memberships = Join-Path $TestDrive 'group_memberships.csv'
        $guests = Join-Path $TestDrive 'guests.csv'
        Copy-Item $dataPaths.UsersPath $users
        Copy-Item $dataPaths.GroupMembershipsPath $memberships
        Copy-Item $dataPaths.GuestsPath $guests
        (Get-Content $users -Raw).Replace(',True,', ',maybe,') | Set-Content $users

        { Import-AccessReviewData -UsersPath $users -GroupMembershipsPath $memberships -GuestsPath $guests } |
            Should -Throw '*Invalid boolean*Expected True or False*'
    }

    It 'reports duplicate employee and guest identifiers' {
        $caseDirectory = Join-Path $TestDrive 'duplicates'
        $null = New-Item -ItemType Directory -Path $caseDirectory
        $users = Join-Path $caseDirectory 'users.csv'
        $memberships = Join-Path $caseDirectory 'group_memberships.csv'
        $guests = Join-Path $caseDirectory 'guests.csv'
        Copy-Item $dataPaths.UsersPath $users
        Copy-Item $dataPaths.GroupMembershipsPath $memberships
        Copy-Item $dataPaths.GuestsPath $guests
        Get-Content $users | Select-Object -Skip 1 -First 1 | Add-Content $users
        Get-Content $guests | Select-Object -Skip 1 -First 1 | Add-Content $guests

        $data = Import-AccessReviewData -UsersPath $users -GroupMembershipsPath $memberships -GuestsPath $guests
        $result = Invoke-AccessReview -UsersPath $users -GroupMembershipsPath $memberships -GuestsPath $guests -AsOfDate $reviewDate -OutputDirectory $caseDirectory

        $data.SourceCounts.Users | Should -Be 74
        $data.SourceCounts.Guests | Should -Be 13
        $data.Users.Count | Should -Be 73
        $data.Guests.Count | Should -Be 12
        @($data.DataQualityIssues.Code) | Should -Be @('DuplicateUserId', 'DuplicateGuestId')
        $result.ReviewStatus | Should -Be 'Incomplete'
        (Get-Content $result.ReportPath -Raw) | Should -Match 'DuplicateUserId.*U001'
        (Get-Content $result.ReportPath -Raw) | Should -Match 'DuplicateGuestId.*G01'
    }

    It 'reports memberships that reference an unknown employee' {
        $caseDirectory = Join-Path $TestDrive 'orphan-membership'
        $null = New-Item -ItemType Directory -Path $caseDirectory
        $users = Join-Path $caseDirectory 'users.csv'
        $memberships = Join-Path $caseDirectory 'group_memberships.csv'
        $guests = Join-Path $caseDirectory 'guests.csv'
        Copy-Item $dataPaths.UsersPath $users
        Copy-Item $dataPaths.GroupMembershipsPath $memberships
        Copy-Item $dataPaths.GuestsPath $guests
        Add-Content $memberships 'UNKNOWN,Test-Group,m365,2026-01-01'

        $result = Invoke-AccessReview -UsersPath $users -GroupMembershipsPath $memberships -GuestsPath $guests -AsOfDate $reviewDate -OutputDirectory $caseDirectory
        $report = Get-Content $result.ReportPath -Raw

        $result.DataQualityIssueCount | Should -Be 1
        $result.ReviewStatus | Should -Be 'Incomplete'
        $report | Should -Match 'OrphanMembership.*UNKNOWN'
        $report | Should -Match 'Correct or remove the orphaned membership rows'
        (Get-Content $result.TeamsMessagesPath -Raw) | Should -Match 'corrected.*clean rerun'
    }

    It 'reports a guest inviter that does not exist and routes ownership safely' {
        $caseDirectory = Join-Path $TestDrive 'missing-inviter'
        $null = New-Item -ItemType Directory -Path $caseDirectory
        $users = Join-Path $caseDirectory 'users.csv'
        $memberships = Join-Path $caseDirectory 'group_memberships.csv'
        $guests = Join-Path $caseDirectory 'guests.csv'
        Copy-Item $dataPaths.UsersPath $users
        Copy-Item $dataPaths.GroupMembershipsPath $memberships
        Copy-Item $dataPaths.GuestsPath $guests
        (Get-Content $guests -Raw).Replace(',U038,True,2026-10-14,', ',UNKNOWN,True,2026-10-14,') | Set-Content $guests

        $data = Import-AccessReviewData -UsersPath $users -GroupMembershipsPath $memberships -GuestsPath $guests
        $findings = @(Get-AccessReviewFinding -Data $data -AsOfDate $reviewDate)
        $result = Invoke-AccessReview -UsersPath $users -GroupMembershipsPath $memberships -GuestsPath $guests -AsOfDate $reviewDate -OutputDirectory $caseDirectory

        @($data.DataQualityIssues.Code) | Should -Be @('MissingGuestInviter')
        $qualityFinding = @($findings | Where-Object Type -eq 'DataQualityIssue')
        $qualityFinding.SubjectId | Should -Be 'G12'
        $qualityFinding.ResponsibleName | Should -Be 'IT & Security'
        (Get-Content $result.ReportPath -Raw) | Should -Match 'MissingGuestInviter.*G12'
    }
}

Describe 'Get-AccessReviewFinding' {
    It 'returns the expected finding totals for the supplied data' {
        $reviewFindings.Count | Should -Be 16
        @($reviewFindings | Where-Object Severity -eq 'Critical').Count | Should -Be 1
        @($reviewFindings | Where-Object Severity -eq 'High').Count | Should -Be 6
        @($reviewFindings | Where-Object Severity -eq 'Medium').Count | Should -Be 7
        @($reviewFindings | Where-Object Severity -eq 'Low').Count | Should -Be 2
    }

    It 'identifies every mandatory privileged-account anomaly' {
        $stalePrivileged = @(
            $reviewFindings |
                Where-Object Type -eq 'StalePrivilegedAccount' |
                Select-Object -ExpandProperty SubjectId
        )
        $stalePrivileged | Should -Be @('U065', 'U066', 'U067', 'U068')

        $disabledPrivileged = @(
            $reviewFindings |
                Where-Object Type -eq 'DisabledPrivilegedAccount' |
                Select-Object -ExpandProperty SubjectId
        )
        $disabledPrivileged | Should -Be @('U065')
    }

    It 'identifies expired and near-expiry guests at the 14-day boundary' {
        @($reviewFindings | Where-Object Type -eq 'ExpiredGuest').SubjectId | Should -Be @('G05')
        @($reviewFindings | Where-Object Type -eq 'GuestNearExpiry').SubjectId | Should -Be @('G07', 'G09')

        $atBoundary = ConvertTo-TestReviewData -LastSignInUtc ([datetime] '2026-08-15') -GuestExpiryUtc ([datetime] '2026-08-29')
        $afterBoundary = ConvertTo-TestReviewData -LastSignInUtc ([datetime] '2026-08-15') -GuestExpiryUtc ([datetime] '2026-08-30')
        @(Get-AccessReviewFinding -Data $atBoundary -AsOfDate $reviewDate | Where-Object Type -eq 'GuestNearExpiry').Count | Should -Be 1
        @(Get-AccessReviewFinding -Data $afterBoundary -AsOfDate $reviewDate | Where-Object Type -eq 'GuestNearExpiry').Count | Should -Be 0
    }

    It 'uses a strict greater-than comparison for the 30-day stale threshold' {
        $atBoundary = ConvertTo-TestReviewData -LastSignInUtc ([datetime] '2026-07-16')
        $pastBoundary = ConvertTo-TestReviewData -LastSignInUtc ([datetime] '2026-07-15')

        @(Get-AccessReviewFinding -Data $atBoundary -AsOfDate $reviewDate | Where-Object Type -eq 'StalePrivilegedAccount').Count | Should -Be 0
        @(Get-AccessReviewFinding -Data $pastBoundary -AsOfDate $reviewDate | Where-Object Type -eq 'StalePrivilegedAccount').Count | Should -Be 1
    }

    It 'surfaces the additional identity hygiene checks' {
        @($reviewFindings | Where-Object Type -eq 'ExternalPrivilegedEmail').SubjectId | Should -Be @('U070')
        @($reviewFindings | Where-Object Type -eq 'StaleStandardAccount').SubjectId | Should -Be @('U059', 'U060', 'U061', 'U062')
        @($reviewFindings | Where-Object Type -eq 'StaleGuest').SubjectId | Should -Be @('G11')
        @($reviewFindings | Where-Object Type -eq 'DisabledResidualMembership').SubjectId | Should -Be @('U063', 'U064')
    }
}

Describe 'Invoke-AccessReview' {
    It 'writes both required report artifacts with accountable actions' {
        $result = Invoke-AccessReview @dataPaths -AsOfDate $reviewDate -OutputDirectory $TestDrive

        $result.FindingCount | Should -Be 16
        $result.ReviewStatus | Should -Be 'Complete'
        $result.DataQualityIssueCount | Should -Be 0
        $result.ReportPath | Should -Exist
        $result.TeamsMessagesPath | Should -Exist

        $report = Get-Content $result.ReportPath -Raw
        $messages = Get-Content $result.TeamsMessagesPath -Raw
        $report | Should -Match 'Priya Nair'
        $report | Should -Match 'disabled privileged account'
        $report | Should -Match 'Diego Fuentes'
        $report | Should -Match 'Review status:\*\* Complete - input integrity checks passed'
        $report | Should -Match 'Employee and guest identifiers are unique'
        $messages | Should -Match 'No access will be changed automatically'
        $messages | Should -Match 'Julia Berg'
    }
}

Describe 'Reviewer-facing CLI' {
    It 'returns exit code 2 after writing an incomplete review' {
        $caseDirectory = Join-Path $TestDrive 'cli-data-quality'
        $outputDirectory = Join-Path $caseDirectory 'output'
        $null = New-Item -ItemType Directory -Path $caseDirectory
        Copy-Item $dataPaths.UsersPath (Join-Path $caseDirectory 'users.csv')
        Copy-Item $dataPaths.GroupMembershipsPath (Join-Path $caseDirectory 'group_memberships.csv')
        Copy-Item $dataPaths.GuestsPath (Join-Path $caseDirectory 'guests.csv')
        Add-Content (Join-Path $caseDirectory 'group_memberships.csv') 'UNKNOWN,Test-Group,m365,2026-01-01'

        & pwsh -NoProfile -File (Join-Path $repositoryRoot 'scripts/Invoke-AccessReview.ps1') `
            -InputDirectory $caseDirectory -OutputDirectory $outputDirectory 2>&1 | Out-Null

        $LASTEXITCODE | Should -Be 2
        (Join-Path $outputDirectory 'access-review-2026-08-15.md') | Should -Exist
        $report = Get-Content (Join-Path $outputDirectory 'access-review-2026-08-15.md') -Raw
        $report | Should -Match 'Review status:\*\* Incomplete'
        $report | Should -Match 'OrphanMembership'
    }
}
