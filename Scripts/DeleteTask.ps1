param(
    [Parameter(Mandatory=$true)]
    [string]$TasksFile,

    [Parameter(Mandatory=$true)]
    [string]$HistoryFile,

    [Parameter(Mandatory=$true)]
    [int]$TaskId
)

# --------------------------------------------------
# DELETE TASK RECORD
# --------------------------------------------------

if (Test-Path $TasksFile) {

    $remainingTasks = @()

    foreach ($line in @(Get-Content $TasksFile)) {

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = $line -split '\|', 6

        # Expected format:
        # status|type|id|weekly|monthly|text
        if ($parts.Count -ge 3) {

            $lineId = 0

            if ([int]::TryParse($parts[2], [ref]$lineId)) {

                if ($lineId -eq $TaskId) {
                    continue
                }
            }
        }

        $remainingTasks += $line
    }

    if ($remainingTasks.Count -eq 0) {
        Set-Content -Path $TasksFile -Value ""
    }
    else {
        Set-Content -Path $TasksFile -Value $remainingTasks
    }
}


# --------------------------------------------------
# REMOVE COMPLETION HISTORY FOR DELETED TASK
# --------------------------------------------------
# Remove completion events tied to the deleted task
# so history stays consistent with Tasks.txt.

if (Test-Path $HistoryFile) {

    $remainingHistory = @()

    foreach ($line in @(Get-Content $HistoryFile)) {

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = $line -split '\|', 2

        if ($parts.Count -ge 1) {

            $lineId = 0

            if ([int]::TryParse($parts[0], [ref]$lineId)) {

                if ($lineId -eq $TaskId) {
                    continue
                }
            }
        }

        $remainingHistory += $line
    }

    if ($remainingHistory.Count -eq 0) {
        Set-Content -Path $HistoryFile -Value ""
    }
    else {
        Set-Content -Path $HistoryFile -Value $remainingHistory
    }
}
