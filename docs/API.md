# Implemented API

All paths start with `/api/v1`. JSON requests, cookie credentials, no bearer token. `GET /auth/csrf` sets the session and returns `{data:{csrf_token}}`. Include `X-CSRF-Token` on **every** write, including login and logout. Successful login rotates the session and returns a new CSRF token. Include `X-Organization-ID` on domain requests; membership is validated on each request. `/me`, `/organizations` and auth routes do not require organization selection.

| Method | Path | Result / authorization |
| --- | --- | --- |
| GET | `/health` | Non-sensitive `{data:{status:"ok",service:"supportflow"}}` |
| GET | `/auth/csrf` | Session CSRF token |
| POST | `/auth/login` | `{email,password}` → user, active memberships, new CSRF token |
| DELETE | `/auth/logout` | Reset session; 204 |
| GET | `/me` | Current user and active memberships |
| GET | `/organizations` | Membership choices only |
| GET | `/tickets` | Staff: organization tickets; customer: owned tickets |
| POST | `/tickets` | `{ticket:{title,description,priority?,category_id?}}`; tenant and creator inferred |
| GET | `/tickets/:id` | Visible ticket; generic 404 otherwise |
| PATCH | `/tickets/:id` | Staff only; `{ticket:{status?,priority?,assignee_id?,category_id?}}` |
| GET | `/tickets/:id/comments` | Public only for customer; all visible ticket comments for staff |
| POST | `/tickets/:id/comments` | `{comment:{body,visibility?}}`; internal requires staff |
| GET | `/tickets/:id/events` | Staff full timeline; customer allowlisted public events |
| GET | `/dashboard/summary` | Role-scoped aggregates; optional ISO `from` and `to` creation-date filters |
| GET | `/notifications` | Paginated recipient + tenant + current visibility scope; `unread_count` |
| PATCH | `/notifications/:id/read` | Recipient only; idempotent read timestamp |
| GET | `/memberships` | Staff directory; safe user ID, name, email, role and active flag |
| POST | `/memberships` | Admin; `{membership:{email,role,name?,password?}}` |
| PATCH | `/memberships/:id` | Admin; `{membership:{role?,active?}}`; last-admin guard |
| GET | `/categories` | Organization category directory, including inactive categories for history/settings |
| POST | `/categories` | Admin; `{category:{name}}` |
| PATCH | `/categories/:id` | Admin; `{category:{name?,active?}}` |
| GET | `/sla_policies` | Selected organization policies |
| PATCH | `/sla_policies/:priority` | Admin; `{sla_policy:{first_response_minutes?,resolution_minutes?}}` |

List parameters: `page` defaults to 1, `per_page` defaults to 20 and clamps to 1–100. `q` searches title/number with bound ILIKE, escaping wildcards. Filters: `status`, `priority`, `category_id`, `assignee_id`. Sort: `created_at`, `updated_at`, or business-ranked `priority`, with `direction=asc|desc`. Invalid ordering returns 400. Responses use `{data:[],meta:{page,per_page,total_pages,total_count}}`.

Ticket responses contain ID, number, title, description, status, priority, timestamps, SLA timestamps, `overdue`, and safe `created_by`, `assignee`, `category` display objects. No internal comment or internal count is embedded. Comment responses contain ID, body, visibility, created_at and safe author display. Event metadata contains only controlled fields; internal notes produce a staff-only event and no customer notification.

Errors use `{error:{code,message,fields?}}`: 400 malformed input/invalid ordering/date, 401 missing identity/invalid credentials, 403 permission/CSRF, 404 missing or out-of-scope record/organization, 409 duplicate/invalid transition/closed ticket/last admin, 422 field validation. Cross-tenant records and same-tenant tickets owned by another customer consistently return 404. There are no HTTP endpoints for worker execution or making tickets overdue.

Public staff replies set the first-response timestamp once. Internal notes do not. Allowed status changes:

```text
open -> in_progress | resolved
in_progress -> waiting_on_customer | resolved
waiting_on_customer -> in_progress | resolved
resolved -> in_progress | closed
closed -> (read-only)
```

Empty assignment/category IDs clear the association. Changing priority or policy does not recompute stored deadlines. Customer ticket-field mutation is denied. Comments on resolved tickets are allowed; closed tickets reject them.

For a browser-backed example, open DevTools Network during `frontend/e2e/ticket-flow.spec.ts`, or use the central client in `frontend/src/api/client.ts`. `backend/config/routes.rb` is the route source of truth.
