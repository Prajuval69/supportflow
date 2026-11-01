# Dot-source from any directory: . U:\projects\supportflow\scripts\env.ps1
$SupportflowRoot = Split-Path $PSScriptRoot -Parent
$SupportflowRuby = Join-Path $SupportflowRoot '.local\rubyinstaller-3.3.10-1-x64\bin'
if (Test-Path $SupportflowRuby) {
  $env:Path = "$SupportflowRuby;" + $env:Path
  $env:RI_DEVKIT = Join-Path $SupportflowRoot '.local\msys64'
}
if (Test-Path (Join-Path $SupportflowRoot '.local\pgdata')) {
  $env:PGHOST = '127.0.0.1'
  $env:PGPORT = '55432'
  $env:PGUSER = 'supportflow'
  $env:REDIS_URL = 'redis://127.0.0.1:56379/0'
}
