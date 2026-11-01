# Verification and acceptance report

**Date:** 2026-11-01 (Asia/Calcutta). **Environment:** Windows, local project services. Source: `U:\projects\supportflow`. No remote deployment or CI run is asserted.

## Executed commands

| Command / working directory | Result | Exit / evidence |
| --- | --- | --- |
| `bundle install` in backend | PASS, locked Rails 7.2.4 and dependencies installed, native extensions built | 0; Gemfile.lock |
| `scripts/setup.ps1` | PASS, dependencies installed from lockfiles, migrations/seeds and Chromium setup | 0; [setup log](evidence/setup.log) |
| `ruby bin\rails db:prepare` for development and test | PASS after explicitly creating local databases | 0; migrations/schema.rb |
| Fresh `supportflow_fresh_check`: `ruby bin\rails db:migrate`, `db:seed` twice | PASS: each seed retained 2 orgs, 11 users, 25 tickets; final 32 comments and 57 events | 0; observed runner counts recorded below |
| `scripts/services.ps1 -Action Start` | PASS, isolated PostgreSQL 55432 and Redis 56379, PONG | 0 |
| `ruby bin\rails server -b 127.0.0.1 -p 3000 -u webrick` | PASS, Rails 7.2.4 / WEBrick 1.9.2 served real HTTP | Running process plus Playwright HTTP workflows |
| `npm.cmd run dev` in frontend | PASS, Vite on 127.0.0.1:5173 with Rails proxy | Running process plus Playwright workflows |
| `bundle exec sidekiq -C config\sidekiq.yml` | PASS, real worker registered cron and consumed Redis jobs | Worker evidence JSON; TTIN/TSTP unsupported messages recorded below |
| `ruby bin\rails runner ..\scripts\verify_worker.rb` | PASS: 2 breach events / 4 notifications, unchanged after 4 duplicate jobs; 1 live worker; cron registered | 0; [worker.json](evidence/worker.json) |
| `scripts/check.ps1` | PASS, including full backend and frontend checks | 0; [raw check log](evidence/local-checks.log) |
| `bundle exec rspec` | PASS: **29 examples, 0 failures** | 0; raw check log |
| `ruby bin\rails zeitwerk:check` | PASS, all autoloads resolve | 0; raw check log |
| `npm run typecheck` | PASS, TypeScript strict mode | 0; raw check log |
| `npm run build` | PASS, production assets generated | 0; raw check log |
| `npm test` | PASS: **9 tests in 3 files** | 0; raw check log |
| `npm run format:check` | PASS, Prettier | 0 |
| `npm audit` | PASS, **0 vulnerabilities** at verification time | 0 |
| `npm run e2e` | PASS: **8 journeys** against Rails/PostgreSQL/Redis/Sidekiq/Vite | 0; [raw browser log](evidence/playwright.log) |

Fresh database runner output:

```json
{"organizations":2,"users":11,"tickets":25,"comments":32,"events":57}
```

No test coverage percentage was measured. No throughput, latency, uptime or load-test figure is claimed. Build output sizes are available in the raw log but are not application performance measurements.

## Acceptance checklist from kit document 15

| Requirement | Status | Evidence |
| --- | --- | --- |
| Rails and React start and communicate over JSON | PASS | Real browser workflows through Vite's `/api` proxy |
| PostgreSQL migrations and idempotent seeds | PASS | Development, test and independent fresh database; two seed runs |
| Cookie login/logout and negative CSRF test | PASS | identity_spec; security_matrix covers every mutation route and hostile Origin; browser logout/login |
| Two organizations, roles and dual member | PASS | 11 seed accounts; dual-member browser journey verifies Acme admin → Orbit customer |
| Server-side role, ownership and tenant isolation | PASS | tickets_spec, admin_spec, security_matrix; browser foreign-ticket 404 |
| Ticket create/list/detail/update, numbering, category, transitions | PASS | tickets_spec + full customer/agent browser flow; eight concurrent creators all unique |
| Internal notes inaccessible through any exposed customer API | PASS | comments, detail and events assertions; staff notification filtering; actual customer screenshot |
| Relevant ticket audit history | PASS | Creation, status, priority, assignment, category, public/internal reply and SLA events; immutable model hooks |
| Filters/search/sort/pagination and scoped dashboard | PASS | Request assertions, frontend query tests, customer aggregates and date-filter tests |
| Member/category/SLA administration | PASS | Request tests for all actions, last-admin protection and audits; browser creates local user, deactivates category, edits policy |
| Real Sidekiq/Redis, both SLA kinds, idempotence | PASS | Worker integration evidence and deterministic job tests; scheduled scan registered |
| Notification list/unread/mark-read | PASS | Ownership/tenant request tests; frontend count test; browser assigns ticket then consumes real worker notification |
| Responsive interface and loading/error/empty states | PASS | RTL assertions, mobile navigation keyboard tests; 390px/375px overflow checks and actual screenshots |
| RSpec model/request/service/job suites | PASS | 29 examples, 0 failures; services exercised directly and through API/job tests |
| Vitest/React Testing Library | PASS | 9 tests |
| Frontend production build/typecheck | PASS | Strict TypeScript and Vite build |
| Playwright privacy workflow and tenant separation | PASS | 8 journeys, all passed; real cookies and CSRF |
| No committed secrets; demo credentials labeled | PASS | Ignore rules, source inspection and tracked-path scan; only explicitly local test/demo credentials |
| CI DB/Redis services and real commands | PARTIAL | `.github/workflows/ci.yml` present, mirrors local checks; remote GitHub execution unverified |
| README commands checked, no Docker dependency | PASS | PowerShell services/setup/checks and process commands run locally; other OS instructions clearly unverified |
| Real screenshots saved | PASS | 13 actual browser PNGs; screenshot tests wait for data, reject alerts, assert no horizontal overflow and no pageerror |
| Commands, results and date documented | PASS | This report, PROGRESS and raw evidence logs |
| Deliverables and open issues explained | PASS | README, architecture, API, decisions, demo guide, evidence, CI and final delivery |

