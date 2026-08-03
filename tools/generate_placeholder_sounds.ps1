$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'generate_placeholder_sounds.py'
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $bundled = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (Test-Path -LiteralPath $bundled) { $python = $bundled }
}
if (-not $python) { throw 'Python 3 is required to regenerate game sounds.' }
& $python $script
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
