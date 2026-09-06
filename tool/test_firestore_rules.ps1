$ErrorActionPreference = 'Stop'

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
  $androidStudioJava = 'C:\Program Files\Android\Android Studio\jbr'
  if (-not (Test-Path -LiteralPath "$androidStudioJava\bin\java.exe")) {
    throw 'Java is required to run the Firestore emulator rules tests.'
  }
  $env:JAVA_HOME = $androidStudioJava
  $env:Path = "$androidStudioJava\bin;$env:Path"
}

Push-Location (Join-Path $PSScriptRoot '..\firestore-rules-tests')
try {
  npm test
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}
