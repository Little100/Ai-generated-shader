$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    node scripts/check.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Shader structure check failed.' }
    New-Item -ItemType Directory -Force dist | Out-Null
    $archive = Join-Path $root 'dist/Loomlight-1.0.0-Iris-1.21.11.zip'
    Compress-Archive -Path (Join-Path $root 'shaders') -DestinationPath $archive -Force
    Write-Output "Created $archive"
} finally {
    Pop-Location
}
