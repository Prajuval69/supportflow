$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
$SupportflowPreviousEnvironment = $env:RAILS_ENV
Push-Location "$SupportflowRoot\backend"
try {
  & ruby bin\rails db:prepare
  if ($LASTEXITCODE -ne 0) { throw 'Development database preparation failed' }
  $env:RAILS_ENV = 'test'
  & ruby bin\rails db:prepare
  if ($LASTEXITCODE -ne 0) { throw 'Test database preparation failed' }
  & bundle exec rspec
  if ($LASTEXITCODE -ne 0) { throw 'RSpec failed' }
  & ruby bin\rails zeitwerk:check
  if ($LASTEXITCODE -ne 0) { throw 'Rails autoload check failed' }
} finally {
  $env:RAILS_ENV = $SupportflowPreviousEnvironment
  Pop-Location
}
Push-Location "$SupportflowRoot\frontend"
try {
  & npm.cmd run typecheck
  if ($LASTEXITCODE -ne 0) { throw 'Typecheck failed' }
  & npm.cmd run build
  if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed' }
  & npm.cmd test
  if ($LASTEXITCODE -ne 0) { throw 'Frontend tests failed' }
  & npm.cmd run format:check
  if ($LASTEXITCODE -ne 0) { throw 'Frontend formatting check failed' }
} finally { Pop-Location }
Write-Output 'Local checks passed. Start Rails, Vite and Sidekiq before running npm.cmd run e2e.'
