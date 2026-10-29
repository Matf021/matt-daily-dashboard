param(
    [Parameter(Mandatory=$true)]
    [string]$TasksFile,

    [Parameter(Mandatory=$true)]
    [int]$TaskId,

    [Parameter(Mandatory=$true)]
    [string]$Task,

    [Parameter(Mandatory=$true)]
    [string]$Type,

    [int]$WeeklyGoal = 0,

    [int]$MonthlyGoal = 0
)

if (-not (Test-Path $TasksFile)) {
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Task)) {
    exit 1
}

$cleanTask =
    ($Task -replace "`r", " " -replace "`n", " ").Trim()

if ($Type -ne "normal" -and $Type -ne "repeat") {
    exit 1
}

$WeeklyGoal = [Math]::Max(0, $WeeklyGoal)
$MonthlyGoal = [Math]::Max(0, $MonthlyGoal)

if ($Type -eq "normal") {
    $WeeklyGoal = 0
    $MonthlyGoal = 0
}

$lines = @(Get-Content $TasksFile)
$updated = @()
$found = $false

foreach ($line in $lines) {

    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    # New format:
    # status|type|id|weekly|monthly|text
    if ($line -match '^([01])\|([^|]+)\|(\d+)\|(\d+)\|(\d+)\|(.*)$') {

        $status = $Matches[1]
        $oldType = $Matches[2]
        $id = [int]$Matches[3]

        if ($id -eq $TaskId) {

            # Repeat tasks are always active.
            # Changing task type also resets completion state.
            if ($Type -eq "repeat" -or $oldType -ne $Type) {
                $status = "0"
            }

            $updated += "$status|$Type|$id|$WeeklyGoal|$MonthlyGoal|$cleanTask"
            $found = $true
            continue
        }

        $updated += $line
        continue
    }
    # Preserve any line we don't recognize.
    $updated += $line
}

if (-not $found) {
    exit 2
}

if ($updated.Count -eq 0) {
    Set-Content -Path $TasksFile -Value ""
}
else {
    Set-Content -Path $TasksFile -Value $updated
}
