param(
    [Parameter(Mandatory=$true)]
    [string]$Note,

    [Parameter(Mandatory=$true)]
    [string]$TodayFile
)

if ([string]::IsNullOrWhiteSpace($Note)) {
    exit
}

if (-not (Test-Path $TodayFile)) {
    New-Item -ItemType File -Path $TodayFile -Force | Out-Null
}

$cleanNote =
    $Note.Trim()

$currentContent =
    Get-Content $TodayFile -Raw

$time =
    Get-Date -Format "HH:mm"

if (-not [string]::IsNullOrWhiteSpace($currentContent)) {
    Add-Content -Path $TodayFile -Value ""
}

Add-Content -Path $TodayFile -Value $time
Add-Content -Path $TodayFile -Value $cleanNote