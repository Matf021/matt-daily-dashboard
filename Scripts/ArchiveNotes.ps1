param(
    [Parameter(Mandatory=$true)]
    [string]$TodayFile,

    [Parameter(Mandatory=$true)]
    [string]$DateFile,

    [switch]$Force
)

$documents = [Environment]::GetFolderPath("MyDocuments")
$archiveFolder = Join-Path $documents "Daily Notes"
$archiveFile = Join-Path $archiveFolder "Daily Notes.md"

if (-not (Test-Path $archiveFolder)) {
    New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
}

if (-not (Test-Path $archiveFile)) {
    Set-Content -Path $archiveFile -Value "# Daily Notes`r`n"
}

$today = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $DateFile)) {
    Set-Content -Path $DateFile -Value $today
    exit
}

$storedDate = (Get-Content $DateFile -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($storedDate)) {
    Set-Content -Path $DateFile -Value $today
    exit
}

if (($storedDate -eq $today) -and (-not $Force)) {
    exit
}

# Read notes from the previously stored date
$notes = ""

if (Test-Path $TodayFile) {
    $notes = (Get-Content $TodayFile -Raw).Trim()
}

# Archive only if there was actually something written
if (-not [string]::IsNullOrWhiteSpace($notes)) {

    try {
        $dateObject = [DateTime]::ParseExact(
            $storedDate,
            "yyyy-MM-dd",
            [Globalization.CultureInfo]::InvariantCulture
        )

        $formattedDate = $dateObject.ToString(
            "MMMM d, yyyy",
            [Globalization.CultureInfo]::InvariantCulture
        )
    }
    catch {
        $formattedDate = $storedDate
    }

    Add-Content -Path $archiveFile -Value ""
    Add-Content -Path $archiveFile -Value "## $formattedDate"
    Add-Content -Path $archiveFile -Value ""
    Add-Content -Path $archiveFile -Value $notes
    Add-Content -Path $archiveFile -Value ""
}

# Clear the live note file
Set-Content -Path $TodayFile -Value ""

# Mark the new day
Set-Content -Path $DateFile -Value $today