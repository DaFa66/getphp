# VC++ Redistributable Registry Diagnostic
# Run this on the spare laptop to see what's detected

Write-Host "=== Scanning Uninstall registry for VC++ Redistributable (x64) ===" -ForegroundColor Cyan
Write-Host ""

$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$found = @()

foreach ($path in $paths) {
    $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match "Microsoft Visual C\+\+ .*Redistributable.*x64" }
    
    foreach ($item in $items) {
        $ver = $null
        $parseOk = $false
        if ($item.DisplayVersion) {
            try {
                $ver = [version]$item.DisplayVersion
                $parseOk = $true
            } catch {
                $ver = "PARSE FAILED: $($item.DisplayVersion)"
            }
        }
        $found += [PSCustomObject]@{
            DisplayName    = $item.DisplayName
            DisplayVersion = $item.DisplayVersion
            ParsedVersion  = $ver
            ParseOk        = $parseOk
            MinVersion     = [version]"14.51.36231"
            MeetsMin       = if ($parseOk) { ($ver -ge [version]"14.51.36231") } else { $false }
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host "NO matching entries found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Dumping ALL entries with 'Redist' in name:" -ForegroundColor Yellow
    foreach ($path in $paths) {
        $all = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match "Redist" }
        foreach ($item in $all) {
            Write-Host "  $($item.DisplayName)  [version: $($item.DisplayVersion)]"
        }
    }
} else {
    $found | Format-Table -AutoSize
    Write-Host ""

    $minVer = [version]"14.51.36231"
    foreach ($f in $found) {
        if ($f.ParseOk) {
            if ($f.ParsedVersion -ge $minVer) {
                Write-Host "RESULT: Meets minimum — Test-VcRedistInstalled returns `$true" -ForegroundColor Green
            } else {
                Write-Host "RESULT: Below minimum ($($f.ParsedVersion) < $minVer) — Test-VcRedistInstalled should return `$false" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ""
Write-Host "=== Also checking Runtimes key ===" -ForegroundColor Cyan
$runtimeKey = 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
if (Test-Path $runtimeKey) {
    $rt = Get-ItemProperty $runtimeKey
    Write-Host "Key exists: Installed=$($rt.Installed), Version=$($rt.Version)"
} else {
    Write-Host "Key does NOT exist (standalone redist doesn't create this key)"
}

Write-Host ""
Read-Host "Press Enter to close"
