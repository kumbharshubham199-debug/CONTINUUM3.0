# CONTINUUM — Manual QA Checklist

Run these checks in a modern browser (preferably a fresh browser profile) before submission. Mark a test complete only after performing it yourself.

## Navigation and layout
- [ ] Login screen opens and enters the dashboard.
- [ ] Sidebar links open all six modules and Settings & Data.
- [ ] Dashboard retains its original eight operational metrics, workflow, attention alerts and quick actions.
- [ ] Layout remains usable on desktop and mobile widths.
- [ ] Warm Neutral palette and continuous-loop logo appear consistently.

## Existing manufacturing workflow
- [ ] Add, edit, search and delete an inventory item.
- [ ] Add stock and use stock; stock cannot be reduced below zero.
- [ ] Create a production plan.
- [ ] Create a production run linked to the plan.
- [ ] Verify planned 500 and actual 350 gives loss 150.
- [ ] Verify actual output above plan is shown as overproduction, not negative loss.
- [ ] Add a machine and record a breakdown.
- [ ] Verify a machine under maintenance cannot be selected for a new production run.
- [ ] Mark a breakdown repaired and verify the historical breakdown / production-loss record remains.
- [ ] Record a quality check; accepted + rejected cannot exceed inspected quantity.
- [ ] Record process stages and final inspection.
- [ ] Dispatch is available only after passed quality and passed final inspection.
- [ ] Dispatch quantity cannot exceed approved accepted quantity or production output.

## Analytics & Updates
- [ ] Add records in at least two modules and verify the pie chart distribution changes.
- [ ] Verify the activity trend reflects real action dates.
- [ ] Verify created vs updated counts change after editing an existing record.
- [ ] Filter by date range and individual module.
- [ ] Verify the recent activity feed shows actor, action and timestamp for new activity.
- [ ] Confirm an empty dataset displays empty states rather than sample values.

## Backup and offline
- [ ] Export all data to JSON.
- [ ] Import a valid backup and verify records / relationships.
- [ ] Try an invalid JSON file and verify existing records remain unchanged.
- [ ] Verify the service worker caches the static app shell when hosted on HTTPS or localhost.
- [ ] After first successful load, reopen the app offline and verify the shell opens on the same browser/device.
- [ ] Remember: local browser data is not cloud-synced; test JSON transfer separately if moving devices.

## Supabase security setup
- [ ] Run `supabase-schema.sql` in Supabase SQL Editor (already done for the current project).
- [ ] Run `supabase-role-security-migration.sql` after the initial schema.
- [ ] Verify each staff role can write only to its assigned module(s), and cannot delete records.
- [ ] Verify Administrator can manage all module records.
- [ ] Verify non-admin users cannot insert/update/delete workspace memberships.
- [ ] Test email confirmation and sign-in using the final GitHub Pages URL after setting Supabase Site URL and Redirect URLs.

## Important scope check
- [ ] Do not describe demo login / role picker as secure authentication.
- [ ] Do not describe multi-company cloud sync, email notifications or realtime sync as active until a real backend is configured and tested.
