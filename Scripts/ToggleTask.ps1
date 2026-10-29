param(
    [Parameter(Mandatory=$true)]
    [string]$TasksFile,

    [Parameter(Mandatory=$true)]
    [int]$TaskId,

    [Parameter(Mandatory=$true)]
    [string]$HistoryFile
)

if (-not (Test-Path $TasksFile)) {
    exit
}

$tasks = @(Get-Content $TasksFile)

for ($i = 0; $i -lt $tasks.Count; $i++) {

    $line = $tasks[$i]

    # Current format:
    # status|type|id|weekly|monthly|text
    if ($line -match '^([01])\|(normal|repeat)\|(\d+)\|(\d+)\|(\d+)\|(.*)$') {

        $status      = $Matches[1]
        $type        = $Matches[2]
        $id          = [int]$Matches[3]
        $weeklyGoal  = [int]$Matches[4]
        $monthlyGoal = [int]$Matches[5]
        $text        = $Matches[6]

        if ($id -ne $TaskId) {
            continue
        }


        # REPEATING TASK
        if ($type -eq "repeat") {

            if (-not (Test-Path $HistoryFile)) {
                New-Item `
                    -ItemType File `
                    -Path $HistoryFile `
                    -Force | Out-Null
            }

            $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

            Add-Content `
                -Path $HistoryFile `
                -Value "$id|$timestamp"

            $tasks[$i] =
                "0|repeat|$id|$weeklyGoal|$monthlyGoal|$text"
        }


        # NORMAL TASK
        else {

            $newStatus =
                if ($status -eq "0") { "1" }
                else { "0" }

            $tasks[$i] =
                "$newStatus|normal|$id|0|0|$text"
        }

        break
    }
}

Set-Content -Path $TasksFile -Value $tasks