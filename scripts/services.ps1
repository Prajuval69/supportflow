param([ValidateSet('Start', 'Stop')][string]$Action = 'Start')
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
$SupportflowLocal = Join-Path $SupportflowRoot '.local'
$SupportflowPgBin = if ($env:PGBIN) { $env:PGBIN } else { 'C:\Program Files\PostgreSQL\18\bin' }
$SupportflowData = Join-Path $SupportflowLocal 'pgdata'
$SupportflowRedisDir = Join-Path $SupportflowLocal 'redis\Redis-7.2.8-Windows-x64-msys2'
$SupportflowRedisExe = Join-Path $SupportflowRedisDir 'redis-server.exe'
$SupportflowRedisCli = Join-Path $SupportflowRedisDir 'redis-cli.exe'
$SupportflowRedisPidFile = Join-Path $SupportflowLocal 'redis.pid'
if (!(Test-Path "$SupportflowPgBin\pg_ctl.exe")) { throw 'PostgreSQL missing. Set PGBIN to the installed PostgreSQL bin directory.' }
if (!(Test-Path $SupportflowRedisExe)) { throw 'Portable Redis missing. See README for the verified Windows archive, or run your own Redis and configure backend/.env.' }
if ($Action -eq 'Start') {
  New-Item -ItemType Directory -Force $SupportflowLocal | Out-Null
  if (!(Test-Path "$SupportflowData\PG_VERSION")) {
    & "$SupportflowPgBin\initdb.exe" -D $SupportflowData -U supportflow -A trust --encoding=UTF8 --locale=C
    if ($LASTEXITCODE -ne 0) { throw 'initdb failed' }
  }
  & "$SupportflowPgBin\pg_ctl.exe" -D $SupportflowData status *> $null
  if ($LASTEXITCODE -ne 0) {
    & "$SupportflowPgBin\pg_ctl.exe" -D $SupportflowData -l "$SupportflowLocal\postgres.log" -o '-p 55432 -h 127.0.0.1' start
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL failed to start' }
  }
  & $SupportflowRedisCli -h 127.0.0.1 -p 56379 ping 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    $SupportflowRedisProcess = Start-Process -FilePath $SupportflowRedisExe -ArgumentList '--bind 127.0.0.1 --port 56379 --save "" --appendonly no' -WorkingDirectory $SupportflowRedisDir -WindowStyle Hidden -PassThru -RedirectStandardOutput "$SupportflowLocal\redis.log" -RedirectStandardError "$SupportflowLocal\redis-error.log"
    $SupportflowRedisProcess.Id | Set-Content $SupportflowRedisPidFile
    Start-Sleep -Milliseconds 500
  }
  & $SupportflowRedisCli -h 127.0.0.1 -p 56379 ping
  if ($LASTEXITCODE -ne 0) { throw 'Redis failed to start' }
  $SupportflowExistingRedis = Get-Process -Name redis-server -ErrorAction SilentlyContinue | Where-Object Path -EQ $SupportflowRedisExe | Select-Object -First 1
  if ($SupportflowExistingRedis) { $SupportflowExistingRedis.Id | Set-Content $SupportflowRedisPidFile }
  Write-Output 'Local PostgreSQL: 127.0.0.1:55432; Redis: 127.0.0.1:56379. Existing system services were not changed.'
} else {
  & "$SupportflowPgBin\pg_ctl.exe" -D $SupportflowData -m fast stop
  if (Test-Path $SupportflowRedisPidFile) {
    $SupportflowOwnedRedisPid = [int](Get-Content $SupportflowRedisPidFile)
    $SupportflowOwnedRedisProcess = Get-Process -Id $SupportflowOwnedRedisPid -ErrorAction SilentlyContinue
    if ($SupportflowOwnedRedisProcess -and $SupportflowOwnedRedisProcess.Path -eq $SupportflowRedisExe) {
      & $SupportflowRedisCli -h 127.0.0.1 -p 56379 shutdown nosave
    }
  }
}
