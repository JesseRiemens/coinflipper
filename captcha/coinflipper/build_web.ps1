Param(
  [string]$BaseHref = '/captcha/coinflipper/output/'
)

Write-Host '== Flutter Web Build (PowerShell) =='
$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error 'flutter command not found in PATH.'
  exit 1
}

Write-Host "Building with base href: $BaseHref"
flutter build web --release --base-href $BaseHref --no-web-resources-cdn --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) {
  Write-Error "Flutter build failed with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}

# Ensure output directory exists and mirror build
if (-not (Test-Path './output')) { New-Item -ItemType Directory -Path './output' | Out-Null }

Write-Host 'Mirroring build/web to output via robocopy'
robocopy .\build\web .\output /MIR /NFL /NDL /NJH /NJS /NP
$rc = $LASTEXITCODE
# Robocopy exit codes: 0=No copy,1=Copied, others may still be OK (<8)
if ($rc -ge 8) {
  Write-Warning "Robocopy reported issues (exit code $rc)"
  exit $rc
}

Write-Host 'Build assets copied to output'
Write-Host 'Done.'