## Browser journeys and evidence

1. Customer creates and replies; agent assigns, adds internal/public comments, resolves; customer sees public response and no internal note.
2. Orbit agent visits known Acme ticket URL and receives generic unavailable/404; customer cannot enter admin settings.
3. Dual-member organization switch changes permissions and clears the organization view.
4. Admin edits high-priority first response to seven minutes; subsequent ticket snapshots it; original policy restored in `finally`.
5. Admin creates/deactivates a category and creates a local member.
6. Admin assigns a new ticket to itself; real Sidekiq notification arrives; mark-read updates count.
7. Desktop captures at 1280×800.
8. Mobile captures at 390×844 plus 375px inbox; menu Escape/focus behavior and layout overflow assertions.

Screenshot files: `login-{desktop,mobile}.png`, `dashboard-{desktop,mobile}.png`, `inbox-{desktop,mobile}.png`, `inbox-mobile-375.png`, `detail-staff-{desktop,mobile}.png`, `detail-customer-{desktop,mobile}.png`, `sla-{desktop,mobile}.png`, all under `docs/screenshots/`. Full-page screenshots may exceed viewport height. Desktop dashboard and mobile dashboard were visually inspected, along with staff/customer views during browser debugging. No screenshots were generated or mocked.

## Failures found and resolved

- Ruby/Redis initially absent. Installed ignored portable runtimes and MSYS2 native build tools. The silent Ruby Devkit installer was rejected by automatic approval review; portable archive setup succeeded.
- Existing PostgreSQL service credentials unavailable. Created an independent loopback-only cluster; left original service untouched.
- Initial Rails db:prepare against nonexistent databases surfaced a libpq connection error. Explicit `createdb` followed by db:prepare succeeded; setup script now checks/creates databases first.
- Initial sidekiq-cron initializer used an unavailable `create!` method. Replaced with checked `Job.new(...).save`; real worker startup and cron registration then passed.
- Worker verifier initially reused Rails query-cached counts. Added uncached polling and verified actual committed worker writes.
- Browser select labels needed explicit accessible names. Added aria-labelledby to form controls.
- Same-resource refresh temporarily removed ticket controls and could discard reply drafts. Retained keyed data during refresh; resource/org changes still invalidate it.
- Empty UUID selection generated unnecessary category events. Normalized blank association IDs before change comparison.
- Historical ticket mutation could fail after creator deactivation. Validate active creator/assignee only when those associations change or on creation; negative assignment checks remain.
- Concurrent numbering test cleanup used an association's nullification behavior. Changed cleanup to explicit tenant-constrained delete relations; eight concurrent PostgreSQL transactions then passed with no duplicate numbers.
- Browser tests navigated before logout finished and used an ambiguous status locator during loading. Added explicit completion waits and targeted success text; final suite passed.
- Initial Vitest dependency audit showed advisories. Selected compatible patched Vitest 4.1.12; final npm audit reported zero vulnerabilities.
- A setup rerun encountered Windows's lock on the live Vite/esbuild executable. Stopped the project-owned processes and reran successfully; setup now checks for the running Vite process before reinstalling dependencies.

## Remaining limits

No required local feature is BLOCKED. Remote GitHub Actions has not run; no remote repository, deployment or cloud account was created. Linux/macOS commands and non-Chromium browsers remain unexecuted. Production HTTPS cookie behavior is configured but not tested with a TLS server. No measured coverage or load testing. No Ruby style linter was added; Ruby syntax/autoload and behavior tests ran. The Windows Redis build is a community port; Sidekiq reports unsupported TTIN/TSTP signals, although job processing and retries were verified. These local runtime results do not establish production suitability.

The local service cluster uses ignored data and loopback-only trust; it is for a single-user developer machine. Use PostgreSQL credentials and a supported worker platform for any future deployment. Browser/demo checks intentionally add labeled records to development. No local seed data was presented as real customer traffic.
