param(
    [Parameter(Mandatory=$true)]
    [string]$Task,

    [Parameter(Mandatory=$true)]
    [string]$TasksFile,

    [string]$Type = "normal",

    [int]$WeeklyGoal = 0,

    [int]$MonthlyGoal = 0
)

if ([string]::IsNullOrWhiteSpace($Task)) {
    exit
}

if (-not (Test-Path $TasksFile)) {
    New-Item -ItemType File -Path $TasksFile -Force | Out-Null
}

$cleanTask =
    ($Task -replace "`r", " " -replace "`n", " ").Trim()

# Validate type
if ($Type -ne "normal" -and $Type -ne "repeat") {
    $Type = "normal"
}

# Normal tasks don't have goals
if ($Type -eq "normal") {
    $WeeklyGoal = 0
    $MonthlyGoal = 0
}

# Prevent negative targets
$WeeklyGoal = [Math]::Max(0, $WeeklyGoal)
$MonthlyGoal = [Math]::Max(0, $MonthlyGoal)


# ------------------------------------------
# FIND NEXT UNIQUE ID
# ------------------------------------------

$highestId = 0

$existingTasks = @(Get-Content $TasksFile)

foreach ($line in $existingTasks) {

    if ($line -match '^[01]\|(?:normal|repeat)\|(\d+)\|\d+\|\d+\|') {

        $id = [int]$Matches[1]

        if ($id -gt $highestId) {
            $highestId = $id
        }
    }
}

$newId = $highestId + 1


# ------------------------------------------
# SAVE TASK
# ------------------------------------------

Add-Content `
    -Path $TasksFile `
    -Value "0|$Type|$newId|$WeeklyGoal|$MonthlyGoal|$cleanTask"