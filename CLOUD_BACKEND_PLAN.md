# CONTINUUM cloud backend — implementation and activation plan

## Current status

The submitted website is local-first. This document records the approved cloud direction; it does not claim a cloud backend is deployed or active.

## Approved target architecture

- Static frontend: existing HTML, CSS and vanilla JavaScript hosted on GitHub Pages.
- Authentication and database: Supabase Auth + PostgreSQL + Realtime.
- Tenant isolation: every manufacturing record belongs to a `workspace_id`; Row Level Security (RLS) must enforce workspace membership on every read/write.
- Offline editing: IndexedDB-backed operation queue with pending / syncing / synced / failed states, idempotency keys and conflict review. Browser localStorage remains the current prototype store until this is implemented and migrated.
- Privileged actions: server-side Edge Functions for invitations, role changes and account administration. Never expose a Supabase service-role key in browser code.

## Workspace and role rules

- Company registration creates a workspace; the registering account becomes Company Admin.
- Employee accounts are invited/created by a Company Admin; there is no public employee signup.
- Roles: Company Admin, Inventory Staff, Production Staff, Quality Staff and Dispatch Staff.
- Admin can review workspace activity. Employees only access permitted modules/actions.
- Deactivation blocks future sign-in but retains manufacturing history. Account deletion must preserve audit records with an actor snapshot/anonymized reference.
- Activity history is append-only for normal users and retained indefinitely according to the approved project requirement.

## Data domains to migrate

Inventory items and stock movements; production plans; products/work orders; production runs; machines; breakdown and repair events; quality checks; process inspections; dispatch records; user profiles; workspaces; memberships; notifications; audit/activity events.

Migration must back up first, validate all arrays and relationships, preserve record IDs and timestamps, avoid duplicates, verify counts, and never clear the original browser data after a failed import. LocalStorage from another device must be transferred separately by JSON export/import.

## Notification routing

- Low stock → Inventory Staff
- Machine breakdown / production loss → Production Staff
- Quality failure / inspection pending → Quality Staff
- Dispatch delay → Dispatch Staff
- Sync failure → affected user and Company Admin
- Employee account changes → Company Admin

Target channels: in-app dashboard notification, browser notification (permission required), and email (provider + server-side function required). Critical events should be immediate; routine updates can be grouped into a daily digest.

## Conflict handling

- Inventory: merge stock movements as transactions; never overwrite the current quantity blindly.
- Planning: flag overlapping schedule edits for review.
- Production: review conflicting actual quantity changes.
- Maintenance: append events; do not overwrite breakdown history.
- Quality and Process & Inspection: conflicting outcomes/approvals require review.
- Dispatch: conflicting status or quantity changes require review.
- Every resolution is written to the audit history.

## Required setup before cloud development can be completed

1. Create a Supabase project owned by the project owner.
2. Provide the project URL and publishable/anon key for frontend configuration (never provide a service-role key in chat or frontend files).
3. Apply reviewed database migrations and RLS policies.
4. Configure Auth redirect URLs for the deployed GitHub Pages domain.
5. Deploy and test server-side invitation/account functions.
6. Configure an email provider and secrets for server-side delivery.
7. Test tenant isolation, role permissions, offline replay, duplicate prevention, conflict resolution, backups and restore before treating the cloud system as submission-ready.

## Security acceptance tests

- A user from Workspace A cannot read or write Workspace B records, even by changing IDs in requests.
- An employee cannot invite users, change roles or perform admin-only actions.
- A deactivated account cannot authenticate.
- No service-role secret appears in HTML, JavaScript, repository history or browser network requests.
- Failed sync never silently discards queued edits.
- Retried operations do not duplicate inventory movements or dispatch records.
