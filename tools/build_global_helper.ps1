param(
    [string]$Runtime = "win-x64",
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$projectFile = Join-Path $repoRoot "tools/global_key_helper/GlobalKeyHelper.csproj"
$publishDir = Join-Path $repoRoot "tools/global_key_helper/publish/$Runtime"
$helperExe = Join-Path $publishDir "global_key_helper.exe"
$resourcesDir = Join-Path $repoRoot "resources"
$helperInResources = Join-Path $resourcesDir "global_key_helper.exe"
$embeddedBinOut = Join-Path $repoRoot "resources/global_key_helper.win64.bin"
$embeddedOut = Join-Path $repoRoot "resources/global_key_helper.win64.b64"

Write-Host "Publishing global key helper ($Runtime)..."
dotnet publish $projectFile `
    -c $Configuration `
    -r $Runtime `
    --self-contained true `
    /p:PublishSingleFile=true `
    /p:PublishTrimmed=false `
    /p:DebugType=None `
    -o $publishDir

if (-not (Test-Path $helperExe)) {
    throw "Expected helper executable not found: $helperExe"
}

Write-Host "Copying helper exe to resources folder for export..."
Copy-Item -Path $helperExe -Destination $helperInResources -Force
Write-Host "Copied to: $helperInResources"

Write-Host "Embedding helper as binary resource..."
$bytes = [System.IO.File]::ReadAllBytes($helperExe)
[System.IO.File]::WriteAllBytes($embeddedBinOut, $bytes)

Write-Host "Embedding as base64 fallback..."
$base64 = [Convert]::ToBase64String($bytes)
[System.IO.File]::WriteAllText($embeddedOut, $base64, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Build Complete!"
Write-Host "  Helper exe copied to: $helperInResources"
Write-Host "  Binary backup:        $embeddedBinOut"
Write-Host "  Base64 backup:        $embeddedOut"
Write-Host "  File size: $(($bytes | Measure-Object -Sum).Sum / 1024 / 1024) MB"
Write-Host "You can now export Godot and distribute a single executable."
