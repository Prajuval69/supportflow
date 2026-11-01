# SupportFlow working instructions

This is the generated application. The original build specification is in the sibling SupportFlow_Codex_Build_Kit directory. Preserve Rails, React, PostgreSQL and real Sidekiq/Redis. Do not replace persistence or jobs with mocks in the running application.

Every domain API request must validate active membership and use the selected organization scope. Customers may access only their own tickets. Internal notes, note events and staff notifications must never leak to customers. Keep standard Rails CSRF protection enabled. Never commit .env, keys or runtime data.

Read docs/DECISIONS.md and docs/ARCHITECTURE.md before changing domain rules. Run scripts/check.ps1 on Windows, or the README's equivalent checks. For UI changes run the relevant Playwright journey with local services running. Update docs/TEST_REPORT.md with actual results, not inferred coverage. User instructions take precedence.
