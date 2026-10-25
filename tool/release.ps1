param(
    [ValidateSet('patch', 'minor', 'major')]
    [string]$Part = 'patch'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

python tool/bump_version.py --part $Part
if ($LASTEXITCODE -ne 0) { throw 'Version bump failed.' }

$content = Get-Content 'pubspec.yaml' -Raw
if ($content -notmatch 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    throw 'Could not read the new version.'
}
$version = $Matches[1]

flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'Flutter release build failed.' }

$apk = 'build/app/outputs/flutter-apk/app-release.apk'
$desktop = [Environment]::GetFolderPath('Desktop')
$downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

foreach ($folder in @($desktop, $downloads)) {
    $target = Join-Path $folder "nada-$version.apk"
    Copy-Item $apk $target -Force
    $hash = (Get-FileHash $target -Algorithm SHA256).Hash
    Set-Content -Path "$target.sha256" -Value "$hash  nada-$version.apk"
    Write-Host "APK: $target"
    Write-Host "SHA256: $hash"
}

Write-Host "nada! $version listo."
