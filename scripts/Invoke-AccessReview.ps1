[CmdletBinding()]
param(
    [string] $InputDirectory,
    [string] $OutputDirectory,

    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string] $AsOfDate = '2026-08-15'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($InputDirectory)) {
    $InputDirectory = Join-Path $repositoryRoot 'data'
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRoot 'output'
}

$reviewDate = [datetime]::ParseExact(
    $AsOfDate,
    'yyyy-MM-dd',
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Globalization.DateTimeStyles]::None
)

Import-Module (Join-Path $repositoryRoot 'src/AccessReview.psm1') -Force

$result = Invoke-AccessReview `
    -UsersPath (Join-Path $InputDirectory 'users.csv') `
    -GroupMembershipsPath (Join-Path $InputDirectory 'group_memberships.csv') `
    -GuestsPath (Join-Path $InputDirectory 'guests.csv') `
    -AsOfDate $reviewDate `
    -OutputDirectory $OutputDirectory

Write-Output "Access review complete for $($result.ReviewDate)."
Write-Output "Findings: $($result.FindingCount) ($($result.CriticalCount) critical, $($result.HighCount) high, $($result.MediumCount) medium, $($result.LowCount) low)."
Write-Output "Report: $($result.ReportPath)"
Write-Output "Teams drafts: $($result.TeamsMessagesPath)"
