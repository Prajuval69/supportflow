$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
$SupportflowRunningVite = Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" | Where-Object { $_.CommandLine -like "*$SupportflowRoot\frontend\node_modules*\vite*" }
if ($SupportflowRunningVite) { throw 'Stop the SupportFlow Vite terminal before setup; Windows locks the running esbuild binary during npm ci.' }
& "$PSScriptRoot\services.ps1" -Action Start
$SupportflowPgBin = if ($env:PGBIN) { $env:PGBIN } else { 'C:\Program Files\PostgreSQL\18\bin' }
& "$SupportflowPgBin\psql.exe" -h 127.0.0.1 -p 55432 -U supportflow -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'supportflow_development'" | Set-Variable SupportflowDevelopmentExists
if ($LASTEXITCODE -ne 0) { throw 'Cannot query local PostgreSQL cluster' }
if (!$SupportflowDevelopmentExists) {
  & "$SupportflowPgBin\createdb.exe" -h 127.0.0.1 -p 55432 -U supportflow supportflow_development
  if ($LASTEXITCODE -ne 0) { throw 'Cannot create development database' }
}
& "$SupportflowPgBin\psql.exe" -h 127.0.0.1 -p 55432 -U supportflow -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'supportflow_test'" | Set-Variable SupportflowTestExists
if ($LASTEXITCODE -ne 0) { throw 'Cannot query local PostgreSQL cluster' }
if (!$SupportflowTestExists) {
  & "$SupportflowPgBin\createdb.exe" -h 127.0.0.1 -p 55432 -U supportflow supportflow_test
  if ($LASTEXITCODE -ne 0) { throw 'Cannot create test database' }
}
Push-Location "$SupportflowRoot\backend"
try {
  & bundle install
  if ($LASTEXITCODE -ne 0) { throw 'bundle install failed' }
  & ruby bin\rails db:prepare
  if ($LASTEXITCODE -ne 0) { throw 'Migrations failed' }
  & ruby bin\rails db:seed
  if ($LASTEXITCODE -ne 0) { throw 'Demo seeds failed' }
} finally { Pop-Location }
Push-Location "$SupportflowRoot\frontend"
try {
  & npm.cmd ci
  if ($LASTEXITCODE -ne 0) { throw 'npm ci failed' }
  & npx.cmd playwright install chromium
  if ($LASTEXITCODE -ne 0) { throw 'Chromium installation failed' }
} finally { Pop-Location }
Write-Output 'Setup complete. Use the README to start Rails, Sidekiq and Vite in separate terminals.'
