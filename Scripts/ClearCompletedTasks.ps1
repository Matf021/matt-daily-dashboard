param(
    [Parameter(Mandatory=$true)]
    [string]$TasksFile
)

if (-not (Test-Path $TasksFile)) {
    exit
}

$tasks = @(Get-Content $TasksFile)

$remaining = @(
    $tasks | Where-Object {
        $_ -notmatch '^1\|'
    }
)

if ($remaining.Count -eq 0) {
    Set-Content -Path $TasksFile -Value ""
}
else {
    Set-Content -Path $TasksFile -Value $remaining
}