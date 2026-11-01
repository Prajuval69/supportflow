# Decisions

2026-11-01. Read AGENTS.md, master prompt, README and docs 02–16 before writing application code.

1. Monorepo with a full-controller Rails JSON app, Vite React TypeScript SPA, PostgreSQL and Sidekiq. No hosted services or Docker required. Sites local-only workflow applies; no hosting registration.
2. Cookie sessions, HTTP-only / SameSite=Lax, Secure in production; session rotation on login and logout. Rails forgery protection remains enabled, including request specs. Vite preserves Host and Origin. CSRF token refreshed after login.
3. Every authenticated domain request validates X-Organization-ID against active membership, and every resource scope starts there. Customers are further restricted to created_by. No shared frontend query cache; remount organization subtree and cancel stale requests on switch.
4. Organization row locks serialize ticket numbering and last-admin changes. Database foreign keys, unique constraints and tenant association validation complement request authorization.
5. Calendar elapsed UTC SLA snapshots at creation. Policy and priority changes preserve existing deadlines. Reopen preserves original first response and resolution deadlines, making old overdue work immediately actionable. Breach deduplication is per ticket/kind for its lifetime.
6. Customers cannot mutate ticket attributes or reopen. Closed tickets reject comments and updates. Staff lifecycle transitions are explicit; resolved may reopen to in_progress.
7. Internal notes create no customer-visible event or notification. Customer timelines allow only public creation/status/reply events with safe metadata; responses omit comment counts. Notifications go only to active eligible members and are reauthorized on read.
8. Admin can add an existing account by email, or create a local account with an explicit initial password (minimum 12 characters). Existing account passwords cannot be overwritten by this endpoint. Last active admin cannot be removed. UI confirms membership mutations.
9. PostgreSQL 18 is installed but its existing service requires unknown credentials. Use an isolated ignored project-local cluster on port 55432 with loopback-only trust for local development, without changing that service. RubyInstaller 3.3.10 portable and community Redis Windows 7.2.8 port will be used if verified runnable. These are local development tools, not production runtime recommendations.
10. Professional navy/teal product UI using system fonts, Tailwind and semantic controls. Marketing design-taste skill was inspected and excludes dashboards; it is not applied to this product UI. No decorative generated assets are needed.
