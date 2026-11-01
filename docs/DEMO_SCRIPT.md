# Three-minute local demo

Start services, Rails, Vite and Sidekiq using the README. Demo password is `DemoPass!12345` unless overridden with DEMO_PASSWORD before the initial seed. All identities and `.example` email domains are fictional, local-only fixtures. Seeds refuse production.

1. **0:00 — Customer:** sign in as `customer1@acme.example`. Open Tickets, create a ticket and add a public follow-up. Keep its URL.
2. **0:40 — Agent:** in another browser context sign in as `agent1@acme.example`. Open that URL, assign Acme Agent1, move to In Progress and save. Add an Internal note, then a Public reply. Resolve the ticket.
3. **1:20 — Privacy:** refresh the customer view. Show the public response and absence of internal notes and staff controls. The customer comments/events API also excludes the note, rather than relying on CSS to hide it.
4. **1:40 — Automation:** with Sidekiq running, execute `ruby bin/rails runner ../scripts/verify_worker.rb` from backend. Show the real Redis job results in `docs/evidence/worker.json`. Sign in as `admin@acme.example` and open Notifications. Mark an alert read. Explain the per-ticket lock and database uniqueness used on retries.
5. **2:15 — Settings and switching:** open SLA policies as admin. Changes affect new tickets only. Sign in as `dual@demo.example`, switch from Acme (admin) to Orbit (customer), and show that admin links disappear and the ticket list is scoped to that identity's own Orbit tickets.
6. **2:40 — Tenant boundary:** sign in as `agent1@orbit.example` and open the saved Acme ticket URL. Show the safe unavailable view and JSON 404. End with the actual test report.

More local accounts: `admin@orbit.example`, `customer2@acme.example`, `customer3@acme.example`, `agent2@acme.example`, `customer1@orbit.example`, `customer2@orbit.example`.

Screenshots are reproducible with `npm run e2e` from frontend after services and seed setup. Browser journeys add clearly labeled test records to the development database; the fresh-seed baseline remains 25 tickets. No public deployment or hosted URL is claimed.

Truthful portfolio bullets supported by this build:

- Built a local multi-tenant support SaaS with Rails, React, TypeScript and PostgreSQL, including cookie sessions, CSRF protection, role permissions and tenant isolation regression tests.
- Implemented ticket workflows and audit history with Redis-backed Sidekiq SLA escalation, retry deduplication and automated RSpec, Vitest and Playwright checks.

Be prepared to explain the generated code and disclose coding-agent assistance when asked. Do not claim production users, uptime, efficiency improvements or measured coverage.
